//
//  AcuMobileApp.swift
//  AcuMobile
//
//  Created by Viraj Kulkarni on 2/27/26.
//

import SwiftUI

@main
struct AcuMobileApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .onOpenURL { url in
                    _ = appState.connectService.handleCallback(url: url)
                }
        }
    }
}
