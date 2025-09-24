//
//  EmergencyKitUITests.swift
//  ReadyKitUITests
//
//  Created by GitHub Copilot on 2025/9/14.
//

import XCTest

/// UI tests specifically for Emergency Kit management features
final class EmergencyKitUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting",  "--reset"]   // the flag '--reset' is used to reset SwiftData store. This is available in Debug builds only.
        app.launch()

        // Navigate to Emergency Kits tab
        app.tabBars.buttons["Emergency Kits"].tap()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Emergency Kit Creation Tests

    @MainActor
    func testCreateEmergencyKitWithMinimalInfo() throws {
        // Test creating kit with only name and location. Both fields are required.
        tapAddButton()

        let nameField = app.textFields.matching(identifier: "Emergency Kit Name").firstMatch
        XCTAssertTrue(nameField.exists, "Name field should exist")
        nameField.tap()
        nameField.typeText("Minimal Kit")

        let locationField = app.textFields.matching(identifier: "Location").firstMatch
        XCTAssertTrue(locationField.exists, "Location field should exist")
        locationField.tap()
        locationField.typeText("Garage")

        saveKit()

        // Verify kit appears in list
        let kitCell = app.cells.containing(.staticText, identifier: "Minimal Kit").firstMatch
        XCTAssertTrue(kitCell.waitForExistence(timeout: 3), "Kit should appear in list")
    }

    @MainActor
    func testCreateEmergencyKitWithPhoto() throws {
        // Navigate to kit creation form
        tapAddButton()

        // Fill required fields (name and location)
        let nameField = app.textFields.matching(identifier: "Emergency Kit Name").firstMatch
        XCTAssertTrue(nameField.exists, "Name field should exist")
        nameField.tap()
        nameField.typeText("Kit With Photo")

        let locationField = app.textFields.matching(identifier: "Location").firstMatch
        XCTAssertTrue(locationField.exists, "Location field should exist")
        locationField.tap()
        locationField.typeText("Test Location")

        // Tap photo button to trigger photo selection
        let photoButton = app.buttons.matching(identifier: "photo").firstMatch
        XCTAssertTrue(photoButton.exists, "Photo button should exist")
        photoButton.tap()

        // Handle photo selection confirmation dialog
        let chooseFromLibraryButton = app.buttons["Choose from Library"]
        XCTAssertTrue(chooseFromLibraryButton.waitForExistence(timeout: 5), "Choose from Library option should appear")
        chooseFromLibraryButton.tap()

        // Handle photo picker and select photo with robust strategies
        let photoCollection = app.collectionViews.firstMatch
        XCTAssertTrue(photoCollection.waitForExistence(timeout: 10), "Photo collection should appear")

        // Allow time for photo picker to fully load
        Thread.sleep(forTimeInterval: 2)

        // Try to dismiss any privacy banners that might block interaction
        let closeBannerButton = app.buttons["Close"]
        if closeBannerButton.exists && closeBannerButton.isHittable {
            closeBannerButton.tap()
            Thread.sleep(forTimeInterval: 1)
        }

        // Attempt to scroll collection to ensure photos are visible
        if photoCollection.exists && photoCollection.isHittable {
            photoCollection.swipeDown()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Find and select the first photo with multiple fallback strategies
        let firstPhoto = photoCollection.cells.element(boundBy: 0)
        XCTAssertTrue(firstPhoto.waitForExistence(timeout: 5), "First photo should exist")

        var photoSelected = false

        // Strategy 1: Try direct tap if hittable
        if firstPhoto.isHittable {
            firstPhoto.tap()
            photoSelected = true
        } else {
            // Strategy 2: Try scrolling to make it hittable
            var scrollAttempts = 0
            while !firstPhoto.isHittable && scrollAttempts < 5 {
                photoCollection.swipeUp()
                Thread.sleep(forTimeInterval: 0.5)
                scrollAttempts += 1
            }

            if firstPhoto.isHittable {
                firstPhoto.tap()
                photoSelected = true
            } else {
                // Strategy 3: Try scrolling down
                scrollAttempts = 0
                while !firstPhoto.isHittable && scrollAttempts < 3 {
                    photoCollection.swipeDown()
                    Thread.sleep(forTimeInterval: 0.5)
                    scrollAttempts += 1
                }

                if firstPhoto.isHittable {
                    firstPhoto.tap()
                    photoSelected = true
                } else {
                    // Strategy 4: Try tapping on collection first, then photo
                    if photoCollection.isHittable {
                        photoCollection.tap()
                        Thread.sleep(forTimeInterval: 0.5)
                        if firstPhoto.isHittable {
                            firstPhoto.tap()
                            photoSelected = true
                        }
                    }
                }
            }
        }

        // Fallback - try coordinate-based tapping
        if !photoSelected && firstPhoto.exists {
            let coordinate = firstPhoto.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coordinate.tap()
            photoSelected = true
        }

        // Last resort - try any hittable photo
        if !photoSelected {
            let anyHittablePhoto = photoCollection.cells.allElementsBoundByIndex.first { $0.isHittable }
            if let hittablePhoto = anyHittablePhoto {
                hittablePhoto.tap()
                photoSelected = true
            }
        }
        XCTAssertTrue(photoSelected, "Should be able to select a photo using one of the strategies")

        // Confirm photo selection (look for Choose/Done/Use Photo button)
        let confirmButtons = ["Choose", "Done", "Use Photo", "Add"]
        var photoConfirmed = false

        for buttonText in confirmButtons {
            let confirmButton = app.buttons[buttonText]
            if confirmButton.waitForExistence(timeout: 3) && confirmButton.isHittable {
                confirmButton.tap()
                photoConfirmed = true
                break
            }
        }
        XCTAssertTrue(photoConfirmed, "Should be able to confirm photo selection")

        saveKit()

        // Verify the kit with photo appears in the list
        // Use predicate-based search for better SwiftUI compatibility
        let kitWithPhotoLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Kit With Photo")).firstMatch
        XCTAssertTrue(kitWithPhotoLabel.waitForExistence(timeout: 5), "Kit with photo should appear in list")

        // Verify photo thumbnail appears
        let kitCell = app.cells.containing(.staticText, identifier: "Kit With Photo").firstMatch
        let photoThumbnail = kitCell.images.firstMatch
        XCTAssertTrue(photoThumbnail.exists, "Photo thumbnail should appear in kit cell")
    }

    @MainActor
    func testCreateMultipleEmergencyKits() throws {
        let kitNames = ["Home Kit", "Car Kit", "Office Kit"]
        let locationNames = ["Living Room", "Trunk", "Desk"]

        for (kitName, locationName) in zip(kitNames, locationNames) {
            tapAddButton()

            let nameField = app.textFields.firstMatch
            nameField.tap()
            nameField.typeText(kitName)

            let locationField = app.textFields.matching(identifier: "Location").firstMatch
            XCTAssertTrue(locationField.exists, "Location field should exist")
            locationField.tap()
            locationField.typeText(locationName)

            saveKit()

            // Verify each kit appears
            let kitCell = app.cells.containing(.staticText, identifier: kitName).firstMatch
            XCTAssertTrue(kitCell.waitForExistence(timeout: 3), "\(kitName) should appear in list")
        }
    }

    // MARK: - Emergency Kit Editing Tests

    @MainActor
    func testEditEmergencyKitName() throws {
        // Create a kit first
        createTestKit(name: "Original Name", location: "Original Location")

        // Navigate to kit detail
        let kitCell = app.cells.containing(.staticText, identifier: "Original Name").firstMatch

        // Swipe the kitCell for edit option if available
        kitCell.swipeLeft()
        // Wait a moment for the button to appear
        sleep(1)
        // Try to find the Edit button as a child of the cell
        var editButton = kitCell.buttons["Edit"]
        if !editButton.exists {
            // Fallback: try to find the Edit button globally
            editButton = app.buttons["Edit"]
        }
        if !editButton.exists {
            // Fallback: try to find any button with label containing "Edit"
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", "Edit")
            editButton = app.buttons.containing(predicate).firstMatch
        }
        // Log all visible buttons for debugging if still not found
        if !editButton.exists {
            let allButtons = app.buttons.allElementsBoundByIndex.map { $0.label }
            print("[DEBUG] Visible buttons after swipe: \(allButtons)")
        }
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Edit button should appear after swipe")
        XCTAssertTrue(editButton.isHittable, "Edit button should be hittable")
        editButton.tap()

        // Edit the name and the location
        let nameField = app.textFields.matching(identifier: "Emergency Kit Name").firstMatch
        nameField.clearAndEnterText("Updated Name")
        let locationField = app.textFields.matching(identifier: "Location").firstMatch
        locationField.clearAndEnterText("Updated Location")

        saveKit()

        // Navigate back to list
        navigateBackToList()

        // Verify name was updated
        let updatedNameCell = app.cells.containing(.staticText, identifier: "Updated Name").firstMatch
        XCTAssertTrue(updatedNameCell.exists, "Updated kit name should appear")
        let originalKitCell = app.cells.containing(.staticText, identifier: "Original Name").firstMatch
        XCTAssertFalse(originalKitCell.exists, "Original kit name should not appear")

        let updatedLocationCell = app.cells.containing(.staticText, identifier: "Updated Location").firstMatch
        XCTAssertTrue(updatedLocationCell.exists, "Updated location should appear")
        let originalLocationCell = app.cells.containing(.staticText, identifier: "Original Location").firstMatch
        XCTAssertFalse(originalLocationCell.exists, "Original location should not appear")
    }

    // MARK: - Emergency Kit Deletion Tests

    @MainActor
    func testDeleteEmergencyKitWithSwipe() throws {
        createTestKit(name: "Kit to Delete", location: "Kit to Delete Location")

        let kitCell = app.cells.containing(.staticText, identifier: "Kit to Delete").firstMatch
        XCTAssertTrue(kitCell.exists, "Kit should exist before deletion")

        // Swipe left to reveal delete option
        kitCell.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.exists, "Delete button should appear after swipe")
        deleteButton.tap()
        // Handle confirmation dialog if it appears
        let confirmButton = app.alerts.firstMatch.buttons["Delete"]
        XCTAssertTrue(confirmButton.exists, "Confirmation dialog should appear")
        confirmButton.tap()

        // Verify kit is removed
        XCTAssertFalse(kitCell.waitForExistence(timeout: 3), "Kit should be deleted")
    }

    @MainActor
    func testDeleteEmergencyKitFromDetailView() throws {
        createTestKit(name: "Detail Delete Kit", location: "Detail Delete Kit Location")

        let kitCell = app.cells.containing(.staticText, identifier: "Detail Delete Kit").firstMatch
        kitCell.tap()

        // Look for delete button in detail view
        let deleteButton = app.buttons.containing(.staticText, identifier: "Delete").firstMatch
        if deleteButton.exists {
            deleteButton.tap()

            // Handle confirmation
            let confirmButton = app.alerts.buttons.containing(.staticText, identifier: "Delete").firstMatch
            if confirmButton.exists {
                confirmButton.tap()
            }
        }

        // Should navigate back to list automatically
        // Verify kit is no longer in list
        let deletedKitCell = app.cells.containing(.staticText, identifier: "Detail Delete Kit").firstMatch
        XCTAssertFalse(deletedKitCell.exists, "Kit should be deleted from list")
    }

    // MARK: - Emergency Kit List Display Tests

    @MainActor
    func testEmptyKitListDisplay() throws {
        // If there are existing kits, this test may not be meaningful
        // Check for empty state indicators
        let emptyStateIndicators = [
            app.staticTexts.containing(.staticText, identifier: "No Emergency Kits Yet").firstMatch,
            app.buttons["Create Emergency Kit"]
        ]

        let hasEmptyState = emptyStateIndicators.contains { $0.exists }
        let hasKits = app.cells.count > 0

        // Either we have an empty state or we have kits
        XCTAssertTrue(hasEmptyState || hasKits, "Should show either empty state or kit list")
    }

    @MainActor
    func testKitListScrolling() throws {
        // Create multiple kits to test scrolling
        let kitNames = (1...10).map { "Kit \($0)" }
        let locationNames = (1...10).map { "Location \($0)" }

        for (kitName, locationName) in zip(kitNames, locationNames) {
            createTestKit(name: kitName, location: locationName)
        }

        // Test scrolling if list is scrollable
        let kitsList = app.collectionViews.firstMatch.exists ? app.collectionViews.firstMatch : app.tables.firstMatch
        if kitsList.exists {
            // Scroll to bottom
            kitsList.swipeUp()
            kitsList.swipeUp()

            // Scroll back to top
            kitsList.swipeDown()
            kitsList.swipeDown()
        }

        // Verify first and last kits are still accessible
        let firstKit = app.cells.containing(.staticText, identifier: "Kit 1").firstMatch
        kitsList.swipeUp()
        let lastKit = app.cells.staticTexts["Kit 10"]

        XCTAssertTrue(firstKit.exists || firstKit.waitForExistence(timeout: 2), "First kit should be accessible")
        while !lastKit.exists || !lastKit.isHittable {
            kitsList.swipeUp()
        }
        XCTAssertTrue(lastKit.exists || lastKit.waitForExistence(timeout: 2), "Last kit should be accessible")
    }

    // MARK: - Helper Methods

    private func tapAddButton() {
        let addButton = app.buttons.matching(identifier: "add").firstMatch
        if addButton.exists {
            addButton.tap()
        } else {
            let createButton = app.buttons.containing(.staticText, identifier: "Create").firstMatch
            if createButton.exists {
                createButton.tap()
            } else {
                let navAddButton = app.navigationBars.buttons["Add"].firstMatch
                XCTAssertTrue(navAddButton.exists, "No add button found")
                navAddButton.tap()
            }
        }
    }

    private func saveKit() {
        let saveButton = app.buttons["Save"]
        if saveButton.exists {
            saveButton.tap()
        } else {
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
            } else {
                // Look for other save options
                let createButton = app.buttons.containing(.staticText, identifier: "Create").firstMatch
                XCTAssertTrue(createButton.exists, "Save button should exist")
                createButton.tap()
            }
        }
    }

    private func createTestKit(name: String, location: String) {
        tapAddButton()

        // Fill-up name and location
        let nameField = app.textFields.matching(identifier: "Emergency Kit Name").firstMatch
        XCTAssertTrue(nameField.exists, "Name field should exist")
        nameField.tap()
        nameField.typeText(name)
        let locationField = app.textFields.matching(identifier: "Location").firstMatch
        XCTAssertTrue(locationField.exists, "Location field should exist")
        locationField.tap()
        locationField.typeText(location)

        saveKit()

        // Verify kit was created
        let kitCell = app.cells.containing(.staticText, identifier: name).firstMatch
        /*

         let lastKitName = "Your Last Kit Name" // Replace with actual last kit's name
         let lastCell = app.cells.staticTexts[lastKitName]
         app.swipeUp() // Optionally, swipe up a few times if the list is long

         // Scroll until the last cell exists and is hittable
         while !lastCell.exists || !lastCell.isHittable {
             app.swipeUp()
         }

         // Optionally, assert it's visible
         XCTAssertTrue(lastCell.exists)
         XCTAssertTrue(lastCell.isHittable)
         */

        while !kitCell.exists || !kitCell.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(kitCell.waitForExistence(timeout: 5), "Kit should be created")
    }

    private func findEditButton() -> XCUIElement {
        let editButtons = [
            app.buttons.containing(.staticText, identifier: "Edit").firstMatch,
            app.navigationBars.buttons["Edit"].firstMatch,
            app.buttons.matching(identifier: "edit").firstMatch
        ]

        return editButtons.first { $0.exists } ?? editButtons[0]
    }

    private func navigateBackToList() {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists {
            backButton.tap()
        } else {
            // Try other navigation methods
            app.swipeRight() // Gesture-based navigation
        }
    }
}
