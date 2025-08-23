//
//  DeleteItemInEmergencyKit.swift
//  ReadyKit
//
//  Created by Luis Wu on 6/28/25.
//

import Foundation

struct DeleteItemInEmergencyKitRequest {
    let itemId: UUID
    let emergencyKitId: UUID
}

typealias DeleteItemInEmergencyKitResult = Result<Void, Error>

final class DeleteItemInEmergencyKitUseCase {
    private let emergencyKitRepository: EmergencyKitRepository
    private let itemRepository: ItemRepository
    
    init(emergencyKitRepository: EmergencyKitRepository, itemRepository: ItemRepository) {
        self.emergencyKitRepository = emergencyKitRepository
        self.itemRepository = itemRepository
    }
    
    func execute(request: DeleteItemInEmergencyKitRequest) -> DeleteItemInEmergencyKitResult {
        do {
            var emergencyKit = try emergencyKitRepository.fetchEmergencyKit(by: request.emergencyKitId)
            guard let index = emergencyKit.items.firstIndex(where: { $0.id == request.itemId }) else {
                return .failure(ItemError.noSuchItem(request.itemId))
            }
            let item = emergencyKit.items[index]
            emergencyKit.items.remove(at: index)
            try itemRepository.delete(item: item)
            try emergencyKitRepository.updateEmergencyKit(emergencyKit)
        } catch {
            return .failure(error)
        }
        return .success(())
    }
}
