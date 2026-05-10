import Foundation
import Combine

class CalculatorViewModel: ObservableObject {
    @Published var currentBGText: String = ""
    @Published var carbsText: String = ""
    @Published var notes: String = ""
    @Published var settings: InsulinSettings
    @Published var lastCalculation: DoseCalculation?

    var historyStore: DoseHistoryStore

    private let settingsKey = "insulinSettings"

    init(historyStore: DoseHistoryStore) {
        self.historyStore = historyStore
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let saved = try? JSONDecoder().decode(InsulinSettings.self, from: data) {
            self.settings = saved
        } else {
            self.settings = .default
        }
    }

    var currentBG: Double? {
        Double(currentBGText)
    }

    var carbs: Double {
        Double(carbsText) ?? 0
    }

    var canCalculate: Bool {
        currentBG != nil
    }

    func calculate() {
        guard let bg = currentBG else { return }
        let calculation = DoseCalculation(currentBG: bg, carbs: carbs, settings: settings)
        lastCalculation = calculation

        let entry = DoseEntry(
            currentBG: bg,
            carbs: carbs,
            totalDose: calculation.roundedTotalDose,
            glucoseUnit: settings.glucoseUnit,
            notes: notes
        )
        historyStore.add(entry)
        notes = ""
    }

    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    func reset() {
        currentBGText = ""
        carbsText = ""
        notes = ""
        lastCalculation = nil
    }
}
