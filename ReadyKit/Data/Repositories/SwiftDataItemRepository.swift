//
//  SwiftDataItemRepository.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/10/25.
//

import Foundation
import SwiftData

enum SwiftDataItemRepositoryError: Error {
    case itemAlreadyExists(_ providedUUID: UUID)
    case itemNotFound(_ providedUUID: UUID)
    case fetchError(_ error: Error)
    case saveError(_ error: Error)
    case deleteError(_ error: Error)
    case fetchExpiringError
}

final class SwiftDataItemRepository: ItemRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        assert(Thread.isMainThread, "SwiftDataItemRepository should be used on the main thread")
        self.context = context
    }

    func fetchAllItems() throws -> [Item] {
        assert(Thread.isMainThread, "SwiftDataItemRepository should be used on the main thread")
        let descriptor = FetchDescriptor<ItemModel>()
        do {
            let items = try context.fetch(descriptor)
            return try items.map { try ItemMapper.toDomain($0) }
        } catch {
            throw SwiftDataItemRepositoryError.fetchError(error)
        }
    }
    
    func fetchExpiring(within days: Int) throws -> [Item] {
        assert(Thread.isMainThread, "SwiftDataItemRepository should be used on the main thread")
        let now = Date()
        guard let expiringDate = Calendar.current.date(byAdding: .day, value: days, to: now) else {
            throw SwiftDataItemRepositoryError.fetchExpiringError
        }
        
        let descriptor = FetchDescriptor<ItemModel>(
            predicate: #Predicate<ItemModel> { item in
                if let expirationDate = item.expirationDate {
                    return expirationDate >= now && expirationDate <= expiringDate
                } else {
                    return false
                }
            }
        )
        
        do {
            let items = try context.fetch(descriptor)
            return try items.map { try ItemMapper.toDomain($0) }
        } catch {
            throw SwiftDataItemRepositoryError.fetchError(error)
        }
    }
    
    func fetchExpired() throws -> [Item] {
        assert(Thread.isMainThread, "SwiftDataItemRepository should be used on the main thread")
        let now = Date()
        let descriptor = FetchDescriptor<ItemModel>(
            predicate: #Predicate<ItemModel> {
                if let expirationDate = $0.expirationDate {
                    return expirationDate < now
                } else {
                    return false
                }
            }
        )
        do {
            let items = try context.fetch(descriptor)
            return try items.map { try ItemMapper.toDomain($0) }
        } catch {
            throw SwiftDataItemRepositoryError.fetchError(error)
        }
    }
    
    func save(item: Item, to emergencyKit: EmergencyKit) throws {
        assert(Thread.isMainThread, "SwiftDataItemRepository should be used on the main thread")
        let emergencyKitModel = EmergencyKitMapper.toModel(emergencyKit)
        // Check if the item already exists
        let itemId = item.id
        let descriptor = FetchDescriptor<ItemModel>(predicate: #Predicate { $0.id == itemId })
        if let existingItem = try context.fetch(descriptor).first {
            // If it exists, update it
            existingItem.name = item.name
            existingItem.expirationDate = item.expirationDate
            existingItem.notes = item.notes
            existingItem.quantityValue = item.quantityValue
            existingItem.quantityUnitName = item.quantityUnitName
            existingItem.photo = item.photo
        } else {
            let itemModel = ItemMapper.toModel(item, emergencyKit: emergencyKitModel)
            context.insert(itemModel)
        }
        do {
            try context.save()
        } catch {
            throw SwiftDataItemRepositoryError.saveError(error)
        }
    }
    
    func delete(item: Item) throws {
        assert(Thread.isMainThread, "SwiftDataItemRepository should be used on the main thread")
        let itemId = item.id
        let descriptor = FetchDescriptor<ItemModel>(predicate: #Predicate { $0.id == itemId })
        guard let itemModel = try context.fetch(descriptor).first else {
            throw SwiftDataItemRepositoryError.itemNotFound(item.id)
        }
        context.delete(itemModel)
        do {
            try context.save()
        } catch {
            throw SwiftDataItemRepositoryError.deleteError(error)
        }
    }

    func fetchItemWithEarliestExpiration() throws -> Item? {
        assert(Thread.isMainThread, "SwiftDataItemRepository should be used on the main thread")
        let descriptor = FetchDescriptor<ItemModel>(
            predicate: #Predicate<ItemModel> { $0.expirationDate != nil },
            sortBy: [SortDescriptor(\.expirationDate, order: .forward)]
        )
        do {
            if let itemModel = try context.fetch(descriptor).first {
                return try ItemMapper.toDomain(itemModel)
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}
