import SwiftUI
import Charts

enum ChartRange: String, CaseIterable, Identifiable {
    case week = "7d"
    case twoWeeks = "14d"
    case month = "30d"
    var id: String { rawValue }
    var days: Int { switch self { case .week: return 7; case .twoWeeks: return 14; case .month: return 30 } }
}

struct HistoryChartView: View {
    let entries: [DoseEntry]
    @State private var range: ChartRange = .week

    private var filtered: [DoseEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -range.days, to: Date())!
        return entries.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Range", selection: $range) {
                ForEach(ChartRange.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            if filtered.isEmpty {
                ContentUnavailableView("No data", systemImage: "chart.line.downtrend.xyaxis")
                    .frame(height: 200)
            } else {
                Chart {
                    ForEach(filtered) { entry in
                        LineMark(x: .value("Date", entry.date),
                                 y: .value("Dose (u)", entry.totalDose))
                            .foregroundStyle(.blue)
                            .symbol(Circle().strokeBorder(lineWidth: 2))
                            .interpolationMethod(.catmullRom)

                        PointMark(x: .value("Date", entry.date),
                                  y: .value("Dose (u)", entry.totalDose))
                            .foregroundStyle(.blue)
                            .annotation(position: .top) {
                                Text(String(format: "%.1f", entry.totalDose))
                                    .font(.system(size: 9))
                                    .foregroundStyle(.blue)
                            }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: range.days > 14 ? 7 : 2)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: 220)
                .chartYAxisLabel("Units", position: .leading)

                // BG chart
                Chart {
                    ForEach(filtered) { entry in
                        LineMark(x: .value("Date", entry.date),
                                 y: .value("BG", entry.currentBG))
                            .foregroundStyle(.red.opacity(0.7))
                            .interpolationMethod(.catmullRom)

                        PointMark(x: .value("Date", entry.date),
                                  y: .value("BG", entry.currentBG))
                            .foregroundStyle(.red)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: range.days > 14 ? 7 : 2)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: 160)
                .chartYAxisLabel(filtered.first?.glucoseUnit.rawValue ?? "mg/dL", position: .leading)
            }
        }
        .padding()
        .background(.background)
    }
}
