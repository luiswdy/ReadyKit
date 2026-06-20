//
//  ItemManagementUITests.swift
//  ReadyKitUITests
//
//  Created by GitHub Copilot on 2025/9/14.
//

import XCTest

/// UI tests specifically for Item management features within Emergency Kits
final class ItemManagementUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchForUITesting()

        // Navigate to Emergency Kits tab and create a test kit
        app.tabBars.buttons["Emergency Kits"].tap()
        createTestKit()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Item Creation Tests

    @MainActor
    func testAddBasicItemToKit() throws {
        navigateToTestKit()
        tapAddItemButton()

        let nameField = app.textFields[A11y.ItemForm.nameField]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Item name field should exist")
        nameField.tap()
        nameField.typeText("Emergency Water")

        let quantityField = app.textFields[A11y.ItemForm.quantityField]
        XCTAssertTrue(quantityField.exists, "Quantity field should exist")
        quantityField.tap()
        quantityField.typeText("12")

        saveItem()

        let itemCell = app.cells.containing(.staticText, identifier: "Emergency Water").firstMatch
        XCTAssertTrue(itemCell.waitForExistence(timeout: 3), "Item should appear in kit")
    }

    @MainActor
    func testAddItemWithExpirationDate() throws {
        navigateToTestKit()
        tapAddItemButton()

        let nameField = app.textFields[A11y.ItemForm.nameField]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Item name field should exist")
        nameField.tap()
        nameField.typeText("First Aid Kit")

        let quantityField = app.textFields[A11y.ItemForm.quantityField]
        XCTAssertTrue(quantityField.exists, "Quantity field should exist")
        quantityField.tap()
        quantityField.typeText("2")

        let expirationToggle = app.switches[A11y.ItemForm.hasExpirationToggle]
        XCTAssertTrue(expirationToggle.exists, "Expiration toggle should exist")
        if expirationToggle.value as? String == "0" {
            // The toggle is an accessibility-grouped row; the switch control sits at the
            // trailing edge, so tap there rather than the (label) center.
            expirationToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        }
        XCTAssertEqual(expirationToggle.value as? String, "1", "Expiration date should be enabled")

        saveItem()

        let itemCell = app.cells.containing(.staticText, identifier: "First Aid Kit").firstMatch
        XCTAssertTrue(itemCell.waitForExistence(timeout: 3), "Item with expiration should appear")
    }

    @MainActor
    func testAddMultipleItemsToKit() throws {
        navigateToTestKit()

        let items = [
            ("Flashlight", "2"),
            ("Batteries", "8"),
            ("Emergency Radio", "1"),
            ("Blanket", "3")
        ]

        for (itemName, quantity) in items {
            createTestItem(name: itemName, quantity: quantity)
        }
    }

    // MARK: - Item Editing Tests

    @MainActor
    func testEditItemDetails() throws {
        navigateToTestKit()
        createTestItem(name: "Editable Item", quantity: "1")

        let itemCell = app.cells.containing(.staticText, identifier: "Editable Item").firstMatch
        XCTAssertTrue(itemCell.exists, "Item should exist to edit")
        itemCell.tap()

        app.buttons[A11y.ItemDetail.moreButton].tap()
        app.buttons[A11y.ItemDetail.editButton].tap()

        let unitField = app.textFields[A11y.ItemDetail.unitField]
        XCTAssertTrue(unitField.waitForExistence(timeout: 3), "Unit field should exist in edit mode")
        unitField.clearAndEnterText("cans")

        let nameField = app.textFields[A11y.ItemDetail.nameField]
        nameField.clearAndEnterText("Updated Item Name")

        app.buttons[A11y.ItemDetail.saveButton].tap()
        navigateBack()

        let updatedItemCell = app.cells.containing(.staticText, identifier: "Updated Item Name").firstMatch
        XCTAssertTrue(updatedItemCell.waitForExistence(timeout: 3), "Updated item name should appear")
    }

    // MARK: - Item Duplication Tests

    @MainActor
    func testDuplicateItemWithSwipeAction() throws {
        navigateToTestKit()
        createTestItem(name: "Duplicate Me", quantity: "1")

        let itemCell = app.cells.containing(.staticText, identifier: "Duplicate Me").firstMatch
        XCTAssertTrue(itemCell.exists, "Item should exist before duplication")

        itemCell.swipeLeft()

        let copyButton = app.buttons[A11y.ItemList.copyAction]
        XCTAssertTrue(copyButton.waitForExistence(timeout: 2), "Copy action should appear after swipe")
        copyButton.tap()

        let itemCells = app.cells.containing(.staticText, identifier: "Duplicate Me")
        XCTAssertTrue(itemCells.count >= 2, "Should have original and duplicate item")
    }

    // MARK: - Item Deletion Tests

    @MainActor
    func testDeleteItemWithSwipeAction() throws {
        navigateToTestKit()
        createTestItem(name: "Delete Me", quantity: "1")

        let itemCell = app.cells.containing(.staticText, identifier: "Delete Me").firstMatch
        XCTAssertTrue(itemCell.exists, "Item should exist before deletion")

        itemCell.swipeLeft()

        let deleteButton = app.buttons[A11y.ItemList.deleteAction]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2), "Delete action should exist after swipe")
        deleteButton.tap()

        let confirmButton = app.alerts.buttons["Delete"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 2), "Confirmation dialog should appear")
        confirmButton.tap()

        XCTAssertFalse(itemCell.waitForExistence(timeout: 2), "Item should be deleted")
    }

    @MainActor
    func testDeleteItemFromDetailView() throws {
        navigateToTestKit()
        createTestItem(name: "Detail Delete", quantity: "1")

        let itemCell = app.cells.containing(.staticText, identifier: "Detail Delete").firstMatch
        itemCell.tap()

        app.buttons[A11y.ItemDetail.moreButton].tap()

        let deleteButton = app.buttons[A11y.ItemDetail.deleteButton]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3), "Delete option should appear in detail menu")
        deleteButton.tap()

        let confirmDeleteButton = app.alerts.buttons["Delete"].firstMatch
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 3), "Delete confirmation should appear")
        confirmDeleteButton.tap()

        let deletedItemCell = app.cells.containing(.staticText, identifier: "Detail Delete").firstMatch
        XCTAssertFalse(deletedItemCell.waitForExistence(timeout: 4), "Item should be deleted from kit")
    }

    // MARK: - Item Search and Filter Tests

    @MainActor
    func testSearchItemsInKit() throws {
        navigateToTestKit()

        let items = ["Water Bottles", "Energy Bars", "First Aid Kit", "Flashlight"]
        for item in items {
            createTestItem(name: item, quantity: "1")
        }

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist")
        searchField.tap()
        searchField.typeText("Water")

        let waterItem = app.cells.containing(.staticText, identifier: "Water Bottles").firstMatch
        XCTAssertTrue(waterItem.waitForExistence(timeout: 2), "Water Bottles should be visible in search results")

        let energyItem = app.cells.containing(.staticText, identifier: "Energy Bars").firstMatch
        XCTAssertFalse(energyItem.exists, "Energy Bars should not be visible in search results")
    }

    // MARK: - Helper Methods

    private func createTestKit() {
        app.buttons[A11y.KitList.addButton].tap()

        let nameField = app.textFields[A11y.KitForm.nameField]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Kit name field should exist")
        nameField.tap()
        nameField.typeText("Test Kit for Items")

        let locationField = app.textFields[A11y.KitForm.locationField]
        XCTAssertTrue(locationField.exists, "Kit location field should exist")
        locationField.tap()
        locationField.typeText("Test Location")

        app.buttons[A11y.KitForm.saveButton].tap()
    }

    private func navigateToTestKit() {
        let kitCell = app.cells.containing(.staticText, identifier: "Test Kit for Items").firstMatch
        XCTAssertTrue(kitCell.waitForExistence(timeout: 3), "Test kit should exist")
        kitCell.tap()
    }

    private func tapAddItemButton() {
        let addButton = app.buttons[A11y.ItemList.addButton]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3), "Add item button should exist")
        addButton.tap()
    }

    private func saveItem() {
        let saveButton = app.buttons[A11y.ItemForm.saveButton]
        XCTAssertTrue(saveButton.exists, "Save button should exist")
        saveButton.tap()
    }

    private func createTestItem(name: String, quantity: String) {
        tapAddItemButton()

        let nameField = app.textFields[A11y.ItemForm.nameField]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Item name field should exist")
        nameField.tap()
        nameField.typeText(name)

        let quantityField = app.textFields[A11y.ItemForm.quantityField]
        XCTAssertTrue(quantityField.exists, "Quantity field should exist")
        quantityField.tap()
        quantityField.typeText(quantity)

        saveItem()

        let itemCell = app.cells.containing(.staticText, identifier: name).firstMatch
        XCTAssertTrue(itemCell.waitForExistence(timeout: 3), "\(name) should be created")
    }

    private func navigateBack() {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.exists, "Back button should exist")
        backButton.tap()
    }
}
