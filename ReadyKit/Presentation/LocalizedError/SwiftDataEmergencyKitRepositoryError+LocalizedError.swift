//
//  SwiftDataEmergencyKitRepositoryError+LocalizedError.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/18/25.
//

import SwiftUICore

extension SwiftDataEmergencyKitRepositoryError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emergencyKitAlreadyExists(let providedUUID):
            return String(localized: "Emergency kit with UUID \(providedUUID.uuidString) already exists.", comment: "Error when trying to create an emergency kit that already exists.")
        case .emergencyKitNotFound(let providedUUID):
            return String(localized: "Emergency kit with UUID \(providedUUID.uuidString) not found.", comment: "Error when trying to fetch an emergency kit that does not exist.")
        case .itemNotFound(let providedUUID):
            return String(localized: "Item with UUID \(providedUUID.uuidString) not found.", comment: "Error when trying to fetch an item that does not exist in the emergency kit.")
        case .fetchError(let error):
            return String(localized: "An error occurred while fetching data: \(error.localizedDescription)", comment: "Error when fetching data from the repository.")
        }
    }

}

