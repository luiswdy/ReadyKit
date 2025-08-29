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

        if identifier.hasPrefix("regularCheckReminder") && response.actionIdentifier == "SNOOZE_ACTION" {
            logger.logInfo("User snoozed regular check reminder")
            scheduleSnoozeNotification(originalIdentifier: identifier)
        } else if actionIdentifier == UNNotificationDefaultActionIdentifier {
            logger.logInfo("User tapped notification (default action)")
            // Handle default tap action here if needed
        } else {
            logger.logInfo("Unhandled notification interaction")
        }

        completionHandler()
    }

    private func scheduleSnoozeNotification(originalIdentifier: String) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Emergency Items Regular Check Reminder", comment: "Title for emergency items regular check reminder notification")
        content.body = String(localized: "⏰ It's time to check your emergency items!", comment: "Body for emergency items regular check reminder notification")
        content.sound = .default
        content.categoryIdentifier = "REGULAR_CHECK_CATEGORY"

        // Schedule for 24 hours from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)

        let snoozeIdentifier = "\(originalIdentifier)-snoozed-\(Date().timeIntervalSince1970)"
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
