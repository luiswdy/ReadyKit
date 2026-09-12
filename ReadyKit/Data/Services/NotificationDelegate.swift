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
    private let notificationCenter: UserNotificationCenter
    private let logger: Logger

    init(reminderScheduler: ReminderScheduler,
         loadUserPreferencesUseCase: LoadUserPreferencesUseCase,
         notificationCenter: UserNotificationCenter = UNUserNotificationCenter.current(),
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

    // Handle notification actions (like snooze). The async delegate variant is used so iOS
    // holds the background execution assertion until this method returns — every async
    // scheduling call below is guaranteed to commit before the process can be suspended.
    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse) async {
        await handleResponse(identifier: response.notification.request.identifier,
                             actionIdentifier: response.actionIdentifier)
    }

    // Internal seam for unit tests: a UNNotificationResponse cannot be constructed in tests.
    @MainActor
    func handleResponse(identifier: String, actionIdentifier: String) async {
        logger.logInfo("didReceive called - Notification ID: \(identifier), Action: \(actionIdentifier)")

        // Regular-check dismiss: reschedule so the pending set stays accurate.
        // (Expiry one-shots and persistent reminder are self-managing: the chain has remaining
        // one-shots still pending, and the persistent reminder's repeating request survives
        // swipe-away.)
        if identifier.hasPrefix(AppConstants.Notification.RequestIdentifier.regularCheckPrefix)
            && actionIdentifier == UNNotificationDismissActionIdentifier {
            logger.logInfo("User dismissed a regular-check notification; rescheduling.")
            await reminderScheduler.removeNonSnoozePendingReminders()
            let result = reminderScheduler.scheduleReminders()
            if case .failure(let error) = result {
                logger.logError("Failed to reschedule reminders after regular-check dismissal: \(error.localizedDescription)")
            }
            return
        }

        // Regular check snooze actions
        if identifier.hasPrefix(AppConstants.Notification.RequestIdentifier.regularCheckPrefix)
            || identifier == AppConstants.Notification.RequestIdentifier.snoozedRegularCheck {
            switch actionIdentifier {
            case AppConstants.Notification.ActionIdentifier.snoozeADay:
                await scheduleSnoozeNotification(snoozeInterval: AppConstants.Notification.RegularCheck.snoozeIntervalADay)
            case AppConstants.Notification.ActionIdentifier.snoozeAnHour:
                await scheduleSnoozeNotification(snoozeInterval: AppConstants.Notification.RegularCheck.snoozeIntervalAnHour)
            default:
                break
            }
        }

        // "Keep reminding me" on an expiry one-shot (batch, last-chance, or expired fallback):
        // cancel the remaining one-shots and establish the persistent daily repeating reminder.
        // This transitions Path A → Path B so future deliveries survive swipe-away.
        if actionIdentifier == AppConstants.Notification.ActionIdentifier.keepRemindingMe {
            logger.logInfo("User tapped 'Keep reminding me'; transitioning to persistent expiry reminder.")
            notificationCenter.removePendingNotificationRequests(
                withIdentifiers: AppConstants.Notification.allExpiryRequestIdentifiers
            )

            let prefsResult = loadUserPreferencesUseCase.execute()
            if case .success(let prefs) = prefsResult {
                await reminderScheduler.schedulePersistentExpiryReminder(userPreferences: prefs)
                logger.logInfo("Persistent expiry reminder established after 'Keep reminding me' tap.")
            } else {
                logger.logError("Failed to load user preferences for persistent expiry reminder.")
            }
        }

        // "Open App" and default tap: iOS brings the app to the foreground via the .foreground
        // action option; ReadyKitApp reschedules on scene activation.
        if actionIdentifier == UNNotificationDefaultActionIdentifier {
            logger.logInfo("User tapped notification body (default action).")
        }
    }

    private func scheduleSnoozeNotification(snoozeInterval: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Emergency Items Regular Check Reminder", comment: "Title for emergency items regular check reminder notification")
        content.body = String(localized: "⏰ It's time to check your emergency items!", comment: "Body for emergency items regular check reminder notification")
        content.sound = .default
        content.categoryIdentifier = AppConstants.Notification.CategoryIdentifier.regularCheck

        // Schedule for `snoozeInterval` seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: snoozeInterval, repeats: false)

        let snoozeIdentifier = AppConstants.Notification.RequestIdentifier.snoozedRegularCheck
        let request = UNNotificationRequest(identifier: snoozeIdentifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            logger.logInfo("Scheduled snoozed notification with identifier: \(snoozeIdentifier)")
        } catch {
            logger.logError("Failed to schedule snoozed notification: \(error.localizedDescription)")
        }
    }
}
