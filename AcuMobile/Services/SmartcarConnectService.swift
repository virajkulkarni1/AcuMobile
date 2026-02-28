//
//  SmartcarConnectService.swift
//  AcuMobile
//

import AuthenticationServices
import Combine
import Foundation
import UIKit

/// Handles launching Smartcar Connect (OAuth) and receiving the authorization code via redirect.
@MainActor
final class SmartcarConnectService: NSObject, ObservableObject {
    /// Called when Connect finishes with an authorization code (or error).
    var onAuthorizationCode: ((Result<String, Error>) -> Void)?

    /// Builds the Smartcar Connect authorization URL.
    func buildConnectURL(state: String? = nil) -> URL? {
        let clientId = AppConfig.smartcarClientId
        guard !clientId.isEmpty else { return nil }
        let redirectURI = AppConfig.smartcarRedirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? AppConfig.smartcarRedirectURI
        let scope = AppConfig.smartcarScopes.joined(separator: " ").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let state = (state ?? UUID().uuidString).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://connect.smartcar.com/oauth/authorize?response_type=code&client_id=\(clientId)&scope=\(scope)&redirect_uri=\(redirectURI)&state=\(state)"
        return URL(string: urlString)
    }

    /// Launches Smartcar Connect in a secure web session. Callback receives the authorization code or error.
    func launchConnect() async throws -> String {
        guard let url = buildConnectURL() else {
            throw SmartcarError.missingClientId
        }
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "sc\(AppConfig.smartcarClientId)"
            ) { callbackURL, error in
                if let error = error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: SmartcarError.userCancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                guard let callbackURL = callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: SmartcarError.noCodeInCallback)
                    return
                }
                continuation.resume(returning: code)
            }
            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = self
            session.start()
        }
    }

    /// Handle redirect URL (call from scene delegate or app delegate when app opens via custom scheme).
    func handleCallback(url: URL) -> Bool {
        guard url.scheme == "sc\(AppConfig.smartcarClientId)" else { return false }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
        if let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
            onAuthorizationCode?(.success(code))
            return true
        }
        if let errorItem = components.queryItems?.first(where: { $0.name == "error" })?.value {
            onAuthorizationCode?(.failure(SmartcarError.connectError(errorItem)))
        }
        return false
    }
}

extension SmartcarConnectService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let window = scene.windows.first(where: { $0.isKeyWindow }) else {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first ?? UIWindow()
        }
        return window
    }
}

enum SmartcarError: LocalizedError {
    case missingClientId
    case userCancelled
    case noCodeInCallback
    case connectError(String)

    var errorDescription: String? {
        switch self {
        case .missingClientId: return "Smartcar Client ID not set. Add it in Settings."
        case .userCancelled: return "Connect was cancelled."
        case .noCodeInCallback: return "No authorization code in redirect."
        case .connectError(let msg): return "Smartcar Connect error: \(msg)"
        }
    }
}
