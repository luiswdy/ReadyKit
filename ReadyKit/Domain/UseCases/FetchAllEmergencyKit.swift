//
//  FetchAllEmergencyKits.swift
//  ReadyKit
//
//  Created by Luis Wu on 6/28/25.
//

typealias FetchAllEmergencyKitsResult = Result<[EmergencyKit], Error>

final class FetchAllEmergencyKitsUseCase {
    private let repository: EmergencyKitRepository
    
    init(repository: EmergencyKitRepository) {
        self.repository = repository
    }
    
    func execute() -> FetchAllEmergencyKitsResult {
        do {
            return .success(try repository.allEmergencyKits())
        } catch {
            return .failure(error)
        }
    }
}
