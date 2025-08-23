//
//  SwiftDataEmergencyKitRepository.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/10/25.
//

import Foundation
import SwiftData

enum SwiftDataEmergencyKitRepositoryError: Error {
    case emergencyKitAlreadyExists(_ providedUUID: UUID)
    case emergencyKitNotFound(_ providedUUID: UUID)
    case itemNotFound(_ providedUUID: UUID)
    case fetchError(_ error: Error)
}

final class SwiftDataEmergencyKitRepository: EmergencyKitRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        assert(Thread.isMainThread, "SwiftDataEmergencyKitshould be used on the main thread")
        self.context = context
    }

    // MARK: - EmergencyKitRepository

    func addEmergencyKit(_ emergencyKit: EmergencyKit) throws {
        assert(Thread.isMainThread, "SwiftDataEmergencyKitRepository should be used on the main thread")
        let emergencyKitId = emergencyKit.id
        let descriptor = FetchDescriptor<EmergencyKitModel>(predicate: #Predicate { $0.id == emergencyKitId })
        // Check if the emergency kit already exists
        if try context.fetch(descriptor).isEmpty {
            // Convert to model and insert
            let model = EmergencyKitMapper.toModel(emergencyKit)
            context.insert(model)
            try context.save()
        } else {
            throw SwiftDataEmergencyKitRepositoryError.emergencyKitAlreadyExists(emergencyKit.id)
        }
    }

    func deleteEmergencyKit(by id: UUID) throws {
        assert(Thread.isMainThread, "SwiftDataEmergencyKitRepository should be used on the main thread")
        let descriptor = FetchDescriptor<EmergencyKitModel>(predicate: #Predicate { $0.id == id })
        do {
            if let emergencyKitModel = try context.fetch(descriptor).first {
                // Delete all items in the emergency kit first
                for item in emergencyKitModel.items {
                    context.delete(item)
                }
                context.delete(emergencyKitModel)
                try context.save()
            } else {
                throw SwiftDataEmergencyKitRepositoryError.emergencyKitNotFound(id)
            }
        } catch {
            throw error
        }
    }

    func updateEmergencyKit(_ emergencyKit: EmergencyKit) throws {
        assert(Thread.isMainThread, "SwiftDataEmergencyKitRepository should be used on the main thread")
        let emergencyKitId = emergencyKit.id
        let descriptor = FetchDescriptor<EmergencyKitModel>(predicate: #Predicate { $0.id == emergencyKitId })
        guard let emergencyKitModel = try context.fetch(descriptor).first else {
            throw SwiftDataEmergencyKitRepositoryError.emergencyKitNotFound(emergencyKit.id)
        }

        // Delete all existing items first
        for item in emergencyKitModel.items {
            context.delete(item)
        }

        // Update the emergency kit properties
        emergencyKitModel.name = emergencyKit.name
        emergencyKitModel.location = emergencyKit.location
        emergencyKitModel.photo = emergencyKit.photo

        // Create new items using the mapper and set their relationships
        let newItemModels = emergencyKit.items.map { ItemMapper.toModel($0, emergencyKit: emergencyKitModel) }

        // Insert all new items into the context
        for itemModel in newItemModels {
            context.insert(itemModel)
        }

        // Set the items relationship
        emergencyKitModel.items = newItemModels

        try context.save()
    }

    func fetchEmergencyKit(by id: UUID) throws -> EmergencyKit {
        assert(Thread.isMainThread, "SwiftDataEmergencyKitRepository should be used on the main thread")
        let descriptor = FetchDescriptor<EmergencyKitModel>(predicate: #Predicate { $0.id == id })
        do {
            let emergencyKitModel = try context.fetch(descriptor).first
            if let emergencyKitModel {
                return try EmergencyKitMapper.toDomain(emergencyKitModel)
            } else {
                throw SwiftDataEmergencyKitRepositoryError.emergencyKitNotFound(id)
            }
        } catch {
            throw SwiftDataEmergencyKitRepositoryError.fetchError(error)
        }
    }

    func allEmergencyKits() throws -> [EmergencyKit] {
        assert(Thread.isMainThread, "SwiftDataEmergencyKitRepository should be used on the main thread")
        let descriptor = FetchDescriptor<EmergencyKitModel>()
        do {
            let emergencyKitModels = try context.fetch(descriptor)
            return try emergencyKitModels.map { try EmergencyKitMapper.toDomain($0) }
        } catch {
            throw SwiftDataEmergencyKitRepositoryError.fetchError(error)
        }
    }

    // MARK: - Efficient Item Operations

    /// Add a single item to an existing emergency kit (more efficient than full update)
    func addItemToEmergencyKit(item: Item, emergencyKitId: UUID) throws {
        assert(Thread.isMainThread, "SwiftDataEmergencyKitRepository should be used on the main thread")
        let descriptor = FetchDescriptor<EmergencyKitModel>(predicate: #Predicate { $0.id == emergencyKitId })
        guard let emergencyKitModel = try context.fetch(descriptor).first else {
            throw SwiftDataEmergencyKitRepositoryError.emergencyKitNotFound(emergencyKitId)
        }

        // Check if item already exists (prevent duplicates)
        if emergencyKitModel.items.contains(where: { $0.id == item.id }) {
            // Item already exists, no need to add
            return
        }

        // Create new item model WITHOUT relationship first
        let newItemModel = ItemMapper.toModel(item, emergencyKit: nil)

        // Insert the new item into the context first
        context.insert(newItemModel)

        // Now establish the relationship after both objects are managed by the context
        newItemModel.emergencyKit = emergencyKitModel
        emergencyKitModel.items.append(newItemModel)

        // Save the context
        try context.save()
    }

    /// Update a single item in an existing emergency kit (more efficient than full update)
    func updateItemInEmergencyKit(updatedItem: Item, emergencyKitId: UUID) throws {
        assert(Thread.isMainThread, "SwiftDataEmergencyKitRepository should be used on the main thread")
        let descriptor = FetchDescriptor<EmergencyKitModel>(predicate: #Predicate { $0.id == emergencyKitId })
        guard let emergencyKitModel = try context.fetch(descriptor).first else {
            throw SwiftDataEmergencyKitRepositoryError.emergencyKitNotFound(emergencyKitId)
        }

        // Find the existing item model to update
        guard let existingItemModel = emergencyKitModel.items.first(where: { $0.id == updatedItem.id }) else {
            throw SwiftDataEmergencyKitRepositoryError.itemNotFound(updatedItem.id)
        }

        // Update the existing item model's properties directly
        existingItemModel.name = updatedItem.name
        existingItemModel.expirationDate = updatedItem.expirationDate
        existingItemModel.notes = updatedItem.notes
        existingItemModel.quantityValue = updatedItem.quantityValue
        existingItemModel.quantityUnitName = updatedItem.quantityUnitName
        existingItemModel.photo = updatedItem.photo

        // Save the context
        try context.save()
    }
}
