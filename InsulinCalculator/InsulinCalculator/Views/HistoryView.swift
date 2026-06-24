import SwiftUI

enum HistoryTab { case list, chart, stats }

struct HistoryView: View {
    @ObservedObject var historyStore: DoseHistoryStore
    let glucoseUnit: GlucoseUnit

    @State private var tab: HistoryTab = .list
    @State private var showExport = false
    @State private var exportItem: Any?
    @State private var pdfDays = 14

    private var stats: GlucoseStats { GlucoseStats(entries: historyStore.entries, unit: glucoseUnit) }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if historyStore.entries.isEmpty {
                    ContentUnavailableView("No History", systemImage: "clock.badge.xmark",
                        description: Text("Calculated doses will appear here."))
                } else {
                    switch tab {
                    case .list:  listView
                    case .chart: HistoryChartView(entries: historyStore.entries)
                    case .stats: StatsView(stats: stats)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar { toolbarContent }
        }
    }

    // MARK: - List

    private var listView: some View {
        List {
            ForEach(historyStore.entries) { entry in
                HistoryRow(entry: entry, dateFormatter: dateFormatter)
            }
            .onDelete(perform: historyStore.delete)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if !historyStore.entries.isEmpty {
                Picker("View", selection: $tab) {
                    Image(systemName: "list.bullet").tag(HistoryTab.list)
                    Image(systemName: "chart.line.uptrend.xyaxis").tag(HistoryTab.chart)
                    Image(systemName: "chart.pie").tag(HistoryTab.stats)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            if !historyStore.entries.isEmpty {
                Menu {
                    Menu("Export CSV") {
                        Button("Last 7 days")  { shareCSV(days: 7) }
                        Button("Last 14 days") { shareCSV(days: 14) }
                        Button("Last 30 days") { shareCSV(days: 30) }
                        Button("All data")     { shareCSV(days: 3650) }
                    }
                    Menu("Export PDF Report") {
                        Button("Last 7 days")  { sharePDF(days: 7) }
                        Button("Last 14 days") { sharePDF(days: 14) }
                        Button("Last 30 days") { sharePDF(days: 30) }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    // MARK: - Export

    private func shareCSV(days: Int) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let entries = historyStore.entries.filter { $0.date >= cutoff }
        var csv = "Date,Blood Glucose,Unit,Carbs (g),Dose (units),Notes\n"
        let f = ISO8601DateFormatter()
        for e in entries {
            csv += [f.string(from: e.date), String(e.currentBG), e.glucoseUnit.rawValue,
                    String(e.carbs), String(e.totalDose),
                    e.notes.replacingOccurrences(of: ",", with: ";")].joined(separator: ",") + "\n"
        }
        exportItem = csv
        showExport = true
    }

    private func sharePDF(days: Int) {
        let pdfData = PDFReportGenerator(stats: stats, days: days).generate()
        exportItem = pdfData
        showExport = true
    }

    private var exportSheet: some View {
        Group {
            if let item = exportItem {
                ShareSheet(activityItems: [item])
            }
        }
    }
}

// MARK: - History Row

struct HistoryRow: View {
    let entry: DoseEntry
    let dateFormatter: DateFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(String(format: "%.1f units", entry.totalDose))
                    .font(.headline).foregroundStyle(.blue)
                Spacer()
                Text(dateFormatter.string(from: entry.date))
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                Label(String(format: "%.0f %@", entry.currentBG, entry.glucoseUnit.rawValue), systemImage: "drop.fill")
                    .font(.subheadline).foregroundStyle(.red)
                if entry.carbs > 0 {
                    Label(String(format: "%.0f g carbs", entry.carbs), systemImage: "fork.knife")
                        .font(.subheadline).foregroundStyle(.orange)
                }
            }
            if !entry.notes.isEmpty {
                Text(entry.notes).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
