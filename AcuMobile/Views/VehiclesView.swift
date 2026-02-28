//
//  VehiclesView.swift
//  AcuMobile
//

import SwiftUI

struct VehiclesView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        NavigationStack {
            List {
                ForEach(app.vehicles) { vehicle in
                    Button {
                        app.selectedVehicleId = vehicle.id
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(vehicle.displayName)
                                    .font(.headline)
                                if let vin = vehicle.vin, !vin.isEmpty {
                                    Text(vin)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if app.selectedVehicleId == vehicle.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Vehicles")
            .overlay {
                if app.vehicles.isEmpty && !app.connectInProgress {
                    ContentUnavailableView(
                        "No vehicles",
                        systemImage: "car.fill",
                        description: Text("Connect a vehicle with Smartcar to get started.")
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await app.connectVehicle() }
                    } label: {
                        if app.connectInProgress {
                            ProgressView()
                        } else {
                            Label("Connect", systemImage: "plus.circle.fill")
                        }
                    }
                    .disabled(app.connectInProgress)
                }
            }
            .refreshable { await app.loadVehicles() }
        }
    }
}

#Preview {
    VehiclesView()
        .environmentObject(AppState())
}
