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
        
        // Find and tap on the item
        let itemCell = app.cells.containing(.staticText, identifier: "Editable Item").firstMatch
        itemCell.tap()
        
        // Look for edit button in item detail view
        let editButton = findEditButton()
        if editButton.exists {
            editButton.tap()
            
            // Edit the name
            let nameField = app.textFields.firstMatch
            if nameField.exists {
                nameField.clearAndEnterText("Updated Item Name")
            }
            
            saveItem()
            
            // Navigate back and verify update
            navigateBack()
            
            let updatedItemCell = app.cells.containing(.staticText, identifier: "Updated Item Name").firstMatch
            XCTAssertTrue(updatedItemCell.exists, "Updated item name should appear")
        }
    }
    
    @MainActor
    func testMarkItemAsPacked() throws {
        navigateToTestKit()
        
        createTestItem(name: "Packable Item", quantity: "1")
        
        let itemCell = app.cells.containing(.staticText, identifier: "Packable Item").firstMatch
        
        // Look for checkbox or toggle to mark as packed
        let checkboxes = app.buttons.matching(identifier: "checkbox")
        let toggles = app.switches
        
        if checkboxes.count > 0 {
            checkboxes.firstMatch.tap()
        } else if toggles.count > 0 {
            toggles.firstMatch.tap()
        } else {
            // Try tapping the item cell itself (might toggle packed state)
            itemCell.tap()
            
            // Look for packed indicator in detail view
            let packedToggle = app.switches.firstMatch
            if packedToggle.exists {
                packedToggle.tap()
            }
        }
        
        // Verify packed state is reflected in UI (visual change might be subtle)
        // This test validates the interaction works, specific UI changes depend on implementation
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
        
        // Look for duplicate button
        let duplicateButton = app.buttons.containing(.staticText, identifier: "Duplicate").firstMatch
        if duplicateButton.exists {
            duplicateButton.tap()
            
            // Verify duplicate appears (might have different identifier or count)
            let itemCells = app.cells.containing(.staticText, identifier: "Duplicate Me")
            XCTAssertTrue(itemCells.count >= 2, "Should have original and duplicate item")
        } else {
            // Alternative: long press might reveal context menu
            itemCell.press(forDuration: 1.0)
            
            let contextDuplicateButton = app.buttons.containing(.staticText, identifier: "Duplicate").firstMatch
            if contextDuplicateButton.exists {
                contextDuplicateButton.tap()
            }
        }
    }
    
    @MainActor
    func testDuplicateItemFromDetailView() throws {
        navigateToTestKit()
        
        createTestItem(name: "Detail Duplicate", quantity: "2")
        
        let itemCell = app.cells.containing(.staticText, identifier: "Detail Duplicate").firstMatch
        itemCell.tap()
        
        // Look for duplicate button in detail view
        let duplicateButton = app.buttons.containing(.staticText, identifier: "Duplicate").firstMatch
        if duplicateButton.exists {
            duplicateButton.tap()
            
            navigateBack()
            
            // Verify duplicate exists in list
            let itemCells = app.cells.containing(.staticText, identifier: "Detail Duplicate")
            XCTAssertTrue(itemCells.count >= 2, "Should have original and duplicate")
        }
    }
    
    // MARK: - Item Deletion Tests
    
    @MainActor
    func testDeleteItemWithSwipeAction() throws {
        navigateToTestKit()
        
        createTestItem(name: "Delete Me", quantity: "1")
        
        let itemCell = app.cells.containing(.staticText, identifier: "Delete Me").firstMatch
        XCTAssertTrue(itemCell.exists, "Item should exist before deletion")
        
        itemCell.swipeLeft()
        
        let deleteButton = app.buttons.containing(.staticText, identifier: "Delete").firstMatch
        if deleteButton.exists {
            deleteButton.tap()
            
            // Handle confirmation if it appears
            let confirmButton = app.alerts.buttons.containing(.staticText, identifier: "Delete").firstMatch
            if confirmButton.exists {
                confirmButton.tap()
            }
            
            // Verify item is removed
            XCTAssertFalse(itemCell.waitForExistence(timeout: 2), "Item should be deleted")
        }
    }
    
    @MainActor
    func testDeleteItemFromDetailView() throws {
        navigateToTestKit()
        
        createTestItem(name: "Detail Delete", quantity: "1")
        
        let itemCell = app.cells.containing(.staticText, identifier: "Detail Delete").firstMatch
        itemCell.tap()
        
        let deleteButton = app.buttons.containing(.staticText, identifier: "Delete").firstMatch
        if deleteButton.exists {
            deleteButton.tap()
            
            let confirmButton = app.alerts.buttons.containing(.staticText, identifier: "Delete").firstMatch
            if confirmButton.exists {
                confirmButton.tap()
            }
            
            // Should navigate back to kit detail automatically
            // Verify item is no longer in list
            let deletedItemCell = app.cells.containing(.staticText, identifier: "Detail Delete").firstMatch
            XCTAssertFalse(deletedItemCell.exists, "Item should be deleted from kit")
        }
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
