import SwiftUI

struct TimeSchedulesView: View {
    @Binding var schedules: [TimeSchedule]
    let glucoseUnit: GlucoseUnit

    @State private var showingAdd = false
    @State private var editingSchedule: TimeSchedule?

    var sortedSchedules: [TimeSchedule] {
        schedules.sorted { $0.startHour < $1.startHour }
    }

    var body: some View {
        List {
            ForEach(sortedSchedules) { schedule in
                Button { editingSchedule = schedule } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(schedule.name)
                                .foregroundStyle(.primary)
                                .font(.headline)
                            Text("From \(hourLabel(schedule.startHour))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Ratio: \(Int(schedule.carbRatio))g/u")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Text("ISF: \(Int(schedule.insulinSensitivityFactor))")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            .onDelete { offsets in
                let ids = offsets.map { sortedSchedules[$0].id }
                schedules.removeAll { ids.contains($0.id) }
            }
        }
        .navigationTitle("Time Schedules")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    EditButton()
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            ScheduleEditView(schedule: TimeSchedule(name: "", startHour: 6, carbRatio: 15, insulinSensitivityFactor: 50, targetBloodGlucose: 100), glucoseUnit: glucoseUnit, isNew: true) { newSchedule in
                schedules.append(newSchedule)
            }
        }
        .sheet(item: $editingSchedule) { schedule in
            ScheduleEditView(schedule: schedule, glucoseUnit: glucoseUnit, isNew: false) { updated in
                if let idx = schedules.firstIndex(where: { $0.id == updated.id }) {
                    schedules[idx] = updated
                }
            }
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        let f = DateFormatter()
        f.dateFormat = "h a"
        return f.string(from: date)
    }
}

struct ScheduleEditView: View {
    @State var schedule: TimeSchedule
    let glucoseUnit: GlucoseUnit
    let isNew: Bool
    let onSave: (TimeSchedule) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Morning", text: $schedule.name)
                }
                Section("Start Time") {
                    Stepper("From \(hourLabel(schedule.startHour))", value: $schedule.startHour, in: 0...23)
                }
                Section("Insulin Ratios") {
                    LabeledContent("Carb Ratio") {
                        HStack {
                            TextField("15", value: $schedule.carbRatio, format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60)
                            Text("g / unit").foregroundStyle(.secondary).font(.subheadline)
                        }
                    }
                    LabeledContent("Sensitivity (ISF)") {
                        HStack {
                            TextField("50", value: $schedule.insulinSensitivityFactor, format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60)
                            Text("\(glucoseUnit.rawValue) / unit").foregroundStyle(.secondary).font(.subheadline)
                        }
                    }
                    LabeledContent("Target BG") {
                        HStack {
                            TextField("100", value: $schedule.targetBloodGlucose, format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60)
                            Text(glucoseUnit.rawValue).foregroundStyle(.secondary).font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "New Schedule" : "Edit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(schedule); dismiss() }
                        .disabled(schedule.name.isEmpty)
                }
            }
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        let f = DateFormatter()
        f.dateFormat = "h a"
        return f.string(from: date)
    }
}
