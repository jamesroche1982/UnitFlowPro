import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyStore: DoseHistoryStore

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if historyStore.entries.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock.badge.xmark",
                        description: Text("Calculated doses will appear here.")
                    )
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
                if !historyStore.entries.isEmpty {
                    EditButton()
                }
            }
        }
    }
}

struct HistoryRow: View {
    let entry: DoseEntry
    let dateFormatter: DateFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(String(format: "%.1f units", entry.totalDose))
                    .font(.headline)
                    .foregroundStyle(.blue)
                Spacer()
                Text(dateFormatter.string(from: entry.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                Label(String(format: "%.0f %@", entry.currentBG, entry.glucoseUnit.rawValue), systemImage: "drop.fill")
                    .font(.subheadline)
                    .foregroundStyle(.red)

                if entry.carbs > 0 {
                    Label(String(format: "%.0f g carbs", entry.carbs), systemImage: "fork.knife")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }

            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}
