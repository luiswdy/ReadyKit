//
//  FetchAllEmergencyKitsUseCaseTests.swift
//  ReadyKitTests
//
//  Created by Claude on 8/22/25.
//

import Testing
import Foundation
@testable import ReadyKit

struct FetchAllEmergencyKitsUseCaseTests {
    
    // MARK: - Success Tests
    
    @Test("FetchAllEmergencyKitsUseCase returns empty array when no kits exist")
    func testEmptyRepository() {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = FetchAllEmergencyKitsUseCase(repository: mockRepository)
        
        let result = useCase.execute()
        
        switch result {
        case .success(let emergencyKits):
            #expect(emergencyKits.isEmpty)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("FetchAllEmergencyKitsUseCase returns single emergency kit")
    func testSingleEmergencyKit() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = FetchAllEmergencyKitsUseCase(repository: mockRepository)
        
        let emergencyKit = TestDataFactory.createValidEmergencyKit(name: "Single Kit", location: "Kitchen")
        try mockRepository.addEmergencyKit(emergencyKit)
        
        let result = useCase.execute()
        
        switch result {
        case .success(let emergencyKits):
            #expect(emergencyKits.count == 1)
            #expect(emergencyKits.first?.name == "Single Kit")
            #expect(emergencyKits.first?.location == "Kitchen")
            #expect(emergencyKits.first?.id == emergencyKit.id)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("FetchAllEmergencyKitsUseCase returns multiple emergency kits")
    func testMultipleEmergencyKits() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = FetchAllEmergencyKitsUseCase(repository: mockRepository)
        
        let kit1 = TestDataFactory.createValidEmergencyKit(name: "Home Kit", location: "Living Room")
        let kit2 = TestDataFactory.createValidEmergencyKit(name: "Car Kit", location: "Garage")
        let kit3 = TestDataFactory.createValidEmergencyKit(name: "Office Kit", location: "Desk")
        
        try mockRepository.addEmergencyKit(kit1)
        try mockRepository.addEmergencyKit(kit2)
        try mockRepository.addEmergencyKit(kit3)
        
        let result = useCase.execute()
        
        switch result {
        case .success(let emergencyKits):
            #expect(emergencyKits.count == 3)
            
            let kitNames = emergencyKits.map { $0.name }
            #expect(kitNames.contains("Home Kit"))
            #expect(kitNames.contains("Car Kit"))
            #expect(kitNames.contains("Office Kit"))
            
            let kitLocations = emergencyKits.map { $0.location }
            #expect(kitLocations.contains("Living Room"))
            #expect(kitLocations.contains("Garage"))
            #expect(kitLocations.contains("Desk"))
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("FetchAllEmergencyKitsUseCase returns kits with items")
    func testEmergencyKitsWithItems() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = FetchAllEmergencyKitsUseCase(repository: mockRepository)
        
        let kit = TestDataFactory.createEmergencyKitWithItems(
            itemCount: 3,
            name: "Complete Kit",
            location: "Storage Room"
        )
        try mockRepository.addEmergencyKit(kit)
        
        let result = useCase.execute()
        
        switch result {
        case .success(let emergencyKits):
            #expect(emergencyKits.count == 1)
            #expect(emergencyKits.first?.items.count == 3)
            #expect(emergencyKits.first?.name == "Complete Kit")
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("FetchAllEmergencyKitsUseCase returns kits with photos")
    func testEmergencyKitsWithPhotos() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = FetchAllEmergencyKitsUseCase(repository: mockRepository)
        
        let photoData = Data([0x01, 0x02, 0x03, 0x04])
        let kit = TestDataFactory.createValidEmergencyKit(
            name: "Photo Kit",
            location: "Basement",
            photo: photoData
        )
        try mockRepository.addEmergencyKit(kit)
        
        let result = useCase.execute()
        
        switch result {
        case .success(let emergencyKits):
            #expect(emergencyKits.count == 1)
            #expect(emergencyKits.first?.photo == photoData)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    // MARK: - Failure Tests
    
    @Test("FetchAllEmergencyKitsUseCase handles repository error")
    func testRepositoryError() {
        let mockRepository = MockEmergencyKitRepository()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = SwiftDataEmergencyKitRepositoryError.fetchError(NSError(domain: "TestError", code: 1))
        
        let useCase = FetchAllEmergencyKitsUseCase(repository: mockRepository)
        
        let result = useCase.execute()
        
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
    
    @Test("FetchAllEmergencyKitsUseCase handles generic error from repository")
    func testGenericRepositoryError() {
        let mockRepository = MockEmergencyKitRepository()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = NSError(domain: "UnexpectedError", code: 999, userInfo: [NSLocalizedDescriptionKey: "Unexpected database error"])
        
        let useCase = FetchAllEmergencyKitsUseCase(repository: mockRepository)
        
        let result = useCase.execute()
        
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
    
    @Test("FetchAllEmergencyKitsUseCase handles large number of kits")
    func testLargeNumberOfKits() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = FetchAllEmergencyKitsUseCase(repository: mockRepository)
        
        let kitCount = 100
        for index in 0..<kitCount {
            let kit = TestDataFactory.createValidEmergencyKit(
                name: "Kit \(index)",
                location: "Location \(index)"
            )
            try mockRepository.addEmergencyKit(kit)
        }
        
        let result = useCase.execute()
        
        switch result {
        case .success(let emergencyKits):
            #expect(emergencyKits.count == kitCount)
            
            // Verify all kits are present
            let kitNames = emergencyKits.map { $0.name }
            for index in 0..<kitCount {
                #expect(kitNames.contains("Kit \(index)"))
            }
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("FetchAllEmergencyKitsUseCase handles kits with Unicode names")
    func testUnicodeNames() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = FetchAllEmergencyKitsUseCase(repository: mockRepository)
        
        let unicodeKit1 = TestDataFactory.createValidEmergencyKit(
            name: "🚨 紧急工具包",
            location: "🏠 家"
        )
        let unicodeKit2 = TestDataFactory.createValidEmergencyKit(
            name: "مجموعة الطوارئ",
            location: "المنزل"
        )
        let unicodeKit3 = TestDataFactory.createValidEmergencyKit(
            name: "Комплект экстренной помощи",
            location: "Дом"
        )
        
        try mockRepository.addEmergencyKit(unicodeKit1)
        try mockRepository.addEmergencyKit(unicodeKit2)
        try mockRepository.addEmergencyKit(unicodeKit3)
        
        let result = useCase.execute()
        
        switch result {
        case .success(let emergencyKits):
            #expect(emergencyKits.count == 3)
            
            let kitNames = emergencyKits.map { $0.name }
            #expect(kitNames.contains("🚨 紧急工具包"))
            #expect(kitNames.contains("مجموعة الطوارئ"))
            #expect(kitNames.contains("Комплект экстренной помощи"))
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("FetchAllEmergencyKitsUseCase handles kits with very long names and locations")
    func testLongStrings() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = FetchAllEmergencyKitsUseCase(repository: mockRepository)
        
        let longName = String(repeating: "Emergency Kit ", count: 100).trimmingCharacters(in: .whitespacesAndNewlines)
        let longLocation = String(repeating: "Storage Location ", count: 100).trimmingCharacters(in: .whitespacesAndNewlines)
        
        let kit = TestDataFactory.createValidEmergencyKit(
            name: longName,
            location: longLocation
        )
        try mockRepository.addEmergencyKit(kit)
        
        let result = useCase.execute()
        
        switch result {
        case .success(let emergencyKits):
            #expect(emergencyKits.count == 1)
            print(emergencyKits.first?.name ?? "nil")
            print(emergencyKits.first?.location ?? "nil")
            #expect(emergencyKits.first?.name == longName)
            #expect(emergencyKits.first?.location == longLocation)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("FetchAllEmergencyKitsUseCase handles kits with many items")
    func testKitsWithManyItems() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = FetchAllEmergencyKitsUseCase(repository: mockRepository)
        
        let kit = TestDataFactory.createEmergencyKitWithItems(
            itemCount: 50,
            name: "Large Kit",
            location: "Storage"
        )
        try mockRepository.addEmergencyKit(kit)
        
        let result = useCase.execute()
        
        switch result {
        case .success(let emergencyKits):
            #expect(emergencyKits.count == 1)
            #expect(emergencyKits.first?.items.count == 50)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
    
    @Test("FetchAllEmergencyKitsUseCase maintains kit identity")
    func testKitIdentityPreservation() throws {
        let mockRepository = MockEmergencyKitRepository()
        let useCase = FetchAllEmergencyKitsUseCase(repository: mockRepository)
        
        let originalKit = TestDataFactory.createValidEmergencyKit()
        try mockRepository.addEmergencyKit(originalKit)
        
        let result = useCase.execute()
        
        switch result {
        case .success(let emergencyKits):
            #expect(emergencyKits.count == 1)
            let fetchedKit = emergencyKits.first!
            
            // Verify all properties are preserved
            #expect(fetchedKit.id == originalKit.id)
            #expect(fetchedKit.name == originalKit.name)
            #expect(fetchedKit.location == originalKit.location)
            #expect(fetchedKit.photo == originalKit.photo)
            #expect(fetchedKit.items.count == originalKit.items.count)
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }
}
