//
//  EmergencyKitMapperTests.swift
//  ReadyKitTests
//
//  Created by Claude on 8/22/25.
//

import Testing
import Foundation
@testable import ReadyKit

struct EmergencyKitMapperTests {
    
    // MARK: - toDomain Tests
    
    @Test("EmergencyKitMapper.toDomain converts model to domain entity successfully")
    func testToDomainBasic() throws {
        let id = UUID()
        let name = "Test Emergency Kit"
        let location = "Living Room"
        let photo = Data([0x01, 0x02, 0x03])
        
        let model = EmergencyKitModel(
            id: id,
            name: name,
            items: [],
            photo: photo,
            location: location
        )
        
        let domainEntity = try EmergencyKitMapper.toDomain(model)
        
        #expect(domainEntity.id == id)
        #expect(domainEntity.name == name)
        #expect(domainEntity.location == location)
        #expect(domainEntity.photo == photo)
        #expect(domainEntity.items.isEmpty)
    }
    
    @Test("EmergencyKitMapper.toDomain handles nil photo")
    func testToDomainWithNilPhoto() throws {
        let model = EmergencyKitModel(
            id: UUID(),
            name: "Kit without Photo",
            items: [],
            photo: nil,
            location: "Garage"
        )
        
        let domainEntity = try EmergencyKitMapper.toDomain(model)
        
        #expect(domainEntity.photo == nil)
        #expect(domainEntity.name == "Kit without Photo")
        #expect(domainEntity.location == "Garage")
    }
    
    @Test("EmergencyKitMapper.toDomain converts items successfully")
    func testToDomainWithItems() throws {
        let kitId = UUID()
        let item1Id = UUID()
        let item2Id = UUID()
        
        let kitModel = EmergencyKitModel(
            id: kitId,
            name: "Kit with Items",
            items: [],
            photo: nil,
            location: "Storage"
        )
        
        let item1Model = ItemModel(
            id: item1Id,
            name: "Item 1",
            expirationDate: Date(),
            notes: "Test notes 1",
            emergencyKit: kitModel,
            quantityValue: 1,
            quantityUnitName: "piece"
        )
        
        let item2Model = ItemModel(
            id: item2Id,
            name: "Item 2",
            expirationDate: nil,
            notes: nil,
            emergencyKit: kitModel,
            quantityValue: 5,
            quantityUnitName: "boxes"
        )
        
        kitModel.items = [item1Model, item2Model]
        
        let domainEntity = try EmergencyKitMapper.toDomain(kitModel)
        
        #expect(domainEntity.items.count == 2)
        
        let item1 = domainEntity.items.first { $0.id == item1Id }
        let item2 = domainEntity.items.first { $0.id == item2Id }
        
        #expect(item1?.name == "Item 1")
        #expect(item1?.notes == "Test notes 1")
        #expect(item1?.quantityValue == 1)
        #expect(item1?.quantityUnitName == "piece")
        
        #expect(item2?.name == "Item 2")
        #expect(item2?.notes == nil)
        #expect(item2?.quantityValue == 5)
        #expect(item2?.quantityUnitName == "boxes")
    }
    
    @Test("EmergencyKitMapper.toDomain throws when item mapping fails")
    func testToDomainWithInvalidItems() {
        let kitModel = EmergencyKitModel(
            id: UUID(),
            name: "Kit with Invalid Items",
            items: [],
            photo: nil,
            location: "Test Location"
        )
        
        // Create an invalid item (empty name should cause Item initialization to fail)
        let invalidItemModel = ItemModel(
            id: UUID(),
            name: "", // This should cause Item validation to fail
            expirationDate: nil,
            notes: nil,
            emergencyKit: kitModel,
            quantityValue: 1,
            quantityUnitName: "piece"
        )
        
        kitModel.items = [invalidItemModel]
        
        #expect(throws: ItemValidationError.self) {
            _ = try EmergencyKitMapper.toDomain(kitModel)
        }
    }
    
    // MARK: - toModel Tests
    
    @Test("EmergencyKitMapper.toModel converts domain entity to model successfully")
    func testToModelBasic() {
        let id = UUID()
        let name = "Test Emergency Kit"
        let location = "Living Room"
        let photo = Data([0x01, 0x02, 0x03])
        
        let domainEntity = try! EmergencyKit(
            id: id,
            name: name,
            items: [],
            photo: photo,
            location: location
        )
        
        let model = EmergencyKitMapper.toModel(domainEntity)
        
        #expect(model.id == id)
        #expect(model.name == name)
        #expect(model.location == location)
        #expect(model.photo == photo)
        #expect(model.items.isEmpty)
    }
    
    @Test("EmergencyKitMapper.toModel handles nil photo")
    func testToModelWithNilPhoto() {
        let domainEntity = try! EmergencyKit(
            name: "Kit without Photo",
            items: [],
            photo: nil,
            location: "Garage"
        )
        
        let model = EmergencyKitMapper.toModel(domainEntity)
        
        #expect(model.photo == nil)
        #expect(model.name == "Kit without Photo")
        #expect(model.location == "Garage")
    }
    
    @Test("EmergencyKitMapper.toModel converts items successfully")
    func testToModelWithItems() throws {
        let item1 = try TestDataFactory.createValidItem(
            name: "Item 1",
            expirationDate: Date(),
            notes: "Test notes 1",
            quantityValue: 1,
            quantityUnitName: "piece"
        )
        
        let item2 = try TestDataFactory.createValidItem(
            name: "Item 2",
            expirationDate: nil,
            notes: nil,
            quantityValue: 5,
            quantityUnitName: "boxes"
        )
        
        let domainEntity = try! EmergencyKit(
            name: "Kit with Items",
            items: [item1, item2],
            photo: nil,
            location: "Storage"
        )
        
        let model = EmergencyKitMapper.toModel(domainEntity)
        
        #expect(model.items.count == 2)
        
        let itemModel1 = model.items.first { $0.id == item1.id }
        let itemModel2 = model.items.first { $0.id == item2.id }
        
        #expect(itemModel1?.name == "Item 1")
        #expect(itemModel1?.notes == "Test notes 1")
        #expect(itemModel1?.quantityValue == 1)
        #expect(itemModel1?.quantityUnitName == "piece")
        #expect(itemModel1?.emergencyKit === model)
        
        #expect(itemModel2?.name == "Item 2")
        #expect(itemModel2?.notes == nil)
        #expect(itemModel2?.quantityValue == 5)
        #expect(itemModel2?.quantityUnitName == "boxes")
        #expect(itemModel2?.emergencyKit === model)
    }
    
    // MARK: - Round Trip Tests
    
    @Test("EmergencyKitMapper round trip conversion preserves data")
    func testRoundTripConversion() throws {
        let originalEntity = try createComplexEmergencyKit()
        
        let model = EmergencyKitMapper.toModel(originalEntity)
        let convertedEntity = try EmergencyKitMapper.toDomain(model)
        
        #expect(convertedEntity.id == originalEntity.id)
        #expect(convertedEntity.name == originalEntity.name)
        #expect(convertedEntity.location == originalEntity.location)
        #expect(convertedEntity.photo == originalEntity.photo)
        #expect(convertedEntity.items.count == originalEntity.items.count)
        
        // Compare items
        for originalItem in originalEntity.items {
            let convertedItem = convertedEntity.items.first { $0.id == originalItem.id }
            #expect(convertedItem != nil, "Item with ID \(originalItem.id) should exist after conversion")
            
            if let convertedItem = convertedItem {
                #expect(convertedItem.name == originalItem.name)
                #expect(convertedItem.expirationDate == originalItem.expirationDate)
                #expect(convertedItem.notes == originalItem.notes)
                #expect(convertedItem.quantityValue == originalItem.quantityValue)
                #expect(convertedItem.quantityUnitName == originalItem.quantityUnitName)
                #expect(convertedItem.photo == originalItem.photo)
            }
        }
    }
    
    @Test("EmergencyKitMapper round trip with empty kit")
    func testRoundTripEmptyKit() throws {
        let originalEntity = try! EmergencyKit(
            name: "Empty Kit",
            items: [],
            photo: nil,
            location: "Basement"
        )
        
        let model = EmergencyKitMapper.toModel(originalEntity)
        let convertedEntity = try EmergencyKitMapper.toDomain(model)
        
        #expect(convertedEntity.id == originalEntity.id)
        #expect(convertedEntity.name == originalEntity.name)
        #expect(convertedEntity.location == originalEntity.location)
        #expect(convertedEntity.photo == originalEntity.photo)
        #expect(convertedEntity.items.isEmpty)
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("EmergencyKitMapper handles Unicode characters")
    func testUnicodeCharacters() throws {
        let unicodeName = "🚨 紧急工具包 Emergency Kit 👨‍⚕️"
        let unicodeLocation = "🏠 客厅 Living Room 📍"
        
        let originalEntity = try! EmergencyKit(
            name: unicodeName,
            items: [],
            photo: nil,
            location: unicodeLocation
        )
        
        let model = EmergencyKitMapper.toModel(originalEntity)
        let convertedEntity = try EmergencyKitMapper.toDomain(model)
        
        #expect(convertedEntity.name == unicodeName)
        #expect(convertedEntity.location == unicodeLocation)
    }
    
    @Test("EmergencyKitMapper handles very long strings")
    func testLongStrings() throws {
        let longName = String(repeating: "Emergency Kit ", count: 100).trimmingCharacters(in: .whitespacesAndNewlines)
        let longLocation = String(repeating: "Storage Location ", count: 100).trimmingCharacters(in: .whitespacesAndNewlines)
        
        let originalEntity = try! EmergencyKit(
            name: longName,
            items: [],
            photo: nil,
            location: longLocation
        )
        
        let model = EmergencyKitMapper.toModel(originalEntity)
        let convertedEntity = try EmergencyKitMapper.toDomain(model)
        
        #expect(convertedEntity.name == longName)
        #expect(convertedEntity.location == longLocation)
    }
    
    @Test("EmergencyKitMapper handles large photo data")
    func testLargePhotoData() throws {
        let largePhotoData = Data(repeating: 0xFF, count: 1024 * 1024) // 1MB
        
        let originalEntity = try! EmergencyKit(
            name: "Large Photo Kit",
            items: [],
            photo: largePhotoData,
            location: "Storage"
        )
        
        let model = EmergencyKitMapper.toModel(originalEntity)
        let convertedEntity = try EmergencyKitMapper.toDomain(model)
        
        #expect(convertedEntity.photo?.count == largePhotoData.count)
        #expect(convertedEntity.photo == largePhotoData)
    }
    
    @Test("EmergencyKitMapper handles many items")
    func testManyItems() throws {
        let itemCount = 100
        let items = try (0..<itemCount).map { index in
            try TestDataFactory.createValidItem(name: "Item \(index)")
        }
        
        let originalEntity = try! EmergencyKit(
            name: "Kit with Many Items",
            items: items,
            photo: nil,
            location: "Storage Room"
        )
        
        let model = EmergencyKitMapper.toModel(originalEntity)
        let convertedEntity = try EmergencyKitMapper.toDomain(model)
        
        #expect(convertedEntity.items.count == itemCount)
        
        // Verify all items are present
        for originalItem in originalEntity.items {
            let convertedItem = convertedEntity.items.first { $0.id == originalItem.id }
            #expect(convertedItem != nil, "Item \(originalItem.name) should be present after conversion")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createComplexEmergencyKit() throws -> EmergencyKit {
        let expiredItem = try TestDataFactory.createExpiredItem(name: "Expired Medicine")
        let expiringItem = try TestDataFactory.createExpiringItem(name: "Expiring Food")
        let nonExpiringItem = try TestDataFactory.createItemWithoutExpiration(name: "Flashlight")
        let itemWithPhoto = try TestDataFactory.createValidItem(
            name: "Item with Photo",
            photo: Data([0x01, 0x02, 0x03, 0x04])
        )
        
        return try! EmergencyKit(
            name: "Complex Emergency Kit",
            items: [expiredItem, expiringItem, nonExpiringItem, itemWithPhoto],
            photo: Data([0xFF, 0xFE, 0xFD]),
            location: "Comprehensive Storage"
        )
    }
}
