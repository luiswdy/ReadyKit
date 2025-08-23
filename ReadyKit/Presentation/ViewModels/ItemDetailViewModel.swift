//
//  ItemDetailViewModel.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/15.
//

import Foundation
import SwiftUI

/// ViewModel for managing individual item details and editing
@Observable
@MainActor
class ItemDetailViewModel {

    // MARK: - Dependencies
    private let dependencyContainer: DependencyContainer

    // MARK: - State
    var item: Item
    var emergencyKit: EmergencyKit
    var isLoading = false
    var errorMessage: LocalizedStringKey?
    var isEditing = false

    // Form fields for editing
    var editedName: String
    var editedQuantityValue: String
    var editedQuantityUnit: String
    var editedExpirationDate: Date?
    var editedNotes: String
    var editedPhoto: Data?
    
    var hasExpirationDate: Bool {
        didSet {
            if hasExpirationDate && editedExpirationDate == nil {
                // Set a default expiration date when toggling on
                editedExpirationDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
            } else if !hasExpirationDate {
                // Clear the date when toggling off
                editedExpirationDate = nil
            }
        }
    }

    // MARK: - Initialization
    init(item: Item, emergencyKit: EmergencyKit, dependencyContainer: DependencyContainer) {
        self.item = item
        self.emergencyKit = emergencyKit
        self.editedName = item.name
        self.editedQuantityValue = String(item.quantityValue)
        self.editedQuantityUnit = item.quantityUnitName
        self.editedExpirationDate = item.expirationDate
        self.editedNotes = item.notes ?? ""
        self.editedPhoto = item.photo
        self.hasExpirationDate = item.expirationDate != nil
        self.dependencyContainer = dependencyContainer
    }

    // MARK: - Public Methods
    func startEditing() {
        isEditing = true
        // Reset form fields to current values
        editedName = item.name
        editedQuantityValue = String(item.quantityValue)
        editedQuantityUnit = item.quantityUnitName
        editedExpirationDate = item.expirationDate
        editedNotes = item.notes ?? ""
        editedPhoto = item.photo
        hasExpirationDate = item.expirationDate != nil
    }

    func cancelEditing() {
        isEditing = false
        clearError()
    }

    func saveChanges() async -> Result<Void, Error>{
        let validationResult = validateForm()
        switch validationResult {
        case .success:
            break // continue
        default:
            // Validation failed, return early
            return validationResult
        }

        isLoading = true
        errorMessage = nil

        do {
            let updatedItem = try Item(
                id: item.id, // Keep the same ID
                name: editedName.trimmingCharacters(in: .whitespacesAndNewlines),
                expirationDate: hasExpirationDate ? editedExpirationDate : nil,
                notes: editedNotes.isEmpty ? nil : editedNotes.trimmingCharacters(in: .whitespacesAndNewlines),
                quantityValue: Int(editedQuantityValue) ?? 0,
                quantityUnitName: editedQuantityUnit.trimmingCharacters(in: .whitespacesAndNewlines),
                photo: editedPhoto
            )

            let request = EditItemInEmergencyKitRequest(
                emergencyKitId: emergencyKit.id,
                updatedItem: updatedItem
            )

            let result = dependencyContainer.editItemInEmergencyKitUseCase.execute(request: request)
            switch result {
            case .success:
                item = updatedItem
                isEditing = false
                isLoading = false
                return .success(())
            case .failure(let error):
                errorMessage = "Failed to save changes: \(error.localizedDescription)"
                isLoading = false
                return .failure(error)
            }
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            isLoading = false
            return .failure(error)
        }
    }

    func deleteItem() async -> Result<Void, Error> {
        isLoading = true
        errorMessage = nil

        let request = DeleteItemInEmergencyKitRequest(
            itemId: item.id,
            emergencyKitId: emergencyKit.id
        )

        let result = dependencyContainer.deleteItemInEmergencyKitUseCase.execute(request: request)
        switch result {
        case .success:
            isLoading = false
        case .failure(let error):
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
            isLoading = false
        }
        return result
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Methods
    private func validateForm() -> Result<Void, Error> {
        // Validate name
        if editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Item name cannot be empty"
            return .failure(ItemValidationError.emptyName(editedName))
        }

        // Validate quantity
        if editedQuantityValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Quantity cannot be empty"
            return .failure(ItemValidationError.invalidQuantityValueInput(editedQuantityValue))
        }

        guard let quantity = Int(editedQuantityValue), quantity > AppConstants.Validation.minimumQuantityValue else {
            errorMessage = "Quantity must be a positive number"
            return .failure(ItemValidationError.invalidQuantityValueInput(editedQuantityValue))
        }

        // Validate unit
        if editedQuantityUnit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Unit cannot be empty"
            return .failure(ItemValidationError.emptyQuantityUnitName(editedQuantityUnit))
        }

        // Validate expiration date if set
        if hasExpirationDate {
            guard let expirationDate = editedExpirationDate else {
                errorMessage = "Please select an expiration date"
                return .failure(ItemValidationError.nilExpirationDate)
            }

            // Allow past dates (for already expired items)
            // but warn if it's more than 10 years in the past
            let yearsAgo = Calendar.current.date(byAdding: .year, value: -AppConstants.Validation.maxYearsInPast, to: Date()) ?? Date()
            if expirationDate < yearsAgo {
                errorMessage = "Expiration date seems too far in the past"
                return .failure(ItemValidationError.tooManyYearsFromToday(expirationDate))
            }
        }

        return .success(())
    }

    // MARK: - Helper Methods
    func formatExpirationStatus() -> (text: String, color: Color) {
        guard let expirationDate = item.expirationDate else {
            return (String(localized: "No expiration date"), .secondary)
        }

        let calendar = Calendar.current
        let today = Date()

        if expirationDate < today {
            let daysExpired = calendar.dateComponents([.day], from: expirationDate, to: today).day ?? 0
            return (String("Expired \(daysExpired) days ago"), .red)
        } else {
            let daysUntilExpiration = calendar.dateComponents([.day], from: today, to: expirationDate).day ?? 0
            // Use user-configurable expiryReminderLeadDays
            let userPreferencesResult = dependencyContainer.loadUserPreferencesUseCase.execute()
            let leadDays: Int
            switch userPreferencesResult {
            case .success(let userPreferences):
                leadDays = userPreferences.expiryReminderLeadDays
            case .failure:
                assertionFailure("As UserPreferences returns a default set to value, this should never happen.")
                leadDays = AppConstants.UserPreferences.defaultExpiryReminderLeadDays
            }
            if daysUntilExpiration <= leadDays {
                return (String( localized: "Expiring in \(daysUntilExpiration) days"), .orange)
            } else {
                return (String(localized: "Expires in \(daysUntilExpiration) days"), .green)
            }
        }
    }

    func formatQuantity() -> String {
        "\(item.quantityValue) \(item.quantityUnitName)"
    }
}
