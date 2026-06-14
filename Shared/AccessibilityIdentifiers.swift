//
//  AccessibilityIdentifiers.swift
//  ReadyKit
//
//  Shared between the app target and the UI-test target so views set the same
//  stable identifiers the UI tests query. Keep values locale-independent.
//

import Foundation

/// Launch arguments the app reads at startup (see DependencyContainer).
enum LaunchArgument {
    static let uiTesting = "--uitesting"
    static let reset = "--reset"
}

/// Stable accessibility identifiers for UI-test targeting.
enum A11y {
    enum KitForm {
        static let nameField = "kitForm.nameField"
        static let locationField = "kitForm.locationField"
        static let photoButton = "kitForm.photoButton"
        static let saveButton = "kitForm.saveButton"
    }

    enum KitList {
        static let addButton = "kitList.addButton"
        static let editAction = "kitList.editAction"
        static let deleteAction = "kitList.deleteAction"
    }

    enum ItemForm {
        static let nameField = "itemForm.nameField"
        static let quantityField = "itemForm.quantityField"
        static let unitPicker = "itemForm.unitPicker"
        static let customUnitField = "itemForm.customUnitField"
        static let hasExpirationToggle = "itemForm.hasExpirationToggle"
        static let expirationDatePicker = "itemForm.expirationDatePicker"
        static let saveButton = "itemForm.saveButton"
    }

    enum ItemList {
        static let addButton = "itemList.addButton"
        static let copyAction = "itemList.copyAction"
        static let deleteAction = "itemList.deleteAction"
    }

    enum ItemDetail {
        static let moreButton = "itemDetail.moreButton"
        static let editButton = "itemDetail.editButton"
        static let deleteButton = "itemDetail.deleteButton"
        static let saveButton = "itemDetail.saveButton"
        static let nameField = "itemDetail.nameField"
        static let quantityField = "itemDetail.quantityField"
        static let unitField = "itemDetail.unitField"
    }

    enum Settings {
        static let hourPicker = "settings.hourPicker"
        static let minutePicker = "settings.minutePicker"
        static let saveButton = "settings.saveButton"
        static let resetButton = "settings.resetButton"

        static let frequencyQuarterly = "settings.frequency.quarterly"
        static let frequencyHalfYearly = "settings.frequency.halfYearly"
        static let frequencyYearly = "settings.frequency.yearly"

        /// `rawValue` is the `RegularCheckFrequency` raw value (e.g. "quarterly").
        static func frequencySegment(rawValue: String) -> String {
            "settings.frequency.\(rawValue)"
        }
    }
}
