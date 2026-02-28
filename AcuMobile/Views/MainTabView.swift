//
//  MainTabView.swift
//  AcuMobile
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "gauge.medium") }
            VehiclesView()
                .tabItem { Label("Vehicles", systemImage: "car.fill") }
            ScheduleView()
                .tabItem { Label("Schedule", systemImage: "calendar") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .alert("Error", isPresented: .constant(app.errorMessage != nil)) {
            Button("OK") { app.errorMessage = nil }
        } message: {
            if let msg = app.errorMessage { Text(msg) }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
