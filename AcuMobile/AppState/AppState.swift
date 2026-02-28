//
//  AppState.swift
//  AcuMobile
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    // MARK: - Published state
    @Published var vehicles: [Vehicle] = []
    @Published var selectedVehicleId: String?
    @Published var departurePlans: [DeparturePlan] = []
    @Published var automationEnabled: Bool = true
    @Published var climateSettings: ClimateSettings = ClimateSettings()
    @Published var leadTimeMinutes: Int = 15

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var connectInProgress: Bool = false

    // MARK: - Services
    let connectService = SmartcarConnectService()
    let api = AcuMobileAPI()
    let scheduleService = ScheduleService()
    private var triggerEngine = TriggerEngine()

    var selectedVehicle: Vehicle? {
        guard let id = selectedVehicleId else { return nil }
        return vehicles.first { $0.id == id }
    }

    /// Next departure for the selected vehicle (or any).
    var nextDeparture: (date: Date, plan: DeparturePlan)? {
        scheduleService.nextDeparture(after: Date(), vehicleId: selectedVehicleId)
    }

    init() {
        departurePlans = scheduleService.plans
        connectService.onAuthorizationCode = { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let code):
                    do {
                        let response = try await self.api.exchangeCode(code)
                        if let list = response.vehicles, !list.isEmpty {
                            self.vehicles.append(contentsOf: list)
                            if self.selectedVehicleId == nil { self.selectedVehicleId = list.first?.id }
                        } else {
                            await self.loadVehicles()
                        }
                    } catch {
                        self.errorMessage = error.localizedDescription
                    }
                case .failure(let err):
                    self.errorMessage = err.localizedDescription
                }
            }
        }
    }

    /// Whether we're in the lead-time window before next departure (for UI / auto-trigger).
    var shouldTriggerPreconditioningNow: Bool {
        let dep = nextDeparture?.date
        var engine = triggerEngine
        engine.leadTimeMinutes = leadTimeMinutes
        return engine.shouldTriggerNow(nextDeparture: dep)
    }

    // MARK: - Actions

    func loadVehicles() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            vehicles = try await api.fetchVehicles()
            if selectedVehicleId == nil, let first = vehicles.first {
                selectedVehicleId = first.id
            }
            if !vehicles.contains(where: { $0.id == selectedVehicleId }) {
                selectedVehicleId = vehicles.first?.id
            }
        } catch {
            errorMessage = error.localizedDescription
            vehicles = []
        }
    }

    func connectVehicle() async {
        connectInProgress = true
        errorMessage = nil
        defer { connectInProgress = false }
        do {
            let code = try await connectService.launchConnect()
            let response = try await api.exchangeCode(code)
            if let list = response.vehicles, !list.isEmpty {
                vehicles.append(contentsOf: list)
                if selectedVehicleId == nil { selectedVehicleId = list.first?.id }
            } else {
                await loadVehicles()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func triggerClimateNow() async {
        guard let vehicleId = selectedVehicleId else {
            errorMessage = "Select a vehicle first."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await api.setClimate(
                vehicleId: vehicleId,
                action: climateSettings.startClimate ? .start : .set,
                temperatureCelsius: climateSettings.temperatureCelsius
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopClimateNow() async {
        guard let vehicleId = selectedVehicleId else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await api.stopClimate(vehicleId: vehicleId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshDeparturePlans() {
        departurePlans = scheduleService.plans
    }

    func addDeparturePlan(_ plan: DeparturePlan) {
        scheduleService.addPlan(plan)
        departurePlans = scheduleService.plans
    }

    func updateDeparturePlan(_ plan: DeparturePlan) {
        scheduleService.updatePlan(plan)
        departurePlans = scheduleService.plans
    }

    func removeDeparturePlan(id: UUID) {
        scheduleService.removePlan(id: id)
        departurePlans = scheduleService.plans
    }

    func setLeadTime(_ minutes: Int) {
        leadTimeMinutes = max(1, min(60, minutes))
    }
}
