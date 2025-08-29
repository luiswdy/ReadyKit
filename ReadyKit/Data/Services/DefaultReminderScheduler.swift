//
//  DefaultReminderScheduler.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/14.
//

import UserNotifications
import SwiftUICore

enum DefaultReminderSchedulerError: Error {
    case failedToLoadPreferences(Error)
    case failedToScheduleReminders(Error)
}

final class DefaultReminderScheduler: ReminderScheduler {
    private let repository: ItemRepository
    private let notificationCenter: UNUserNotificationCenter
    private let loadUserPreferencesUseCase: LoadUserPreferencesUseCase
    private let saveUserPreferencesUseCase: SaveUserPreferencesUseCase
    private let logger: Logger

    init(repository: ItemRepository,
         notificationCenter: UNUserNotificationCenter = .current(),
         userPreferencesRepository: UserPreferencesRepository,
         logger: Logger = DefaultLogger.shared) {
        self.repository = repository
        self.notificationCenter = notificationCenter
        self.loadUserPreferencesUseCase = LoadUserPreferencesUseCase(userPreferencesRepository: userPreferencesRepository)
        self.saveUserPreferencesUseCase = SaveUserPreferencesUseCase(userPreferencesRepository: userPreferencesRepository)
        self.logger = logger

        registerNotificationCategories()
    }

    func removePendingReminders() -> ReminderSchedulerResult {
        notificationCenter.removeAllPendingNotificationRequests()
        return .success(())
    }

    func scheduleReminders() -> ReminderSchedulerResult {
        // Get current user preferences dynamically
        let result = loadUserPreferencesUseCase.execute()
        switch result {
        case .failure(let error):
            return .failure(DefaultReminderSchedulerError.failedToLoadPreferences(error))
        case .success(let userPreferences):
            do {
                try scheduleExpiringItemsReminder(with: userPreferences)
                scheduleRegularCheckReminder(with: userPreferences)
            } catch {
                return .failure(error)
            }
            return .success(())
        }
    }

    private func registerNotificationCategories() {
        let snoozeAnHourAction = UNNotificationAction(
            identifier: AppConstants.Notification.ActionIdentifier.snoozeAnHour,
            title: String(localized: "Snooze for an hour", comment: "Snooze button for notifications: an hour"),
            options: []
        )

        let snoozeADayAction = UNNotificationAction(
            identifier: AppConstants.Notification.ActionIdentifier.snoozeADay,
            title: String(localized: "Snooze for a day", comment: "Snooze button for notifications: a day"),
            options: []
        )

        let regularCheckCategory = UNNotificationCategory(
            identifier: AppConstants.Notification.CategoryIdentifier.regularCheck,
            actions: [snoozeAnHourAction, snoozeADayAction],
            intentIdentifiers: [],
            options: []
        )

        let expiringItemsCategory = UNNotificationCategory(
            identifier: AppConstants.Notification.CategoryIdentifier.expiringItems,
            actions: [snoozeAnHourAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([regularCheckCategory, expiringItemsCategory])
    }

    private func scheduleExpiringItemsReminder(with userPreferences: UserPreferences) throws -> Void {
        let content = UNMutableNotificationContent()
        let expiringItemCount = try repository.fetchExpiring(within: userPreferences.expiryReminderLeadDays).count
        let expiredItemCount = try repository.fetchExpired().count

        let summary = ItemSummaryFormatter.summaryMessage(expiringCount: expiringItemCount, expiredCount: expiredItemCount)
        content.title = String(localized: "Emergency Items Expiry Reminder", comment: "Title for emergency items expiry reminder notification")
        content.body = summary
        content.sound = .defaultCritical
        content.badge = NSNumber(value: (expiringItemCount + expiredItemCount))

        // Ensure timezone is properly set for local time
        var dateComponents = userPreferences.dailyNotificationTime
        dateComponents.timeZone = TimeZone.current // Explicitly set to current timezone

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "expiringItemsReminder", content: content, trigger: trigger)
        notificationCenter.add(request)
    }

    private func scheduleRegularCheckReminder(with userPreferences: UserPreferences) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Emergency Items Regular Check Reminder", comment: "Title for emergency items regular check reminder notification")
        content.body = String(localized: "⏰ It's time to check your emergency items!", comment: "Body for emergency items regular check reminder notification")
        content.sound = .default

        content.categoryIdentifier = AppConstants.Notification.CategoryIdentifier.regularCheck

        var dateComponentsList: [DateComponents] = []
        var triggers: [UNCalendarNotificationTrigger] = []

        switch userPreferences.regularCheck {
        case .quarterly:
            for month in AppConstants.Notification.RegularCheck.quarterlyMonths {
                var dateComponents = DateComponents()
                dateComponents.month = month
                dateComponents.day = 1
                dateComponents.hour = userPreferences.dailyNotificationTime.hour
                dateComponents.minute = userPreferences.dailyNotificationTime.minute
                dateComponents.timeZone = TimeZone.current
                dateComponentsList.append(dateComponents)
            }
            triggers = dateComponentsList.map { UNCalendarNotificationTrigger(dateMatching: $0, repeats: false) }
        case .halfYearly:
            for month in AppConstants.Notification.RegularCheck.halfYearlyMonths {
                var dateComponents = DateComponents()
                dateComponents.month = month
                dateComponents.day = 1
                dateComponents.hour = userPreferences.dailyNotificationTime.hour
                dateComponents.minute = userPreferences.dailyNotificationTime.minute
                dateComponents.timeZone = TimeZone.current
                dateComponentsList.append(dateComponents)
            }
            triggers = dateComponentsList.map { UNCalendarNotificationTrigger(dateMatching: $0, repeats: false) }
        case .yearly:
            var dateComponents = DateComponents()
            dateComponents.month = AppConstants.Notification.RegularCheck.yearlyMonth
            dateComponents.day = 1
            dateComponents.hour = userPreferences.dailyNotificationTime.hour
            dateComponents.minute = userPreferences.dailyNotificationTime.minute
            dateComponents.timeZone = TimeZone.current
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            triggers = [trigger]
        }
        for (index, trigger) in triggers.enumerated() {
            let request = UNNotificationRequest(identifier: "regularCheckReminder-\(index)", content: content, trigger: trigger)
            notificationCenter.add(request) { [weak self] errorOrNil in
                guard let self = self else { return }
                if let error = errorOrNil {
                    self.logger.logError("Failed to schedule regular check reminder with identifier: regularCheckReminder-\(index), error: \(error.localizedDescription)")
                } else {
                    self.logger.logInfo("Scheduled regular check reminder with identifier: regularCheckReminder-\(index)")
                }
            }
        }
    }
}
