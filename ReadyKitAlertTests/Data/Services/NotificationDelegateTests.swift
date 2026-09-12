//
//  NotificationDelegateTests.swift
//  ReadyKitTests
//
//  Created by Luis Wu on 2026/7/12.
//

import Foundation
import Testing
import UserNotifications
@testable import ReadyKit

@MainActor
struct NotificationDelegateTests {

    private let reminderScheduler = MockReminderScheduler()
    private let userPreferencesRepository = MockUserPreferencesRepository()
    private let notificationCenter = MockUserNotificationCenter()
    private let logger = MockLogger()

    private func makeDelegate() -> NotificationDelegate {
        NotificationDelegate(
            reminderScheduler: reminderScheduler,
            loadUserPreferencesUseCase: LoadUserPreferencesUseCase(userPreferencesRepository: userPreferencesRepository),
            notificationCenter: notificationCenter,
            logger: logger
        )
    }

    // Regular-check dismiss → full reschedule so the pending set stays accurate.
    @Test func regularCheckDismissalTriggersReschedule() async {
        let delegate = makeDelegate()

        await delegate.handleResponse(
            identifier: "\(AppConstants.Notification.RequestIdentifier.regularCheckPrefix)0",
            actionIdentifier: UNNotificationDismissActionIdentifier)

        #expect(reminderScheduler.removePendingRemindersCalled)
        #expect(reminderScheduler.scheduleRemindersCalled)
    }

    // Snooze actions → one-shot time-interval trigger with the snoozed identifier.
    @Test(arguments: [
        (AppConstants.Notification.ActionIdentifier.snoozeAnHour, AppConstants.Notification.RegularCheck.snoozeIntervalAnHour),
        (AppConstants.Notification.ActionIdentifier.snoozeADay, AppConstants.Notification.RegularCheck.snoozeIntervalADay),
    ])
    func snoozeActionSchedulesSnoozedNotification(actionIdentifier: String, expectedInterval: TimeInterval) async throws {
        let delegate = makeDelegate()

        await delegate.handleResponse(
            identifier: "\(AppConstants.Notification.RequestIdentifier.regularCheckPrefix)1",
            actionIdentifier: actionIdentifier)

        let snoozed = try #require(notificationCenter.pendingRequests.first {
            $0.identifier == AppConstants.Notification.RequestIdentifier.snoozedRegularCheck
        })
        let trigger = try #require(snoozed.trigger as? UNTimeIntervalNotificationTrigger)
        #expect(trigger.timeInterval == expectedInterval)
        #expect(!trigger.repeats)
    }

    // Snoozing an already-snoozed notification works the same way.
    @Test func snoozeFromSnoozedNotificationReschedules() async {
        let delegate = makeDelegate()

        await delegate.handleResponse(
            identifier: AppConstants.Notification.RequestIdentifier.snoozedRegularCheck,
            actionIdentifier: AppConstants.Notification.ActionIdentifier.snoozeAnHour)

        #expect(notificationCenter.pendingRequests.map(\.identifier) == [AppConstants.Notification.RequestIdentifier.snoozedRegularCheck])
    }

    // "Keep reminding me" (from any expiry one-shot) → cancel the whole one-shot chain
    // and establish the persistent daily reminder with the loaded preferences.
    @Test(arguments: [
        AppConstants.Notification.expiryBatchIdentifier(for: 1),
        AppConstants.Notification.expiredFallbackIdentifier(for: 3),
        AppConstants.Notification.RequestIdentifier.expiryLastChance,
    ])
    func keepRemindingMeTransitionsToPersistentReminder(identifier: String) async {
        let prefs = TestDataFactory.createCustomUserPreferences(notificationHour: 8, notificationMinute: 15)
        userPreferencesRepository.setStoredPreferences(prefs)
        let delegate = makeDelegate()

        await delegate.handleResponse(
            identifier: identifier,
            actionIdentifier: AppConstants.Notification.ActionIdentifier.keepRemindingMe)

        #expect(notificationCenter.removedIdentifiers == AppConstants.Notification.allExpiryRequestIdentifiers)
        #expect(reminderScheduler.schedulePersistentExpiryReminderCalled)
        #expect(reminderScheduler.persistentExpiryReminderPreferences?.dailyNotificationTime.hour == 8)
        #expect(reminderScheduler.persistentExpiryReminderPreferences?.dailyNotificationTime.minute == 15)
    }

    // Default tap / unknown action → nothing scheduled or removed.
    @Test func defaultTapDoesNothing() async {
        let delegate = makeDelegate()

        await delegate.handleResponse(
            identifier: AppConstants.Notification.RequestIdentifier.persistentExpiryReminder,
            actionIdentifier: UNNotificationDefaultActionIdentifier)

        #expect(notificationCenter.pendingRequests.isEmpty)
        #expect(notificationCenter.removedIdentifiers.isEmpty)
        #expect(!reminderScheduler.scheduleRemindersCalled)
        #expect(!reminderScheduler.schedulePersistentExpiryReminderCalled)
    }

    // Snooze add failure → logged, no crash.
    @Test func snoozeAddFailureIsLogged() async {
        notificationCenter.shouldFailToSchedule = true
        let delegate = makeDelegate()

        await delegate.handleResponse(
            identifier: "\(AppConstants.Notification.RequestIdentifier.regularCheckPrefix)0",
            actionIdentifier: AppConstants.Notification.ActionIdentifier.snoozeADay)

        #expect(logger.getLogCount(for: "error") > 0)
        #expect(notificationCenter.pendingRequests.isEmpty)
    }
}
