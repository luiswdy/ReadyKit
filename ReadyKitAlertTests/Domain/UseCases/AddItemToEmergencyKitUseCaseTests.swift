//
//  AddItemToEmergencyKitUseCaseTests.swift
//  ReadyKitTests
//
//  Created by Claude on 8/22/25.
//

import Testing
import Foundation
@testable import ReadyKit

struct AddItemToEmergencyKitUseCaseTests {
    
    // MARK: - Success Tests
    
    @Test("AddItemToEmergencyKitUseCase executes successfully with valid request")
    func testSuccessfulExecution() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = AddItemToEmergencyKitUseCase(repository: mockRepository)
        
        // Create and store an emergency kit first
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        try mockRepository.addEmergencyKit(emergencyKit)
        
        let request = TestDataFactory.createValidAddItemRequest(
            emergencyKitId: emergencyKit.id,
            itemName: "First Aid Kit",
            quantityValue: 1,
            quantityUnitName: "box"
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let updatedKit = try mockRepository.fetchEmergencyKit(by: emergencyKit.id)
            #expect(updatedKit.items.count == 1)
            #expect(updatedKit.items.first?.name == "First Aid Kit")
            #expect(updatedKit.items.first?.quantityValue == 1)
            #expect(updatedKit.items.first?.quantityUnitName == "box")
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("AddItemToEmergencyKitUseCase creates item with expiration date")
    func testAddItemWithExpirationDate() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = AddItemToEmergencyKitUseCase(repository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        try mockRepository.addEmergencyKit(emergencyKit)
        
        let expirationDate = Date().addingTimeInterval(86400 * 30) // 30 days from now
        let request = AddItemToEmergencyKitRequest(
            emergencyKitId: emergencyKit.id,
            itemName: "Canned Food",
            itemQuantityValue: 5,
            itemQuantityUnitName: "cans",
            itemExpirationDate: expirationDate,
            itemNotes: "Best before date",
            itemPhoto: nil
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let updatedKit = try mockRepository.fetchEmergencyKit(by: emergencyKit.id)
            #expect(updatedKit.items.count == 1)
            #expect(updatedKit.items.first?.expirationDate == expirationDate)
            #expect(updatedKit.items.first?.notes == "Best before date")
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("AddItemToEmergencyKitUseCase creates item with photo")
    func testAddItemWithPhoto() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = AddItemToEmergencyKitUseCase(repository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        try mockRepository.addEmergencyKit(emergencyKit)
        
        let photoData = Data([0x01, 0x02, 0x03, 0x04])
        let request = AddItemToEmergencyKitRequest(
            emergencyKitId: emergencyKit.id,
            itemName: "Flashlight",
            itemQuantityValue: 2,
            itemQuantityUnitName: "pieces",
            itemExpirationDate: nil,
            itemNotes: nil,
            itemPhoto: photoData
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let updatedKit = try mockRepository.fetchEmergencyKit(by: emergencyKit.id)
            #expect(updatedKit.items.count == 1)
            #expect(updatedKit.items.first?.photo == photoData)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("AddItemToEmergencyKitUseCase adds multiple items to same kit")
    func testAddMultipleItems() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = AddItemToEmergencyKitUseCase(repository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        try mockRepository.addEmergencyKit(emergencyKit)
        
        let request1 = TestDataFactory.createValidAddItemRequest(
            emergencyKitId: emergencyKit.id,
            itemName: "Water Bottle",
            quantityValue: 10,
            quantityUnitName: "bottles"
        )
        
        let request2 = TestDataFactory.createValidAddItemRequest(
            emergencyKitId: emergencyKit.id,
            itemName: "Energy Bar",
            quantityValue: 20,
            quantityUnitName: "bars"
        )
        
        let result1 = useCase.execute(request: request1)
        let result2 = useCase.execute(request: request2)
        
        switch (result1, result2) {
        case (.success, .success):
            let updatedKit = try mockRepository.fetchEmergencyKit(by: emergencyKit.id)
            #expect(updatedKit.items.count == 2)
            
            let itemNames = updatedKit.items.map { $0.name }
            #expect(itemNames.contains("Water Bottle"))
            #expect(itemNames.contains("Energy Bar"))
        case (.failure(let error), _):
            Issue.record("First request failed: \(error)")
        case (_, .failure(let error)):
            Issue.record("Second request failed: \(error)")
        }
    }
    
    // MARK: - Failure Tests
    
    @Test("AddItemToEmergencyKitUseCase fails when emergency kit doesn't exist")
    func testNonExistentEmergencyKit() {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = AddItemToEmergencyKitUseCase(repository: mockRepository)
        
        let nonExistentId = UUID()
        let request = TestDataFactory.createValidAddItemRequest(
            emergencyKitId: nonExistentId,
            itemName: "Test Item"
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            #expect(error is SwiftDataEmergencyKitRepositoryError)
            if case SwiftDataEmergencyKitRepositoryError.emergencyKitNotFound(let id) = error {
                #expect(id == nonExistentId)
            } else {
                Issue.record("Expected emergencyKitNotFound error")
            }
        }
    }
    
    @Test("AddItemToEmergencyKitUseCase fails with invalid item name")
    func testInvalidItemName() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = AddItemToEmergencyKitUseCase(repository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        try mockRepository.addEmergencyKit(emergencyKit)
        
        let request = AddItemToEmergencyKitRequest(
            emergencyKitId: emergencyKit.id,
            itemName: "",  // Empty name
            itemQuantityValue: 1,
            itemQuantityUnitName: "piece",
            itemExpirationDate: nil,
            itemNotes: nil,
            itemPhoto: nil
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            Issue.record("Expected failure due to invalid item name but got success")
        case .failure(let error):
            #expect(error is ItemValidationError)
            if case ItemValidationError.emptyName = error {
                // Expected error type
            } else {
                Issue.record("Expected emptyName validation error")
            }
        }
    }
    
    @Test("AddItemToEmergencyKitUseCase fails with invalid quantity")
    func testInvalidQuantity() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = AddItemToEmergencyKitUseCase(repository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        try mockRepository.addEmergencyKit(emergencyKit)
        
        let request = AddItemToEmergencyKitRequest(
            emergencyKitId: emergencyKit.id,
            itemName: "Test Item",
            itemQuantityValue: 0,  // Invalid quantity
            itemQuantityUnitName: "piece",
            itemExpirationDate: nil,
            itemNotes: nil,
            itemPhoto: nil
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            Issue.record("Expected failure due to invalid quantity but got success")
        case .failure(let error):
            #expect(error is ItemValidationError)
            if case ItemValidationError.invalidQuantityValue = error {
                // Expected error type
            } else {
                Issue.record("Expected invalidQuantityValue validation error")
            }
        }
    }
    
    @Test("AddItemToEmergencyKitUseCase fails with invalid unit name")
    func testInvalidUnitName() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = AddItemToEmergencyKitUseCase(repository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        try mockRepository.addEmergencyKit(emergencyKit)
        
        let request = AddItemToEmergencyKitRequest(
            emergencyKitId: emergencyKit.id,
            itemName: "Test Item",
            itemQuantityValue: 1,
            itemQuantityUnitName: "",  // Empty unit name
            itemExpirationDate: nil,
            itemNotes: nil,
            itemPhoto: nil
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            Issue.record("Expected failure due to invalid unit name but got success")
        case .failure(let error):
            #expect(error is ItemValidationError)
            if case ItemValidationError.emptyQuantityUnitName = error {
                // Expected error type
            } else {
                Issue.record("Expected emptyQuantityUnitName validation error")
            }
        }
    }
    
    @Test("AddItemToEmergencyKitUseCase fails when repository throws error")
    func testRepositoryError() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = AddItemToEmergencyKitUseCase(repository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        try mockRepository.addEmergencyKit(emergencyKit)
        
        // Configure repository to throw error
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = SwiftDataEmergencyKitRepositoryError.fetchError(NSError(domain: "TestError", code: 1))
        
        let request = TestDataFactory.createValidAddItemRequest(
            emergencyKitId: emergencyKit.id,
            itemName: "Test Item"
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            #expect(error is SwiftDataEmergencyKitRepositoryError)
        }
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("AddItemToEmergencyKitUseCase handles Unicode characters in item name")
    func testUnicodeItemName() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = AddItemToEmergencyKitUseCase(repository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        try mockRepository.addEmergencyKit(emergencyKit)
        
        let unicodeName = "🔋 电池 Battery باتری"
        let request = AddItemToEmergencyKitRequest(
            emergencyKitId: emergencyKit.id,
            itemName: unicodeName,
            itemQuantityValue: 4,
            itemQuantityUnitName: "pieces",
            itemExpirationDate: nil,
            itemNotes: nil,
            itemPhoto: nil
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let updatedKit = try mockRepository.fetchEmergencyKit(by: emergencyKit.id)
            #expect(updatedKit.items.first?.name == unicodeName)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("AddItemToEmergencyKitUseCase handles very long notes")
    func testLongNotes() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = AddItemToEmergencyKitUseCase(repository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        try mockRepository.addEmergencyKit(emergencyKit)
        
        let longNotes = String(repeating: "This is a very detailed note about the item. ", count: 50)
        let request = AddItemToEmergencyKitRequest(
            emergencyKitId: emergencyKit.id,
            itemName: "Detailed Item",
            itemQuantityValue: 1,
            itemQuantityUnitName: "piece",
            itemExpirationDate: nil,
            itemNotes: longNotes,
            itemPhoto: nil
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let updatedKit = try mockRepository.fetchEmergencyKit(by: emergencyKit.id)
            #expect(updatedKit.items.first?.notes == longNotes)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("AddItemToEmergencyKitUseCase handles large quantity values")
    func testLargeQuantity() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = AddItemToEmergencyKitUseCase(repository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        try mockRepository.addEmergencyKit(emergencyKit)
        
        let largeQuantity = 999999
        let request = AddItemToEmergencyKitRequest(
            emergencyKitId: emergencyKit.id,
            itemName: "Bulk Item",
            itemQuantityValue: largeQuantity,
            itemQuantityUnitName: "pieces",
            itemExpirationDate: nil,
            itemNotes: nil,
            itemPhoto: nil
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let updatedKit = try mockRepository.fetchEmergencyKit(by: emergencyKit.id)
            #expect(updatedKit.items.first?.quantityValue == largeQuantity)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("AddItemToEmergencyKitUseCase handles past expiration dates")
    func testPastExpirationDate() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = AddItemToEmergencyKitUseCase(repository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        try mockRepository.addEmergencyKit(emergencyKit)
        
        let pastDate = TestConstants.Dates.past
        let request = AddItemToEmergencyKitRequest(
            emergencyKitId: emergencyKit.id,
            itemName: "Expired Item",
            itemQuantityValue: 1,
            itemQuantityUnitName: "piece",
            itemExpirationDate: pastDate,
            itemNotes: "Already expired",
            itemPhoto: nil
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let updatedKit = try mockRepository.fetchEmergencyKit(by: emergencyKit.id)
            #expect(updatedKit.items.first?.expirationDate == pastDate)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
}
