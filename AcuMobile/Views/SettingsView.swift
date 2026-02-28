//
//  SettingsView.swift
//  AcuMobile
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @AppStorage("smartcar_client_id") private var clientId = ""
    @AppStorage("backend_base_url") private var backendURL = "http://localhost:8000"

    private var startClimateBinding: Binding<Bool> {
        Binding(
            get: { app.climateSettings.startClimate },
            set: { newValue in
                app.climateSettings = ClimateSettings(
                    temperatureCelsius: app.climateSettings.temperatureCelsius,
                    startClimate: newValue
                )
            }
        )
    }

    private var temperatureBinding: Binding<Double> {
        Binding(
            get: { app.climateSettings.temperatureCelsius ?? 20 },
            set: { newValue in
                app.climateSettings = ClimateSettings(
                    temperatureCelsius: newValue,
                    startClimate: app.climateSettings.startClimate
                )
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Climate defaults") {
                    Toggle("Start climate when preconditioning", isOn: startClimateBinding)
                    HStack {
                        Text("Temperature (°C)")
                        Spacer()
                        TextField("20", value: temperatureBinding, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                }

                Section("Automation") {
                    Stepper("Lead time: \(app.leadTimeMinutes) min before", value: Binding(
                        get: { app.leadTimeMinutes },
                        set: { app.setLeadTime($0) }
                    ), in: 1...60)
                }

                Section("Developer") {
                    TextField("Smartcar Client ID", text: $clientId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Backend URL", text: $backendURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
