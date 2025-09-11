//
//  EmergencyKit.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/10/25.
//

import Foundation

enum EmergencyKitValidationError: Error, Equatable {
    case emptyName(_ providedName: String)
    case emptyLocation(_ providedLocation: String)
    case duplicateItems(_ providedItems: [Item])
}

enum EmergencyKitError: Error, Equatable {
    case nilEmergencyKitId
    case noSuchEmergencyKit(_ providedId: UUID)
}

struct EmergencyKit: Equatable, Hashable {
    let id: UUID
    var name: String
    var items: [Item] = []
    var photo: Data? = nil
    var location: String = ""

    init(id: UUID = UUID(), name: String, items: [Item] = [], photo: Data? = nil, location: String = "") throws {
        // validate the inputs
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw EmergencyKitValidationError.emptyName(name)
        }
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLocation.isEmpty else {
           throw EmergencyKitValidationError.emptyLocation(location)
        }
        // assert that items are valid and no duplicate IDs exist
        guard Set(items.map { $0.id }).count == items.count else {
            throw EmergencyKitValidationError.duplicateItems(items)
        }
        self.id = id
        self.name = trimmedName
        self.items = items
        self.photo = photo
        self.location = trimmedLocation
    }
}
