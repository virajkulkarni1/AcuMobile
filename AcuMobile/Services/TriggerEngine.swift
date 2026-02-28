//
//  TriggerEngine.swift
//  AcuMobile
//

import Foundation

/// Decides when to trigger preconditioning based on next departure and lead time.
struct TriggerEngine {
    /// Minutes before departure to start preconditioning.
    var leadTimeMinutes: Int = 15

    /// Returns true if we are currently within the lead-time window before the next departure.
    func shouldTriggerNow(nextDeparture: Date?, now: Date = Date()) -> Bool {
        guard let dep = nextDeparture else { return false }
        let windowStart = Calendar.current.date(byAdding: .minute, value: -leadTimeMinutes, to: dep) ?? dep
        return now >= windowStart && now <= dep
    }

    /// Returns the date when the next trigger should fire (start of lead-time window), or nil.
    func nextTriggerDate(nextDeparture: Date?, now: Date = Date()) -> Date? {
        guard let dep = nextDeparture else { return nil }
        let windowStart = Calendar.current.date(byAdding: .minute, value: -leadTimeMinutes, to: dep) ?? dep
        if now >= windowStart { return nil }
        return windowStart
    }
}
