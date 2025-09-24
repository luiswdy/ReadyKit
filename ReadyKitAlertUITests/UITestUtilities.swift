//
//  UITestUtilities.swift
//  ReadyKitUITests
//
//  Created by GitHub Copilot on 2025/9/14.
//

import XCTest

/// Shared utilities and extensions for UI tests
extension XCUIElement {
    /// Clear the current text and enter new text in a text field
    func clearAndEnterText(_ text: String) {
        guard self.exists else { return }
        
        self.tap()
        self.press(forDuration: 1.0)
        
        let selectAll = XCUIApplication().menuItems["Select All"]
        if selectAll.exists {
            selectAll.tap()
        }
        
        self.typeText(text)
    }
}