// CreateEmergencyKit.swift
// ReadyKit
//
// Created by Luis Wu on 6/28/25.
//
import Foundation

struct CreateEmergencyKitRequest {
    let name: String
    let items: [Item]
    let photo: Data?
    let location: String
}

typealias CreateEmergencyKitResult = Result<Void, Error>

final class CreateEmergencyKitUseCase {
    private let repository: EmergencyKitRepository

    init(repository: EmergencyKitRepository) {
        self.repository = repository
    }

    func execute(request: CreateEmergencyKitRequest) -> CreateEmergencyKitResult {
        do {
            let emergencyKit = try EmergencyKit(
                name: request.name,
                items: request.items,
                photo: request.photo,
                location: request.location
            )
            try repository.addEmergencyKit(emergencyKit)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
