//
//  DeparturePlan.swift
//  AcuMobile
//

import Foundation

/// A planned departure used to trigger preconditioning (e.g. leave at 5 PM on Tuesdays).
struct DeparturePlan: Identifiable, Codable, Equatable {
    var id: UUID
    var label: String
    /// Weekday (1 = Sunday, 7 = Saturday) — nil means “every day”.
    var weekdays: Set<Int>?
    var time: TimeOfDay
    /// Optional: only apply to this vehicle ID.
    var vehicleId: String?

    init(
        id: UUID = UUID(),
        label: String,
        weekdays: Set<Int>? = nil,
        time: TimeOfDay,
        vehicleId: String? = nil
    ) {
        self.id = id
        self.label = label
        self.weekdays = weekdays
        self.time = time
        self.vehicleId = vehicleId
    }

    /// Next calendar date/time after `from` that matches this plan.
    func nextDeparture(after from: Date, calendar: Calendar = .current) -> Date? {
        let fromComponents = calendar.dateComponents([.year, .month, .day, .weekday, .hour, .minute], from: from)
        var candidate = calendar.date(from: DateComponents(
            year: fromComponents.year,
            month: fromComponents.month,
            day: fromComponents.day,
            hour: time.hour,
            minute: time.minute
        )) ?? from

        if candidate <= from {
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }

        let allowedWeekdays = weekdays ?? Set(1...7)
        var steps = 0
        while steps < 8 {
            let weekday = calendar.component(.weekday, from: candidate)
            if allowedWeekdays.contains(weekday) {
                return candidate
            }
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
            steps += 1
        }
        return candidate
    }
}

/// Time of day (hour and minute).
struct TimeOfDay: Codable, Equatable {
    var hour: Int
    var minute: Int

    var dateComponents: DateComponents { DateComponents(hour: hour, minute: minute) }

    static func from(_ date: Date, calendar: Calendar = .current) -> TimeOfDay {
        let comp = calendar.dateComponents([.hour, .minute], from: date)
        return TimeOfDay(hour: comp.hour ?? 0, minute: comp.minute ?? 0)
    }
}
