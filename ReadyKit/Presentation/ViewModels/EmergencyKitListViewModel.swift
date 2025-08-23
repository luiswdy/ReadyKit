//
//  EmergencyKitListViewModel.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/14/25.
//

import Foundation
import SwiftUI

/// ViewModel for managing the list of emergency kits
@Observable
@MainActor
final class EmergencyKitListViewModel {

    // MARK: - Dependencies
    private let dependencyContainer: DependencyContainer

    // MARK: - State
    var emergencyKits: [EmergencyKit] = []
    var isLoading = false
    var errorMessage: LocalizedStringKey?
    var searchText = ""
    var showingCreateForm = false
    var showingPhotoSelection = false
    var selectedEmergencyKitForPhoto: EmergencyKit?
    var emergencyKitToEdit: EmergencyKit? // State for the emergency kit being edited
    var showingEditForm = false // State to control the display of the edit form

    // MARK: - Computed Properties
    var filteredEmergencyKits: [EmergencyKit] {
        if searchText.isEmpty {
            return emergencyKits
        }
        return emergencyKits.filter { emergencyKit in
            emergencyKit.name.localizedCaseInsensitiveContains(searchText) ||
            emergencyKit.location.localizedCaseInsensitiveContains(searchText)
        }
    }

    var hasEmergencyKits: Bool {
        !emergencyKits.isEmpty
    }

    // MARK: - Initialization
    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
        loadEmergencyKits()
    }

    // MARK: - Public Methods
    func loadEmergencyKits() {
        isLoading = true
        errorMessage = nil

        let result = dependencyContainer.fetchAllEmergencyKitUseCase.execute()
        switch result {
        case .success(let fetchedEmergencyKits):
            emergencyKits = fetchedEmergencyKits
        case .failure(let error):
            errorMessage = "Failed to load emergency kits: \(error.localizedDescription)"
            emergencyKits = []
        }

        isLoading = false
    }

    func createEmergencyKit(name: String, location: String, photo: Data? = nil) -> Result<Void, Error> {
        let request = CreateEmergencyKitRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            items: [], // Start with empty items array
            photo: photo,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        let result = dependencyContainer.createEmergencyKitUseCase.execute(request: request)
        switch result {
        case .success:
            loadEmergencyKits() // Refresh the list
        case .failure(let error):
            errorMessage = "Failed to create emergency kit: \(error.localizedDescription)"
        }
        return result
    }

    func deleteEmergencyKit(_ emergencyKit: EmergencyKit) {
        let request = DeleteEmergencyKitRequest(emergencyKitId: emergencyKit.id)
        let result = dependencyContainer.deleteEmergencyKitUseCase.execute(request: request)

        switch result {
        case .success:
            loadEmergencyKits() // Refresh the list
        case .failure(let error):
            errorMessage = "Failed to delete emergency kit: \(error.localizedDescription)"
        }
    }

    func updateEmergencyKit(_ emergencyKit: EmergencyKit, name: String? = nil, location: String? = nil, photo: Data? = nil) -> Result<Void, Error>{
        let request = EditEmergencyKitRequest(
            id: emergencyKit.id,
            name: name,
            items: nil, // Don't update items here
            photo: photo,
            location: location,
            shouldUpdatePhoto: true
        )

        let result = dependencyContainer.editEmergencyKitUseCase.execute(request: request)
        switch result {
        case .success:
            loadEmergencyKits() // Refresh the list
            return .success(())
        case .failure(let error):
            errorMessage = "Failed to update emergency kit: \(error.localizedDescription)"
            return .failure(error)
        }
    }

    func refresh() {
        loadEmergencyKits()
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Edit Management
    func editEmergencyKit(_ emergencyKit: EmergencyKit) {
        emergencyKitToEdit = emergencyKit
        showingEditForm = true
    }

    // MARK: - Photo Management
    func selectPhotoForEmergencyKit(_ emergencyKit: EmergencyKit) {
        selectedEmergencyKitForPhoto = emergencyKit
        showingPhotoSelection = true
    }

    func updateEmergencyKitPhoto(_ photoData: Data?) -> Result<Void, Error> {
        guard let emergencyKit = selectedEmergencyKitForPhoto else { return .failure(EmergencyKitError.nilEmergencyKitId) }

        let result = updateEmergencyKit(
            emergencyKit,
            name: emergencyKit.name,
            location: emergencyKit.location,
            photo: photoData
        )
        switch result {
        case .success:
            selectedEmergencyKitForPhoto = nil
            showingPhotoSelection = false
            return .success(())
        case .failure(let error):
            return  .failure(error)
        }
    }

    func removeEmergencyKitPhoto(_ emergencyKit: EmergencyKit) -> Result<Void, Error> {
        return updateEmergencyKit(
            emergencyKit,
            name: emergencyKit.name,
            location: emergencyKit.location,
            photo: nil
        )
    }

    // MARK: - Helper Methods
    func itemCount(for emergencyKit: EmergencyKit) -> Int {
        emergencyKit.items.count
    }

    func expiredItemsCount(for emergencyKit: EmergencyKit) -> Int {
        return emergencyKit.items.filter { item in
            guard let expirationDate = item.expirationDate else { return false }
            return expirationDate < Date()
        }.count
    }

    func expiringItemsCount(for emergencyKit: EmergencyKit) -> Int {
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
        let now = Date()
        let cutoffDate = Calendar.current.date(byAdding: .day, value: leadDays, to: now) ?? now
        return emergencyKit.items.filter { item in
            guard let expirationDate = item.expirationDate else { return false }
            return expirationDate >= now && expirationDate <= cutoffDate
        }.count
    }
}
