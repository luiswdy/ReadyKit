//
//  SwiftDataItemRepositoryError+LocalizedError.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/18/25.
//

import SwiftUICore

extension SwiftDataItemRepositoryError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .itemAlreadyExists(let providedUUID):
            return String(localized: "An item with UUID \(providedUUID.uuidString) already exists.", comment: "Error when trying to save an item that already exists.")
        case .itemNotFound(let providedUUID):
            return String(localized: "No item found with UUID \(providedUUID.uuidString).", comment: "Error when trying to fetch an item that does not exist.")
        case .fetchError(let error):
            return String(localized: "Failed to fetch items: \(error.localizedDescription)", comment: "Error when fetching items from the repository.")
        case .saveError(let error):
            return String(localized: "Failed to save item: \(error.localizedDescription)", comment: "Error when saving an item to the repository.")
        case .deleteError(let error):
            return String(localized: "Failed to delete item: \(error.localizedDescription)", comment: "Error when deleting an item from the repository.")
        case .fetchExpiringError:
            return String(localized: "Failed to fetch expiring items.", comment: "Error when fetching expiring items from the repository.")
        }
    }
}
