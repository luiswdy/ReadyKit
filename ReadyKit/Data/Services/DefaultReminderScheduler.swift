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

    func removeNonSnoozePendingReminders() -> ReminderSchedulerResult {
        Task {
            let requests = await notificationCenter.pendingNotificationRequests()
            let identifiers = requests.map { $0.identifier }.filter { $0 != AppConstants.Notification.RequestIdentifier.snoozedRegularCheck }
            notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
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
                scheduleFirstExpiringItemAlert(userPreferences: userPreferences)
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
            options: [.customDismissAction]
        )

        let expiryReminderCategory = UNNotificationCategory(
            identifier: AppConstants.Notification.CategoryIdentifier.expiringItemsReminder,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let earliestExpiringItemAlertCategory = UNNotificationCategory(
            identifier: AppConstants.Notification.CategoryIdentifier.earliestExpiringItemAlert,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([regularCheckCategory, expiryReminderCategory, earliestExpiringItemAlertCategory])
    }

    private func scheduleFirstExpiringItemAlert(userPreferences: UserPreferences) {
        do {
            guard let earliestExpiration = try repository.fetchItemWithEarliestExpiration()?.expirationDate else {
                logger.logInfo("No items with expiration dates found; skipping first expiring item alert scheduling.")
                return
            }

            let now = Date()
            guard earliestExpiration > now && Calendar.current.date(byAdding: .day, value: -userPreferences.expiryReminderLeadDays, to: earliestExpiration)! > now else {
                logger.logInfo("Earliest expiring item is already expired or within lead time; skipping first expiring item alert scheduling.")
                return
            }

            // schedule for (earliestExpiration - lead time) at dailyNotificationTime
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: earliestExpiration)
            dateComponents.hour = userPreferences.dailyNotificationTime.hour
            dateComponents.minute = userPreferences.dailyNotificationTime.minute
            dateComponents.second = 0
            let leadTimeDate = Calendar.current.date(byAdding: .day, value: -userPreferences.expiryReminderLeadDays, to: earliestExpiration)!
            let leadTimeComponents = Calendar.current.dateComponents([.year, .month, .day], from: leadTimeDate)
            dateComponents.year = leadTimeComponents.year
            dateComponents.month = leadTimeComponents.month
            dateComponents.day = leadTimeComponents.day
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

            let content = UNMutableNotificationContent()
            content.title = String(localized: "Expiring items detected", comment: "Title for first expiring item alert notification")
            content.body = String(localized: "You have items that are expiring soon. Please open the app and check your emergency kit.", comment: "Body for first expiring item alert notification")
            content.sound = .default
            content.categoryIdentifier = AppConstants.Notification.CategoryIdentifier.earliestExpiringItemAlert

            let request = UNNotificationRequest(
                identifier: AppConstants.Notification.RequestIdentifier.earliestExpiringItemAlert,
                content: content,
                trigger: trigger
            )
            notificationCenter.add(request)
        } catch {
            logger.logError("Failed to fetch first expiring items: \(error.localizedDescription)")
        }
    }

    private func scheduleExpiringItemsReminder(with userPreferences: UserPreferences) throws {
        let content = UNMutableNotificationContent()
        let expiringItemCount = try repository.fetchExpiring(within: userPreferences.expiryReminderLeadDays).count
        let expiredItemCount = try repository.fetchExpired().count

        let summary = ItemSummaryFormatter.summaryMessage(expiringCount: expiringItemCount, expiredCount: expiredItemCount)
        content.title = String(localized: "Emergency Items Expiry Reminder", comment: "Title for emergency items expiry reminder notification")
        content.body = summary
        content.sound = .default
        content.badge = NSNumber(value: (expiringItemCount + expiredItemCount))
        content.categoryIdentifier = AppConstants.Notification.CategoryIdentifier.expiringItemsReminder

        // Ensure timezone is properly set for local time
        let dateComponents = userPreferences.dailyNotificationTime

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: AppConstants.Notification.RequestIdentifier.expiringItemsReminder,
            content: content,
            trigger: trigger)
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
            let request = UNNotificationRequest(
                identifier: "\(AppConstants.Notification.RequestIdentifier.regularCheckPrefix)\(index)",
                content: content,
                trigger: trigger)
            notificationCenter.add(request) { [weak self] errorOrNil in
                guard let self = self else { return }
                if let error = errorOrNil {
                    self.logger.logError("Failed to schedule regular check reminder with identifier: regularCheckReminder-\(index), error: \(error.localizedDescription)")
                } else {
                    self.logger.logInfo("Scheduled regular check reminder with identifier: \(AppConstants.Notification.RequestIdentifier.regularCheckPrefix)\(index)")
                }
            }
        }
    }
}
