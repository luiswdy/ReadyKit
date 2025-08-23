//
//  ItemMapperTests.swift
//  ReadyKitTests
//
//  Created by Claude on 8/22/25.
//

import Testing
import Foundation
@testable import ReadyKit

struct ItemMapperTests {
    
    // MARK: - toDomain Tests
    
    @Test("ItemMapper.toDomain converts model to domain entity successfully")
    func testToDomainBasic() throws {
        let id = UUID()
        let name = "Test Item"
        let expirationDate = Date()
        let notes = "Test notes"
        let quantityValue = 5
        let quantityUnitName = "pieces"
        let photo = Data([0x01, 0x02, 0x03])
        
        let model = ItemModel(
            id: id,
            name: name,
            expirationDate: expirationDate,
            notes: notes,
            emergencyKit: nil,
            quantityValue: quantityValue,
            quantityUnitName: quantityUnitName,
            photo: photo
        )
        
        let domainEntity = try ItemMapper.toDomain(model)
        
        #expect(domainEntity.id == id)
        #expect(domainEntity.name == name)
        #expect(domainEntity.expirationDate == expirationDate)
        #expect(domainEntity.notes == notes)
        #expect(domainEntity.quantityValue == quantityValue)
        #expect(domainEntity.quantityUnitName == quantityUnitName)
        #expect(domainEntity.photo == photo)
    }
    
    @Test("ItemMapper.toDomain handles minimal item")
    func testToDomainMinimal() throws {
        let model = ItemModel(
            id: UUID(),
            name: "Minimal Item",
            expirationDate: nil,
            notes: nil,
            emergencyKit: nil,
            quantityValue: 1,
            quantityUnitName: "piece",
            photo: nil
        )
        
        let domainEntity = try ItemMapper.toDomain(model)
        
        #expect(domainEntity.name == "Minimal Item")
        #expect(domainEntity.expirationDate == nil)
        #expect(domainEntity.notes == nil)
        #expect(domainEntity.quantityValue == 1)
        #expect(domainEntity.quantityUnitName == "piece")
        #expect(domainEntity.photo == nil)
    }
    
    @Test("ItemMapper.toDomain handles item with emergency kit reference")
    func testToDomainWithEmergencyKitReference() throws {
        let emergencyKitModel = EmergencyKitModel(
            id: UUID(),
            name: "Parent Kit",
            items: [],
            photo: nil,
            location: "Storage"
        )
        
        let itemModel = ItemModel(
            id: UUID(),
            name: "Child Item",
            expirationDate: nil,
            notes: nil,
            emergencyKit: emergencyKitModel,
            quantityValue: 3,
            quantityUnitName: "boxes"
        )
        
        let domainEntity = try ItemMapper.toDomain(itemModel)
        
        #expect(domainEntity.name == "Child Item")
        #expect(domainEntity.quantityValue == 3)
        #expect(domainEntity.quantityUnitName == "boxes")
        // Note: Domain entity doesn't maintain reference to emergency kit
    }
    
    @Test("ItemMapper.toDomain throws with invalid name")
    func testToDomainWithInvalidName() {
        let model = ItemModel(
            id: UUID(),
            name: "", // Empty name should cause validation error
            expirationDate: nil,
            notes: nil,
            emergencyKit: nil,
            quantityValue: 1,
            quantityUnitName: "piece"
        )
        
        #expect(throws: ItemValidationError.self) {
            _ = try ItemMapper.toDomain(model)
        }
    }
    
    @Test("ItemMapper.toDomain throws with invalid quantity")
    func testToDomainWithInvalidQuantity() {
        let model = ItemModel(
            id: UUID(),
            name: "Valid Name",
            expirationDate: nil,
            notes: nil,
            emergencyKit: nil,
            quantityValue: 0, // Invalid quantity
            quantityUnitName: "piece"
        )
        
        #expect(throws: ItemValidationError.self) {
            _ = try ItemMapper.toDomain(model)
        }
    }
    
    @Test("ItemMapper.toDomain throws with invalid unit name")
    func testToDomainWithInvalidUnitName() {
        let model = ItemModel(
            id: UUID(),
            name: "Valid Name",
            expirationDate: nil,
            notes: nil,
            emergencyKit: nil,
            quantityValue: 1,
            quantityUnitName: "" // Invalid unit name
        )
        
        #expect(throws: ItemValidationError.self) {
            _ = try ItemMapper.toDomain(model)
        }
    }
    
    // MARK: - toModel Tests
    
    @Test("ItemMapper.toModel converts domain entity to model successfully")
    func testToModelBasic() throws {
        let id = UUID()
        let name = "Test Item"
        let expirationDate = Date()
        let notes = "Test notes"
        let quantityValue = 5
        let quantityUnitName = "pieces"
        let photo = Data([0x01, 0x02, 0x03])
        
        let domainEntity = try Item(
            id: id,
            name: name,
            expirationDate: expirationDate,
            notes: notes,
            quantityValue: quantityValue,
            quantityUnitName: quantityUnitName,
            photo: photo
        )
        
        let model = ItemMapper.toModel(domainEntity, emergencyKit: nil)
        
        #expect(model.id == id)
        #expect(model.name == name)
        #expect(model.expirationDate == expirationDate)
        #expect(model.notes == notes)
        #expect(model.quantityValue == quantityValue)
        #expect(model.quantityUnitName == quantityUnitName)
        #expect(model.photo == photo)
        #expect(model.emergencyKit == nil)
    }
    
    @Test("ItemMapper.toModel handles minimal item")
    func testToModelMinimal() throws {
        let domainEntity = try Item(
            name: "Minimal Item",
            quantityValue: 1,
            quantityUnitName: "piece"
        )
        
        let model = ItemMapper.toModel(domainEntity, emergencyKit: nil)
        
        #expect(model.name == "Minimal Item")
        #expect(model.expirationDate == nil)
        #expect(model.notes == nil)
        #expect(model.quantityValue == 1)
        #expect(model.quantityUnitName == "piece")
        #expect(model.photo == nil)
        #expect(model.emergencyKit == nil)
    }
    
    @Test("ItemMapper.toModel sets emergency kit reference")
    func testToModelWithEmergencyKitReference() throws {
        let emergencyKitModel = EmergencyKitModel(
            id: UUID(),
            name: "Parent Kit",
            items: [],
            photo: nil,
            location: "Storage"
        )
        
        let domainEntity = try Item(
            name: "Child Item",
            quantityValue: 3,
            quantityUnitName: "boxes"
        )
        
        let model = ItemMapper.toModel(domainEntity, emergencyKit: emergencyKitModel)
        
        #expect(model.name == "Child Item")
        #expect(model.quantityValue == 3)
        #expect(model.quantityUnitName == "boxes")
        #expect(model.emergencyKit === emergencyKitModel)
    }
    
    // MARK: - Round Trip Tests
    
    @Test("ItemMapper round trip conversion preserves data")
    func testRoundTripConversion() throws {
        let originalEntity = try TestDataFactory.createValidItem(
            name: "Round Trip Item",
            expirationDate: Date(),
            notes: "Test notes for round trip",
            quantityValue: 10,
            quantityUnitName: "bottles",
            photo: Data([0xFF, 0xFE, 0xFD])
        )
        
        let model = ItemMapper.toModel(originalEntity, emergencyKit: nil)
        let convertedEntity = try ItemMapper.toDomain(model)
        
        #expect(convertedEntity.id == originalEntity.id)
        #expect(convertedEntity.name == originalEntity.name)
        #expect(convertedEntity.expirationDate == originalEntity.expirationDate)
        #expect(convertedEntity.notes == originalEntity.notes)
        #expect(convertedEntity.quantityValue == originalEntity.quantityValue)
        #expect(convertedEntity.quantityUnitName == originalEntity.quantityUnitName)
        #expect(convertedEntity.photo == originalEntity.photo)
    }
    
    @Test("ItemMapper round trip with minimal item")
    func testRoundTripMinimal() throws {
        let originalEntity = try Item(
            name: "Minimal Round Trip",
            quantityValue: 1,
            quantityUnitName: "piece"
        )
        
        let model = ItemMapper.toModel(originalEntity, emergencyKit: nil)
        let convertedEntity = try ItemMapper.toDomain(model)
        
        #expect(convertedEntity.id == originalEntity.id)
        #expect(convertedEntity.name == originalEntity.name)
        #expect(convertedEntity.expirationDate == originalEntity.expirationDate)
        #expect(convertedEntity.notes == originalEntity.notes)
        #expect(convertedEntity.quantityValue == originalEntity.quantityValue)
        #expect(convertedEntity.quantityUnitName == originalEntity.quantityUnitName)
        #expect(convertedEntity.photo == originalEntity.photo)
    }
    
    @Test("ItemMapper round trip preserves emergency kit reference")
    func testRoundTripWithEmergencyKitReference() throws {
        let emergencyKitModel = EmergencyKitModel(
            id: UUID(),
            name: "Reference Kit",
            items: [],
            photo: nil,
            location: "Test Location"
        )
        
        let originalEntity = try TestDataFactory.createValidItem(name: "Referenced Item")
        
        let model = ItemMapper.toModel(originalEntity, emergencyKit: emergencyKitModel)
        let convertedEntity = try ItemMapper.toDomain(model)
        
        // Domain entity properties should be preserved
        #expect(convertedEntity.id == originalEntity.id)
        #expect(convertedEntity.name == originalEntity.name)
        
        // Model should maintain emergency kit reference
        #expect(model.emergencyKit === emergencyKitModel)
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("ItemMapper handles Unicode characters")
    func testUnicodeCharacters() throws {
        let unicodeName = "🔋 电池 Battery باتری"
        let unicodeNotes = "测试笔记 тестовые заметки ملاحظات الاختبار"
        let unicodeUnitName = "个 pieces штук"
        
        let originalEntity = try Item(
            name: unicodeName,
            notes: unicodeNotes,
            quantityValue: 4,
            quantityUnitName: unicodeUnitName
        )
        
        let model = ItemMapper.toModel(originalEntity, emergencyKit: nil)
        let convertedEntity = try ItemMapper.toDomain(model)
        
        #expect(convertedEntity.name == unicodeName)
        #expect(convertedEntity.notes == unicodeNotes)
        #expect(convertedEntity.quantityUnitName == unicodeUnitName)
    }
    
    @Test("ItemMapper handles very long strings")
    func testLongStrings() throws {
        let longName = String(repeating: "Very Long Item Name ", count: 50)
        let longNotes = String(repeating: "This is a very detailed note about the item. ", count: 100)
        let longUnitName = String(repeating: "unit", count: 25)
        
        let originalEntity = try Item(
            name: longName,
            notes: longNotes,
            quantityValue: 1,
            quantityUnitName: longUnitName
        )
        
        let model = ItemMapper.toModel(originalEntity, emergencyKit: nil)
        let convertedEntity = try ItemMapper.toDomain(model)
        
        #expect(convertedEntity.name == longName)
        #expect(convertedEntity.notes == longNotes)
        #expect(convertedEntity.quantityUnitName == longUnitName)
    }
    
    @Test("ItemMapper handles large photo data")
    func testLargePhotoData() throws {
        let largePhotoData = Data(repeating: 0xAB, count: 2 * 1024 * 1024) // 2MB
        
        let originalEntity = try Item(
            name: "Large Photo Item",
            quantityValue: 1,
            quantityUnitName: "piece",
            photo: largePhotoData
        )
        
        let model = ItemMapper.toModel(originalEntity, emergencyKit: nil)
        let convertedEntity = try ItemMapper.toDomain(model)
        
        #expect(convertedEntity.photo?.count == largePhotoData.count)
        #expect(convertedEntity.photo == largePhotoData)
    }
    
    @Test("ItemMapper handles large quantity values")
    func testLargeQuantityValues() throws {
        let largeQuantity = 999999
        
        let originalEntity = try Item(
            name: "Bulk Item",
            quantityValue: largeQuantity,
            quantityUnitName: "pieces"
        )
        
        let model = ItemMapper.toModel(originalEntity, emergencyKit: nil)
        let convertedEntity = try ItemMapper.toDomain(model)
        
        #expect(convertedEntity.quantityValue == largeQuantity)
    }
    
    @Test("ItemMapper handles edge date values")
    func testEdgeDateValues() throws {
        let pastDate = TestConstants.Dates.past
        let futureDate = TestConstants.Dates.farFuture
        
        let pastItem = try Item(
            name: "Past Item",
            expirationDate: pastDate,
            quantityValue: 1,
            quantityUnitName: "piece"
        )
        
        let futureItem = try Item(
            name: "Future Item",
            expirationDate: futureDate,
            quantityValue: 1,
            quantityUnitName: "piece"
        )
        
        let pastModel = ItemMapper.toModel(pastItem, emergencyKit: nil)
        let futureModel = ItemMapper.toModel(futureItem, emergencyKit: nil)
        
        let convertedPastItem = try ItemMapper.toDomain(pastModel)
        let convertedFutureItem = try ItemMapper.toDomain(futureModel)
        
        #expect(convertedPastItem.expirationDate == pastDate)
        #expect(convertedFutureItem.expirationDate == futureDate)
    }
    
    @Test("ItemMapper preserves ID uniqueness")
    func testIdUniqueness() throws {
        let item1 = try TestDataFactory.createValidItem(name: "Item 1")
        let item2 = try TestDataFactory.createValidItem(name: "Item 2")
        
        let model1 = ItemMapper.toModel(item1, emergencyKit: nil)
        let model2 = ItemMapper.toModel(item2, emergencyKit: nil)
        
        #expect(model1.id != model2.id)
        #expect(model1.id == item1.id)
        #expect(model2.id == item2.id)
        
        let convertedItem1 = try ItemMapper.toDomain(model1)
        let convertedItem2 = try ItemMapper.toDomain(model2)
        
        #expect(convertedItem1.id == item1.id)
        #expect(convertedItem2.id == item2.id)
        #expect(convertedItem1.id != convertedItem2.id)
    }
}
