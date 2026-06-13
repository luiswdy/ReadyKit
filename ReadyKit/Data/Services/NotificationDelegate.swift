//
//  NotificationDelegate.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/28.
//

import UserNotifications
import Foundation

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let reminderScheduler: ReminderScheduler
    private let loadUserPreferencesUseCase: LoadUserPreferencesUseCase
    private let notificationCenter: UNUserNotificationCenter
    private let logger: Logger

    init(reminderScheduler: ReminderScheduler,
         loadUserPreferencesUseCase: LoadUserPreferencesUseCase,
         notificationCenter: UNUserNotificationCenter = .current(),
         logger: Logger = DefaultLogger.shared) {
        self.reminderScheduler = reminderScheduler
        self.loadUserPreferencesUseCase = loadUserPreferencesUseCase
        self.notificationCenter = notificationCenter
        self.logger = logger
        super.init()
        logger.logInfo("NotificationDelegate initialized")
    }

    // Handle notification presentation when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        logger.logInfo("willPresent called for notification: \(notification.request.identifier)")
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification actions (like snooze)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        let actionIdentifier = response.actionIdentifier

        logger.logInfo("didReceive called - Notification ID: \(identifier), Action: \(actionIdentifier)")

        // Regular-check dismiss: reschedule so the pending set stays accurate.
        // (Expiry batch and persistent reminder are self-managing: batch has remaining one-shots
        // still pending, and the persistent reminder's repeating request survives swipe-away.)
        if identifier.hasPrefix(AppConstants.Notification.RequestIdentifier.regularCheckPrefix)
            && actionIdentifier == UNNotificationDismissActionIdentifier {
            logger.logInfo("User dismissed a regular-check notification; rescheduling.")
            // completionHandler is called inside the Task so iOS keeps the background
            // execution assertion alive until rescheduling finishes.
            Task { @MainActor in
                await reminderScheduler.removeNonSnoozePendingReminders()
                let result = reminderScheduler.scheduleReminders()
                if case .failure(let error) = result {
                    logger.logError("Failed to reschedule reminders after regular-check dismissal: \(error.localizedDescription)")
                }
                completionHandler()
            }
            return
        }

        // Regular check snooze actions
        if identifier.hasPrefix(AppConstants.Notification.RequestIdentifier.regularCheckPrefix)
            || identifier == AppConstants.Notification.RequestIdentifier.snoozedRegularCheck {
            switch actionIdentifier {
            case AppConstants.Notification.ActionIdentifier.snoozeADay:
                scheduleSnoozeNotification(originalIdentifier: identifier,
                                           snoozeInterval: AppConstants.Notification.RegularCheck.snoozeIntervalADay)
            case AppConstants.Notification.ActionIdentifier.snoozeAnHour:
                scheduleSnoozeNotification(originalIdentifier: identifier,
                                           snoozeInterval: AppConstants.Notification.RegularCheck.snoozeIntervalAnHour)
            default:
                break
            }
        }

        // "Keep reminding me" on a batch expiry notification:
        // cancel remaining batch one-shots and establish the persistent daily repeating reminder.
        // This transitions Path A → Path B so future deliveries survive swipe-away.
        if actionIdentifier == AppConstants.Notification.ActionIdentifier.keepRemindingMe {
            logger.logInfo("User tapped 'Keep reminding me'; transitioning to persistent expiry reminder.")
            let batchIdentifiers = (0..<AppConstants.Notification.ExpiryBatch.size).map {
                AppConstants.Notification.expiryBatchIdentifier(for: $0)
            }
            notificationCenter.removePendingNotificationRequests(withIdentifiers: batchIdentifiers)

            let prefsResult = loadUserPreferencesUseCase.execute()
            if case .success(let prefs) = prefsResult {
                reminderScheduler.schedulePersistentExpiryReminder(userPreferences: prefs)
                logger.logInfo("Persistent expiry reminder established after 'Keep reminding me' tap.")
            } else {
                logger.logError("Failed to load user preferences for persistent expiry reminder.")
            }
        }

        // "Open App" and default tap: iOS brings the app to the foreground via the .foreground
        // action option; ReadyKitApp.task handles rescheduling on appear.
        if actionIdentifier == UNNotificationDefaultActionIdentifier {
            logger.logInfo("User tapped notification body (default action).")
        }

        completionHandler()
    }

    private func scheduleSnoozeNotification(originalIdentifier: String, snoozeInterval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Emergency Items Regular Check Reminder", comment: "Title for emergency items regular check reminder notification")
        content.body = String(localized: "⏰ It's time to check your emergency items!", comment: "Body for emergency items regular check reminder notification")
        content.sound = .default
        content.categoryIdentifier = AppConstants.Notification.CategoryIdentifier.regularCheck

        // Schedule for `snoozeInternal` seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: snoozeInterval, repeats: false)

        let snoozeIdentifier = "\(AppConstants.Notification.RequestIdentifier.snoozedRegularCheck)"
        let request = UNNotificationRequest(identifier: snoozeIdentifier, content: content, trigger: trigger)

        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.logger.logError("Failed to schedule snoozed notification: \(error.localizedDescription)")
            } else {
                self?.logger.logInfo("Scheduled snoozed notification with identifier: \(snoozeIdentifier)")
            }
        }
    }
}
