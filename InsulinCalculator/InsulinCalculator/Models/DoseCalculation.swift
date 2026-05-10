import Foundation

struct DoseCalculation {
    let currentBG: Double
    let carbs: Double
    let iob: Double
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

    var rawTotal: Double { correctionDose + mealDose }

    var totalDose: Double { max(0, rawTotal - iob) }

    var roundedTotalDose: Double { (totalDose * 2).rounded() / 2 }
}
