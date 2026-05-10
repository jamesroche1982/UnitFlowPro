import Foundation

struct TimeSchedule: Codable, Identifiable {
    var id: UUID
    var name: String
    var startHour: Int   // 0–23
    var carbRatio: Double
    var insulinSensitivityFactor: Double
    var targetBloodGlucose: Double

    init(id: UUID = UUID(), name: String, startHour: Int, carbRatio: Double, insulinSensitivityFactor: Double, targetBloodGlucose: Double) {
        self.id = id
        self.name = name
        self.startHour = startHour
        self.carbRatio = carbRatio
        self.insulinSensitivityFactor = insulinSensitivityFactor
        self.targetBloodGlucose = targetBloodGlucose
    }

    static let defaults: [TimeSchedule] = [
        TimeSchedule(name: "Morning", startHour: 6, carbRatio: 12, insulinSensitivityFactor: 40, targetBloodGlucose: 100),
        TimeSchedule(name: "Afternoon", startHour: 12, carbRatio: 15, insulinSensitivityFactor: 50, targetBloodGlucose: 100),
        TimeSchedule(name: "Evening", startHour: 18, carbRatio: 12, insulinSensitivityFactor: 45, targetBloodGlucose: 110),
        TimeSchedule(name: "Night", startHour: 22, carbRatio: 20, insulinSensitivityFactor: 60, targetBloodGlucose: 120),
    ]
}

extension [TimeSchedule] {
    func active(at date: Date = Date()) -> TimeSchedule? {
        guard !isEmpty else { return nil }
        let hour = Calendar.current.component(.hour, from: date)
        let sorted = self.sorted { $0.startHour < $1.startHour }
        return sorted.last(where: { $0.startHour <= hour }) ?? sorted.last
    }
}
