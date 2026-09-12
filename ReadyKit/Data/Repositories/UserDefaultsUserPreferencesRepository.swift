//
//  UserDefaultsUserPreferencesRepository.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/13.
//

import Foundation

final class UserDefaultsUserPreferencesRepository: UserPreferencesRepository {
    private let userDefaults: UserDefaults
    private let preferencesKey = AppConstants.UserDefaultUserPreferencesKey.userPreferencesKey
    private let logger: Logger

    init(userDefaults: UserDefaults = .standard, logger: Logger = DefaultLogger.shared) {
        self.userDefaults = userDefaults
        self.logger = logger
    }

    func load() -> UserPreferences {
        let defaultPreferences = UserPreferences(
            dailyNotificationTime: DateComponents(
                timeZone: .current,
                hour: AppConstants.UserPreferences.defaultNotificationHour,
                minute: AppConstants.UserPreferences.defaultNotificationMinute,
                second: AppConstants.UserPreferences.defaultNotificationSecond
            ),
            expiryReminderLeadDays: AppConstants.UserPreferences.defaultExpiryReminderLeadDays,
            regularCheck: AppConstants.UserPreferences.defaultRegularCheckFrequency
        )
        
        guard let data = userDefaults.data(forKey: preferencesKey) else {
            return defaultPreferences
        }
        do {
            return try JSONDecoder().decode(UserPreferences.self, from: data)
        } catch {
            // Visible in release builds too — the user silently reverts to defaults otherwise.
            logger.logError("Failed to decode UserPreferences from UserDefaults; falling back to defaults: \(error)")
            assertionFailure("Failed to decode UserPreferences from UserDefaults: \(error)")
            return defaultPreferences
        }
    }

    func save(_ preferences: UserPreferences) throws {
        let data = try JSONEncoder().encode(preferences)
        userDefaults.set(data, forKey: preferencesKey)
    }
}
