//
//  TestHelpers.swift
//  ReadyKitTests
//
//  Created by Claude on 8/22/25.
//

import Foundation
@testable import ReadyKit

// MARK: - Test Data Factory

struct TestDataFactory {
    
    // MARK: - Emergency Kit Factory Methods
    
    static func createValidEmergencyKit(
        id: UUID = UUID(),
        name: String = "Test Emergency Kit",
        location: String = "Test Location",
        items: [Item] = [],
        photo: Data? = nil
    ) -> EmergencyKit {
        return try! EmergencyKit(
            id: id,
            name: name,
            items: items,
            photo: photo,
            location: location
        )
    }
    
    static func createEmergencyKitWithItems(
        itemCount: Int = 3,
        name: String = "Test Kit with Items",
        location: String = "Test Location"
    ) -> EmergencyKit {
        let items = (0..<itemCount).map { index in
            try! createValidItem(name: "Test Item \(index + 1)")
        }
        
        return try! EmergencyKit(
            id: UUID(),
            name: name,
            items: items,
            photo: nil,
            location: location
        )
    }
    
    // MARK: - Item Factory Methods
    
    static func createValidItem(
        id: UUID = UUID(),
        name: String = "Test Item",
        expirationDate: Date? = nil,
        notes: String? = "Test notes",
        quantityValue: Int = 1,
        quantityUnitName: String = "piece",
        photo: Data? = nil
    ) throws -> Item {
        return try Item(
            id: id,
            name: name,
            expirationDate: expirationDate,
            notes: notes,
            quantityValue: quantityValue,
            quantityUnitName: quantityUnitName,
            photo: photo
        )
    }
    
    static func createExpiredItem(
        name: String = "Expired Item",
        daysExpired: Int = 1
    ) throws -> Item {
        let expiredDate = Calendar.current.date(byAdding: .day, value: -daysExpired, to: Date()) ?? Date()
        return try createValidItem(name: name, expirationDate: expiredDate)
    }
    
    static func createExpiringItem(
        name: String = "Expiring Item",
        daysUntilExpiration: Int = 7
    ) throws -> Item {
        let expiringDate = Calendar.current.date(byAdding: .day, value: daysUntilExpiration, to: Date()) ?? Date()
        return try createValidItem(name: name, expirationDate: expiringDate)
    }
    
    static func createItemWithoutExpiration(
        name: String = "Non-expiring Item"
    ) throws -> Item {
        return try createValidItem(name: name, expirationDate: nil)
    }
    
    // MARK: - User Preferences Factory Methods
    
    static func createDefaultUserPreferences() -> UserPreferences {
        return UserPreferences()
    }
    
    static func createCustomUserPreferences(
        notificationHour: Int = 14,
        notificationMinute: Int = 30,
        expiryReminderLeadDays: Int = 15,
        regularCheck: RegularCheckFrequency = .halfYearly
    ) -> UserPreferences {
        return UserPreferences(
            dailyNotificationTime: DateComponents(hour: notificationHour, minute: notificationMinute),
            expiryReminderLeadDays: expiryReminderLeadDays,
            regularCheck: regularCheck
        )
    }
    
    // MARK: - Request Factory Methods
    
    static func createValidCreateEmergencyKitRequest(
        name: String = "Test Kit",
        location: String = "Test Location",
        items: [Item] = [],
        photo: Data? = nil
    ) -> CreateEmergencyKitRequest {
        return CreateEmergencyKitRequest(
            name: name,
            items: items,
            photo: photo,
            location: location
        )
    }
    
    static func createValidAddItemRequest(
        emergencyKitId: UUID = UUID(),
        itemName: String = "Test Item",
        quantityValue: Int = 1,
        quantityUnitName: String = "piece",
        expirationDate: Date? = nil,
        notes: String? = nil,
        photo: Data? = nil
    ) -> AddItemToEmergencyKitRequest {
        return AddItemToEmergencyKitRequest(
            emergencyKitId: emergencyKitId,
            itemName: itemName,
            itemQuantityValue: quantityValue,
            itemQuantityUnitName: quantityUnitName,
            itemExpirationDate: expirationDate,
            itemNotes: notes,
            itemPhoto: photo
        )
    }
}

// MARK: - Test Constants

struct TestConstants {
    
    enum Validation {
        static let validNames = ["Valid Kit", "Another Kit", "Emergency Supplies"]
        static let invalidNames = ["", "   ", "\n\t", "  \n  "]
        static let validLocations = ["Living Room", "Garage", "Office"]
        static let invalidLocations = ["", "   ", "\n\t", "  \n  "]
        static let validQuantities = [1, 5, 100, 999]
        static let invalidQuantities = [0, -1, -100]
        static let validUnitNames = ["piece", "bottle", "box", "kg"]
        static let invalidUnitNames = ["", "   ", "\n\t"]
    }
    
    enum Dates {
        static let past = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        static let nearFuture = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        static let farFuture = Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()
        static let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        static let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }
    
    enum UserPreferences {
        static let validHours = [0, 6, 12, 18, 23]
        static let invalidHours = [-1, 24, 25, 100]
        static let validMinutes = [0, 15, 30, 45, 59]
        static let invalidMinutes = [-1, 60, 61, 100]
        static let validLeadDays = [1, 7, 30, 365]
        static let invalidLeadDays = [0, -1, 366, 1000]
    }
}

// MARK: - Test Extensions

extension Date {
    /// Creates a date with specific components for testing
    static func testDate(year: Int, month: Int, day: Int, hour: Int = 12, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}

extension EmergencyKit {
    /// Returns the count of expired items in this emergency kit
    func expiredItemsCount() -> Int {
        let now = Date()
        return items.filter { item in
            guard let expirationDate = item.expirationDate else { return false }
            return expirationDate < now
        }.count
    }
    
    /// Returns the count of expiring items within the given number of days
    func expiringItemsCount(within days: Int) -> Int {
        let now = Date()
        let cutoffDate = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
        return items.filter { item in
            guard let expirationDate = item.expirationDate else { return false }
            return expirationDate >= now && expirationDate <= cutoffDate
        }.count
    }
}
