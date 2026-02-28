//
//  ClimateSettings.swift
//  AcuMobile
//

import Foundation

/// User preferences for preconditioning (temperature, etc.).
struct ClimateSettings: Codable, Equatable {
    /// Temperature in Celsius (e.g. 20).
    var temperatureCelsius: Double?
    /// Whether to start cabin climate (START) or only set temperature (SET).
    var startClimate: Bool

    init(temperatureCelsius: Double? = nil, startClimate: Bool = true) {
        self.temperatureCelsius = temperatureCelsius
        self.startClimate = startClimate
    }
}
