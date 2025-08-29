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
    private let logger: Logger

    init(reminderScheduler: ReminderScheduler, logger: Logger = DefaultLogger.shared) {
        self.reminderScheduler = reminderScheduler
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

        // Leverage UNNotificationDismissActionIdentifier to detect dismissal of regular check and expiring item reminder
        // and then reschedule reminders accordingly
        if (identifier.hasPrefix(AppConstants.Notification.RequestIdentifier.regularCheckPrefix)
            || identifier == AppConstants.Notification.RequestIdentifier.expiringItemsReminder
            || identifier == AppConstants.Notification.RequestIdentifier.earliestExpiringItemAlert)
            && actionIdentifier == UNNotificationDismissActionIdentifier {
            logger.logInfo("User dismissed the notification")
            let removeReminderResult = reminderScheduler.removeNonSnoozePendingReminders()
            switch removeReminderResult {
            case .success:
                logger.logInfo("Successfully removed non-snooze pending reminders")
            case .failure(let error):
                logger.logError("Failed to remove non-snooze pending reminders: \(error.localizedDescription)")
            }
            let scheduleReminderResult = reminderScheduler.scheduleReminders()
            switch scheduleReminderResult {
            case .success:
                logger.logInfo("Successfully scheduled reminders after dismissal")
            case .failure(let error):
                logger.logError("Failed to schedule reminders after dismissal: \(error.localizedDescription)")
            }
        }

        // handling regular check snooze action
        if identifier.hasPrefix(AppConstants.Notification.RequestIdentifier.regularCheckPrefix) || identifier == AppConstants.Notification.RequestIdentifier.snoozedRegularCheck {
            switch actionIdentifier {
            case AppConstants.Notification.ActionIdentifier.snoozeADay:
                scheduleSnoozeNotification(originalIdentifier: identifier,
                                           snoozeInterval: AppConstants.Notification.RegularCheck.snoozeIntervalADay)
            case AppConstants.Notification.ActionIdentifier.snoozeAnHour:
                scheduleSnoozeNotification(originalIdentifier: identifier,
                                           snoozeInterval: AppConstants.Notification.RegularCheck.snoozeIntervalAnHour)
            default:
                logger.logInfo("Unknown action for regular check notification: \(actionIdentifier)")
            }
        } else if actionIdentifier == UNNotificationDefaultActionIdentifier {
            logger.logInfo("User tapped notification (default action)")
            // Handle default tap action here if needed
        } else {
            logger.logInfo("Unhandled notification interaction")
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

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                self?.logger.logError("Failed to schedule snoozed notification: \(error.localizedDescription)")
            } else {
                self?.logger.logInfo("Scheduled snoozed notification with identifier: \(snoozeIdentifier)")
            }
        }
    }
}
