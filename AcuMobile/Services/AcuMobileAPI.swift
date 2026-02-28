//
//  AcuMobileAPI.swift
//  AcuMobile
//

import Foundation

/// Backend API client: exchange auth code, fetch vehicles, trigger climate, manage departure plans.
/// Configure backend URL in AppConfig (or Settings). Token exchange and vehicle requests must run on your server.
struct AcuMobileAPI {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private var baseURL: String {
        AppConfig.backendBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private func url(_ path: String, query: [String: String]? = nil) -> URL? {
        var comp = URLComponents(string: "\(baseURL)/\(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))")
        comp?.queryItems = query?.map { URLQueryItem(name: $0.key, value: $0.value) }
        return comp?.url
    }

    // MARK: - Auth & vehicles

    /// Exchange authorization code for session. Backend returns tokens and stores them; response may include vehicle list.
    func exchangeCode(_ code: String) async throws -> ExchangeResponse {
        guard let url = url("exchange", query: ["code": code]) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: data)
        return try JSONDecoder().decode(ExchangeResponse.self, from: data)
    }

    /// Fetch list of connected vehicles from backend.
    func fetchVehicles() async throws -> [Vehicle] {
        guard let url = url("vehicles") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: data)
        let list = try JSONDecoder().decode(VehicleListResponse.self, from: data)
        return list.vehicles
    }

    // MARK: - Climate

    /// Start or set cabin climate for a vehicle. Backend calls Smartcar POST {make}/climate/cabin.
    func setClimate(vehicleId: String, action: ClimateAction, temperatureCelsius: Double?) async throws -> ClimateStateResponse {
        guard let url = url("vehicles/\(vehicleId)/climate") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = ["action": action.rawValue]
        if let temp = temperatureCelsius { body["temperature"] = temp }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: data)
        return try JSONDecoder().decode(ClimateStateResponse.self, from: data)
    }

    /// Stop cabin climate.
    func stopClimate(vehicleId: String) async throws -> ClimateStateResponse {
        try await setClimate(vehicleId: vehicleId, action: .stop, temperatureCelsius: nil)
    }

    // MARK: - Departure plans (backend can store these, or app-only; here we assume backend can sync)

    /// Fetch departure plans from backend (optional; app may store locally only).
    func fetchDeparturePlans() async throws -> [DeparturePlan] {
        guard let url = url("departure_plans") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: data)
        let list = try JSONDecoder().decode(DeparturePlansResponse.self, from: data)
        return list.plans
    }

    /// Save (create or update) a departure plan.
    func saveDeparturePlan(_ plan: DeparturePlan) async throws {
        guard let url = url("departure_plans") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(plan)
        let (_, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: nil)
    }

    /// Delete a departure plan.
    func deleteDeparturePlan(id: UUID) async throws {
        guard let url = url("departure_plans/\(id.uuidString)") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (_, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: nil)
    }

    private func validateHTTP(response: URLResponse, data: Data?) throws {
        guard let http = response as? HTTPURLResponse else { return }
        if http.statusCode >= 200 && http.statusCode < 300 { return }
        let message = (data.flatMap { try? JSONDecoder().decode(APIErrorResponse.self, from: $0) })?.message
            ?? String(data: data ?? Data(), encoding: .utf8)
            ?? "HTTP \(http.statusCode)"
        throw APIError.serverError(status: http.statusCode, message: message)
    }
}

// MARK: - DTOs

struct ExchangeResponse: Codable {
    let vehicles: [Vehicle]?
}

struct VehicleListResponse: Codable {
    let vehicles: [Vehicle]
}

enum ClimateAction: String, Codable {
    case start = "START"
    case stop = "STOP"
    case set = "SET"
}

struct ClimateStateResponse: Codable {
    let status: String?
    let temperature: Double?
}

struct DeparturePlansResponse: Codable {
    let plans: [DeparturePlan]
}

struct APIErrorResponse: Codable {
    let message: String?
}

enum APIError: LocalizedError {
    case invalidURL
    case serverError(status: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL."
        case .serverError(let status, let msg): return "Server error (\(status)): \(msg)"
        }
    }
}

