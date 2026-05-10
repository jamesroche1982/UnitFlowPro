import SwiftUI

struct CalculatorView: View {
    @ObservedObject var viewModel: CalculatorViewModel
    @FocusState private var focusedField: Field?
    @State private var showingPresets = false

    enum Field { case bg, carbs, notes }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    disclaimerBanner

                    if viewModel.iob > 0.05 {
                        iobBanner
                    }

                    if viewModel.settings.timeSchedulesEnabled, let schedule = viewModel.activeSchedule {
                        activeScheduleBanner(schedule)
                    }

                    inputSection

                    if viewModel.timerActive {
                        CountdownCard(seconds: viewModel.countdown, onDismiss: viewModel.stopTimer)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if let calc = viewModel.lastCalculation {
                        ResultCard(calculation: calc)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding()
            }
            .navigationTitle("Insulin Calculator")
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") { focusedField = nil }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.lastCalculation != nil {
                        Button("Reset", action: viewModel.reset)
                    }
                }
            }
            .animation(.spring(), value: viewModel.lastCalculation != nil)
            .animation(.spring(), value: viewModel.timerActive)
            .animation(.spring(), value: viewModel.iob)
            .sheet(isPresented: $showingPresets) {
                MealPresetsView(presetStore: viewModel.presetStore) { preset in
                    viewModel.applyPreset(preset)
                }
            }
        }
    }

    // MARK: - Subviews

    private var disclaimerBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            Text("Always confirm doses with your healthcare provider.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    private var iobBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "timer").foregroundStyle(.purple)
            VStack(alignment: .leading, spacing: 1) {
                Text(String(format: "Active insulin: %.2f u (IOB)", viewModel.iob))
                    .font(.subheadline).fontWeight(.medium).foregroundStyle(.purple)
                Text("This will be subtracted from your next dose.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    private func activeScheduleBanner(_ schedule: TimeSchedule) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill").foregroundStyle(.teal)
            Text("Using **\(schedule.name)** schedule — ratio \(Int(schedule.carbRatio))g/u, ISF \(Int(schedule.insulinSensitivityFactor))")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    private var inputSection: some View {
        VStack(spacing: 14) {

            // BG field
            GroupBox {
                HStack {
                    TextField("Current level", text: $viewModel.currentBGText)
                        .keyboardType(.decimalPad).focused($focusedField, equals: .bg).font(.title2)
                    if HKAvailable {
                        Button {
                            focusedField = nil
                            viewModel.fetchLatestBGFromHealthKit()
                        } label: {
                            Image(systemName: "heart.fill").foregroundStyle(.red)
                        }
                    }
                    Text(viewModel.settings.glucoseUnit.rawValue).foregroundStyle(.secondary).font(.subheadline)
                }
                .padding(.top, 4)
            } label: { Text("Blood Glucose") }

            // Correction-only toggle
            Toggle("Correction dose only (no meal)", isOn: $viewModel.correctionOnly)
                .font(.subheadline)
                .tint(.blue)

            // Carbs field (hidden in correction-only mode)
            if !viewModel.correctionOnly {
                GroupBox {
                    HStack {
                        TextField("0", text: $viewModel.carbsText)
                            .keyboardType(.decimalPad).focused($focusedField, equals: .carbs).font(.title2)
                        Button { showingPresets = true } label: {
                            Label("Presets", systemImage: "fork.knife").font(.caption)
                        }
                        .buttonStyle(.bordered).controlSize(.small)
                        Text("grams").foregroundStyle(.secondary).font(.subheadline)
                    }
                    .padding(.top, 4)
                } label: { Text("Carbohydrates") }
            }

            // Notes
            GroupBox {
                TextField("Meal description, etc.", text: $viewModel.notes, axis: .vertical)
                    .focused($focusedField, equals: .notes).lineLimit(2...4).padding(.top, 4)
            } label: { Text("Notes (optional)") }

            // Calculate button
            Button {
                focusedField = nil
                withAnimation { viewModel.calculate() }
            } label: {
                Label("Calculate Dose", systemImage: "function")
                    .font(.headline).frame(maxWidth: .infinity).padding()
                    .background(viewModel.canCalculate ? Color.blue : Color.gray.opacity(0.4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!viewModel.canCalculate)
        }
    }

    private var HKAvailable: Bool {
        viewModel.healthKitAuthorized
    }
}

// MARK: - Result Card

struct ResultCard: View {
    let calculation: DoseCalculation

    var body: some View {
        VStack(spacing: 16) {
            Text("Recommended Dose").font(.headline).foregroundStyle(.secondary)

            Text(String(format: "%.1f units", calculation.roundedTotalDose))
                .font(.system(size: 56, weight: .bold, design: .rounded)).foregroundStyle(.blue)

            Divider()

            HStack {
                breakdown(label: "Meal dose", value: calculation.mealDose)
                Spacer()
                breakdown(label: "Correction", value: calculation.correctionDose)
                Spacer()
                breakdown(label: "IOB deducted", value: -calculation.iob, color: .purple)
            }

            if calculation.iob > 0.05 {
                Label(String(format: "%.2f u active insulin subtracted to prevent stacking.", calculation.iob), systemImage: "checkmark.shield.fill")
                    .font(.caption).foregroundStyle(.purple).multilineTextAlignment(.center)
            }

            if calculation.correctionDose < 0 {
                Label("BG is below target — correction is negative.", systemImage: "info.circle")
                    .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private func breakdown(label: String, value: Double, color: Color = .primary) -> some View {
        VStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(String(format: "%.2f u", value))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(value < 0 ? .red : color)
        }
    }
}

// MARK: - Countdown Card

struct CountdownCard: View {
    let seconds: Int
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer").font(.title2).foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Inject now — eat in").font(.subheadline).fontWeight(.semibold)
                Text(timeString).font(.title.monospacedDigit()).foregroundStyle(.green)
            }
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
    }

    private var timeString: String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
