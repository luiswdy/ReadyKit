//
//  CreateEmergencyKitUseCaseTests.swift
//  ReadyKitTests
//
//  Created by Claude on 8/22/25.
//

import Testing
import Foundation
@testable import ReadyKit

struct CreateEmergencyKitUseCaseTests {
    
    // MARK: - Success Tests
    
    @Test("CreateEmergencyKitUseCase executes successfully with valid request")
    func testSuccessfulExecution() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = CreateEmergencyKitUseCase(repository: mockRepository)
        
        let request = TestDataFactory.createValidCreateEmergencyKitRequest(
            name: "Test Emergency Kit",
            location: "Living Room"
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let storedKits = mockRepository.getStoredEmergencyKits()
            #expect(storedKits.count == 1)
            #expect(storedKits.first?.name == "Test Emergency Kit")
            #expect(storedKits.first?.location == "Living Room")
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("CreateEmergencyKitUseCase creates emergency kit with items")
    func testCreateEmergencyKitWithItems() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = CreateEmergencyKitUseCase(repository: mockRepository)
        
        let items = [
            try TestDataFactory.createValidItem(name: "First Aid Kit"),
            try TestDataFactory.createValidItem(name: "Water Bottle")
        ]
        
        let request = TestDataFactory.createValidCreateEmergencyKitRequest(
            name: "Complete Emergency Kit",
            location: "Garage",
            items: items
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let storedKits = mockRepository.getStoredEmergencyKits()
            #expect(storedKits.count == 1)
            #expect(storedKits.first?.items.count == 2)
            #expect(storedKits.first?.items.contains { $0.name == "First Aid Kit" } == true)
            #expect(storedKits.first?.items.contains { $0.name == "Water Bottle" } == true)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("CreateEmergencyKitUseCase creates emergency kit with photo")
    func testCreateEmergencyKitWithPhoto() {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = CreateEmergencyKitUseCase(repository: mockRepository)
        
        let photoData = Data([0x01, 0x02, 0x03, 0x04])
        let request = TestDataFactory.createValidCreateEmergencyKitRequest(
            name: "Photo Emergency Kit",
            location: "Basement",
            photo: photoData
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let storedKits = mockRepository.getStoredEmergencyKits()
            #expect(storedKits.count == 1)
            #expect(storedKits.first?.photo == photoData)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("CreateEmergencyKitUseCase trims whitespace from name and location")
    func testWhitespaceTrimmingFromRequest() {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = CreateEmergencyKitUseCase(repository: mockRepository)
        
        let request = CreateEmergencyKitRequest(
            name: "  Trimmed Kit  ",
            items: [],
            photo: nil,
            location: "  Trimmed Location  "
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let storedKits = mockRepository.getStoredEmergencyKits()
            #expect(storedKits.first?.name == "Trimmed Kit")
            #expect(storedKits.first?.location == "Trimmed Location")
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    // MARK: - Failure Tests
    
    @Test("CreateEmergencyKitUseCase fails when repository throws error")
    func testRepositoryError() {
        let mockRepository = MockEmergencyKitRepository()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = SwiftDataEmergencyKitRepositoryError.emergencyKitAlreadyExists(UUID())
        
        let useCase = CreateEmergencyKitUseCase(repository: mockRepository)
        let request = TestDataFactory.createValidCreateEmergencyKitRequest()
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            #expect(error is SwiftDataEmergencyKitRepositoryError)
            if case SwiftDataEmergencyKitRepositoryError.emergencyKitAlreadyExists = error {
                // Expected error type
            } else {
                Issue.record("Expected emergencyKitAlreadyExists error")
            }
        }
    }
    
    @Test("CreateEmergencyKitUseCase fails with empty name after trimming")
    func testEmptyNameAfterTrimming() {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = CreateEmergencyKitUseCase(repository: mockRepository)
        
        let request = CreateEmergencyKitRequest(
            name: "   ",  // Only whitespace
            items: [],
            photo: nil,
            location: "Valid Location"
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            Issue.record("Expected failure due to empty name but got success")
        case .failure:
            // Expected failure due to EmergencyKit initialization validation
            let storedKits = mockRepository.getStoredEmergencyKits()
            #expect(storedKits.isEmpty)
        }
    }
    
    @Test("CreateEmergencyKitUseCase fails with empty location after trimming")
    func testEmptyLocationAfterTrimming() {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = CreateEmergencyKitUseCase(repository: mockRepository)
        
        let request = CreateEmergencyKitRequest(
            name: "Valid Name",
            items: [],
            photo: nil,
            location: "   "  // Only whitespace
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            Issue.record("Expected failure due to empty location but got success")
        case .failure:
            // Expected failure due to EmergencyKit initialization validation
            let storedKits = mockRepository.getStoredEmergencyKits()
            #expect(storedKits.isEmpty)
        }
    }
    
    @Test("CreateEmergencyKitUseCase fails with duplicate item IDs")
    func testDuplicateItemIds() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = CreateEmergencyKitUseCase(repository: mockRepository)
        
        let sharedId = UUID()
        let item1 = try Item(id: sharedId, name: "Item 1", quantityValue: 1, quantityUnitName: "piece")
        let item2 = try Item(id: sharedId, name: "Item 2", quantityValue: 2, quantityUnitName: "piece")
        
        let request = CreateEmergencyKitRequest(
            name: "Duplicate Items Kit",
            items: [item1, item2],
            photo: nil,
            location: "Test Location"
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            Issue.record("Expected failure due to duplicate item IDs but got success")
        case .failure:
            // Expected failure due to EmergencyKit initialization validation
            let storedKits = mockRepository.getStoredEmergencyKits()
            #expect(storedKits.isEmpty)
        }
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("CreateEmergencyKitUseCase handles very long names and locations")
    func testLongStrings() {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = CreateEmergencyKitUseCase(repository: mockRepository)
        
        let longName = String(repeating: "A", count: 1000)
        let longLocation = String(repeating: "B", count: 1000)
        
        let request = CreateEmergencyKitRequest(
            name: longName,
            items: [],
            photo: nil,
            location: longLocation
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let storedKits = mockRepository.getStoredEmergencyKits()
            #expect(storedKits.first?.name == longName)
            #expect(storedKits.first?.location == longLocation)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("CreateEmergencyKitUseCase handles Unicode characters")
    func testUnicodeCharacters() {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = CreateEmergencyKitUseCase(repository: mockRepository)
        
        let unicodeName = "🚨 紧急工具包 Emergency Kit 👨‍⚕️"
        let unicodeLocation = "🏠 客厅 Living Room 📍"
        
        let request = CreateEmergencyKitRequest(
            name: unicodeName,
            items: [],
            photo: nil,
            location: unicodeLocation
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let storedKits = mockRepository.getStoredEmergencyKits()
            #expect(storedKits.first?.name == unicodeName)
            #expect(storedKits.first?.location == unicodeLocation)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("CreateEmergencyKitUseCase handles large photo data")
    func testLargePhotoData() {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = CreateEmergencyKitUseCase(repository: mockRepository)
        
        let largePhotoData = Data(repeating: 0xFF, count: 1024 * 1024) // 1MB of data
        let request = CreateEmergencyKitRequest(
            name: "Large Photo Kit",
            items: [],
            photo: largePhotoData,
            location: "Storage"
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let storedKits = mockRepository.getStoredEmergencyKits()
            #expect(storedKits.first?.photo?.count == largePhotoData.count)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("CreateEmergencyKitUseCase handles maximum number of items")
    func testManyItems() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = CreateEmergencyKitUseCase(repository: mockRepository)
        
        let itemCount = 100
        let items = try (0..<itemCount).map { index in
            try TestDataFactory.createValidItem(name: "Item \(index)")
        }
        
        let request = CreateEmergencyKitRequest(
            name: "Many Items Kit",
            items: items,
            photo: nil,
            location: "Storage Room"
        )
        
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let storedKits = mockRepository.getStoredEmergencyKits()
            #expect(storedKits.first?.items.count == itemCount)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
}
