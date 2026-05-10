import Foundation

struct GlucoseStats {
    let entries: [DoseEntry]
    let unit: GlucoseUnit

    private var bgs: [Double] { entries.map(\.currentBG) }

    var count: Int { bgs.count }
    var isEmpty: Bool { bgs.isEmpty }

    var averageBG: Double {
        guard !bgs.isEmpty else { return 0 }
        return bgs.reduce(0, +) / Double(bgs.count)
    }

    var averageDose: Double {
        guard !entries.isEmpty else { return 0 }
        return entries.map(\.totalDose).reduce(0, +) / Double(entries.count)
    }

    // Standard ranges in mg/dL
    private var lowThreshold: Double    { unit == .mgdL ? 70 : 3.9 }
    private var highThreshold: Double   { unit == .mgdL ? 180 : 10.0 }

    var inRangeCount: Int   { bgs.filter { $0 >= lowThreshold && $0 <= highThreshold }.count }
    var belowRangeCount: Int { bgs.filter { $0 < lowThreshold }.count }
    var aboveRangeCount: Int { bgs.filter { $0 > highThreshold }.count }

    var timeInRange: Double    { guard count > 0 else { return 0 }; return Double(inRangeCount) / Double(count) }
    var timeBelowRange: Double { guard count > 0 else { return 0 }; return Double(belowRangeCount) / Double(count) }
    var timeAboveRange: Double { guard count > 0 else { return 0 }; return Double(aboveRangeCount) / Double(count) }

    // eA1C from average glucose (ADAG formula), always uses mg/dL
    var estimatedA1C: Double {
        guard !bgs.isEmpty else { return 0 }
        let avgMgdL = unit == .mmolL ? averageBG * 18.0 : averageBG
        return (avgMgdL + 46.7) / 28.7
    }

    var standardDeviation: Double {
        guard bgs.count > 1 else { return 0 }
        let mean = averageBG
        let variance = bgs.map { pow($0 - mean, 2) }.reduce(0, +) / Double(bgs.count)
        return sqrt(variance)
    }

    // Filter to last N days
    func filtered(days: Int) -> GlucoseStats {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return GlucoseStats(entries: entries.filter { $0.date >= cutoff }, unit: unit)
    }
}
