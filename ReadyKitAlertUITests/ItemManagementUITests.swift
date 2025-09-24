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
        app.launchArguments = ["--uitesting", "--reset"]
        app.launch()

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

        // Fill basic item information
        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.exists, "Item name field should exist")
        nameField.tap()
        nameField.typeText("Emergency Water")

        // Try to fill quantity if field exists
        let quantityField = app.textFields.element(boundBy: 1)
        if quantityField.exists {
            quantityField.tap()
            quantityField.typeText("12")
        }

        saveItem()

        // Verify item appears in kit
        let itemCell = app.cells.containing(.staticText, identifier: "Emergency Water").firstMatch
        XCTAssertTrue(itemCell.waitForExistence(timeout: 3), "Item should appear in kit")
    }

    @MainActor
    func testAddItemWithExpirationDate() throws {
        navigateToTestKit()

        tapAddItemButton()

        // Fill item name
        let nameField = app.textFields.firstMatch
        nameField.tap()
        nameField.typeText("First Aid Kit")

        // Fill quantity to 2
        let quantityField = app.textFields.element(boundBy: 1)
        if quantityField.exists {
            quantityField.tap()
            quantityField.typeText("2")
        }

        // Toggle "Has Expiration Date" to enable date picker
        let expirationToggle = app.switches["Has Expiration Date"]
        if expirationToggle.exists && expirationToggle.isHittable && expirationToggle.value as? String
            == "0" {
            expirationToggle.tap()
        }

        // Set expiration date to 30 days from now
        let datePickers = app.datePickers
        if datePickers.count > 0 {
            let datePicker = datePickers.firstMatch
            let targetDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let dateString = formatter.string(from: targetDate)
            datePicker.adjust(toPickerWheelValue: dateString)
        }
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
            tapAddItemButton()

            let nameField = app.textFields.firstMatch
            nameField.tap()
            nameField.typeText(itemName)

            let quantityField = app.textFields.element(boundBy: 1)
            if quantityField.exists {
                quantityField.tap()
                quantityField.typeText(quantity)
            }

            saveItem()

            // Verify each item appears
            let itemCell = app.cells.containing(.staticText, identifier: itemName).firstMatch
            XCTAssertTrue(itemCell.waitForExistence(timeout: 3), "\(itemName) should appear in kit")
        }
    }

    // MARK: - Item Editing Tests

    @MainActor
    func testEditItemDetails() throws {
        navigateToTestKit()

        // Create an item first
        createTestItem(name: "Editable Item", quantity: "1")

        // Click on the item to open detail view
        let itemCell = app.cells.containing(.staticText, identifier: "Editable Item").firstMatch
        XCTAssertTrue(itemCell.exists, "Item should exist to edit")
        itemCell.tap()

        // Look for Edit button
        app/*@START_MENU_TOKEN@*/.images["ellipsis.circle"]/*[[".buttons",".images",".images[\"More\"]",".images[\"ellipsis.circle\"]"],[[[-1,3],[-1,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.buttons["Edit"]/*[[".cells.buttons[\"Edit\"]",".buttons[\"Edit\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()

        let unitTextField = app/*@START_MENU_TOKEN@*/.textFields["Unit"]/*[[".otherElements",".textFields[\"cans\"]",".textFields[\"Unit\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.firstMatch
        unitTextField.tap()
        unitTextField.typeKey(.delete, modifierFlags:[])
        unitTextField.clearAndEnterText("cans")
        let itemNameTextField = app.textFields["Editable Item"].firstMatch
        itemNameTextField.clearAndEnterText("Updated Item Name")
        saveItem()
        navigateBack()

        let updatedItemCell = app.cells.containing(.staticText, identifier: "Updated Item Name").firstMatch
        XCTAssertTrue(updatedItemCell.exists, "Updated item name should appear")
    }

    // MARK: - Item Duplication Tests

    @MainActor
    func testDuplicateItemWithSwipeAction() throws {
        navigateToTestKit()

        createTestItem(name: "Duplicate Me", quantity: "1")

        let itemCell = app.cells.containing(.staticText, identifier: "Duplicate Me").firstMatch
        XCTAssertTrue(itemCell.exists, "Item should exist before duplication")

        // Swipe left to reveal actions
        itemCell.swipeLeft()

        // prefer the button inside the cell, fall back to app-level lookup
        let copyButton = app.buttons["Copy"].firstMatch

        if copyButton.waitForExistence(timeout: 2), copyButton.isHittable {
            copyButton.tap()

            let itemCells = app.cells.containing(.staticText, identifier: "Duplicate Me")
            XCTAssertTrue(itemCells.count >= 2, "Should have original and duplicate item")
            return
        }
        XCTFail("Duplicate button not found after swipe")
    }

    // MARK: - Item Deletion Tests

    @MainActor
    func testDeleteItemWithSwipeAction() throws {
        navigateToTestKit()

        createTestItem(name: "Delete Me", quantity: "1")

        let itemCell = app.cells.containing(.staticText, identifier: "Delete Me").firstMatch
        XCTAssertTrue(itemCell.exists, "Item should exist before deletion")

        itemCell.swipeLeft()

        let deleteButton = app.buttons["Delete"].firstMatch
        // wait for delete button to appear
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2), "Delete button should exist after swipe")
        deleteButton.tap()

        // Handle confirmation if it appears
        let confirmButton = app.alerts.buttons["Delete"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 2), "Confirmation dialog should appear")
        confirmButton.tap()

        // Verify item is removed
        XCTAssertFalse(itemCell.waitForExistence(timeout: 2), "Item should be deleted")
    }

    @MainActor
    func testDeleteItemFromDetailView() throws {
        navigateToTestKit()

        createTestItem(name: "Detail Delete", quantity: "1")

        let itemCell = app.cells.containing(.staticText, identifier: "Detail Delete").firstMatch
        itemCell.tap()

        // Open the detail "more" menu (uses same approach as testEditItemDetails)
        let moreButtonCandidates = [
            app.images["ellipsis.circle"].firstMatch,
            app.buttons["More"].firstMatch,
            app.navigationBars.buttons["More"].firstMatch
        ]
        let moreButton = moreButtonCandidates.first { $0.exists } ?? moreButtonCandidates[0]
        if moreButton.exists {
            // wait and tap
            XCTAssertTrue(moreButton.waitForExistence(timeout: 2), "More button should exist")
            if moreButton.isHittable {
                moreButton.tap()
            } else {
                moreButton.tap() // try tap anyway; XCTest will attempt
            }
        }

        // Look for Delete option in the presented menu
        let deleteOptionCandidates = [
            app.buttons["Delete"].firstMatch,
            app.buttons.containing(.staticText, identifier: "Delete").firstMatch,
            app.staticTexts["Delete"].firstMatch
        ]
        let deleteOption = deleteOptionCandidates.first { $0.exists } ?? deleteOptionCandidates[0]
        if deleteOption.waitForExistence(timeout: 3) {
            // ensure hittable then tap
            if deleteOption.isHittable {
                deleteOption.tap()
            } else {
                // fallback to coordinate tap
                let coord = deleteOption.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                coord.tap()
            }
        } else {
            XCTFail("Delete option not found in detail view menu")
            return
        }

        // Handle confirmation alert if present
        let confirmDeleteButton = app.alerts.buttons["Delete"].firstMatch
        if confirmDeleteButton.waitForExistence(timeout: 3) {
            confirmDeleteButton.tap()
        }

        // Verify item is no longer present in the kit list
        // Wait a bit for navigation/refresh
        let deletedItemCell = app.cells.containing(.staticText, identifier: "Detail Delete").firstMatch
        XCTAssertFalse(deletedItemCell.waitForExistence(timeout: 4), "Item should be deleted from kit")
    }

    // MARK: - Item Search and Filter Tests

    @MainActor
    func testSearchItemsInKit() throws {
        navigateToTestKit()

        // Create multiple items for searching
        let items = ["Water Bottles", "Energy Bars", "First Aid Kit", "Flashlight"]
        for item in items {
            createTestItem(name: item, quantity: "1")
        }

        // Look for search field
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            searchField.typeText("Water")

            // Verify filtered results
            let waterItem = app.cells.containing(.staticText, identifier: "Water Bottles").firstMatch
            XCTAssertTrue(waterItem.exists, "Water Bottles should be visible in search results")

            let energyItem = app.cells.containing(.staticText, identifier: "Energy Bars").firstMatch
            // Energy Bars might be hidden depending on search implementation
            XCTAssertFalse(energyItem.exists, "Energy Bars should not be visible in search results")
        }
    }

    // MARK: - Helper Methods

    private func createTestKit() {
        let addButton = app.buttons.matching(identifier: "add").firstMatch
        if addButton.exists {
            addButton.tap()
        } else {
            let createButton = app.buttons.containing(.staticText, identifier: "Create").firstMatch
            if createButton.exists {
                createButton.tap()
            } else {
                let navAddButton = app.navigationBars.buttons["Add"].firstMatch
                if navAddButton.exists {
                    navAddButton.tap()
                }
            }
        }

        let nameField = app.textFields.matching(identifier: "Emergency Kit Name").firstMatch
        if nameField.exists {
            nameField.tap()
            nameField.typeText("Test Kit for Items")
        }

        // fill-up next field "location", which is a required field to enable save button
        let locationField = app.textFields.matching(identifier: "Location").firstMatch
        if locationField.exists {
            locationField.tap()
            locationField.typeText("Test Location")
        }

        let saveButton = app.buttons["Save"]
        if saveButton.exists {
            saveButton.tap()
        } else {
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
            }
        }

    }

    private func navigateToTestKit() {
        let kitCell = app.cells.containing(.staticText, identifier: "Test Kit for Items").firstMatch
        if kitCell.exists {
            kitCell.tap()
        }
    }

    private func tapAddItemButton() {
        let addItemButtons = [
            app.buttons.matching(identifier: "add").firstMatch,
            app.buttons.containing(.staticText, identifier: "Add Item").firstMatch,
            app.navigationBars.buttons["Add"].firstMatch
        ]

        for button in addItemButtons {
            if button.exists {
                button.tap()
                return
            }
        }

        XCTFail("No add item button found")
    }

    private func saveItem() {
        let saveButtons = [
            app.buttons["Save"],
            app.buttons["Done"],
            app.buttons["Add"]
        ]

        for button in saveButtons {
            if button.exists {
                print("HERE!")
                button.tap()
                return
            }
        }

        XCTFail("No save button found")
    }

    private func createTestItem(name: String, quantity: String) {
        tapAddItemButton()

        let nameField = app.textFields.firstMatch
        nameField.tap()
        nameField.typeText(name)

        let quantityField = app.textFields.element(boundBy: 1)
        if quantityField.exists {
            quantityField.tap()
            quantityField.typeText(quantity)
        }

        saveItem()

        let itemCell = app.cells.containing(.staticText, identifier: name).firstMatch
        XCTAssertTrue(itemCell.waitForExistence(timeout: 3), "\(name) should be created")
    }

    private func findEditButton() -> XCUIElement {
        let editButtons = [
            app.buttons.containing(.staticText, identifier: "Edit").firstMatch,
            app.navigationBars.buttons["Edit"].firstMatch,
            app.buttons.matching(identifier: "edit").firstMatch
        ]

        return editButtons.first { $0.exists } ?? editButtons[0]
    }

    private func navigateBack() {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists {
            backButton.tap()
        } else {
            app.swipeRight()
        }
    }
}
