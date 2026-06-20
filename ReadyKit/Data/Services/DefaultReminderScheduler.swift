//
//  DefaultReminderScheduler.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/14.
//

import UserNotifications
import SwiftUI

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

    // MARK: - ReminderScheduler protocol

    func removeNonSnoozePendingReminders() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        let identifiers = requests.map { $0.identifier }
            .filter { $0 != AppConstants.Notification.RequestIdentifier.snoozedRegularCheck }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    @MainActor func scheduleReminders() -> ReminderSchedulerResult {
        let result = loadUserPreferencesUseCase.execute()
        switch result {
        case .failure(let error):
            return .failure(DefaultReminderSchedulerError.failedToLoadPreferences(error))
        case .success(let userPreferences):
            do {
                let expiringCount = try repository.countExpiring(within: userPreferences.expiryReminderLeadDays)
                let expiredCount = try repository.countExpired()

                if expiringCount > 0 || expiredCount > 0 {
                    schedulePersistentExpiryReminder(userPreferences: userPreferences)
                } else {
                    // Fetch once here and pass down — avoids a redundant DB read inside scheduleExpiryBatch
                    let earliestExpiration = try repository.fetchItemWithEarliestExpiration()?.expirationDate
                    scheduleExpiryBatch(userPreferences: userPreferences, earliestExpiration: earliestExpiration)
                }

                scheduleRegularCheckReminder(with: userPreferences)
            } catch {
                return .failure(DefaultReminderSchedulerError.failedToScheduleReminders(error))
            }
            return .success(())
        }
    }

    /// Schedules a persistent daily repeating expiry reminder at the user's preferred notification
    /// time. Because the trigger uses `repeats: true` with only hour/minute components, the
    /// pending request is never consumed on delivery — swiping the delivered notification does not
    /// remove it from the queue, so it fires again the next day without any app code running.
    ///
    /// Also called by `NotificationDelegate` when the user taps "Keep reminding me" on a batch
    /// notification, transitioning from Path A to Path B mid-cycle.
    func schedulePersistentExpiryReminder(userPreferences: UserPreferences) {
        let content = buildExpiryNotificationContent(
            categoryIdentifier: AppConstants.Notification.CategoryIdentifier.persistentExpiryReminder
        )
        content.interruptionLevel = .timeSensitive

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: userPreferences.dailyNotificationTime,
            repeats: true)
        let request = UNNotificationRequest(
            identifier: AppConstants.Notification.RequestIdentifier.persistentExpiryReminder,
            content: content,
            trigger: trigger)
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.logger.logError("Failed to schedule persistent expiry reminder: \(error.localizedDescription)")
            } else {
                let h = userPreferences.dailyNotificationTime.hour ?? 0
                let m = userPreferences.dailyNotificationTime.minute ?? 0
                self?.logger.logInfo("Scheduled persistent expiry reminder (repeats daily at \(h):\(String(format: "%02d", m)))")
            }
        }
    }

    // MARK: - Notification categories

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

        // Batch: "Keep reminding me" transitions to the persistent reminder;
        // "Open App" foreground-launches the app for direct resolution.
        let keepRemindingMeAction = UNNotificationAction(
            identifier: AppConstants.Notification.ActionIdentifier.keepRemindingMe,
            title: String(localized: "Keep reminding me", comment: "Action to establish a daily repeating expiry reminder"),
            options: []
        )
        let expiryBatchCategory = UNNotificationCategory(
            identifier: AppConstants.Notification.CategoryIdentifier.expiryBatch,
            actions: [keepRemindingMeAction, makeOpenAppAction()],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Persistent: "Open App" only — "Keep reminding me" is redundant since the trigger repeats daily.
        let expiryPersistentCategory = UNNotificationCategory(
            identifier: AppConstants.Notification.CategoryIdentifier.persistentExpiryReminder,
            actions: [makeOpenAppAction()],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        notificationCenter.setNotificationCategories([
            regularCheckCategory,
            expiryBatchCategory,
            expiryPersistentCategory,
        ])
    }

    // MARK: - Path A: expiry batch (items beyond lead window)

    /// Schedules up to `ExpiryBatch.size` one-shot notifications starting on the first day the
    /// earliest item enters its lead window. Swipe-safe: if the user swipes one, the next day's is
    /// still pending. Tapping "Keep reminding me" cancels the batch and establishes the persistent
    /// reminder (see `NotificationDelegate`).
    ///
    /// `earliestExpiration` is fetched by the caller (`scheduleReminders`) to avoid an extra DB read.
    private func scheduleExpiryBatch(userPreferences: UserPreferences, earliestExpiration: Date?) {
        guard
            let earliestExpiration = earliestExpiration,
            earliestExpiration > Date(),
            let startDate = Calendar.current.date(
                byAdding: .day,
                value: -userPreferences.expiryReminderLeadDays,
                to: earliestExpiration),
            startDate > Date()
        else {
            logger.logInfo("No future items beyond the lead window; skipping expiry batch scheduling.")
            return
        }

        for i in 0..<AppConstants.Notification.ExpiryBatch.size {
            guard let batchDate = Calendar.current.date(byAdding: .day, value: i, to: startDate) else { continue }

            var components = Calendar.current.dateComponents([.year, .month, .day], from: batchDate)
            components.hour = userPreferences.dailyNotificationTime.hour
            components.minute = userPreferences.dailyNotificationTime.minute
            components.timeZone = userPreferences.dailyNotificationTime.timeZone ?? .current

            let content = buildExpiryNotificationContent(
                categoryIdentifier: AppConstants.Notification.CategoryIdentifier.expiryBatch
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = AppConstants.Notification.expiryBatchIdentifier(for: i)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            notificationCenter.add(request) { [weak self] error in
                if let error = error {
                    self?.logger.logError("Failed to schedule expiry batch[\(i)]: \(error.localizedDescription)")
                } else {
                    self?.logger.logInfo("Scheduled expiry batch[\(i)] for \(batchDate)")
                }
            }
        }

        if let lastChanceDate = Calendar.current.date(byAdding: .day, value: -1, to: earliestExpiration),
           lastChanceDate > Date() {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: lastChanceDate)
            components.hour = userPreferences.dailyNotificationTime.hour
            components.minute = userPreferences.dailyNotificationTime.minute
            components.timeZone = userPreferences.dailyNotificationTime.timeZone ?? .current

            let content = buildExpiryNotificationContent(
                categoryIdentifier: AppConstants.Notification.CategoryIdentifier.expiryBatch
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: AppConstants.Notification.RequestIdentifier.expiryLastChance,
                content: content,
                trigger: trigger
            )
            notificationCenter.add(request) { [weak self] error in
                if let error = error {
                    self?.logger.logError("Failed to schedule expiry last-chance: \(error.localizedDescription)")
                } else {
                    self?.logger.logInfo("Scheduled expiry last-chance for \(lastChanceDate)")
                }
            }
        }
    }

    // MARK: - Regular check reminder

    private func scheduleRegularCheckReminder(with userPreferences: UserPreferences) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Emergency Items Regular Check Reminder", comment: "Title for emergency items regular check reminder notification")
        content.body = String(localized: "⏰ It's time to check your emergency items!", comment: "Body for emergency items regular check reminder notification")
        content.sound = .default
        content.categoryIdentifier = AppConstants.Notification.CategoryIdentifier.regularCheck

        let months: [Int]
        switch userPreferences.regularCheck {
        case .quarterly:  months = AppConstants.Notification.RegularCheck.quarterlyMonths
        case .halfYearly: months = AppConstants.Notification.RegularCheck.halfYearlyMonths
        case .yearly:     months = [AppConstants.Notification.RegularCheck.yearlyMonth]
        }

        for (index, month) in months.enumerated() {
            var components = DateComponents()
            components.month = month
            components.day = 1
            components.hour = userPreferences.dailyNotificationTime.hour
            components.minute = userPreferences.dailyNotificationTime.minute
            components.timeZone = TimeZone.current

            // repeats: true — fires annually on month/day (no year component), so quarterly and
            // half-yearly reminders recur every year without requiring an app open to reschedule.
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(AppConstants.Notification.RequestIdentifier.regularCheckPrefix)\(index)",
                content: content,
                trigger: trigger)
            notificationCenter.add(request) { [weak self] error in
                if let error = error {
                    self?.logger.logError("Failed to schedule regular check reminder [\(index)]: \(error.localizedDescription)")
                } else {
                    let h = userPreferences.dailyNotificationTime.hour ?? 0
                    let m = userPreferences.dailyNotificationTime.minute ?? 0
                    self?.logger.logInfo("Scheduled regular check reminder [\(index)] for month \(month) at \(h):\(String(format: "%02d", m))")
                }
            }
        }
    }

    // MARK: - Private helpers

    private func buildExpiryNotificationContent(categoryIdentifier: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Expiring items detected",
                               comment: "Expiry notification title")
        content.body = String(localized: "⚠️Expiring/Expired items detected. Please check your emergency kits.",
                              comment: "Expiry notification body")
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        return content
    }

    private func makeOpenAppAction() -> UNNotificationAction {
        UNNotificationAction(
            identifier: AppConstants.Notification.ActionIdentifier.openApp,
            title: String(localized: "Open App", comment: "Action to open the app and review expiring items"),
            options: [.foreground]
        )
    }
}
