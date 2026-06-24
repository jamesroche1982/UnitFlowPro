import Foundation

struct MealPreset: Codable, Identifiable {
    var id: UUID
    var name: String
    var carbs: Double

    init(id: UUID = UUID(), name: String, carbs: Double) {
        self.id = id
        self.name = name
        self.carbs = carbs
    }

    static let defaults: [MealPreset] = [
        MealPreset(name: "Bowl of pasta", carbs: 60),
        MealPreset(name: "Sandwich", carbs: 35),
        MealPreset(name: "Banana", carbs: 27),
        MealPreset(name: "Pizza slice", carbs: 30),
        MealPreset(name: "Bowl of rice", carbs: 45),
    ]
}

class MealPresetStore: ObservableObject {
    @Published var presets: [MealPreset] = []
    private let key = "mealPresets"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([MealPreset].self, from: data) {
            presets = decoded
        } else {
            presets = MealPreset.defaults
            save()
        }
    }

    func add(_ preset: MealPreset) { presets.append(preset); save() }
    func delete(at offsets: IndexSet) { presets.remove(atOffsets: offsets); save() }
    func move(from source: IndexSet, to destination: Int) { presets.move(fromOffsets: source, toOffset: destination); save() }

    private func save() {
        if let data = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
