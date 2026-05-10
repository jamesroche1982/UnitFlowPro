import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: CalculatorViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Glucose Unit", selection: $viewModel.settings.glucoseUnit) {
                        ForEach(GlucoseUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)
                } header: {
                    Text("Units")
                }

                Section {
                    LabeledContent("Carb Ratio") {
                        HStack {
                            TextField("15", value: $viewModel.settings.carbRatio, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                            Text("g / unit")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }

                    LabeledContent("Sensitivity Factor (ISF)") {
                        HStack {
                            TextField("50", value: $viewModel.settings.insulinSensitivityFactor, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                            Text("\(viewModel.settings.glucoseUnit.rawValue) / unit")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }

                    LabeledContent("Target Blood Glucose") {
                        HStack {
                            TextField("100", value: $viewModel.settings.targetBloodGlucose, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                            Text(viewModel.settings.glucoseUnit.rawValue)
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                } header: {
                    Text("Personal Settings")
                } footer: {
                    Text("Set by your endocrinologist. Consult your doctor before changing these values.")
                }

                Section("About") {
                    LabeledContent("Formula") {
                        Text("(BG − Target) ÷ ISF + Carbs ÷ Ratio")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Rounding", value: "Nearest 0.5 unit")
                    LabeledContent("Version", value: "1.0")
                }

                Section {
                    Text("This app is a calculation aid only. It does not replace professional medical advice. Always verify doses with your healthcare team. Never adjust insulin based solely on this calculator without medical guidance.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Medical Disclaimer")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { viewModel.saveSettings() }
                }
            }
        }
    }
}
