//
//  ScheduleService.swift
//  AcuMobile
//

import Combine
import Foundation

/// Manages departure plans and computes the next departure time (for trigger engine).
final class ScheduleService: ObservableObject {
    @Published private(set) var plans: [DeparturePlan] = []
    private let calendar = Calendar.current
    private let defaultsKey = "acu_departure_plans"

    init() {
        loadFromStorage()
    }

    func addPlan(_ plan: DeparturePlan) {
        plans.append(plan)
        saveToStorage()
    }

    func updatePlan(_ plan: DeparturePlan) {
        if let i = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[i] = plan
            saveToStorage()
        }
    }

    func removePlan(id: UUID) {
        plans.removeAll { $0.id == id }
        saveToStorage()
    }

    /// Next departure time from now (or after `from`) for the given vehicle (or any if vehicleId is nil).
    func nextDeparture(after from: Date = Date(), vehicleId: String?) -> (date: Date, plan: DeparturePlan)? {
        let relevant = plans.filter { $0.vehicleId == nil || $0.vehicleId == vehicleId }
        var best: (Date, DeparturePlan)?
        for plan in relevant {
            guard let dep = plan.nextDeparture(after: from, calendar: calendar) else { continue }
            if best == nil || dep < best!.0 {
                best = (dep, plan)
            }
        }
        return best
    }

    private func loadFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([DeparturePlan].self, from: data) else { return }
        plans = decoded
    }

    private func saveToStorage() {
        guard let data = try? JSONEncoder().encode(plans) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
