//
//  EmergencyKitValidationError+LocalizedError.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/18/25.
//

import SwiftUI

extension EmergencyKitValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emptyName(let providedName):
            return String(localized:"The emergency kit name cannot be empty. Provided: \(providedName)", comment: "Error message when the emergency kit name is empty")
        case .emptyLocation(let providedLocation):
            return String(localized: "The emergency kit location cannot be empty. Provided: \(providedLocation)", comment: "Error message when the emergency kit location is empty")
        case .duplicateItems(let items):
            let itemNames = items.map { $0.name }.joined(separator: ", ")
            return String(localized: "The emergency kit contains duplicate items: \(itemNames). Please remove duplicates.", comment: "Error message when the emergency kit contains duplicate items")
        }
    }
}
