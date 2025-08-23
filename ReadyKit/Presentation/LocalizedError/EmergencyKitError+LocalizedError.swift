//
//  EmergencyKitError+LocalizedError.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/18/25.
//

import SwiftUICore

extension EmergencyKitError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .nilEmergencyKitId:
            return "Emergency kit ID cannot be nil."
        case .noSuchEmergencyKit(let providedUUID):
            return "Emergency kit with ID \(providedUUID.uuidString) not found."
        }
    }
}
