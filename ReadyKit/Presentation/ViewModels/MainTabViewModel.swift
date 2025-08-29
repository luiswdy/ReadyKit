//
//  MainTabViewModel.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/14/25.
//

import Foundation
import SwiftUI

/// Root app state management ViewModel
@Observable
@MainActor
class MainTabViewModel {

    // MARK: - Dependencies
    private let dependencyContainer: DependencyContainer

    // MARK: - State
    var isLoading = false
    var errorMessage: LocalizedStringKey?
    var userPreferences: UserPreferences?
    var notificationPermission: NotificationPermission = .notGranted

    // MARK: - Initialization
    init(dependencyContainer : DependencyContainer) {
        self.dependencyContainer = dependencyContainer
        loadInitialData()
    }

    // MARK: - Public Methods
    func loadInitialData() {
        isLoading = true
        errorMessage = nil

        // Load user preferences
        let preferencesResult = dependencyContainer.loadUserPreferencesUseCase.execute()
        switch preferencesResult {
        case .success(let preferences):
            userPreferences = preferences
        case .failure:
            // Use default preferences
            userPreferences = UserPreferences(
                dailyNotificationTime: DateComponents(
                    hour: AppConstants.UserPreferences.defaultNotificationHour,
                    minute: AppConstants.UserPreferences.defaultNotificationMinute
                ),
                expiryReminderLeadDays: AppConstants.UserPreferences.defaultExpiryReminderLeadDays,
                regularCheck: AppConstants.UserPreferences.defaultRegularCheckFrequency
            )
        }

        // Check notification permission
        Task {
            notificationPermission = await dependencyContainer.checkNotificationPermissionUseCase.execute()
        }
        isLoading = false
    }

    func requestNotificationPermission() {
        Task {
            notificationPermission = await dependencyContainer.requestNotificationPermissionUseCase.execute()
            if notificationPermission == .granted {
                rescheduleReminders()
            }
        }
    }

    private func rescheduleReminders() {
        let result = dependencyContainer.rescheduleRemindersUseCase.execute()
        switch result {
        case .success:
            break // Success, no action needed
        case .failure(let error):
            errorMessage = "Failed to schedule reminders: \(error.localizedDescription)"
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
