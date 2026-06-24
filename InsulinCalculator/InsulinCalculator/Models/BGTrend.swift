import Foundation

enum TrendArrow: String {
    case rapidlyRising  = "⬆⬆"
    case rising         = "⬆"
    case slowlyRising   = "↗"
    case stable         = "→"
    case slowlyFalling  = "↘"
    case falling        = "⬇"
    case rapidlyFalling = "⬇⬇"

    // mg/dL per minute thresholds
    static func from(rate: Double) -> TrendArrow {
        switch rate {
        case  3...:        return .rapidlyRising
        case  2..<3:       return .rising
        case  1..<2:       return .slowlyRising
        case -1..<1:       return .stable
        case -2..<(-1):    return .slowlyFalling
        case -3..<(-2):    return .falling
        default:           return .rapidlyFalling
        }
    }

    var label: String {
        switch self {
        case .rapidlyRising:  return "Rapidly Rising"
        case .rising:         return "Rising"
        case .slowlyRising:   return "Slowly Rising"
        case .stable:         return "Stable"
        case .slowlyFalling:  return "Slowly Falling"
        case .falling:        return "Falling"
        case .rapidlyFalling: return "Rapidly Falling"
        }
    }

    var color: String { // for UI
        switch self {
        case .rapidlyRising, .rapidlyFalling: return "red"
        case .rising, .falling:               return "orange"
        case .slowlyRising, .slowlyFalling:   return "yellow"
        case .stable:                         return "green"
        }
    }

    // Additional units needed based on trend, projected 30 min ahead
    func doseAdjustment(isf: Double) -> Double {
        guard isf > 0 else { return 0 }
        let projectedDelta = ratePerMinute * 30
        return projectedDelta / isf
    }

    private var ratePerMinute: Double {
        switch self {
        case .rapidlyRising:  return 3.5
        case .rising:         return 2.5
        case .slowlyRising:   return 1.0
        case .stable:         return 0
        case .slowlyFalling:  return -1.0
        case .falling:        return -2.5
        case .rapidlyFalling: return -3.5
        }
    }
}

struct BGTrendReading {
    let rate: Double        // mg/dL per minute
    let arrow: TrendArrow
    let sampleAge: TimeInterval  // seconds since most recent sample

    static func calculate(current: Double, previous: Double, interval: TimeInterval) -> BGTrendReading {
        let rate = interval > 0 ? (current - previous) / (interval / 60) : 0
        return BGTrendReading(rate: rate, arrow: TrendArrow.from(rate: rate), sampleAge: 0)
    }
}
