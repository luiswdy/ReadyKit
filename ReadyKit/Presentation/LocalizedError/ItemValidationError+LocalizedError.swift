//
//  ItemValidationError+LocalizedError.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/18/25.
//

import SwiftUI

extension ItemValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emptyName(let providedName):
            return String(localized: "Item name cannot be empty. Provided: \(providedName)", comment: "Error message when item name is empty")
        case .invalidQuantityValue(let providedValue):
            return String(localized: "Item quantity value must be greater than zero. Provided: \(providedValue)", comment: "Error message when item quantity value is invalid")
        case .emptyQuantityUnitName(let providedUnitName):
            return String(localized: "Item quantity unit name cannot be empty. Provided: \(providedUnitName)", comment: "Error message when item quantity unit name is empty")
        case .nilExpirationDate:
            return String(localized: "Item expiration date cannot be nil.", comment: "Error message when item expiration date is nil")
        case .tooManyYearsFromToday(let providedDate):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            let dateString = formatter.string(from: providedDate)
            return String(localized: "Item expiration date cannot be more than \(AppConstants.Validation.maxYearsInPast) years from today. Provided: \(dateString)", comment: "Error message when item expiration date is too far in the future")
        case .invalidQuantityValueInput(let providedString):
            return String(localized: "Invalid input for item quantity value: \(providedString). Please enter a valid number.", comment: "Error message when item quantity value input is invalid")
        }
    }
}
