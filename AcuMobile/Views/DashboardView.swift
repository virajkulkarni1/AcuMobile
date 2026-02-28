//
//  DashboardView.swift
//  AcuMobile
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        NavigationStack {
            Group {
                if app.vehicles.isEmpty {
                    emptyState
                } else {
                    dashboardContent
                }
            }
            .navigationTitle("AcuMobile")
            .refreshable { await app.loadVehicles() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No vehicles connected")
                .font(.title2)
            Text("Add a vehicle in the Vehicles tab to start.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var dashboardContent: some View {
        List {
            if let vehicle = app.selectedVehicle {
                Section("Active vehicle") {
                    Label(vehicle.displayName, systemImage: "car.fill")
                }
            }

            Section("Climate") {
                Button {
                    Task { await app.triggerClimateNow() }
                } label: {
                    Label("Precondition now", systemImage: "thermometer.medium")
                }
                .disabled(app.selectedVehicleId == nil || app.isLoading)

                Button(role: .destructive) {
                    Task { await app.stopClimateNow() }
                } label: {
                    Label("Stop climate", systemImage: "stop.circle")
                }
                .disabled(app.selectedVehicleId == nil || app.isLoading)
            }

            if let next = app.nextDeparture {
                Section("Next departure") {
                    HStack {
                        Text(next.plan.label)
                        Spacer()
                        Text(next.date, style: .time)
                    }
                    Text("Preconditioning will start \(app.leadTimeMinutes) min before.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Automation") {
                Toggle("Precondition on schedule", isOn: $app.automationEnabled)
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
}
