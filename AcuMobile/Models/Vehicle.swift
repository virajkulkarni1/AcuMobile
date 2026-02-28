//
//  Vehicle.swift
//  AcuMobile
//

import Foundation

/// A vehicle connected via Smartcar.
struct Vehicle: Identifiable, Codable, Equatable {
    let id: String
    let make: String
    let model: String
    let year: Int?
    let vin: String?

    var displayName: String {
        if let year = year {
            return "\(year) \(make) \(model)"
        }
        return "\(make) \(model)"
    }
}
