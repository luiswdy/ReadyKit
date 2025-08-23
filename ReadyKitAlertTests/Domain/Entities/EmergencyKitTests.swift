//
//  EmergencyKitTests.swift
//  ReadyKitTests
//
//  Created by Claude on 8/22/25.
//

import Testing
import Foundation
@testable import ReadyKit

struct EmergencyKitTests {

    // MARK: - Initialization Tests

    @Test("EmergencyKit initialization with valid parameters succeeds")
    func testValidInitialization() throws {
        let id = UUID()
        let name = "Test Emergency Kit"
        let location = "Living Room"
        let items = [try TestDataFactory.createValidItem()]
        let photo = Data([0x01, 0x02, 0x03])

        let emergencyKit = try EmergencyKit(
            id: id,
            name: name,
            items: items,
            photo: photo,
            location: location
        )

        #expect(emergencyKit.id == id)
        #expect(emergencyKit.name == name)
        #expect(emergencyKit.location == location)
        #expect(emergencyKit.items.count == 1)
        #expect(emergencyKit.photo == photo)
    }

    @Test("EmergencyKit initialization with empty name throws EmergencyKitValidationError.emptyName")
    func testInitializationWithEmptyName() {
        #expect(throws: EmergencyKitValidationError.emptyName("")) {
            _ = try EmergencyKit(name: "", location: "Living Room")
        }
    }

    @Test("EmergencyKit initialization with whitespace-only name throws EmergencyKitValidationError.emptyName")
    func testInitializationWithWhitespaceOnlyName() {
        let invalidNames = TestConstants.Validation.invalidNames

        for invalidName in invalidNames {
            #expect(throws: EmergencyKitValidationError.emptyName(invalidName), "Name '\(invalidName)' should throw emptyName error") {
                _ = try EmergencyKit(name: invalidName, location: "Living Room")
            }
        }
    }

    @Test("EmergencyKit initialization with empty location throws EmergencyKitValidationError.emptyLocation")
    func testInitializationWithEmptyLocation() {
        #expect(throws: EmergencyKitValidationError.emptyLocation("")) {
            _ = try EmergencyKit(name: "Valid Name", location: "")
        }
    }

    @Test("EmergencyKit initialization with whitespace-only location throws EmergencyKitValidationError.emptyLocation")
    func testInitializationWithWhitespaceOnlyLocation() {
        let invalidLocations = TestConstants.Validation.invalidLocations

        for invalidLocation in invalidLocations {
            #expect(throws: EmergencyKitValidationError.emptyLocation(invalidLocation), "Location '\(invalidLocation)' should throw emptyLocation error") {
                _ = try EmergencyKit(name: "Valid Name", location: invalidLocation)
            }
        }
    }

    @Test("EmergencyKit initialization with duplicate item IDs throws EmergencyKitValidationError.duplicateItems")
    func testInitializationWithDuplicateItemIds() throws {
        let itemId = UUID()
        let item1 = try Item(id: itemId, name: "Item 1", quantityValue: 1, quantityUnitName: "piece")
        let item2 = try Item(id: itemId, name: "Item 2", quantityValue: 2, quantityUnitName: "piece")

        #expect(throws: EmergencyKitValidationError.duplicateItems([item1, item2])) {
            _ = try EmergencyKit(name: "Test Kit", items: [item1, item2], location: "Test Location")
        }
    }

    @Test("EmergencyKit initialization with unique item IDs succeeds")
    func testInitializationWithUniqueItemIds() throws {
        let item1 = try TestDataFactory.createValidItem(name: "Item 1")
        let item2 = try TestDataFactory.createValidItem(name: "Item 2")

        let emergencyKit = try EmergencyKit(
            name: "Test Kit",
            items: [item1, item2],
            location: "Test Location"
        )

        #expect(emergencyKit.items.count == 2)
        #expect(emergencyKit.items[0].name == "Item 1")
        #expect(emergencyKit.items[1].name == "Item 2")
    }

    // MARK: - Default Values Tests

    @Test("EmergencyKit initialization with minimal parameters uses default values")
    func testDefaultValues() throws {
        let emergencyKit = try EmergencyKit(name: "Test Kit", location: "Test Location")

        #expect(emergencyKit.items.isEmpty)
        #expect(emergencyKit.photo == nil)
        #expect(!emergencyKit.name.isEmpty)
        #expect(!emergencyKit.location.isEmpty)
    }

    // MARK: - Property Mutation Tests

    @Test("EmergencyKit properties can be mutated after initialization")
    func testPropertyMutation() throws {
        var emergencyKit = try EmergencyKit(name: "Original Name", location: "Original Location")
        let newItem = try TestDataFactory.createValidItem()
        let newPhoto = Data([0x04, 0x05, 0x06])

        emergencyKit.name = "Updated Name"
        emergencyKit.location = "Updated Location"
        emergencyKit.items = [newItem]
        emergencyKit.photo = newPhoto

        #expect(emergencyKit.name == "Updated Name")
        #expect(emergencyKit.location == "Updated Location")
        #expect(emergencyKit.items.count == 1)
        #expect(emergencyKit.items[0].id == newItem.id)
        #expect(emergencyKit.photo == newPhoto)
    }

    // MARK: - Edge Cases Tests

    @Test("EmergencyKit can be initialized with maximum realistic number of items")
    func testLargeNumberOfItems() throws {
        let itemCount = 100
        let items = try (0..<itemCount).map { index in
            try TestDataFactory.createValidItem(name: "Item \(index)")
        }

        let emergencyKit = try EmergencyKit(
            name: "Large Kit",
            items: items,
            location: "Storage Room"
        )

        #expect(emergencyKit.items.count == itemCount)
    }

    @Test("EmergencyKit can handle very long names and locations")
    func testLongStrings() throws {
        let longName = String(repeating: "A", count: 1000)
        let longLocation = String(repeating: "B", count: 1000)

        let emergencyKit = try EmergencyKit(name: longName, location: longLocation)

        #expect(emergencyKit.name == longName)
        #expect(emergencyKit.location == longLocation)
    }

    @Test("EmergencyKit can handle Unicode characters in name and location")
    func testUnicodeCharacters() throws {
        let unicodeName = "🚨 Emergency Kit 紧急工具包 👨‍⚕️"
        let unicodeLocation = "🏠 Living Room 客厅 📍"

        let emergencyKit = try EmergencyKit(name: unicodeName, location: unicodeLocation)

        #expect(emergencyKit.name == unicodeName)
        #expect(emergencyKit.location == unicodeLocation)
    }

    // MARK: - ID Uniqueness Tests

    @Test("EmergencyKit generates unique IDs by default")
    func testUniqueIdGeneration() throws {
        let kit1 = try EmergencyKit(name: "Kit 1", location: "Location 1")
        let kit2 = try EmergencyKit(name: "Kit 2", location: "Location 2")

        #expect(kit1.id != kit2.id)
    }

    @Test("EmergencyKit accepts custom ID")
    func testCustomId() throws {
        let customId = UUID()
        let emergencyKit = try EmergencyKit(id: customId, name: "Custom ID Kit", location: "Test Location")

        #expect(emergencyKit.id == customId)
    }
}

// MARK: - EmergencyKitError Tests

struct EmergencyKitErrorTests {

    @Test("EmergencyKitValidationError.emptyName contains provided name")
    func testEmptyNameError() {
        let providedName = "   "
        let error = EmergencyKitValidationError.emptyName(providedName)

        switch error {
        case .emptyName(let name):
            #expect(name == providedName)
        default:
            Issue.record("Expected emptyName error")
        }
    }

    @Test("EmergencyKitValidationError.emptyLocation contains provided location")
    func testEmptyLocationError() {
        let providedLocation = ""
        let error = EmergencyKitValidationError.emptyLocation(providedLocation)

        switch error {
        case .emptyLocation(let location):
            #expect(location == providedLocation)
        default:
            Issue.record("Expected emptyLocation error")
        }
    }

    @Test("EmergencyKitError.noSuchEmergencyKit contains provided ID")
    func testNoSuchEmergencyKitError() {
        let providedId = UUID()
        let error = EmergencyKitError.noSuchEmergencyKit(providedId)

        switch error {
        case .noSuchEmergencyKit(let id):
            #expect(id == providedId)
        default:
            Issue.record("Expected noSuchEmergencyKit error")
        }
    }

    @Test("EmergencyKitError.nilEmergencyKitId is properly defined")
    func testNilEmergencyKitIdError() {
        let error = EmergencyKitError.nilEmergencyKitId

        switch error {
        case .nilEmergencyKitId:
            // Test passes
            break
        default:
            Issue.record("Expected nilEmergencyKitId error")
        }
    }
}
