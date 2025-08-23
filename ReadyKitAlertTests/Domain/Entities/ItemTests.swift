//
//  ItemTests.swift
//  ReadyKitTests
//
//  Created by Claude on 8/22/25.
//

import Testing
import Foundation
@testable import ReadyKit

struct ItemTests {
    
    // MARK: - Valid Initialization Tests
    
    @Test("Item initialization with valid parameters succeeds")
    func testValidInitialization() throws {
        let id = UUID()
        let name = "Test Item"
        let expirationDate = Date()
        let notes = "Test notes"
        let quantityValue = 5
        let quantityUnitName = "pieces"
        let photo = Data([0x01, 0x02, 0x03])
        
        let item = try Item(
            id: id,
            name: name,
            expirationDate: expirationDate,
            notes: notes,
            quantityValue: quantityValue,
            quantityUnitName: quantityUnitName,
            photo: photo
        )
        
        #expect(item.id == id)
        #expect(item.name == name)
        #expect(item.expirationDate == expirationDate)
        #expect(item.notes == notes)
        #expect(item.quantityValue == quantityValue)
        #expect(item.quantityUnitName == quantityUnitName)
        #expect(item.photo == photo)
    }
    
    @Test("Item initialization with minimal valid parameters succeeds")
    func testMinimalValidInitialization() throws {
        let item = try Item(
            name: "Minimal Item",
            quantityValue: 1,
            quantityUnitName: "piece"
        )
        
        #expect(!item.name.isEmpty)
        #expect(item.expirationDate == nil)
        #expect(item.notes == nil)
        #expect(item.quantityValue == 1)
        #expect(item.quantityUnitName == "piece")
        #expect(item.photo == nil)
    }
    
    // MARK: - Name Validation Tests
    
    @Test("Item initialization with empty name throws ItemValidationError.emptyName")
    func testEmptyNameValidation() {
        #expect(throws: ItemValidationError.self) {
            _ = try Item(name: "", quantityValue: 1, quantityUnitName: "piece")
        }
    }
    
    @Test("Item initialization with whitespace-only name throws validation error")
    func testWhitespaceOnlyNameValidation() {
        let invalidNames = TestConstants.Validation.invalidNames
        
        for invalidName in invalidNames {
            #expect(throws: ItemValidationError.self, "Name '\(invalidName)' should fail validation") {
                _ = try Item(name: invalidName, quantityValue: 1, quantityUnitName: "piece")
            }
        }
    }
    
    @Test("Item initialization with valid names succeeds")
    func testValidNameValidation() throws {
        let validNames = TestConstants.Validation.validNames
        
        for validName in validNames {
            let item = try Item(name: validName, quantityValue: 1, quantityUnitName: "piece")
            #expect(item.name == validName)
        }
    }
    
    // MARK: - Quantity Validation Tests
    
    @Test("Item initialization with positive quantity values succeeds")
    func testValidQuantityValues() throws {
        let validQuantities = TestConstants.Validation.validQuantities
        
        for quantity in validQuantities {
            let item = try Item(name: "Test Item", quantityValue: quantity, quantityUnitName: "piece")
            #expect(item.quantityValue == quantity)
        }
    }
    
    @Test("Item initialization with zero quantity throws validation error")
    func testZeroQuantityValidation() {
        #expect(throws: ItemValidationError.self) {
            _ = try Item(name: "Test Item", quantityValue: 0, quantityUnitName: "piece")
        }
    }
    
    @Test("Item initialization with negative quantity throws validation error")
    func testNegativeQuantityValidation() {
        let invalidQuantities = TestConstants.Validation.invalidQuantities
        
        for quantity in invalidQuantities {
            #expect(throws: ItemValidationError.self, "Quantity \(quantity) should fail validation") {
                _ = try Item(name: "Test Item", quantityValue: quantity, quantityUnitName: "piece")
            }
        }
    }
    
    // MARK: - Quantity Unit Name Validation Tests
    
    @Test("Item initialization with valid unit names succeeds")
    func testValidUnitNameValidation() throws {
        let validUnitNames = TestConstants.Validation.validUnitNames
        
        for unitName in validUnitNames {
            let item = try Item(name: "Test Item", quantityValue: 1, quantityUnitName: unitName)
            #expect(item.quantityUnitName == unitName)
        }
    }
    
    @Test("Item initialization with empty unit name throws validation error")
    func testEmptyUnitNameValidation() {
        #expect(throws: ItemValidationError.self) {
            _ = try Item(name: "Test Item", quantityValue: 1, quantityUnitName: "")
        }
    }
    
    @Test("Item initialization with whitespace-only unit name throws validation error")
    func testWhitespaceOnlyUnitNameValidation() {
        let invalidUnitNames = TestConstants.Validation.invalidUnitNames
        
        for unitName in invalidUnitNames {
            #expect(throws: ItemValidationError.self, "Unit name '\(unitName)' should fail validation") {
                _ = try Item(name: "Test Item", quantityValue: 1, quantityUnitName: unitName)
            }
        }
    }
    
    // MARK: - Optional Properties Tests
    
    @Test("Item initialization with nil expiration date succeeds")
    func testNilExpirationDate() throws {
        let item = try Item(
            name: "Non-expiring Item",
            expirationDate: nil,
            quantityValue: 1,
            quantityUnitName: "piece"
        )
        
        #expect(item.expirationDate == nil)
    }
    
    @Test("Item initialization with nil notes succeeds")
    func testNilNotes() throws {
        let item = try Item(
            name: "Item without notes",
            notes: nil,
            quantityValue: 1,
            quantityUnitName: "piece"
        )
        
        #expect(item.notes == nil)
    }
    
    @Test("Item initialization with nil photo succeeds")
    func testNilPhoto() throws {
        let item = try Item(
            name: "Item without photo",
            quantityValue: 1,
            quantityUnitName: "piece",
            photo: nil
        )
        
        #expect(item.photo == nil)
    }
    
    // MARK: - Property Mutation Tests
    
    @Test("Item properties can be mutated after initialization")
    func testPropertyMutation() throws {
        var item = try TestDataFactory.createValidItem()
        
        let newExpirationDate = Date().addingTimeInterval(86400) // Tomorrow
        let newNotes = "Updated notes"
        let newQuantityValue = 10
        let newQuantityUnitName = "boxes"
        let newPhoto = Data([0x04, 0x05, 0x06])
        
        item.name = "Updated Item"
        item.expirationDate = newExpirationDate
        item.notes = newNotes
        item.quantityValue = newQuantityValue
        item.quantityUnitName = newQuantityUnitName
        item.photo = newPhoto
        
        #expect(item.name == "Updated Item")
        #expect(item.expirationDate == newExpirationDate)
        #expect(item.notes == newNotes)
        #expect(item.quantityValue == newQuantityValue)
        #expect(item.quantityUnitName == newQuantityUnitName)
        #expect(item.photo == newPhoto)
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("Item can handle very long names")
    func testLongName() throws {
        let longName = String(repeating: "A", count: 1000)
        let item = try Item(name: longName, quantityValue: 1, quantityUnitName: "piece")
        
        #expect(item.name == longName)
    }
    
    @Test("Item can handle Unicode characters in name")
    func testUnicodeCharactersInName() throws {
        let unicodeName = "🔋 Battery 电池 باتری"
        let item = try Item(name: unicodeName, quantityValue: 1, quantityUnitName: "piece")
        
        #expect(item.name == unicodeName)
    }
    
    @Test("Item can handle Unicode characters in unit name")
    func testUnicodeCharactersInUnitName() throws {
        let unicodeUnitName = "个 pieces штук"
        let item = try Item(name: "Test Item", quantityValue: 1, quantityUnitName: unicodeUnitName)
        
        #expect(item.quantityUnitName == unicodeUnitName)
    }
    
    @Test("Item can handle very long notes")
    func testLongNotes() throws {
        let longNotes = String(repeating: "This is a very long note. ", count: 100)
        let item = try Item(
            name: "Test Item",
            notes: longNotes,
            quantityValue: 1,
            quantityUnitName: "piece"
        )
        
        #expect(item.notes == longNotes)
    }
    
    @Test("Item can handle maximum reasonable quantity values")
    func testLargeQuantityValues() throws {
        let largeQuantity = 999999
        let item = try Item(
            name: "Large Quantity Item",
            quantityValue: largeQuantity,
            quantityUnitName: "pieces"
        )
        
        #expect(item.quantityValue == largeQuantity)
    }
    
    // MARK: - Date Edge Cases Tests
    
    @Test("Item can handle past expiration dates")
    func testPastExpirationDate() throws {
        let pastDate = TestConstants.Dates.past
        let item = try Item(
            name: "Already Expired Item",
            expirationDate: pastDate,
            quantityValue: 1,
            quantityUnitName: "piece"
        )
        
        #expect(item.expirationDate == pastDate)
    }
    
    @Test("Item can handle far future expiration dates")
    func testFarFutureExpirationDate() throws {
        let futureDate = TestConstants.Dates.farFuture
        let item = try Item(
            name: "Long Lasting Item",
            expirationDate: futureDate,
            quantityValue: 1,
            quantityUnitName: "piece"
        )
        
        #expect(item.expirationDate == futureDate)
    }
    
    // MARK: - ID Uniqueness Tests
    
    @Test("Item generates unique IDs by default")
    func testUniqueIdGeneration() throws {
        let item1 = try TestDataFactory.createValidItem(name: "Item 1")
        let item2 = try TestDataFactory.createValidItem(name: "Item 2")
        
        #expect(item1.id != item2.id)
    }
    
    @Test("Item accepts custom ID")
    func testCustomId() throws {
        let customId = UUID()
        let item = try Item(
            id: customId,
            name: "Custom ID Item",
            quantityValue: 1,
            quantityUnitName: "piece"
        )
        
        #expect(item.id == customId)
    }
}

// MARK: - ItemValidationError Tests

struct ItemValidationErrorTests {
    
    @Test("ItemValidationError.emptyName contains provided name")
    func testEmptyNameError() {
        let providedName = "   "
        let error = ItemValidationError.emptyName(providedName)
        
        switch error {
        case .emptyName(let name):
            #expect(name == providedName)
        default:
            Issue.record("Expected emptyName error")
        }
    }
    
    @Test("ItemValidationError.invalidQuantityValue contains provided value")
    func testInvalidQuantityValueError() {
        let providedValue = -5
        let error = ItemValidationError.invalidQuantityValue(providedValue)
        
        switch error {
        case .invalidQuantityValue(let value):
            #expect(value == providedValue)
        default:
            Issue.record("Expected invalidQuantityValue error")
        }
    }
    
    @Test("ItemValidationError.invalidQuantityValueInput contains provided string")
    func testInvalidQuantityValueInputError() {
        let providedString = "invalid"
        let error = ItemValidationError.invalidQuantityValueInput(providedString)
        
        switch error {
        case .invalidQuantityValueInput(let string):
            #expect(string == providedString)
        default:
            Issue.record("Expected invalidQuantityValueInput error")
        }
    }
    
    @Test("ItemValidationError.emptyQuantityUnitName contains provided unit name")
    func testEmptyQuantityUnitNameError() {
        let providedUnitName = ""
        let error = ItemValidationError.emptyQuantityUnitName(providedUnitName)
        
        switch error {
        case .emptyQuantityUnitName(let unitName):
            #expect(unitName == providedUnitName)
        default:
            Issue.record("Expected emptyQuantityUnitName error")
        }
    }
    
    @Test("ItemValidationError.tooManyYearsFromToday contains provided date")
    func testTooManyYearsFromTodayError() {
        let providedDate = Date()
        let error = ItemValidationError.tooManyYearsFromToday(providedDate)
        
        switch error {
        case .tooManyYearsFromToday(let date):
            #expect(date == providedDate)
        default:
            Issue.record("Expected tooManyYearsFromToday error")
        }
    }
}

// MARK: - ItemError Tests

struct ItemErrorTests {
    
    @Test("ItemError.noSuchItem contains provided ID")
    func testNoSuchItemError() {
        let providedId = UUID()
        let error = ItemError.noSuchItem(providedId)
        
        switch error {
        case .noSuchItem(let id):
            #expect(id == providedId)
        }
    }
}
