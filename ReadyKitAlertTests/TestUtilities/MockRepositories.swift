//
//  MockRepositories.swift
//  ReadyKitTests
//
//  Created by Claude on 8/22/25.
//

import Foundation
@testable import ReadyKit

// MARK: - Mock Emergency Kit Repository

final class MockEmergencyKitRepository: EmergencyKitRepository {
    private var emergencyKits: [EmergencyKit] = []

    // Test configuration
    var shouldThrowError = false
    var errorToThrow: Error = SwiftDataEmergencyKitRepositoryError.emergencyKitNotFound(UUID())

    func addEmergencyKit(_ emergencyKit: EmergencyKit) throws {
        if shouldThrowError {
            throw errorToThrow
        }

        // Check for duplicates
        if emergencyKits.contains(where: { $0.id == emergencyKit.id }) {
            throw SwiftDataEmergencyKitRepositoryError.emergencyKitAlreadyExists(emergencyKit.id)
        }

        emergencyKits.append(emergencyKit)
    }

    func deleteEmergencyKit(by id: UUID) throws {
        if shouldThrowError {
            throw errorToThrow
        }

        guard let index = emergencyKits.firstIndex(where: { $0.id == id }) else {
            throw SwiftDataEmergencyKitRepositoryError.emergencyKitNotFound(id)
        }

        emergencyKits.remove(at: index)
    }

    func updateEmergencyKit(_ emergencyKit: EmergencyKit) throws {
        if shouldThrowError {
            throw errorToThrow
        }

        guard let index = emergencyKits.firstIndex(where: { $0.id == emergencyKit.id }) else {
            throw SwiftDataEmergencyKitRepositoryError.emergencyKitNotFound(emergencyKit.id)
        }

        emergencyKits[index] = emergencyKit
    }

    func fetchEmergencyKit(by id: UUID) throws -> EmergencyKit {
        if shouldThrowError {
            throw errorToThrow
        }

        guard let emergencyKit = emergencyKits.first(where: { $0.id == id }) else {
            throw SwiftDataEmergencyKitRepositoryError.emergencyKitNotFound(id)
        }

        return emergencyKit
    }

    func allEmergencyKits() throws -> [EmergencyKit] {
        if shouldThrowError {
            throw errorToThrow
        }

        return emergencyKits
    }

    func addItemToEmergencyKit(item: Item, emergencyKitId: UUID) throws {
        if shouldThrowError {
            throw errorToThrow
        }

        guard let index = emergencyKits.firstIndex(where: { $0.id == emergencyKitId }) else {
            throw SwiftDataEmergencyKitRepositoryError.emergencyKitNotFound(emergencyKitId)
        }

        var emergencyKit = emergencyKits[index]

        // Check for duplicate items
        if emergencyKit.items.contains(where: { $0.id == item.id }) {
            return // Item already exists, no need to add
        }

        emergencyKit.items.append(item)
        emergencyKits[index] = emergencyKit
    }

    func updateItemInEmergencyKit(updatedItem: Item, emergencyKitId: UUID) throws {
        if shouldThrowError {
            throw errorToThrow
        }

        guard let kitIndex = emergencyKits.firstIndex(where: { $0.id == emergencyKitId }) else {
            throw SwiftDataEmergencyKitRepositoryError.emergencyKitNotFound(emergencyKitId)
        }

        var emergencyKit = emergencyKits[kitIndex]
        guard let itemIndex = emergencyKit.items.firstIndex(where: { $0.id == updatedItem.id }) else {
            throw SwiftDataEmergencyKitRepositoryError.itemNotFound(updatedItem.id)
        }

        emergencyKit.items[itemIndex] = updatedItem
        emergencyKits[kitIndex] = emergencyKit
    }

    // Test helper methods
    func reset() {
        emergencyKits.removeAll()
        shouldThrowError = false
    }

    func getStoredEmergencyKits() -> [EmergencyKit] {
        return emergencyKits
    }
}

// MARK: - Mock Item Repository

final class MockItemRepository: ItemRepository {
    private var items: [Item] = []

    // Test configuration
    var shouldThrowError = false
    var errorToThrow: Error = SwiftDataItemRepositoryError.itemNotFound(UUID())
    var duplicateCallCount = 0
    var lastDuplicatedItem: Item?
    var lastTargetEmergencyKit: EmergencyKit?

    func duplicate(item: Item, to emergencyKit: EmergencyKit) throws {
        duplicateCallCount += 1
        lastDuplicatedItem = item
        lastTargetEmergencyKit = emergencyKit

        if shouldThrowError {
            throw errorToThrow
        }

        // Create a new item with the same properties but new ID
        let duplicatedItem = try Item(
            name: item.name,
            expirationDate: item.expirationDate,
            notes: item.notes,
            quantityValue: item.quantityValue,
            quantityUnitName: item.quantityUnitName,
            photo: item.photo
        )

        items.append(duplicatedItem)
    }

    func fetchItemWithEarliestExpiration() throws -> Item? {
        if shouldThrowError {
            throw errorToThrow
        }

        return items
            .compactMap { item -> (Item, Date)? in
                guard let expirationDate = item.expirationDate else { return nil }
                return (item, expirationDate)
            }
            .min(by: { $0.1 < $1.1 })?.0
    }

    func fetchAllItems() throws -> [Item] {
        if shouldThrowError {
            throw errorToThrow
        }
        return items
    }

    func fetchExpiring(within days: Int) throws -> [Item] {
        if shouldThrowError {
            throw errorToThrow
        }

        let now = Date()
        let cutoffDate = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now

        return items.filter { item in
            guard let expirationDate = item.expirationDate else { return false }
            return expirationDate >= now && expirationDate <= cutoffDate
        }
    }

    func fetchExpired() throws -> [Item] {
        if shouldThrowError {
            throw errorToThrow
        }

        let now = Date()
        return items.filter { item in
            guard let expirationDate = item.expirationDate else { return false }
            return expirationDate < now
        }
    }

    func save(item: Item, to emergencyKit: EmergencyKit) throws {
        if shouldThrowError {
            throw errorToThrow
        }

        // Add or update item
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        } else {
            items.append(item)
        }
    }

    func delete(item: Item) throws {
        if shouldThrowError {
            throw errorToThrow
        }

        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            throw SwiftDataItemRepositoryError.itemNotFound(item.id)
        }

        items.remove(at: index)
    }

    // Test helper methods
    func reset() {
        items.removeAll()
        shouldThrowError = false
    }

    func addItem(_ item: Item) {
        items.append(item)
    }

    func getStoredItems() -> [Item] {
        return items
    }
}

// MARK: - Mock User Preferences Repository

final class MockUserPreferencesRepository: UserPreferencesRepository {
    private var storedPreferences: UserPreferences?

    // Test configuration
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "TestError", code: 1, userInfo: nil)

    func load() -> UserPreferences {
        // Return stored preferences or default
        return storedPreferences ?? UserPreferences()
    }

    func save(_ preferences: UserPreferences) {
        storedPreferences = preferences
    }

    // Test helper methods
    func reset() {
        storedPreferences = nil
        shouldThrowError = false
    }

    func setStoredPreferences(_ preferences: UserPreferences) {
        storedPreferences = preferences
    }

    func getStoredPreferences() -> UserPreferences? {
        return storedPreferences
    }
}
