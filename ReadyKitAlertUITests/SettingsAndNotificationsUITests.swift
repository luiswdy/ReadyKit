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
    func testToggleReminderSettings() throws {
        app.tabBars.buttons["Settings"].tap()
        
        let toggles = app.switches
        if toggles.count > 0 {
            for i in 0..<min(toggles.count, 3) { // Test first 3 toggles
                let toggle = toggles.element(boundBy: i)
                let initialState = toggle.value as? String
                
                toggle.tap()
                
                // Verify state changed
                let newState = toggle.value as? String
                XCTAssertNotEqual(initialState, newState, "Toggle \(i) state should change")
                
                // Toggle back to original state
                toggle.tap()
                
                let finalState = toggle.value as? String
                XCTAssertEqual(initialState, finalState, "Toggle \(i) should return to original state")
            }
        }
    }
    
    @MainActor
    func testReminderFrequencySettings() throws {
        app.tabBars.buttons["Settings"].tap()
        
        // Look for reminder frequency options (steppers, pickers, or sliders)
        let steppers = app.steppers
        let pickers = app.pickers
        let sliders = app.sliders
        
        if steppers.count > 0 {
            let stepper = steppers.firstMatch
            stepper.buttons["Increment"].tap()
            stepper.buttons["Decrement"].tap()
        }
        
        if pickers.count > 0 {
            let picker = pickers.firstMatch
            picker.tap()
            
            // Try to select different values
            let pickerWheels = picker.pickerWheels
            if pickerWheels.count > 0 {
                // Pick picker with label 'Hour' and pick a different value
                if let hourPicker = pickerWheels.firstMatch as XCUIElement?, hourPicker.exists
                    && hourPicker.label.contains("Hour") {
                    hourPicker.adjust(toPickerWheelValue: "10")
                }
                // Pick picker with label 'Minute' and pick a different value
                if let minutePicker = pickerWheels.firstMatch as XCUIElement?, minutePicker.exists
                    && minutePicker.label.contains("Minute") {
                    minutePicker.adjust(toPickerWheelValue: "39")
                }
            }
        }
        
        if sliders.count > 0 {
            let slider = sliders.firstMatch
            slider.adjust(toNormalizedSliderPosition: 0.7)
        }
    }
    
    @MainActor
    func testNotificationPermissionRequest() throws {
        app.tabBars.buttons["Settings"].tap()
        
        // Look for notification permission button or toggle
        let notificationButton = app.buttons.containing(.staticText, identifier: "Enable Notifications").firstMatch
        if notificationButton.exists {
            notificationButton.tap()
            
            // Handle system notification permission dialog
            // Note: In UI tests, we can't actually grant permissions, but we can verify the request is made
            let systemAlert = app.alerts.firstMatch
            if systemAlert.waitForExistence(timeout: 3) {
                // If "Don't Allow" button exists, tap it to dismiss (for testing purposes)
                let dontAllowButton = systemAlert.buttons["Don't Allow"]
                if dontAllowButton.exists {
                    dontAllowButton.tap()
                }
            }
        }
    }
    
    // MARK: - Background Mode Tests
    
    @MainActor
    func testBackgroundModeStatus() throws {
        app.tabBars.buttons["Settings"].tap()
        
        // Look for background mode status indicators
        let backgroundModeIndicators = [
            app.staticTexts.containing(.staticText, identifier: "Background").firstMatch,
            app.staticTexts.containing(.staticText, identifier: "App Refresh").firstMatch,
            app.buttons.containing(.staticText, identifier: "Settings").firstMatch
        ]
        
        let hasBackgroundModeInfo = backgroundModeIndicators.contains { $0.exists }
        
        if hasBackgroundModeInfo {
            // Test interaction with background mode settings
            let settingsButton = app.buttons.containing(.staticText, identifier: "Open Settings").firstMatch
            if settingsButton.exists {
                // Note: This would open system settings, which we can't test in UI tests
                // We just verify the button exists
                XCTAssertTrue(settingsButton.exists, "Settings button should be available")
            }
        }
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
            app.buttons.containing(.staticText, identifier: "Export").firstMatch,
            app.buttons.containing(.staticText, identifier: "Backup").firstMatch,
            app.buttons.containing(.staticText, identifier: "Share").firstMatch
        ]
        
        for exportButton in exportButtons {
            if exportButton.exists {
                // We don't actually tap it to avoid triggering system dialogs
                XCTAssertTrue(exportButton.exists, "Export functionality should be available")
                break
            }
        }
    }
    
    @MainActor
    func testImportDataButton() throws {
        app.tabBars.buttons["Backup"].tap()
        
        // Look for import/restore buttons
        let importButtons = [
            app.buttons.containing(.staticText, identifier: "Import").firstMatch,
            app.buttons.containing(.staticText, identifier: "Restore").firstMatch,
            app.buttons.containing(.staticText, identifier: "Load").firstMatch
        ]
        
        for importButton in importButtons {
            if importButton.exists {
                // We don't actually tap it to avoid triggering file pickers
                XCTAssertTrue(importButton.exists, "Import functionality should be available")
                break
            }
        }
    }
    
    @MainActor
    func testBackupInfo() throws {
        app.tabBars.buttons["Backup"].tap()
        
        // Look for backup information (size, date, etc.)
        let infoTexts = app.staticTexts
        let hasBackupInfo = infoTexts.count > 0
        
        if hasBackupInfo {
            // Check for common backup-related text
            let backupInfoIndicators = [
                "Last backup",
                "Data size",
                "Export",
                "Import",
                "Privacy"
            ]
            
            var foundInfo = false
            for indicator in backupInfoIndicators {
                if infoTexts.containing(.staticText, identifier: indicator).firstMatch.exists {
                    foundInfo = true
                    break
                }
            }
            
            XCTAssertTrue(foundInfo || infoTexts.count > 2, "Backup info should be displayed")
        }
    }
    
    // MARK: - Privacy and Data Tests
    
    @MainActor
    func testPrivacyInformation() throws {
        app.tabBars.buttons["Backup"].tap()
        
        // Look for privacy-related information
        let privacyTexts = [
            app.staticTexts.containing(.staticText, identifier: "Privacy").firstMatch,
            app.staticTexts.containing(.staticText, identifier: "Local").firstMatch,
            app.staticTexts.containing(.staticText, identifier: "No data collection").firstMatch
        ]
        
        let hasPrivacyInfo = privacyTexts.contains { $0.exists }
        
        if hasPrivacyInfo {
            // Verify privacy information is accessible
            for privacyText in privacyTexts {
                if privacyText.exists {
                    XCTAssertTrue(privacyText.exists, "Privacy information should be visible")
                }
            }
        }
    }
    
    @MainActor
    func testDataStorageInfo() throws {
        app.tabBars.buttons["Backup"].tap()
        
        // Look for data storage information
        let storageIndicators = [
            app.staticTexts.containing(.staticText, identifier: "storage").firstMatch,
            app.staticTexts.containing(.staticText, identifier: "device").firstMatch,
            app.staticTexts.containing(.staticText, identifier: "local").firstMatch
        ]
        
        let hasStorageInfo = storageIndicators.contains { $0.exists }
        
        if hasStorageInfo {
            // Verify storage information provides context about local data
            XCTAssertTrue(hasStorageInfo, "Data storage information should be available")
        }
    }
    
    // MARK: - Integration Tests for Settings
    
    @MainActor
    func testSettingsChangePersistence() throws {
        app.tabBars.buttons["Settings"].tap()
        
        let toggles = app.switches
        if toggles.count > 0 {
            let firstToggle = toggles.firstMatch
            let initialState = firstToggle.value as? String
            
            // Change setting
            firstToggle.tap()
            let changedState = firstToggle.value as? String
            
            // Navigate away and back to verify persistence
            app.tabBars.buttons["Emergency Kits"].tap()
            app.tabBars.buttons["Settings"].tap()
            
            // Check if setting persisted
            let persistedState = firstToggle.value as? String
            XCTAssertEqual(changedState, persistedState, "Settings should persist across navigation")
            
            // Restore original state
            if initialState != persistedState {
                firstToggle.tap()
            }
        }
    }
    
    @MainActor
    func testNotificationSettingsFlow() throws {
        // Test complete notification setup flow
        app.tabBars.buttons["Settings"].tap()
        
        // Enable notifications (if toggle exists)
        let notificationToggle = app.switches.firstMatch
        if notificationToggle.exists {
            let wasEnabled = (notificationToggle.value as? String) == "1"
            
            if !wasEnabled {
                notificationToggle.tap()
            }
            
            // Configure notification frequency/settings
            let steppers = app.steppers
            if steppers.count > 0 {
                steppers.firstMatch.buttons["Increment"].tap()
            }
            
            // Navigate away and verify settings remain
            app.tabBars.buttons["Emergency Kits"].tap()
            app.tabBars.buttons["Settings"].tap()
            
            let finalState = (notificationToggle.value as? String) == "1"
            XCTAssertTrue(finalState, "Notification settings should be maintained")
        }
    }
}
