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

                    // Hypo warning — shown above everything else
                    switch viewModel.hypoStatus {
                    case .hypo(let bg):
                        HypoWarningCard(bg: bg, unit: viewModel.settings.glucoseUnit, severe: true)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    case .caution(let bg):
                        HypoWarningCard(bg: bg, unit: viewModel.settings.glucoseUnit, severe: false)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    case .safe:
                        EmptyView()
                    }

                    if viewModel.iob > 0.05 { iobBanner }

                    if viewModel.settings.timeSchedulesEnabled, let s = viewModel.activeSchedule {
                        activeScheduleBanner(s)
                    }

                    inputSection

                    if viewModel.timerActive {
                        CountdownCard(seconds: viewModel.countdown, onDismiss: viewModel.stopTimer)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if let calc = viewModel.lastCalculation {
                        ResultCard(calculation: calc, trend: viewModel.trend)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding()
            }
            .navigationTitle("Insulin Calculator")
            .toolbar {
                ToolbarItem(placement: .keyboard) { Button("Done") { focusedField = nil } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.lastCalculation != nil { Button("Reset", action: viewModel.reset) }
                }
            }
            .animation(.spring(), value: viewModel.lastCalculation != nil)
            .animation(.spring(), value: viewModel.timerActive)
            .animation(.spring(), value: viewModel.iob)
            .animation(.spring(), value: "\(viewModel.hypoStatus)")
            .sheet(isPresented: $showingPresets) {
                MealPresetsView(presetStore: viewModel.presetStore) { viewModel.applyPreset($0) }
            }
        }
    }

    // MARK: - Banners

    private var disclaimerBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            Text("Always confirm doses with your healthcare provider.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
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
        .padding(10).background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    private func activeScheduleBanner(_ schedule: TimeSchedule) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill").foregroundStyle(.teal)
            Text("Using **\(schedule.name)** schedule — ratio \(Int(schedule.carbRatio))g/u, ISF \(Int(schedule.insulinSensitivityFactor))")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
        .background(.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 14) {
            GroupBox {
                HStack {
                    TextField("Current level", text: $viewModel.currentBGText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .bg)
                        .font(.title2)
                        .onChange(of: viewModel.currentBGText) { viewModel.onBGChanged() }

                    // Trend arrow from HealthKit
                    if let trend = viewModel.trend {
                        Text(trend.arrow.rawValue)
                            .font(.title3)
                            .help(trend.arrow.label)
                    }

                    if viewModel.healthKitAuthorized {
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

                // Trend detail row
                if let trend = viewModel.trend {
                    HStack {
                        Text(trend.arrow.label)
                            .font(.caption).foregroundStyle(.secondary)
                        if abs(trend.rate) > 1 {
                            Text(String(format: "(%.1f mg/dL/min)", trend.rate))
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                        Spacer()
                        if abs(trend.arrow.doseAdjustment(isf: viewModel.effectiveISF)) > 0.05 {
                            let adj = trend.arrow.doseAdjustment(isf: viewModel.effectiveISF)
                            Text(String(format: "%+.2f u trend adjustment", adj))
                                .font(.caption).foregroundStyle(adj > 0 ? .orange : .blue)
                        }
                    }
                }
            } label: { Text("Blood Glucose") }

            Toggle("Correction dose only (no meal)", isOn: $viewModel.correctionOnly)
                .font(.subheadline).tint(.blue)

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

            GroupBox {
                TextField("Meal description, etc.", text: $viewModel.notes, axis: .vertical)
                    .focused($focusedField, equals: .notes).lineLimit(2...4).padding(.top, 4)
            } label: { Text("Notes (optional)") }

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
}

// MARK: - Hypo Warning Card

struct HypoWarningCard: View {
    let bg: Double
    let unit: GlucoseUnit
    let severe: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: severe ? "cross.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(severe ? .red : .orange)
                    .font(.title3)
                Text(severe ? "Low Blood Glucose — Do Not Dose" : "Blood Glucose Approaching Low")
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundStyle(severe ? .red : .orange)
            }
            Text(severe
                 ? "BG of \(String(format: "%.0f", bg)) \(unit.rawValue) is below 70 mg/dL. Treat the low first: take 15g fast-acting carbs, wait 15 minutes, then recheck before considering insulin."
                 : "BG of \(String(format: "%.0f", bg)) \(unit.rawValue) is between 70–80 mg/dL. Exercise caution — confirm with your care team before dosing.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((severe ? Color.red : Color.orange).opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke((severe ? Color.red : Color.orange).opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Result Card

struct ResultCard: View {
    let calculation: DoseCalculation
    let trend: BGTrendReading?

    var body: some View {
        VStack(spacing: 16) {
            Text("Recommended Dose").font(.headline).foregroundStyle(.secondary)

            Text(String(format: "%.1f units", calculation.roundedTotalDose))
                .font(.system(size: 56, weight: .bold, design: .rounded)).foregroundStyle(.blue)

            Divider()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                breakdown(label: "Meal", value: calculation.mealDose)
                breakdown(label: "Correction", value: calculation.correctionDose)
                if abs(calculation.trendAdjustment) > 0.01 {
                    breakdown(label: "Trend adj.", value: calculation.trendAdjustment, color: .orange)
                }
                breakdown(label: "IOB", value: -calculation.iob, color: .purple)
            }

            if let trend, trend.arrow != .stable {
                HStack(spacing: 6) {
                    Text(trend.arrow.rawValue)
                    Text("\(trend.arrow.label) — dose adjusted by \(String(format: "%+.2f u", calculation.trendAdjustment)) for trend.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            if calculation.iob > 0.05 {
                Label(String(format: "%.2f u active insulin subtracted.", calculation.iob), systemImage: "checkmark.shield.fill")
                    .font(.caption).foregroundStyle(.purple)
            }
        }
        .padding()
        .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private func breakdown(label: String, value: Double, color: Color = .primary) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(String(format: "%.2f u", value))
                .font(.caption.monospacedDigit())
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

    private var timeString: String { String(format: "%d:%02d", seconds / 60, seconds % 60) }
}
