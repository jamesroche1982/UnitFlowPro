import SwiftUI
import Charts

struct StatsView: View {
    let stats: GlucoseStats
    @State private var range = 14

    private var filtered: GlucoseStats { stats.filtered(days: range) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                rangePicker

                if filtered.isEmpty {
                    ContentUnavailableView("No data for this period",
                        systemImage: "chart.pie", description: Text("Log doses to see statistics."))
                        .padding(.top, 40)
                } else {
                    a1cCard
                    tirCard
                    averagesCard
                    sdCard
                }
            }
            .padding()
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Range Picker
    private var rangePicker: some View {
        Picker("Range", selection: $range) {
            Text("7d").tag(7)
            Text("14d").tag(14)
            Text("30d").tag(30)
            Text("90d").tag(90)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - A1C Card
    private var a1cCard: some View {
        VStack(spacing: 6) {
            Text("Estimated HbA1c")
                .font(.subheadline).foregroundStyle(.secondary)
            Text(String(format: "%.1f%%", filtered.estimatedA1C))
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(a1cColor(filtered.estimatedA1C))
            Text(a1cLabel(filtered.estimatedA1C))
                .font(.caption).foregroundStyle(.secondary)
            Text("Based on \(filtered.count) readings · ADAG formula")
                .font(.caption2).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - TIR Card
    private var tirCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Time in Range")
                .font(.headline)

            HStack(spacing: 16) {
                TIRRing(inRange: filtered.timeInRange,
                        below: filtered.timeBelowRange,
                        above: filtered.timeAboveRange)
                    .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 10) {
                    tirRow(label: "In range", pct: filtered.timeInRange, color: .green,
                           range: stats.unit == .mgdL ? "70–180 mg/dL" : "3.9–10.0 mmol/L")
                    tirRow(label: "Above range", pct: filtered.timeAboveRange, color: .orange,
                           range: stats.unit == .mgdL ? ">180 mg/dL" : ">10.0 mmol/L")
                    tirRow(label: "Below range", pct: filtered.timeBelowRange, color: .red,
                           range: stats.unit == .mgdL ? "<70 mg/dL" : "<3.9 mmol/L")
                }
            }

            Text("International consensus target: ≥70% in range, <4% below")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func tirRow(label: String, pct: Double, color: Color, range: String) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption).fontWeight(.medium)
                Text(range).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Text(String(format: "%.0f%%", pct * 100))
                .font(.subheadline).fontWeight(.bold).foregroundStyle(color)
        }
    }

    // MARK: - Averages Card
    private var averagesCard: some View {
        HStack(spacing: 0) {
            statCell(value: String(format: "%.0f", filtered.averageBG),
                     unit: stats.unit.rawValue, label: "Avg BG", color: .blue)
            Divider().frame(height: 50)
            statCell(value: String(format: "%.1f", filtered.averageDose),
                     unit: "units", label: "Avg Dose", color: .purple)
            Divider().frame(height: 50)
            statCell(value: "\(filtered.count)", unit: "readings", label: "Readings", color: .teal)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func statCell(value: String, unit: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold()).foregroundStyle(color)
            Text(unit).font(.caption2).foregroundStyle(.secondary)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - SD Card
    private var sdCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Glucose Variability")
                .font(.headline)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.0f %@", filtered.standardDeviation, stats.unit.rawValue))
                        .font(.title3.bold())
                    Text("Standard deviation")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                let target = stats.unit == .mgdL ? 36.0 : 2.0
                VStack(alignment: .trailing, spacing: 2) {
                    Text(filtered.standardDeviation <= target ? "Good" : "High")
                        .font(.subheadline.bold())
                        .foregroundStyle(filtered.standardDeviation <= target ? .green : .orange)
                    Text("Target: <\(stats.unit == .mgdL ? "36" : "2.0") \(stats.unit.rawValue)")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Helpers
    private func a1cColor(_ val: Double) -> Color {
        if val < 7 { return .green }
        if val < 8 { return .yellow }
        return .red
    }

    private func a1cLabel(_ val: Double) -> String {
        if val < 6.5 { return "Below diabetes threshold" }
        if val < 7   { return "Well-controlled" }
        if val < 8   { return "Moderate — consult your doctor" }
        return "Elevated — review with your care team"
    }
}

// MARK: - TIR Ring

struct TIRRing: View {
    let inRange: Double
    let below: Double
    let above: Double

    var body: some View {
        ZStack {
            Circle().stroke(Color(.systemGray5), lineWidth: 14)

            // Above range (orange)
            Circle()
                .trim(from: 0, to: above)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 14, lineCap: .butt))
                .rotationEffect(.degrees(-90))

            // In range (green) — starts after above
            Circle()
                .trim(from: above, to: above + inRange)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 14, lineCap: .butt))
                .rotationEffect(.degrees(-90))

            // Below range (red) — starts after in-range
            Circle()
                .trim(from: above + inRange, to: 1)
                .stroke(Color.red, style: StrokeStyle(lineWidth: 14, lineCap: .butt))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 1) {
                Text(String(format: "%.0f%%", inRange * 100))
                    .font(.title3.bold()).foregroundStyle(.green)
                Text("TIR").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}
