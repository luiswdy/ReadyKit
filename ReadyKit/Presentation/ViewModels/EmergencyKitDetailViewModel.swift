//
//  EmergencyKitDetailViewModel.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/15.
//

import Foundation
import SwiftUI

/// ViewModel for managing individual emergency kit details and its items
@Observable
@MainActor
final class EmergencyKitDetailViewModel {

    // MARK: - private properties
    private let container: DependencyContainer

    // MARK: - State
    var emergencyKit: EmergencyKit
    var isLoading = false
    var errorMessage: LocalizedStringKey?
    var searchText = ""
    var showingAddItemForm = false
    var selectedItem: Item?
    var showingItemDetail = false
    var showingDeleteConfirmation = false
    var itemToDelete: Item?

    // MARK: - Computed Properties
    var filteredItems: [Item] {
        let items = if searchText.isEmpty {
            emergencyKit.items
        } else {
            emergencyKit.items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                (item.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Sort by days before expiration date (ascending), with no-expiration items at the end
        return items.sorted { item1, item2 in
            switch (item1.expirationDate, item2.expirationDate) {
            case (nil, nil):
                // Both have no expiration date - maintain original order
                return false
            case (nil, _):
                // item1 has no expiration date - put it after item2
                return false
            case (_, nil):
                // item2 has no expiration date - put item1 before it
                return true
            case (let date1?, let date2?):
                // Both have expiration dates - sort by expiration date (earliest first)
                return date1 < date2
            }
        }
    }

    var expiringItems: [Item] {
        let userPreferencesResult = container.loadUserPreferencesUseCase.execute()
        let leadDays: Int

        switch userPreferencesResult {
        case .success(let userPreferences):
            leadDays = userPreferences.expiryReminderLeadDays
        case .failure:
            assertionFailure("As UserPreferences returns a default set to value, this should never happen.")
            leadDays = AppConstants.UserPreferences.defaultExpiryReminderLeadDays
        }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: leadDays, to: Date()) ?? Date()
        return emergencyKit.items.filter { item in
            guard let expirationDate = item.expirationDate else { return false }
            return expirationDate <= cutoffDate && expirationDate >= Date()
        }.sorted { ($0.expirationDate ?? Date.distantFuture) < ($1.expirationDate ?? Date.distantFuture) }
    }

    var expiredItems: [Item] {
        return emergencyKit.items.filter { item in
            guard let expirationDate = item.expirationDate else { return false }
            return expirationDate < Date()
        }.sorted { ($0.expirationDate ?? Date.distantPast) > ($1.expirationDate ?? Date.distantPast) }
    }

    var hasItems: Bool {
        !emergencyKit.items.isEmpty
    }

    // MARK: - Photo Handling
    /// The photo associated with the emergency kit (bind to UI)
    var photo: Data? {
        get { emergencyKit.photo }
        set { emergencyKit.photo = newValue }
    }

    // MARK: - Initialization
    init(emergencyKit: EmergencyKit, container: DependencyContainer) {
        self.emergencyKit = emergencyKit
        self.container = container
    }

    // MARK: - Public Methods
    func addItem(
        name: String,
        quantityValue: Int,
        quantityUnit: String,
        expirationDate: Date? = nil,
        notes: String? = nil,
        photo: Data? = nil
    ) -> Result<Void, Error> {
        isLoading = true
        errorMessage = nil

        let request = AddItemToEmergencyKitRequest(
            emergencyKitId: emergencyKit.id,
            itemName: name.trimmingCharacters(in: .whitespacesAndNewlines),
            itemQuantityValue: quantityValue,
            itemQuantityUnitName: quantityUnit.trimmingCharacters(in: .whitespacesAndNewlines),
            itemExpirationDate: expirationDate,
            itemNotes: notes?.isEmpty == true ? nil : notes,
            itemPhoto: photo
        )

        let result = container.addItemToEmergencyKitUseCase.execute(request: request)
        switch result {
        case .success:
            refreshEmergencyKit()
            isLoading = false
        case .failure(let error):
            errorMessage = "Failed to add item: \(error.localizedDescription)"
            isLoading = false
        }
        return result
    }

    func updateItem(_ item: Item) -> Bool {
        isLoading = true
        let request = EditItemInEmergencyKitRequest(
            emergencyKitId: emergencyKit.id,
            updatedItem: item
        )

        let result = container.editItemInEmergencyKitUseCase.execute(request: request)
        switch result {
        case .success:
            refreshEmergencyKit()
            isLoading = false
            return true
        case .failure(let error):
            errorMessage = "Failed to update item: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    func deleteItem(_ item: Item) -> Result<Void, Error> {
        isLoading = true
        errorMessage = nil

        let request = DeleteItemInEmergencyKitRequest(
            itemId: item.id,
            emergencyKitId: emergencyKit.id
        )
        
        let result = container.deleteItemInEmergencyKitUseCase.execute(request: request)
        switch result {
        case .success:
            refreshEmergencyKit() // Refresh to get updated emergency kit
            isLoading = false
        case .failure(let error):
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
            isLoading = false
        }
        return result
    }

    func refreshEmergencyKit() {
        // Fetch the latest emergency kit data
        let result = container.fetchAllEmergencyKitUseCase.execute()
        switch result {
        case .success(let emergencyKits):
            if let updatedEmergencyKit = emergencyKits.first(where: { $0.id == emergencyKit.id }) {
                emergencyKit = updatedEmergencyKit
            }
        case .failure(let error):
            errorMessage = "Failed to refresh emergency kit: \(error.localizedDescription)"
        }
    }

    func selectItem(_ item: Item) {
        selectedItem = item
        showingItemDetail = true
    }

    func clearError() {
        errorMessage = nil
    }

    func requestDeleteItem(_ item: Item) {
        itemToDelete = item
        showingDeleteConfirmation = true
    }

    func confirmDeleteItem() {
        guard let item = itemToDelete else { return }
        let result = deleteItem(item)
        switch result {
        case .success:
            // Successfully deleted item, reset state
            itemToDelete = nil
        case .failure(_):
            // Do nothing. deleteItem sets errorMessage if it fails.
            break
        }
        showingDeleteConfirmation = false
    }

    func cancelDeleteItem() {
        itemToDelete = nil
        showingDeleteConfirmation = false
    }

    /// Update the emergency kit details (name, location, photo)
    func updateEmergencyKit(name: String? = nil, location: String? = nil) -> Bool {
        isLoading = true
        errorMessage = nil
        let request = EditEmergencyKitRequest(
            id: emergencyKit.id,
            name: name ?? emergencyKit.name,
            items: emergencyKit.items,
            photo: photo,
            location: location ?? emergencyKit.location,
            shouldUpdatePhoto: true
        )
        let result = container.editEmergencyKitUseCase.execute(request: request)
        switch result {
        case .success:
            refreshEmergencyKit()
            isLoading = false
            return true
        case .failure(let error):
            errorMessage = "Failed to update emergency kit: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Helper Methods
    func formatExpirationStatus(for item: Item) -> (text: String, color: Color) {
        guard let expirationDate = item.expirationDate else {
            return (String(localized: "No expiration"), .secondary)
        }

        let calendar = Calendar.current
        let today = Date()

        if expirationDate < today {
            let daysExpired = calendar.dateComponents([.day], from: expirationDate, to: today).day ?? 0
            return (String(localized: "Expired \(daysExpired) days ago"), .red)
        } else {
            let daysUntilExpiration = calendar.dateComponents([.day], from: today, to: expirationDate).day ?? 0
            // Use user-configurable expiryReminderLeadDays
            let userPreferencesResult = container.loadUserPreferencesUseCase.execute()
            let leadDays: Int
            switch userPreferencesResult {
            case .success(let userPreferences):
                leadDays = userPreferences.expiryReminderLeadDays
            case .failure:
                assertionFailure("As UserPreferences returns a default set to value, this should never happen.")
                leadDays = AppConstants.UserPreferences.defaultExpiryReminderLeadDays
            }
            if daysUntilExpiration <= leadDays {
                return (String(localized: "Expiring in \(daysUntilExpiration) days"), .orange)
            } else {
                return (String(localized: "Expires in \(daysUntilExpiration) days"), .green)
            }
        }
    }
}
