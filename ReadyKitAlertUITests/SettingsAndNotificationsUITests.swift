//
//  SettingsAndNotificationsUITests.swift
//  ReadyKitUITests
//
//  Created by GitHub Copilot on 2025/9/14.
//

import XCTest

/// UI tests for Settings, Notifications, and Backup functionality
final class SettingsAndNotificationsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchForUITesting()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Reminder Settings Tests

    @MainActor
    func testNavigateToReminderSettings() throws {
        app.tabBars.buttons["Settings"].tap()

        XCTAssertTrue(
            app.staticTexts["Daily Notification Time"].waitForExistence(timeout: 3),
            "Reminder settings should be displayed"
        )
    }

    @MainActor
    func testSavingReminderSettings() throws {
        let emergencyKitsTab = app.tabBars.buttons["Emergency Kits"]
        let settingsTab = app.tabBars.buttons["Settings"]

        settingsTab.tap()

        // The app launches with cleared preferences, so it starts from the defaults:
        // 12:00, 30 lead days, quarterly.
        let hourPicker = app.pickerWheels.element(boundBy: 0)
        let minutePicker = app.pickerWheels.element(boundBy: 1)
        XCTAssertTrue(hourPicker.waitForExistence(timeout: 3), "Hour picker should be visible")
        XCTAssertEqual(hourPicker.value as? String, "12", "Hour should start at the default 12")
        XCTAssertEqual(minutePicker.value as? String, "00", "Minute should start at the default 00")

        hourPicker.adjust(toPickerWheelValue: "22")
        minutePicker.adjust(toPickerWheelValue: "31")

        let incrementButton = app.buttons["Increment"].firstMatch
        let decrementButton = app.buttons["Decrement"].firstMatch
        XCTAssertTrue(incrementButton.waitForExistence(timeout: 5), "Stepper increment should be available")
        for _ in 0..<6 { incrementButton.tap() }
        decrementButton.tap()   // 30 + 6 - 1 = 35

        let halfYearly = app.buttons[A11y.Settings.frequencyHalfYearly]
        XCTAssertTrue(halfYearly.waitForExistence(timeout: 3), "Half-Yearly segment should be available")
        halfYearly.tap()
        app.buttons[A11y.Settings.saveButton].tap()

        // Round-trip away and back to confirm persistence.
        emergencyKitsTab.tap()
        settingsTab.tap()

        XCTAssertEqual(hourPicker.value as? String, "22", "Hour should persist after saving")
        XCTAssertEqual(minutePicker.value as? String, "31", "Minute should persist after saving")
        XCTAssertTrue(app.buttons[A11y.Settings.frequencyHalfYearly].isSelected, "Half-Yearly should be selected")
        XCTAssertTrue(app.staticTexts["35 days before expiration"].exists, "Lead days should be 35")

        // Reset to defaults and confirm. The reset button sits at the bottom of the form.
        let resetButton = app.buttons[A11y.Settings.resetButton]
        var scrolls = 0
        while !resetButton.isHittable && scrolls < 5 {
            app.swipeUp()
            scrolls += 1
        }
        resetButton.tap()
        app.buttons[A11y.Settings.saveButton].tap()
        emergencyKitsTab.tap()
        settingsTab.tap()

        XCTAssertEqual(hourPicker.value as? String, "12", "Hour should reset to default")
        XCTAssertEqual(minutePicker.value as? String, "00", "Minute should reset to default")
        XCTAssertTrue(app.buttons[A11y.Settings.frequencyQuarterly].isSelected, "Quarterly should be selected")
        XCTAssertTrue(app.staticTexts["30 days before expiration"].exists, "Lead days should be 30")
    }

    // MARK: - Database Backup Tests

    @MainActor
    func testNavigateToDatabaseBackup() throws {
        let backupTabButton = app.tabBars.buttons["Backup"]
        backupTabButton.tap()
        XCTAssertTrue(backupTabButton.isSelected, "Backup tab should be selected")
    }

    @MainActor
    func testExportDataButton() throws {
        app.tabBars.buttons["Backup"].tap()

        // We don't actually tap it to avoid triggering system dialogs.
        let exportButton = app.buttons.containing(.staticText, identifier: "Export Database Files").firstMatch
        XCTAssertTrue(exportButton.waitForExistence(timeout: 3), "Export functionality should be available")
    }

    @MainActor
    func testImportDataButton() throws {
        app.tabBars.buttons["Backup"].tap()

        // We don't actually tap it to avoid triggering file pickers.
        let importButton = app.buttons.containing(.staticText, identifier: "Import Database Files").firstMatch
        XCTAssertTrue(importButton.waitForExistence(timeout: 3), "Import functionality should be available")
    }
}
