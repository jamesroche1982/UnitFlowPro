import Foundation

struct DoseCalculation {
    let currentBG: Double
    let carbs: Double
    let iob: Double
    let trendAdjustment: Double   // extra units from BG rate of change
    let settings: InsulinSettings

    var correctionDose: Double {
        let diff = currentBG - settings.targetBloodGlucose
        guard settings.insulinSensitivityFactor > 0 else { return 0 }
        return diff / settings.insulinSensitivityFactor
    }

    var mealDose: Double {
        guard settings.carbRatio > 0 else { return 0 }
        return carbs / settings.carbRatio
    }

    var rawTotal: Double { correctionDose + mealDose + trendAdjustment }

    var totalDose: Double { max(0, rawTotal - iob) }

    var roundedTotalDose: Double { (totalDose * 2).rounded() / 2 }
}

// MARK: - Hypo Guard

enum HypoStatus {
    case safe
    case caution(bg: Double)    // 70–80 mg/dL
    case hypo(bg: Double)       // < 70 mg/dL

    static func evaluate(bg: Double, unit: GlucoseUnit) -> HypoStatus {
        let mgdL = unit == .mgdL ? bg : bg * 18.0
        if mgdL < 70  { return .hypo(bg: bg) }
        if mgdL < 80  { return .caution(bg: bg) }
        return .safe
    }

    var blocksCalculation: Bool {
        if case .hypo = self { return true }
        return false
    }
}
