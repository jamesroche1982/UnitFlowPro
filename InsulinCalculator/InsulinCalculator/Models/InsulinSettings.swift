import Foundation

struct InsulinSettings: Codable {
    var carbRatio: Double        // grams of carbs per 1 unit of insulin
    var insulinSensitivityFactor: Double  // mg/dL drop per 1 unit of insulin
    var targetBloodGlucose: Double  // mg/dL
    var glucoseUnit: GlucoseUnit

    static let `default` = InsulinSettings(
        carbRatio: 15,
        insulinSensitivityFactor: 50,
        targetBloodGlucose: 100,
        glucoseUnit: .mgdL
    )
}

enum GlucoseUnit: String, Codable, CaseIterable, Identifiable {
    case mgdL = "mg/dL"
    case mmolL = "mmol/L"

    var id: String { rawValue }

    func convert(_ value: Double, to unit: GlucoseUnit) -> Double {
        if self == unit { return value }
        if self == .mgdL && unit == .mmolL { return value / 18.0 }
        return value * 18.0
    }
}
