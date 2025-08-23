//
//  FetchItemInEmergencyKit.swift
//  ReadyKit
//
//  Created by Luis Wu on 6/28/25.
//

import Foundation

struct FetchItemsInEmergencyKitRequest {
    let emergencyKitId: UUID
    let itemId: UUID
}

typealias FetchItemsInEmergencyKitResult = Result<Item, Error>

final class FetchItemInEmergencyKitUseCase {
    private let repository: EmergencyKitRepository
    
    init(repository: EmergencyKitRepository) {
        self.repository = repository
    }
    
    func execute(request: FetchItemsInEmergencyKitRequest) -> FetchItemsInEmergencyKitResult {
        do {
            let emergencyKit = try repository.fetchEmergencyKit(by: request.emergencyKitId)
            guard let item = emergencyKit.items.first(where: { $0.id == request.itemId }) else {
                return .failure(ItemError.noSuchItem(request.itemId))
            }
            return .success(item)
        } catch {
            return .failure(error)
        }
    }
}
