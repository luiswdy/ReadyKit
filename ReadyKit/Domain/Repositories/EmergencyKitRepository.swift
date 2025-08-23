//
//  EmergencyKitRepository.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/10/25.
//

import Foundation

protocol EmergencyKitRepository {
    func addEmergencyKit(_ emergencyKit: EmergencyKit) throws
    func deleteEmergencyKit(by id: UUID) throws
    func updateEmergencyKit(_ emergencyKit: EmergencyKit) throws
    func fetchEmergencyKit(by id: UUID) throws -> EmergencyKit
    func allEmergencyKits() throws -> [EmergencyKit]

    // New method for efficiently adding a single item
    func addItemToEmergencyKit(item: Item, emergencyKitId: UUID) throws

    // New method to update individual items without affecting other items in the emergency kit
    func updateItemInEmergencyKit(updatedItem: Item, emergencyKitId: UUID) throws
}
