import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: CalculatorViewModel
    @State private var showingSchedules = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Units
                Section {
                    Picker("Glucose Unit", selection: $viewModel.settings.glucoseUnit) {
                        ForEach(GlucoseUnit.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented).listRowSeparator(.hidden)
                } header: { Text("Units") }

                // MARK: Appearance
                Section("Appearance") {
                    Picker("Color Scheme", selection: $viewModel.settings.appColorScheme) {
                        ForEach(AppColorScheme.allCases) { scheme in
                            Label(scheme.rawValue, systemImage: scheme.icon).tag(scheme)
                        }
                    }
                    .pickerStyle(.segmented).listRowSeparator(.hidden)
                }

                // MARK: Personal Settings
                Section {
                    LabeledContent("Carb Ratio") {
                        HStack {
                            TextField("15", value: $viewModel.settings.carbRatio, format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 70)
                            Text("g / unit").foregroundStyle(.secondary).font(.subheadline)
                        }
                    }
                    LabeledContent("Sensitivity Factor (ISF)") {
                        HStack {
                            TextField("50", value: $viewModel.settings.insulinSensitivityFactor, format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 70)
                            Text("\(viewModel.settings.glucoseUnit.rawValue) / unit").foregroundStyle(.secondary).font(.subheadline)
                        }
                    }
                    LabeledContent("Target Blood Glucose") {
                        HStack {
                            TextField("100", value: $viewModel.settings.targetBloodGlucose, format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 70)
                            Text(viewModel.settings.glucoseUnit.rawValue).foregroundStyle(.secondary).font(.subheadline)
                        }
                    }
                } header: { Text("Personal Settings") }
                  footer: { Text("Set by your endocrinologist. Consult your doctor before changing these values.") }

                // MARK: Insulin & IOB
                Section {
                    LabeledContent("Insulin Duration") {
                        HStack {
                            TextField("4", value: $viewModel.settings.insulinDuration, format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 50)
                            Text("hours").foregroundStyle(.secondary).font(.subheadline)
                        }
                    }
                } header: { Text("Insulin on Board (IOB)") }
                  footer: { Text("How long your insulin stays active. Typical range is 4–6 hours. Used to subtract remaining active insulin from your next dose.") }

                // MARK: Pre-Meal Timer
                Section {
                    LabeledContent("Pre-Meal Delay") {
                        HStack {
                            TextField("15", value: $viewModel.settings.preMealMinutes, format: .number)
                                .keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 50)
                            Text("minutes").foregroundStyle(.secondary).font(.subheadline)
                        }
                    }
                } header: { Text("Pre-Meal Timer") }
                  footer: { Text("A countdown starts after calculating. Set to 0 to disable. Fast-acting insulin typically works best 15–20 min before eating.") }

                // MARK: Time Schedules
                Section {
                    Toggle("Use Time-Based Ratios", isOn: $viewModel.settings.timeSchedulesEnabled)
                    if viewModel.settings.timeSchedulesEnabled {
                        NavigationLink("Manage Schedules (\(viewModel.settings.timeSchedules.count))") {
                            TimeSchedulesView(schedules: $viewModel.settings.timeSchedules,
                                             glucoseUnit: viewModel.settings.glucoseUnit)
                        }
                        if let active = viewModel.settings.timeSchedules.active() {
                            LabeledContent("Active Now", value: active.name)
                                .foregroundStyle(.teal)
                        }
                    }
                } header: { Text("Time Schedules") }
                  footer: { Text("Override carb ratio, ISF, and target by time of day. Useful for dawn phenomenon and different meal types.") }

                // MARK: HealthKit
                Section {
                    if viewModel.healthKitAuthorized {
                        Label("Connected to Apple Health", systemImage: "heart.fill")
                            .foregroundStyle(.red)
                    } else {
                        Button("Connect Apple Health") {
                            viewModel.requestHealthKitPermission()
                        }
                    }
                    if let err = viewModel.healthKitError {
                        Text(err).font(.caption).foregroundStyle(.red)
                    }
                } header: { Text("Apple Health") }
                  footer: { Text("Reads the latest blood glucose reading from Health to pre-fill the calculator field.") }

                // MARK: About
                Section("About") {
                    LabeledContent("Formula") {
                        Text("(BG − Target) ÷ ISF + Carbs ÷ Ratio − IOB")
                            .font(.caption.monospaced()).foregroundStyle(.secondary).multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Rounding", value: "Nearest 0.5 unit")
                    LabeledContent("Version", value: "2.0")
                }

                // MARK: Disclaimer
                Section {
                    Text("This app is a calculation aid only. It does not replace professional medical advice. Always verify doses with your healthcare team.")
                        .font(.caption).foregroundStyle(.secondary)
                } header: { Text("Medical Disclaimer") }
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
