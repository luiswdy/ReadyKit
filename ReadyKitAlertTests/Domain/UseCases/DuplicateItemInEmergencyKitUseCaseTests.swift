//
//  DuplicateItemInEmergencyKitUseCaseTests.swift
//  ReadyKitTests
//
//  Created by AI Assistant on 9/13/25.
//

import Testing
import Foundation
@testable import ReadyKit

struct DuplicateItemInEmergencyKitUseCaseTests {
    
    // MARK: - Success Tests
    
    @Test("DuplicateItemInEmergencyKitUseCase executes successfully with valid item and emergency kit")
    func testSuccessfulExecution() throws {
        let mockRepository = MockItemRepository()
        let useCase = DuplicateItemInEmergencyKitUseCase(itemRepository: mockRepository)
        
        // Create test data
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        let originalItem = try TestDataFactory.createValidItem(
            name: "First Aid Kit",
            expirationDate: Date().addingTimeInterval(86400 * 30), // 30 days from now
            quantityValue: 1,
            quantityUnitName: "box"
        )
        
        // Execute the use case
        try useCase.execute(item: originalItem, emergencyKit: emergencyKit)
        
        // Verify the repository was called correctly
        #expect(mockRepository.duplicateCallCount == 1)
        #expect(mockRepository.lastDuplicatedItem?.id == originalItem.id)
        #expect(mockRepository.lastDuplicatedItem?.name == originalItem.name)
        #expect(mockRepository.lastTargetEmergencyKit?.id == emergencyKit.id)
        
        // Verify a new item was created
        let storedItems = mockRepository.getStoredItems()
        #expect(storedItems.count == 1)
        
        let duplicatedItem = storedItems.first!
        #expect(duplicatedItem.id != originalItem.id) // Different ID
        #expect(duplicatedItem.name == originalItem.name) // Same name
        #expect(duplicatedItem.expirationDate == originalItem.expirationDate) // Same expiration
        #expect(duplicatedItem.quantityValue == originalItem.quantityValue) // Same quantity
        #expect(duplicatedItem.quantityUnitName == originalItem.quantityUnitName) // Same unit
    }
    
    @Test("DuplicateItemInEmergencyKitUseCase handles item with nil expiration date")
    func testDuplicateItemWithNilExpirationDate() throws {
        let mockRepository = MockItemRepository()
        let useCase = DuplicateItemInEmergencyKitUseCase(itemRepository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        let originalItem = try TestDataFactory.createValidItem(
            name: "Non-perishable Item",
            expirationDate: nil,
            quantityValue: 5,
            quantityUnitName: "pieces"
        )
        
        try useCase.execute(item: originalItem, emergencyKit: emergencyKit)
        
        #expect(mockRepository.duplicateCallCount == 1)
        let storedItems = mockRepository.getStoredItems()
        #expect(storedItems.count == 1)
        
        let duplicatedItem = storedItems.first!
        #expect(duplicatedItem.expirationDate == nil)
        #expect(duplicatedItem.name == originalItem.name)
    }
    
    @Test("DuplicateItemInEmergencyKitUseCase handles item with notes")
    func testDuplicateItemWithNotes() throws {
        let mockRepository = MockItemRepository()
        let useCase = DuplicateItemInEmergencyKitUseCase(itemRepository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        let originalItem = try TestDataFactory.createValidItem(
            name: "Medicine",
            notes: "Keep in cool, dry place",
            quantityValue: 2,
            quantityUnitName: "bottles"
        )
        
        try useCase.execute(item: originalItem, emergencyKit: emergencyKit)
        
        let storedItems = mockRepository.getStoredItems()
        let duplicatedItem = storedItems.first!
        #expect(duplicatedItem.notes == originalItem.notes)
    }
    
    // MARK: - Error Tests
    
    @Test("DuplicateItemInEmergencyKitUseCase throws error when repository fails")
    func testRepositoryError() throws {
        let mockRepository = MockItemRepository()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = SwiftDataItemRepositoryError.saveError(NSError(domain: "TestError", code: 1))
        
        let useCase = DuplicateItemInEmergencyKitUseCase(itemRepository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        let originalItem = try TestDataFactory.createValidItem(name: "Test Item")
        
        #expect(throws: SwiftDataItemRepositoryError.self) {
            try useCase.execute(item: originalItem, emergencyKit: emergencyKit)
        }
        
        #expect(mockRepository.duplicateCallCount == 1)
        #expect(mockRepository.getStoredItems().isEmpty)
    }
    
    @Test("DuplicateItemInEmergencyKitUseCase throws error for invalid item data")
    func testInvalidItemDataError() throws {
        let mockRepository = MockItemRepository()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = ItemValidationError.emptyName("")
        
        let useCase = DuplicateItemInEmergencyKitUseCase(itemRepository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        let originalItem = try TestDataFactory.createValidItem(name: "Test Item")
        
        #expect(throws: ItemValidationError.self) {
            try useCase.execute(item: originalItem, emergencyKit: emergencyKit)
        }
    }
    
    // MARK: - Edge Cases
    
    @Test("DuplicateItemInEmergencyKitUseCase handles multiple duplications")
    func testMultipleDuplications() throws {
        let mockRepository = MockItemRepository()
        let useCase = DuplicateItemInEmergencyKitUseCase(itemRepository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        let originalItem = try TestDataFactory.createValidItem(name: "Flashlight")
        
        // Duplicate the same item multiple times
        try useCase.execute(item: originalItem, emergencyKit: emergencyKit)
        try useCase.execute(item: originalItem, emergencyKit: emergencyKit)
        try useCase.execute(item: originalItem, emergencyKit: emergencyKit)
        
        #expect(mockRepository.duplicateCallCount == 3)
        #expect(mockRepository.getStoredItems().count == 3)
        
        // Verify all duplicated items have different IDs but same properties
        let storedItems = mockRepository.getStoredItems()
        let uniqueIds = Set(storedItems.map { $0.id })
        #expect(uniqueIds.count == 3) // All different IDs
        
        // All should have the same name
        let uniqueNames = Set(storedItems.map { $0.name })
        #expect(uniqueNames.count == 1)
        #expect(uniqueNames.first == originalItem.name)
    }
    
    @Test("DuplicateItemInEmergencyKitUseCase preserves all item properties")
    func testAllPropertiesPreserved() throws {
        let mockRepository = MockItemRepository()
        let useCase = DuplicateItemInEmergencyKitUseCase(itemRepository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        let futureDate = Date().addingTimeInterval(86400 * 365) // 1 year from now
        let photoData = Data([0x01, 0x02, 0x03, 0x04]) // Sample photo data
        
        let originalItem = try TestDataFactory.createValidItem(
            name: "Complex Item",
            expirationDate: futureDate,
            notes: "Detailed notes about this item",
            quantityValue: 42,
            quantityUnitName: "units",
            photo: photoData
        )
        
        try useCase.execute(item: originalItem, emergencyKit: emergencyKit)
        
        let duplicatedItem = mockRepository.getStoredItems().first!
        
        // Verify all properties are preserved except ID
        #expect(duplicatedItem.id != originalItem.id)
        #expect(duplicatedItem.name == originalItem.name)
        #expect(duplicatedItem.expirationDate == originalItem.expirationDate)
        #expect(duplicatedItem.notes == originalItem.notes)
        #expect(duplicatedItem.quantityValue == originalItem.quantityValue)
        #expect(duplicatedItem.quantityUnitName == originalItem.quantityUnitName)
        #expect(duplicatedItem.photo == originalItem.photo)
    }
}
