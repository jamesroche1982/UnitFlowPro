import Foundation

struct DoseEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let currentBG: Double
    let carbs: Double
    let totalDose: Double
    let glucoseUnit: GlucoseUnit
    let notes: String

    init(id: UUID = UUID(), date: Date = Date(), currentBG: Double, carbs: Double, totalDose: Double, glucoseUnit: GlucoseUnit, notes: String = "") {
        self.id = id
        self.date = date
        self.currentBG = currentBG
        self.carbs = carbs
        self.totalDose = totalDose
        self.glucoseUnit = glucoseUnit
        self.notes = notes
    }
}

class DoseHistoryStore: ObservableObject {
    @Published var entries: [DoseEntry] = []

    private let storageKey = "doseHistory"

    init() {
        load()
    }

    func add(_ entry: DoseEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([DoseEntry].self, from: data) else { return }
        entries = decoded
    }
}
