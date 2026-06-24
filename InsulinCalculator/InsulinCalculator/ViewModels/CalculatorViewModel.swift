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
    @Published var countdown: Int = 0
    @Published var iob: Double = 0
    @Published var activeSchedule: TimeSchedule?
    @Published var healthKitAuthorized: Bool = false
    @Published var healthKitError: String?
    @Published var trend: BGTrendReading?
    @Published var hypoStatus: HypoStatus = .safe

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

    var canCalculate: Bool {
        guard let bg = currentBG else { return false }
        return !hypoStatus.blocksCalculation
    }

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

    func onBGChanged() {
        guard let bg = currentBG else { hypoStatus = .safe; return }
        hypoStatus = HypoStatus.evaluate(bg: bg, unit: settings.glucoseUnit)
    }

    func calculate() {
        guard let bg = currentBG, !hypoStatus.blocksCalculation else { return }
        refreshIOB()

        var calcSettings = settings
        calcSettings.carbRatio = effectiveCarbRatio
        calcSettings.insulinSensitivityFactor = effectiveISF
        calcSettings.targetBloodGlucose = effectiveTarget

        let trendAdj = trend?.arrow.doseAdjustment(isf: effectiveISF) ?? 0
        let calculation = DoseCalculation(currentBG: bg, carbs: carbs, iob: iob,
                                          trendAdjustment: trendAdj, settings: calcSettings)
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

    func applyPreset(_ preset: MealPreset) { carbsText = String(Int(preset.carbs)) }

    func reset() {
        currentBGText = ""; carbsText = ""; notes = ""
        lastCalculation = nil; hypoStatus = .safe
        stopTimer()
    }

    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
        refreshActiveSchedule()
    }

    func refreshIOB() {
        iob = IOBCalculator(entries: historyStore.entries, insulinDuration: settings.insulinDuration).iob()
    }

    func refreshActiveSchedule() { activeSchedule = settings.timeSchedules.active() }

    // MARK: - Timer

    private func startCountdown(seconds: Int) {
        stopTimer()
        countdown = seconds
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.countdown > 0 { self.countdown -= 1 } else { self.stopTimer() }
            }
    }

    func stopTimer() { timerCancellable?.cancel(); timerCancellable = nil; countdown = 0 }

    // MARK: - HealthKit

    func requestHealthKitPermission() {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthKitError = "Health data is not available on this device."; return
        }
        let bgType = HKQuantityType(.bloodGlucose)
        healthStore.requestAuthorization(toShare: nil, read: [bgType]) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.healthKitAuthorized = success
                if !success { self?.healthKitError = error?.localizedDescription }
                if success { self?.fetchTrend() }
            }
        }
    }

    func fetchLatestBGFromHealthKit() {
        let bgType = HKQuantityType(.bloodGlucose)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: bgType, predicate: nil, limit: 1, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            guard let self, let sample = samples?.first as? HKQuantitySample else { return }
            let value = sample.quantity.doubleValue(for: self.hkUnit)
            DispatchQueue.main.async {
                self.currentBGText = String(format: "%.0f", value)
                self.onBGChanged()
                self.fetchTrend()
            }
        }
        healthStore.execute(query)
    }

    func fetchTrend() {
        let bgType = HKQuantityType(.bloodGlucose)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        // Fetch last 2 samples within 30 minutes
        let cutoff = Date().addingTimeInterval(-1800)
        let predicate = HKQuery.predicateForSamples(withStart: cutoff, end: Date())
        let query = HKSampleQuery(sampleType: bgType, predicate: predicate, limit: 2, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            guard let self,
                  let s = samples as? [HKQuantitySample], s.count >= 2 else { return }
            let bg1 = s[0].quantity.doubleValue(for: self.hkUnit)
            let bg2 = s[1].quantity.doubleValue(for: self.hkUnit)
            let interval = s[0].endDate.timeIntervalSince(s[1].endDate)
            // Convert to mg/dL for rate calculation if needed
            let bg1mgdL = self.settings.glucoseUnit == .mmolL ? bg1 * 18 : bg1
            let bg2mgdL = self.settings.glucoseUnit == .mmolL ? bg2 * 18 : bg2
            let reading = BGTrendReading.calculate(current: bg1mgdL, previous: bg2mgdL, interval: interval)
            DispatchQueue.main.async { self.trend = reading }
        }
        healthStore.execute(query)
    }

    private var hkUnit: HKUnit {
        settings.glucoseUnit == .mgdL
            ? HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
            : HKUnit(from: "mmol/L")
    }
}
