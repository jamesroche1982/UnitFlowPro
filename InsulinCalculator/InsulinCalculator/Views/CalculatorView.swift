import SwiftUI

struct CalculatorView: View {
    @ObservedObject var viewModel: CalculatorViewModel
    @FocusState private var focusedField: Field?

    enum Field { case bg, carbs, notes }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    disclaimerBanner

                    inputSection

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
        }
    }

    private var disclaimerBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("Always confirm doses with your healthcare provider.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    private var inputSection: some View {
        VStack(spacing: 16) {
            GroupBox("Blood Glucose") {
                HStack {
                    TextField("Current level", text: $viewModel.currentBGText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .bg)
                        .font(.title2)
                    Text(viewModel.settings.glucoseUnit.rawValue)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .padding(.top, 4)
            }

            GroupBox("Carbohydrates") {
                HStack {
                    TextField("0", text: $viewModel.carbsText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .carbs)
                        .font(.title2)
                    Text("grams")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .padding(.top, 4)
            }

            GroupBox("Notes (optional)") {
                TextField("Meal description, etc.", text: $viewModel.notes, axis: .vertical)
                    .focused($focusedField, equals: .notes)
                    .lineLimit(2...4)
                    .padding(.top, 4)
            }

            Button(action: {
                focusedField = nil
                withAnimation { viewModel.calculate() }
            }) {
                Label("Calculate Dose", systemImage: "function")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canCalculate ? Color.blue : Color.gray.opacity(0.4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!viewModel.canCalculate)
        }
    }
}

struct ResultCard: View {
    let calculation: DoseCalculation

    var body: some View {
        VStack(spacing: 16) {
            Text("Recommended Dose")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(String(format: "%.1f units", calculation.roundedTotalDose))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.blue)

            Divider()

            HStack {
                breakdown(label: "Meal dose", value: calculation.mealDose)
                Spacer()
                breakdown(label: "Correction", value: calculation.correctionDose)
            }

            if calculation.correctionDose < 0 {
                Label("Correction is negative (BG below target) — meal dose reduced accordingly.", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private func breakdown(label: String, value: Double) -> some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "%.2f u", value))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(value < 0 ? .red : .primary)
        }
    }
}
