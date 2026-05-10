import Foundation
import Combine
import HealthKit

class CalculatorViewModel: ObservableObject {
    // MARK: - Inputs
    @Published var currentBGText: String = ""
    @Published var carbsText: String = ""
    @Published var notes: String = ""
    @Published var correctionOnly: Bool = false

    // MARK: - State
    @Published var settings: InsulinSettings
    @Published var lastCalculation: DoseCalculation?
    @Published var countdown: Int = 0          // seconds remaining
    @Published var iob: Double = 0
    @Published var activeSchedule: TimeSchedule?
    @Published var healthKitAuthorized: Bool = false
    @Published var healthKitError: String?

    var historyStore: DoseHistoryStore
    var presetStore: MealPresetStore

    private let settingsKey = "insulinSettings"
    private var timerCancellable: AnyCancellable?
    private let healthStore = HKHealthStore()

    init(historyStore: DoseHistoryStore, presetStore: MealPresetStore) {
        self.historyStore = historyStore
        self.presetStore = presetStore
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let saved = try? JSONDecoder().decode(InsulinSettings.self, from: data) {
            self.settings = saved
        } else {
            self.settings = .default
        }
        refreshIOB()
        refreshActiveSchedule()
    }

    // MARK: - Computed

    var currentBG: Double? { Double(currentBGText) }
    var carbs: Double { correctionOnly ? 0 : (Double(carbsText) ?? 0) }
    var canCalculate: Bool { currentBG != nil }

    var effectiveCarbRatio: Double {
        settings.timeSchedulesEnabled ? (activeSchedule?.carbRatio ?? settings.carbRatio) : settings.carbRatio
    }
    var effectiveISF: Double {
        settings.timeSchedulesEnabled ? (activeSchedule?.insulinSensitivityFactor ?? settings.insulinSensitivityFactor) : settings.insulinSensitivityFactor
    }
    var effectiveTarget: Double {
        settings.timeSchedulesEnabled ? (activeSchedule?.targetBloodGlucose ?? settings.targetBloodGlucose) : settings.targetBloodGlucose
    }

    var timerActive: Bool { countdown > 0 }

    // MARK: - Actions

    func calculate() {
        guard let bg = currentBG else { return }
        refreshIOB()

        var calcSettings = settings
        calcSettings.carbRatio = effectiveCarbRatio
        calcSettings.insulinSensitivityFactor = effectiveISF
        calcSettings.targetBloodGlucose = effectiveTarget

        let calculation = DoseCalculation(currentBG: bg, carbs: carbs, iob: iob, settings: calcSettings)
        lastCalculation = calculation

        let entry = DoseEntry(currentBG: bg, carbs: carbs, totalDose: calculation.roundedTotalDose,
                              glucoseUnit: settings.glucoseUnit, notes: notes)
        historyStore.add(entry)
        notes = ""

        if settings.preMealMinutes > 0 {
            startCountdown(seconds: settings.preMealMinutes * 60)
        }
        refreshIOB()
    }

    func applyPreset(_ preset: MealPreset) {
        carbsText = String(Int(preset.carbs))
    }

    func reset() {
        currentBGText = ""
        carbsText = ""
        notes = ""
        lastCalculation = nil
        stopTimer()
    }

    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
        refreshActiveSchedule()
    }

    func refreshIOB() {
        let calculator = IOBCalculator(entries: historyStore.entries, insulinDuration: settings.insulinDuration)
        iob = calculator.iob()
    }

    func refreshActiveSchedule() {
        activeSchedule = settings.timeSchedules.active()
    }

    // MARK: - Timer

    private func startCountdown(seconds: Int) {
        stopTimer()
        countdown = seconds
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.countdown > 0 {
                    self.countdown -= 1
                } else {
                    self.stopTimer()
                }
            }
    }

    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        countdown = 0
    }

    // MARK: - HealthKit

    func requestHealthKitPermission() {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthKitError = "Health data is not available on this device."
            return
        }
        let bgType = HKQuantityType(.bloodGlucose)
        healthStore.requestAuthorization(toShare: nil, read: [bgType]) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.healthKitAuthorized = success
                if !success { self?.healthKitError = error?.localizedDescription }
            }
        }
    }

    func fetchLatestBGFromHealthKit() {
        let bgType = HKQuantityType(.bloodGlucose)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: bgType, predicate: nil, limit: 1, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            guard let self, let sample = samples?.first as? HKQuantitySample else { return }
            let unit: HKUnit = self.settings.glucoseUnit == .mgdL ? .gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci)) : HKUnit(from: "mmol/L")
            let value = sample.quantity.doubleValue(for: unit)
            DispatchQueue.main.async {
                self.currentBGText = String(format: "%.0f", value)
            }
        }
        healthStore.execute(query)
    }
}
