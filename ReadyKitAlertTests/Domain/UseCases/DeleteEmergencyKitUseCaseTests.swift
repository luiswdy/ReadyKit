//
//  DeleteEmergencyKitUseCaseTests.swift
//  ReadyKitTests
//
//  Created by Claude on 8/22/25.
//

import Testing
import Foundation
@testable import ReadyKit

struct DeleteEmergencyKitUseCaseTests {
    
    // MARK: - Success Tests
    
    @Test("DeleteEmergencyKitUseCase successfully deletes existing kit")
    func testSuccessfulDeletion() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = DeleteEmergencyKitUseCase(repository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        try mockRepository.addEmergencyKit(emergencyKit)
        
        // Verify kit exists before deletion
        let initialKits = try mockRepository.allEmergencyKits()
        #expect(initialKits.count == 1)
        
        let request = DeleteEmergencyKitRequest(emergencyKitId: emergencyKit.id)
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let remainingKits = try mockRepository.allEmergencyKits()
            #expect(remainingKits.isEmpty)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("DeleteEmergencyKitUseCase deletes kit with items")
    func testDeleteKitWithItems() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = DeleteEmergencyKitUseCase(repository: mockRepository)
        
        let kitWithItems = TestDataFactory.createEmergencyKitWithItems(
            itemCount: 5,
            name: "Kit with Items",
            location: "Storage"
        )
        try mockRepository.addEmergencyKit(kitWithItems)
        
        // Verify kit and items exist
        let initialKits = try mockRepository.allEmergencyKits()
        #expect(initialKits.count == 1)
        #expect(initialKits.first?.items.count == 5)
        
        let request = DeleteEmergencyKitRequest(emergencyKitId: kitWithItems.id)
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let remainingKits = try mockRepository.allEmergencyKits()
            #expect(remainingKits.isEmpty)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("DeleteEmergencyKitUseCase deletes specific kit from multiple kits")
    func testDeleteSpecificKit() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = DeleteEmergencyKitUseCase(repository: mockRepository)
        
        let kit1 = TestDataFactory.createValidEmergencyKit(name: "Kit 1", location: "Location 1")
        let kit2 = TestDataFactory.createValidEmergencyKit(name: "Kit 2", location: "Location 2")
        let kit3 = TestDataFactory.createValidEmergencyKit(name: "Kit 3", location: "Location 3")
        
        try mockRepository.addEmergencyKit(kit1)
        try mockRepository.addEmergencyKit(kit2)
        try mockRepository.addEmergencyKit(kit3)
        
        // Verify all kits exist
        let initialKits = try mockRepository.allEmergencyKits()
        #expect(initialKits.count == 3)
        
        // Delete the middle kit
        let request = DeleteEmergencyKitRequest(emergencyKitId: kit2.id)
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let remainingKits = try mockRepository.allEmergencyKits()
            #expect(remainingKits.count == 2)
            
            let remainingIds = remainingKits.map { $0.id }
            #expect(remainingIds.contains(kit1.id))
            #expect(!remainingIds.contains(kit2.id))
            #expect(remainingIds.contains(kit3.id))
            
            let remainingNames = remainingKits.map { $0.name }
            #expect(remainingNames.contains("Kit 1"))
            #expect(!remainingNames.contains("Kit 2"))
            #expect(remainingNames.contains("Kit 3"))
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("DeleteEmergencyKitUseCase deletes kit with photo")
    func testDeleteKitWithPhoto() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = DeleteEmergencyKitUseCase(repository: mockRepository)
        
        let photoData = Data([0x01, 0x02, 0x03, 0x04])
        let kitWithPhoto = TestDataFactory.createValidEmergencyKit(
            name: "Photo Kit",
            location: "Studio",
            photo: photoData
        )
        try mockRepository.addEmergencyKit(kitWithPhoto)
        
        let request = DeleteEmergencyKitRequest(emergencyKitId: kitWithPhoto.id)
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let remainingKits = try mockRepository.allEmergencyKits()
            #expect(remainingKits.isEmpty)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    // MARK: - Failure Tests
    
    @Test("DeleteEmergencyKitUseCase fails when kit doesn't exist")
    func testDeleteNonExistentKit() {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = DeleteEmergencyKitUseCase(repository: mockRepository)
        
        let nonExistentId = UUID()
        let request = DeleteEmergencyKitRequest(emergencyKitId: nonExistentId)
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
    
    @Test("DeleteEmergencyKitUseCase fails when repository throws error")
    func testRepositoryError() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = DeleteEmergencyKitUseCase(repository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        try mockRepository.addEmergencyKit(emergencyKit)
        
        // Configure repository to throw error on delete
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = SwiftDataEmergencyKitRepositoryError.fetchError(
            NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database error"])
        )
        
        let request = DeleteEmergencyKitRequest(emergencyKitId: emergencyKit.id)
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            #expect(error is SwiftDataEmergencyKitRepositoryError)
            if case SwiftDataEmergencyKitRepositoryError.fetchError = error {
                // Expected error type
            } else {
                Issue.record("Expected fetchError")
            }
        }
    }
    
    @Test("DeleteEmergencyKitUseCase fails with generic repository error")
    func testGenericRepositoryError() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = DeleteEmergencyKitUseCase(repository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        try mockRepository.addEmergencyKit(emergencyKit)
        
        // Configure repository to throw generic error
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = NSError(
            domain: "UnexpectedError",
            code: 999,
            userInfo: [NSLocalizedDescriptionKey: "Unexpected deletion error"]
        )
        
        let request = DeleteEmergencyKitRequest(emergencyKitId: emergencyKit.id)
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            let nsError = error as NSError
            #expect(nsError.domain == "UnexpectedError")
            #expect(nsError.code == 999)
        }
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("DeleteEmergencyKitUseCase handles multiple deletions")
    func testMultipleDeletions() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = DeleteEmergencyKitUseCase(repository: mockRepository)
        
        let kit1 = TestDataFactory.createValidEmergencyKit(name: "Kit 1")
        let kit2 = TestDataFactory.createValidEmergencyKit(name: "Kit 2")
        let kit3 = TestDataFactory.createValidEmergencyKit(name: "Kit 3")
        
        try mockRepository.addEmergencyKit(kit1)
        try mockRepository.addEmergencyKit(kit2)
        try mockRepository.addEmergencyKit(kit3)
        
        // Delete all kits one by one
        let request1 = DeleteEmergencyKitRequest(emergencyKitId: kit1.id)
        let request2 = DeleteEmergencyKitRequest(emergencyKitId: kit2.id)
        let request3 = DeleteEmergencyKitRequest(emergencyKitId: kit3.id)
        
        let result1 = useCase.execute(request: request1)
        let result2 = useCase.execute(request: request2)
        let result3 = useCase.execute(request: request3)
        
        switch (result1, result2, result3) {
        case (.success, .success, .success):
            let remainingKits = try mockRepository.allEmergencyKits()
            #expect(remainingKits.isEmpty)
        case (.failure(let error), _, _):
            Issue.record("First deletion failed: \(error)")
        case (_, .failure(let error), _):
            Issue.record("Second deletion failed: \(error)")
        case (_, _, .failure(let error)):
            Issue.record("Third deletion failed: \(error)")
        }
    }
    
    @Test("DeleteEmergencyKitUseCase handles deletion of already deleted kit")
    func testDeleteAlreadyDeletedKit() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = DeleteEmergencyKitUseCase(repository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit()
        try mockRepository.addEmergencyKit(emergencyKit)
        
        let request = DeleteEmergencyKitRequest(emergencyKitId: emergencyKit.id)
        
        // First deletion should succeed
        let firstResult = useCase.execute(request: request)
        switch firstResult {
        case .success:
            break // Expected
        case .failure(let error):
            Issue.record("First deletion failed: \(error)")
            return
        }
        
        // Second deletion should fail
        let secondResult = useCase.execute(request: request)
        switch secondResult {
        case .success:
            Issue.record("Expected failure for second deletion but got success")
        case .failure(let error):
            #expect(error is SwiftDataEmergencyKitRepositoryError)
            if case SwiftDataEmergencyKitRepositoryError.emergencyKitNotFound = error {
                // Expected error
            } else {
                Issue.record("Expected emergencyKitNotFound error")
            }
        }
    }
    
    @Test("DeleteEmergencyKitUseCase handles deletion with complex item relationships")
    func testDeleteKitWithComplexItems() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = DeleteEmergencyKitUseCase(repository: mockRepository)
        
        // Create kit with items having various properties
        let expiredItem = try TestDataFactory.createExpiredItem()
        let expiringItem = try TestDataFactory.createExpiringItem()
        let nonExpiringItem = try TestDataFactory.createItemWithoutExpiration()
        let itemWithPhoto = try TestDataFactory.createValidItem(photo: Data([0x01, 0x02]))
        
        let complexKit = TestDataFactory.createValidEmergencyKit(
            name: "Complex Kit",
            location: "Storage",
            items: [expiredItem, expiringItem, nonExpiringItem, itemWithPhoto]
        )
        try mockRepository.addEmergencyKit(complexKit)
        
        let request = DeleteEmergencyKitRequest(emergencyKitId: complexKit.id)
        let result = useCase.execute(request: request)
        
        switch result {
        case .success:
            let remainingKits = try mockRepository.allEmergencyKits()
            #expect(remainingKits.isEmpty)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
}
