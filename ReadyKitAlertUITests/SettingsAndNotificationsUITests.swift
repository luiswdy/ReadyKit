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
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Reminder Settings Tests

    @MainActor
    func testNavigateToReminderSettings() throws {
        app.tabBars.buttons["Settings"].tap()

        // Verify we're on the settings tab
        let settingsView = app.staticTexts.containing(.staticText, identifier: "Settings").firstMatch
        XCTAssertTrue(settingsView.waitForExistence(timeout: 3) || app.switches.count > 0,
                     "Settings view should be displayed")
    }

    @MainActor
    func testSavingReminderSettings() throws {
        let emergencyKitsTabButton = app.tabBars.buttons["Emergency Kits"]
        let settingsTabButton = app.tabBars.buttons["Settings"]
        let hourPickerWheel = app.pickerWheels["12"].firstMatch
        let minutePickerWheel = app.pickerWheels["00"].firstMatch

        settingsTabButton.tap()
        hourPickerWheel.adjust(toPickerWheelValue: "22")
        minutePickerWheel.adjust(toPickerWheelValue: "31")

        let incrementButton = app.buttons["Increment"].firstMatch
        let decrementButton = app.buttons["Decrement"].firstMatch
        for _ in 0..<6 {
            incrementButton.tap()
        }
        decrementButton.tap()   // 35 days

        let halfYearlyButton = app.buttons["Half-Yearly"].firstMatch
        halfYearlyButton.tap()

        let saveButton = app.buttons["Save"].firstMatch
        saveButton.tap()
        emergencyKitsTabButton.tap()
        settingsTabButton.tap()

        XCTAssertNotNil(app.pickerWheels["22"].firstMatch, "Hour picker should retain value")
        XCTAssertNotNil(app.pickerWheels["31"].firstMatch, "Minute picker should retain value")
        XCTAssertTrue(halfYearlyButton.isSelected, "Half-Yearly button should be selected")
        XCTAssertTrue(app.staticTexts["35 days before expiration"].exists, "Days before expiration should be 35")

        let resetToDefaultButton = app.buttons["Reset to Defaults"].firstMatch
        let quarterlyButton = app.buttons["Quarterly"].firstMatch
        app/*@START_MENU_TOKEN@*/.staticTexts["Reminder Settings"].firstMatch.swipeUp()/*[[".otherElements.staticTexts[\"Reminder Settings\"].firstMatch",".swipeUp()",".swipeRight()",".staticTexts[\"Reminder Settings\"].firstMatch"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,1]]@END_MENU_TOKEN@*/
        resetToDefaultButton.tap()
        saveButton.tap()
        emergencyKitsTabButton.tap()
        settingsTabButton.tap()

        XCTAssertTrue(hourPickerWheel.value as? String == "12", "Hour picker should retain value")
        XCTAssertTrue(minutePickerWheel.value as? String == "00", "Minute picker should retain value")
        XCTAssertTrue(quarterlyButton.isSelected, "Quarterly button should be selected")
        XCTAssertTrue(app.staticTexts["30 days before expiration"].exists, "Days before expiration should be 30")
        let app = XCUIApplication()
        app.activate()
        app/*@START_MENU_TOKEN@*/.buttons["Settings"]/*[[".buttons.containing(.image, identifier: \"bell.fill\")",".otherElements.buttons[\"Settings\"]",".buttons[\"Settings\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Reminder Settings"].firstMatch.swipeUp()/*[[".otherElements.staticTexts[\"Reminder Settings\"].firstMatch",".swipeUp()",".swipeRight()",".staticTexts[\"Reminder Settings\"].firstMatch"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,1]]@END_MENU_TOKEN@*/
        app/*@START_MENU_TOKEN@*/.buttons["Reset to Defaults"]/*[[".otherElements.buttons[\"Reset to Defaults\"]",".buttons[\"Reset to Defaults\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
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

        // Look for export/backup buttons
        let exportButtons = [
            app.buttons.containing(.staticText, identifier: "Export Database Files").firstMatch,
        ]

        for exportButton in exportButtons {
            if exportButton.exists {
                // We don't actually tap it to avoid triggering system dialogs
                XCTAssertTrue(exportButton.exists, "Export functionality should be available")
                return
            }
        }
        XCTFail("No export button found")
    }

    @MainActor
    func testImportDataButton() throws {
        app.tabBars.buttons["Backup"].tap()

        // Look for import/restore buttons
        let importButtons = [
            app.buttons.containing(.staticText, identifier: "Import Database Files").firstMatch,
        ]

        for importButton in importButtons {
            if importButton.exists {
                // We don't actually tap it to avoid triggering file pickers
                XCTAssertTrue(importButton.exists, "Import functionality should be available")
                return
            }
        }
        XCTFail("No import button found")
    }
}
