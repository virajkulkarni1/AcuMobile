//
//  AppConfig.swift
//  AcuMobile
//

import Foundation

/// Central config for Smartcar and backend. Replace with your Smartcar client ID and backend URL.
enum AppConfig {
    /// Smartcar application client ID (from Smartcar Dashboard).
    static var smartcarClientId: String {
        ProcessInfo.processInfo.environment["SMARTCAR_CLIENT_ID"]
            ?? UserDefaults.standard.string(forKey: "smartcar_client_id")
            ?? ""
    }

    /// Backend base URL for token exchange, vehicle list, and climate commands (e.g. https://your-api.com).
    static var backendBaseURL: String {
        ProcessInfo.processInfo.environment["ACU_BACKEND_URL"]
            ?? UserDefaults.standard.string(forKey: "backend_base_url")
            ?? "http://localhost:8000"
    }

    /// Smartcar redirect URI for iOS: sc{clientId}://exchange
    static var smartcarRedirectURI: String {
        "sc\(smartcarClientId)://exchange"
    }

    /// Scopes requested during Connect (read vehicle info + climate control).
    static let smartcarScopes = [
        "read_vehicle_info",
        "read_vin",
        "control_climate"
    ]
}
