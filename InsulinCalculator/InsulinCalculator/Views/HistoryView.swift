import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyStore: DoseHistoryStore
    @State private var showChart = false
    @State private var showExport = false
    @State private var exportText = ""

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if historyStore.entries.isEmpty {
                    ContentUnavailableView("No History", systemImage: "clock.badge.xmark",
                        description: Text("Calculated doses will appear here."))
                } else if showChart {
                    HistoryChartView(entries: historyStore.entries)
                } else {
                    List {
                        ForEach(historyStore.entries) { entry in
                            HistoryRow(entry: entry, dateFormatter: dateFormatter)
                        }
                        .onDelete(perform: historyStore.delete)
                    }
                }
            }
            .navigationTitle("Dose History")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !historyStore.entries.isEmpty {
                        Button {
                            withAnimation { showChart.toggle() }
                        } label: {
                            Image(systemName: showChart ? "list.bullet" : "chart.line.uptrend.xyaxis")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if !historyStore.entries.isEmpty {
                            Button {
                                exportText = generateCSV()
                                showExport = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                            if !showChart { EditButton() }
                        }
                    }
                }
            }
            .sheet(isPresented: $showExport) {
                ShareSheet(activityItems: [exportText])
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func generateCSV() -> String {
        var csv = "Date,Blood Glucose,Unit,Carbs (g),Dose (units),Notes\n"
        let f = ISO8601DateFormatter()
        for entry in historyStore.entries {
            let row = [
                f.string(from: entry.date),
                String(entry.currentBG),
                entry.glucoseUnit.rawValue,
                String(entry.carbs),
                String(entry.totalDose),
                entry.notes.replacingOccurrences(of: ",", with: ";")
            ].joined(separator: ",")
            csv += row + "\n"
        }
        return csv
    }
}

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

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
