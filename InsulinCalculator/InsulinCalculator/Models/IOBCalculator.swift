import Foundation

struct IOBCalculator {
    let entries: [DoseEntry]
    let insulinDuration: Double  // hours

    func iob(at date: Date = Date()) -> Double {
        entries.reduce(0) { total, entry in
            let elapsed = date.timeIntervalSince(entry.date) / 3600  // hours
            guard elapsed >= 0, elapsed < insulinDuration else { return total }
            let remaining = 1.0 - (elapsed / insulinDuration)
            return total + entry.totalDose * remaining
        }
    }
}
