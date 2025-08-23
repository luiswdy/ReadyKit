//
//  AddItemToEmergencyKit.swift
//  ReadyKit
//
//  Created by Luis Wu on 6/28/25.
//

import Foundation

struct AddItemToEmergencyKitRequest {
    let emergencyKitId: UUID
    let itemName: String
    let itemQuantityValue: Int
    let itemQuantityUnitName: String
    let itemExpirationDate: Date?
    let itemNotes: String?
    let itemPhoto: Data?
}

typealias AddItemToEmergencyKitResult = Result<Void, Error>

final class AddItemToEmergencyKitUseCase {
    private let repository: EmergencyKitRepository

    init(repository: EmergencyKitRepository) {
        self.repository = repository
    }

    func execute(request: AddItemToEmergencyKitRequest) -> AddItemToEmergencyKitResult {
        do {
            // Create the new item
            let item = try Item(name: request.itemName,
                                expirationDate: request.itemExpirationDate,
                                notes: request.itemNotes,
                                quantityValue: request.itemQuantityValue,
                                quantityUnitName: request.itemQuantityUnitName,
                                photo: request.itemPhoto)

            // Add item directly to emergency kit using the efficient method
            try repository.addItemToEmergencyKit(item: item, emergencyKitId: request.emergencyKitId)

            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
