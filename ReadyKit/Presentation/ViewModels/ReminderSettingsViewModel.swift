//
//  ReminderSettingsViewModel.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/15.
//

import Foundation
import SwiftUI

/// ViewModel for managing reminder settings and user preferences
@Observable
@MainActor
final class ReminderSettingsViewModel {

    // MARK: - Dependencies
    private let dependencyContainer: DependencyContainer

    // MARK: - State
    var userPreferences: UserPreferences?
    var isLoading = false
    var errorMessage: LocalizedStringKey?
    var isSaving = false
    var notificationPermission: NotificationPermission = .notGranted
    var showSettingsAlert = false

    // Form fields
    var selectedHour: Int = AppConstants.UserPreferences.defaultNotificationHour
    var selectedMinute: Int = AppConstants.UserPreferences.defaultNotificationMinute
    var expiryReminderLeadDays: Int = AppConstants.UserPreferences.defaultExpiryReminderLeadDays
    var regularCheckFrequency: RegularCheckFrequency = AppConstants.UserPreferences.defaultRegularCheckFrequency

    // MARK: - Computed Properties
    var notificationTimeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        var components = DateComponents()
        components.hour = selectedHour
        components.minute = selectedMinute

        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    var hasUnsavedChanges: Bool {
        guard let preferences = userPreferences else { return false }

        return selectedHour != (preferences.dailyNotificationTime.hour ?? AppConstants.UserPreferences.defaultNotificationHour) ||
        selectedMinute != (preferences.dailyNotificationTime.minute ?? AppConstants.UserPreferences.defaultNotificationMinute) ||
               expiryReminderLeadDays != preferences.expiryReminderLeadDays ||
               regularCheckFrequency != preferences.regularCheck
    }

    // MARK: - Initialization
    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
        self.loadPreferences()
        Task { [weak self] in
            guard let self = self else { return }
            self.notificationPermission = await self.dependencyContainer.notificationPermissionService.checkPermission()
        }
    }

    // MARK: - Public Methods
    func loadPreferences() {
        isLoading = true
        errorMessage = nil

        let result = dependencyContainer.loadUserPreferencesUseCase.execute()
        switch result {
        case .success(let preferences):
            userPreferences = preferences
            updateFormFields(from: preferences)
        case .failure(let error):
            errorMessage = "Failed to load preferences: \(error.localizedDescription)"
            resetToDefaults()
        }

        isLoading = false
    }

    func savePreferences() async -> Bool {
        isSaving = true
        errorMessage = nil

        guard validateForm() else {
            isSaving = false
            errorMessage = "Please correct the errors in the form."
            return false
        }

        let updatedPreferences = UserPreferences(
            dailyNotificationTime: DateComponents(hour: selectedHour, minute: selectedMinute, second: 0),
            expiryReminderLeadDays: expiryReminderLeadDays,
            regularCheck: regularCheckFrequency
        )

        let request = SaveUserPreferencesRequest(preferences: updatedPreferences)

        let result = dependencyContainer.saveUserPreferencesUseCase.execute(request: request)
        switch result {
        case .success:
            userPreferences = updatedPreferences

            // Automatically reschedule notifications with new settings
            let rescheduleResult = dependencyContainer.rescheduleRemindersUseCase.execute()
            switch rescheduleResult {
            case .success:
                break
            case .failure(let error):
                errorMessage = "Settings saved, but failed to reschedule notifications: \(error.localizedDescription)"
            }

            isSaving = false
            return true
        case .failure(let error):
            errorMessage = "Failed to save preferences: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }

    func rescheduleNotifications() async -> Bool {
        isLoading = true
        errorMessage = nil

        let result = dependencyContainer.rescheduleRemindersUseCase.execute()
        switch result {
        case .success:
            isLoading = false
            return true
        case .failure(let error):
            errorMessage = "Failed to reschedule notifications: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    func refreshAll() async {
        isLoading = true
        errorMessage = nil

        // Refresh preferences
        let result = dependencyContainer.loadUserPreferencesUseCase.execute()
        switch result {
        case .success(let preferences):
            userPreferences = preferences
            updateFormFields(from: preferences)
        case .failure(let error):
            errorMessage = "Failed to load preferences: \(error.localizedDescription)"
            resetToDefaults()
        }

        // Refresh notification permission status
        notificationPermission = await dependencyContainer.notificationPermissionService.checkPermission()

        isLoading = false
    }

    func resetToDefaults() {
        updateFormFields(from: UserPreferences())
    }

    func clearError() {
        errorMessage = nil
    }

    func requestNotificationPermission() {
        Task { @MainActor in
            notificationPermission = await dependencyContainer.notificationPermissionService.requestPermission()
            switch notificationPermission {
            case .granted:
                notificationPermission = .granted
            case .notGranted:
                showSettingsAlert = true            }
        }
    }

    func openAppSettings() {
        AppSettingsHelper.openAppSettings()
    }

    // MARK: - Private Methods

    private func updateFormFields(from preferences: UserPreferences) {
        selectedHour = preferences.dailyNotificationTime.hour ?? AppConstants.UserPreferences.defaultNotificationHour
        selectedMinute = preferences.dailyNotificationTime.minute ?? AppConstants.UserPreferences.defaultNotificationMinute
        expiryReminderLeadDays = preferences.expiryReminderLeadDays
        regularCheckFrequency = preferences.regularCheck
    }

    private func validateForm() -> Bool {
        // Validate hour
        if !AppConstants.Validation.hourRange.contains(selectedHour) {
            errorMessage = "Hour must be between \(AppConstants.Validation.hourRange.lowerBound) and \(AppConstants.Validation.hourRange.upperBound)"
            return false
        }

        // Validate minute
        if !AppConstants.Validation.minuteRange.contains(selectedMinute) {
            errorMessage = "Minute must be between \(AppConstants.Validation.minuteRange.lowerBound) and \(AppConstants.Validation.minuteRange.upperBound)"
            return false
        }

        // Validate expiry reminder lead days
        if !AppConstants.Validation.expiryReminderLeadDaysRange.contains(expiryReminderLeadDays) {
            errorMessage = "Reminder lead time must be between \(AppConstants.Validation.expiryReminderLeadDaysRange.lowerBound) and \(AppConstants.Validation.expiryReminderLeadDaysRange.upperBound) days"
            return false
        }

        return true
    }

    // MARK: - Helper Methods
    func regularCheckFrequencyDescription(_ frequency: RegularCheckFrequency) -> LocalizedStringResource {
        switch frequency {
        case .quarterly:
            return "Quarterly"
        case .halfYearly:
            return "Half-Yearly"
        case .yearly:
            return "Yearly"
        }
    }

    func expiryReminderDescription() -> LocalizedStringResource {
        return "Remind me \(expiryReminderLeadDays) days before items expire"
    }
}
