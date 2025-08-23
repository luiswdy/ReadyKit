// UpdateEmergencyKit.swift
// ReadyKit
//
// Created by Luis Wu on 6/28/25.

import Foundation

struct EditEmergencyKitRequest {
    let id: UUID
    let name: String?
    let items: [Item]?
    let photo: Data?
    let location: String?
    let shouldUpdatePhoto: Bool
}

typealias EditEmergencyKitResult = Result<Void, Error>

final class EditEmergencyKitUseCase {
    private let repository: EmergencyKitRepository

    init(repository: EmergencyKitRepository) {
        self.repository = repository
    }

    func execute(request: EditEmergencyKitRequest) -> EditEmergencyKitResult {
        do {
            var emergencyKit = try repository.fetchEmergencyKit(by: request.id)
            if let name = request.name {
                emergencyKit.name = name
            }
            if let items = request.items {
                emergencyKit.items = items
            }
            if request.shouldUpdatePhoto {
                emergencyKit.photo = request.photo
            }
            if let location = request.location {
                emergencyKit.location = location
            }
            try repository.updateEmergencyKit(emergencyKit)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
