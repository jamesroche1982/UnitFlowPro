import SwiftUI

struct MealPresetsView: View {
    @ObservedObject var presetStore: MealPresetStore
    var onSelect: ((MealPreset) -> Void)?

    @State private var showingAdd = false
    @State private var newName = ""
    @State private var newCarbs = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(presetStore.presets) { preset in
                    Button {
                        onSelect?(preset)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.name)
                                    .foregroundStyle(.primary)
                                Text(String(format: "%.0f g carbs", preset.carbs))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if onSelect != nil {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                .onDelete(perform: presetStore.delete)
                .onMove(perform: presetStore.move)
            }
            .navigationTitle("Meal Presets")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if onSelect != nil { Button("Cancel") { dismiss() } }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        EditButton()
                        Button { showingAdd = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                addSheet
            }
        }
    }

    private var addSheet: some View {
        NavigationStack {
            Form {
                Section("Meal Name") {
                    TextField("e.g. Bowl of pasta", text: $newName)
                }
                Section("Carbohydrates") {
                    HStack {
                        TextField("0", text: $newCarbs)
                            .keyboardType(.decimalPad)
                        Text("grams").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAdd = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let carbs = Double(newCarbs), !newName.isEmpty {
                            presetStore.add(MealPreset(name: newName, carbs: carbs))
                            newName = ""; newCarbs = ""
                            showingAdd = false
                        }
                    }
                    .disabled(newName.isEmpty || Double(newCarbs) == nil)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
