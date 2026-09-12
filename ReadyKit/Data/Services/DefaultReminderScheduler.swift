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
    private let notificationCenter: UserNotificationCenter
    private let loadUserPreferencesUseCase: LoadUserPreferencesUseCase
    private let logger: Logger

    init(repository: ItemRepository,
         notificationCenter: UserNotificationCenter = UNUserNotificationCenter.current(),
         userPreferencesRepository: UserPreferencesRepository,
         logger: Logger = DefaultLogger.shared) {
        self.repository = repository
        self.notificationCenter = notificationCenter
        self.loadUserPreferencesUseCase = LoadUserPreferencesUseCase(userPreferencesRepository: userPreferencesRepository)
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
                    schedulePersistentExpiryReminderFireAndForget(userPreferences: userPreferences)
                } else {
                    // Nothing is expiring or expired: any previously delivered expiry
                    // notifications are stale — clear them from Notification Center.
                    notificationCenter.removeDeliveredNotifications(
                        withIdentifiers: AppConstants.Notification.allExpiryRequestIdentifiers
                    )
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
    func schedulePersistentExpiryReminder(userPreferences: UserPreferences) async {
        do {
            try await notificationCenter.add(makePersistentExpiryRequest(userPreferences: userPreferences))
            logPersistentExpiryScheduled(userPreferences: userPreferences)
        } catch {
            logger.logError("Failed to schedule persistent expiry reminder: \(error.localizedDescription)")
        }
    }

    /// Completion-based bridge for the synchronous `scheduleReminders()` path; the
    /// delegate's "Keep reminding me" path awaits the async variant instead so the
    /// request is committed before the background execution assertion is released.
    private func schedulePersistentExpiryReminderFireAndForget(userPreferences: UserPreferences) {
        notificationCenter.add(makePersistentExpiryRequest(userPreferences: userPreferences)) { [weak self] error in
            if let error = error {
                self?.logger.logError("Failed to schedule persistent expiry reminder: \(error.localizedDescription)")
            } else {
                self?.logPersistentExpiryScheduled(userPreferences: userPreferences)
            }
        }
    }

    private func makePersistentExpiryRequest(userPreferences: UserPreferences) -> UNNotificationRequest {
        let content = buildExpiryNotificationContent(
            categoryIdentifier: AppConstants.Notification.CategoryIdentifier.persistentExpiryReminder
        )
        content.interruptionLevel = .timeSensitive

        // Unified timezone policy: interpret the user's notification time in the
        // device's current timezone at scheduling time (see scheduleRegularCheckReminder).
        var timeComponents = DateComponents()
        timeComponents.hour = userPreferences.dailyNotificationTime.hour
        timeComponents.minute = userPreferences.dailyNotificationTime.minute
        timeComponents.second = userPreferences.dailyNotificationTime.second
        timeComponents.timeZone = TimeZone.current

        let trigger = UNCalendarNotificationTrigger(dateMatching: timeComponents, repeats: true)
        return UNNotificationRequest(
            identifier: AppConstants.Notification.RequestIdentifier.persistentExpiryReminder,
            content: content,
            trigger: trigger)
    }

    private func logPersistentExpiryScheduled(userPreferences: UserPreferences) {
        let h = userPreferences.dailyNotificationTime.hour ?? 0
        let m = userPreferences.dailyNotificationTime.minute ?? 0
        logger.logInfo("Scheduled persistent expiry reminder (repeats daily at \(h):\(String(format: "%02d", m)))")
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

    /// Schedules the one-shot Path A chain computed by `ExpiryReminderPlan`: up to
    /// `ExpiryBatch.size` batch notifications when the earliest item enters its lead window,
    /// a last-chance notification the day before expiry, and `ExpiredFallback.size` daily
    /// "expired" fallbacks from expiry day on — so the app is not silent after expiry even
    /// if it is never opened and the background task never runs. Swipe-safe: each one-shot
    /// is independent. Tapping "Keep reminding me" cancels the chain and establishes the
    /// persistent reminder (see `NotificationDelegate`).
    ///
    /// `earliestExpiration` is fetched by the caller (`scheduleReminders`) to avoid an extra DB read.
    private func scheduleExpiryBatch(userPreferences: UserPreferences, earliestExpiration: Date?) {
        guard let earliestExpiration = earliestExpiration else {
            logger.logInfo("No items with an expiration date; skipping expiry batch scheduling.")
            return
        }

        let plan = ExpiryReminderPlan.plan(
            earliestExpiration: earliestExpiration,
            leadDays: userPreferences.expiryReminderLeadDays,
            notificationHour: userPreferences.dailyNotificationTime.hour ?? AppConstants.UserPreferences.defaultNotificationHour,
            notificationMinute: userPreferences.dailyNotificationTime.minute ?? AppConstants.UserPreferences.defaultNotificationMinute
        )

        for (i, components) in plan.batchTriggers.enumerated() {
            addOneShotExpiryRequest(
                identifier: AppConstants.Notification.expiryBatchIdentifier(for: i),
                content: buildExpiryNotificationContent(
                    categoryIdentifier: AppConstants.Notification.CategoryIdentifier.expiryBatch
                ),
                components: components
            )
        }

        if let components = plan.lastChanceTrigger {
            addOneShotExpiryRequest(
                identifier: AppConstants.Notification.RequestIdentifier.expiryLastChance,
                content: buildExpiryNotificationContent(
                    categoryIdentifier: AppConstants.Notification.CategoryIdentifier.expiryBatch
                ),
                components: components
            )
        }

        for (j, components) in plan.fallbackTriggers.enumerated() {
            let content = buildExpiredFallbackContent()
            addOneShotExpiryRequest(
                identifier: AppConstants.Notification.expiredFallbackIdentifier(for: j),
                content: content,
                components: components
            )
        }
    }

    private func addOneShotExpiryRequest(identifier: String,
                                         content: UNMutableNotificationContent,
                                         components: DateComponents) {
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.logger.logError("Failed to schedule \(identifier): \(error.localizedDescription)")
            } else {
                self?.logger.logInfo("Scheduled \(identifier) for \(components)")
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
            // Unified timezone policy: the device's current timezone at scheduling time.
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

    private func buildExpiredFallbackContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Expired items in your kit",
                               comment: "Expired fallback notification title")
        content.body = String(localized: "⚠️ Items in your emergency kit have expired. Please replace them.",
                              comment: "Expired fallback notification body")
        content.sound = .default
        content.categoryIdentifier = AppConstants.Notification.CategoryIdentifier.expiryBatch
        content.interruptionLevel = .timeSensitive
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
