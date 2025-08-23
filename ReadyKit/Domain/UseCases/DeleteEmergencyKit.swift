//
//  DeleteEmergencyKit.swift
//  ReadyKit
//
//  Created by Luis Wu on 6/28/25.
//

import Foundation

struct DeleteEmergencyKitRequest {
    let emergencyKitId: UUID
}

typealias DeleteEmergencyKitResult = Result<Void, Error>

final class DeleteEmergencyKitUseCase {
    private let repository: EmergencyKitRepository
    
    init(repository: EmergencyKitRepository) {
        self.repository = repository
    }
    
    func execute(request: DeleteEmergencyKitRequest) -> DeleteEmergencyKitResult {
        do {
            try repository.deleteEmergencyKit(by: request.emergencyKitId)
        } catch {
            return .failure(error)
        }
        return .success(())
    }
}
