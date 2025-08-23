//
//  EditItemInEmergencyKit.swift
//  ReadyKit
//
//  Created by Luis Wu on 6/28/25.
//

import Foundation

struct EditItemInEmergencyKitRequest {
    let emergencyKitId: UUID
    let updatedItem: Item // the uuid of the item must match the one in the emergency kit
}

typealias EditItemInEmergencyKitResult = Result<Void, Error>

final class EditItemInEmergencyKitUseCase {
    private let repository: EmergencyKitRepository

    init(repository: EmergencyKitRepository) {
        self.repository = repository
    }

    func execute(request: EditItemInEmergencyKitRequest) -> EditItemInEmergencyKitResult {
        do {
            try repository.updateItemInEmergencyKit(updatedItem: request.updatedItem, emergencyKitId: request.emergencyKitId)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
