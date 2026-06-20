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
        app.launchForUITesting()

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

        let nameField = app.textFields[A11y.KitForm.nameField]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Name field should exist")
        nameField.tap()
        nameField.typeText("Minimal Kit")

        let locationField = app.textFields[A11y.KitForm.locationField]
        XCTAssertTrue(locationField.exists, "Location field should exist")
        locationField.tap()
        locationField.typeText("Garage")

        saveKit()

        let kitCell = app.cells.containing(.staticText, identifier: "Minimal Kit").firstMatch
        XCTAssertTrue(kitCell.waitForExistence(timeout: 3), "Kit should appear in list")
    }

    @MainActor
    func testCreateEmergencyKitWithPhoto() throws {
        tapAddButton()

        let nameField = app.textFields[A11y.KitForm.nameField]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Name field should exist")
        nameField.tap()
        nameField.typeText("Kit With Photo")

        let locationField = app.textFields[A11y.KitForm.locationField]
        XCTAssertTrue(locationField.exists, "Location field should exist")
        locationField.tap()
        locationField.typeText("Test Location")

        // Tap photo button to trigger photo selection
        let photoButton = app.buttons[A11y.KitForm.photoButton]
        XCTAssertTrue(photoButton.exists, "Photo button should exist")
        photoButton.tap()

        // Handle photo selection confirmation dialog
        let chooseFromLibraryButton = app.buttons["Choose from Library"]
        XCTAssertTrue(chooseFromLibraryButton.waitForExistence(timeout: 5), "Choose from Library option should appear")
        chooseFromLibraryButton.tap()

        // The system Photos picker is out-of-process UI we can't add identifiers to, so we
        // wait for it and select the first available photo with a few fallback strategies.
        let photoCollection = app.collectionViews.firstMatch
        XCTAssertTrue(photoCollection.waitForExistence(timeout: 10), "Photo collection should appear")

        // Allow the photo picker to fully load.
        Thread.sleep(forTimeInterval: 2)

        // Dismiss any privacy banner that might block interaction.
        let closeBannerButton = app.buttons["Close"]
        if closeBannerButton.exists && closeBannerButton.isHittable {
            closeBannerButton.tap()
            Thread.sleep(forTimeInterval: 1)
        }

        if photoCollection.exists && photoCollection.isHittable {
            photoCollection.swipeDown()
            Thread.sleep(forTimeInterval: 0.5)
        }

        let firstPhoto = photoCollection.cells.element(boundBy: 0)
        XCTAssertTrue(firstPhoto.waitForExistence(timeout: 5), "First photo should exist")

        var photoSelected = false
        if firstPhoto.isHittable {
            firstPhoto.tap()
            photoSelected = true
        } else {
            var scrollAttempts = 0
            while !firstPhoto.isHittable && scrollAttempts < 5 {
                photoCollection.swipeUp()
                Thread.sleep(forTimeInterval: 0.5)
                scrollAttempts += 1
            }
            if firstPhoto.isHittable {
                firstPhoto.tap()
                photoSelected = true
            }
        }
        if !photoSelected && firstPhoto.exists {
            firstPhoto.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            photoSelected = true
        }
        if !photoSelected {
            if let hittablePhoto = photoCollection.cells.allElementsBoundByIndex.first(where: { $0.isHittable }) {
                hittablePhoto.tap()
                photoSelected = true
            }
        }
        XCTAssertTrue(photoSelected, "Should be able to select a photo")

        // Confirm photo selection (look for Choose/Done/Use Photo/Add button)
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

        let kitWithPhotoLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Kit With Photo")).firstMatch
        XCTAssertTrue(kitWithPhotoLabel.waitForExistence(timeout: 5), "Kit with photo should appear in list")

        let kitCell = app.cells.containing(.staticText, identifier: "Kit With Photo").firstMatch
        let photoThumbnail = kitCell.images.firstMatch
        XCTAssertTrue(photoThumbnail.exists, "Photo thumbnail should appear in kit cell")
    }

    @MainActor
    func testCreateMultipleEmergencyKits() throws {
        let kitNames = ["Home Kit", "Car Kit", "Office Kit"]
        let locationNames = ["Living Room", "Trunk", "Desk"]

        for (kitName, locationName) in zip(kitNames, locationNames) {
            createTestKit(name: kitName, location: locationName)
        }
    }

    // MARK: - Emergency Kit Editing Tests

    @MainActor
    func testEditEmergencyKitName() throws {
        createTestKit(name: "Original Name", location: "Original Location")

        let kitCell = app.cells.containing(.staticText, identifier: "Original Name").firstMatch
        kitCell.swipeLeft()

        let editButton = app.buttons[A11y.KitList.editAction]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Edit button should appear after swipe")
        editButton.tap()

        let nameField = app.textFields[A11y.KitForm.nameField]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Name field should exist")
        nameField.clearAndEnterText("Updated Name")

        let locationField = app.textFields[A11y.KitForm.locationField]
        locationField.clearAndEnterText("Updated Location")

        saveKit()
        navigateBackToList()

        XCTAssertTrue(
            app.cells.containing(.staticText, identifier: "Updated Name").firstMatch.waitForExistence(timeout: 3),
            "Updated kit name should appear"
        )
        XCTAssertFalse(
            app.cells.containing(.staticText, identifier: "Original Name").firstMatch.exists,
            "Original kit name should not appear"
        )
        XCTAssertTrue(
            app.cells.containing(.staticText, identifier: "Updated Location").firstMatch.exists,
            "Updated location should appear"
        )
    }

    // MARK: - Emergency Kit Deletion Tests

    @MainActor
    func testDeleteEmergencyKitWithSwipe() throws {
        createTestKit(name: "Kit to Delete", location: "Kit to Delete Location")

        let kitCell = app.cells.containing(.staticText, identifier: "Kit to Delete").firstMatch
        XCTAssertTrue(kitCell.exists, "Kit should exist before deletion")

        kitCell.swipeLeft()

        let deleteButton = app.buttons[A11y.KitList.deleteAction]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2), "Delete button should appear after swipe")
        deleteButton.tap()

        let confirmButton = app.alerts.firstMatch.buttons["Delete"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 2), "Confirmation dialog should appear")
        confirmButton.tap()

        XCTAssertFalse(kitCell.waitForExistence(timeout: 3), "Kit should be deleted")
    }

    // MARK: - Emergency Kit List Display Tests

    @MainActor
    func testEmptyKitListDisplay() throws {
        // The app launches with an empty in-memory store, so the empty state must show.
        XCTAssertTrue(
            app.staticTexts["No Emergency Kits Yet"].waitForExistence(timeout: 3),
            "Empty state should be displayed when there are no kits"
        )
    }

    @MainActor
    func testKitListScrolling() throws {
        let kitNames = (1...10).map { "Kit \($0)" }
        let locationNames = (1...10).map { "Location \($0)" }

        for (kitName, locationName) in zip(kitNames, locationNames) {
            createTestKit(name: kitName, location: locationName)
        }

        let firstKit = app.cells.containing(.staticText, identifier: "Kit 1").firstMatch
        let lastKit = app.cells.staticTexts["Kit 10"]

        // Scroll to the bottom to confirm the last kit is reachable.
        var scrolls = 0
        while !lastKit.isHittable && scrolls < 10 {
            app.swipeUp()
            scrolls += 1
        }
        XCTAssertTrue(lastKit.isHittable, "Last kit should be reachable by scrolling")

        // Scroll back to the top to confirm the first kit is reachable.
        scrolls = 0
        while !firstKit.isHittable && scrolls < 10 {
            app.swipeDown()
            scrolls += 1
        }
        XCTAssertTrue(firstKit.isHittable, "First kit should be reachable by scrolling")
    }

    // MARK: - Helper Methods

    private func tapAddButton() {
        let addButton = app.buttons[A11y.KitList.addButton]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3), "Add kit button should exist")
        addButton.tap()
    }

    private func saveKit() {
        let saveButton = app.buttons[A11y.KitForm.saveButton]
        XCTAssertTrue(saveButton.exists, "Save button should exist")
        saveButton.tap()
    }

    private func createTestKit(name: String, location: String) {
        tapAddButton()

        let nameField = app.textFields[A11y.KitForm.nameField]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Name field should exist")
        nameField.tap()
        nameField.typeText(name)

        let locationField = app.textFields[A11y.KitForm.locationField]
        XCTAssertTrue(locationField.exists, "Location field should exist")
        locationField.tap()
        locationField.typeText(location)

        saveKit()

        let kitCell = app.cells.containing(.staticText, identifier: name).firstMatch
        var scrolls = 0
        while !kitCell.exists && scrolls < 10 {
            app.swipeUp()
            scrolls += 1
        }
        XCTAssertTrue(kitCell.waitForExistence(timeout: 5), "Kit should be created")
    }

    private func navigateBackToList() {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.exists, "Back button should exist")
        backButton.tap()
    }
}
