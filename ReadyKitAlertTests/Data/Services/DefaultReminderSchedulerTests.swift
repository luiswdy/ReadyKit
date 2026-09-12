//
//  DefaultReminderSchedulerTests.swift
//  ReadyKitTests
//
//  Created by Luis Wu on 2026/7/12.
//

import Foundation
import Testing
import UserNotifications
@testable import ReadyKit

@MainActor
struct DefaultReminderSchedulerTests {

    private let itemRepository = MockItemRepository()
    private let userPreferencesRepository = MockUserPreferencesRepository()
    private let notificationCenter = MockUserNotificationCenter()
    private let logger = MockLogger()

    private func makeScheduler() -> DefaultReminderScheduler {
        DefaultReminderScheduler(
            repository: itemRepository,
            notificationCenter: notificationCenter,
            userPreferencesRepository: userPreferencesRepository,
            logger: logger
        )
    }

    // MARK: - Path selection

    @Test func expiringItemSchedulesPersistentReminderOnly() throws {
        itemRepository.addItem(try TestDataFactory.createExpiringItem(daysUntilExpiration: 7))
        let scheduler = makeScheduler()

        let result = scheduler.scheduleReminders()

        #expect((try? result.get()) != nil)
        #expect(notificationCenter.hasPendingRequest(withIdentifier: AppConstants.Notification.RequestIdentifier.persistentExpiryReminder))
        #expect(!notificationCenter.hasPendingRequest(withIdentifier: AppConstants.Notification.expiryBatchIdentifier(for: 0)))
        #expect(!notificationCenter.hasPendingRequest(withIdentifier: AppConstants.Notification.expiredFallbackIdentifier(for: 0)))

        let persistent = try #require(notificationCenter.pendingRequests.first {
            $0.identifier == AppConstants.Notification.RequestIdentifier.persistentExpiryReminder
        })
        let trigger = try #require(persistent.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.repeats)
        let prefs = userPreferencesRepository.load()
        #expect(trigger.dateComponents.hour == prefs.dailyNotificationTime.hour)
        #expect(trigger.dateComponents.minute == prefs.dailyNotificationTime.minute)
    }

    @Test func expiredItemSchedulesPersistentReminder() throws {
        itemRepository.addItem(try TestDataFactory.createExpiredItem(daysExpired: 3))
        let scheduler = makeScheduler()

        let result = scheduler.scheduleReminders()

        #expect((try? result.get()) != nil)
        #expect(notificationCenter.hasPendingRequest(withIdentifier: AppConstants.Notification.RequestIdentifier.persistentExpiryReminder))
        // Delivered expiry notifications must NOT be cleared while items still need attention.
        #expect(notificationCenter.removedDeliveredIdentifiers.isEmpty)
    }

    @Test func futureItemBeyondLeadWindowSchedulesOneShotChain() throws {
        // 40 days out with default leadDays 30 → deterministic full chain regardless of time of day.
        itemRepository.addItem(try TestDataFactory.createExpiringItem(daysUntilExpiration: 40))
        let scheduler = makeScheduler()

        let result = scheduler.scheduleReminders()

        #expect((try? result.get()) != nil)
        for i in 0..<AppConstants.Notification.ExpiryBatch.size {
            #expect(notificationCenter.hasPendingRequest(withIdentifier: AppConstants.Notification.expiryBatchIdentifier(for: i)))
        }
        #expect(notificationCenter.hasPendingRequest(withIdentifier: AppConstants.Notification.RequestIdentifier.expiryLastChance))
        for j in 0..<AppConstants.Notification.ExpiredFallback.size {
            #expect(notificationCenter.hasPendingRequest(withIdentifier: AppConstants.Notification.expiredFallbackIdentifier(for: j)))
        }
        #expect(!notificationCenter.hasPendingRequest(withIdentifier: AppConstants.Notification.RequestIdentifier.persistentExpiryReminder))

        // One-shot triggers only.
        let expiryRequests = notificationCenter.pendingRequests.filter {
            AppConstants.Notification.allExpiryRequestIdentifiers.contains($0.identifier)
        }
        #expect(expiryRequests.allSatisfy { ($0.trigger as? UNCalendarNotificationTrigger)?.repeats == false })
    }

    @Test func noExpiringOrExpiredItemsClearsDeliveredExpiryNotifications() throws {
        itemRepository.addItem(try TestDataFactory.createExpiringItem(daysUntilExpiration: 40))
        let scheduler = makeScheduler()

        _ = scheduler.scheduleReminders()

        #expect(notificationCenter.removedDeliveredIdentifiers == AppConstants.Notification.allExpiryRequestIdentifiers)
    }

    @Test func noItemsWithExpirationSchedulesOnlyRegularChecks() throws {
        itemRepository.addItem(try TestDataFactory.createItemWithoutExpiration())
        let scheduler = makeScheduler()

        let result = scheduler.scheduleReminders()

        #expect((try? result.get()) != nil)
        let identifiers = notificationCenter.pendingRequests.map(\.identifier)
        #expect(identifiers.allSatisfy { $0.hasPrefix(AppConstants.Notification.RequestIdentifier.regularCheckPrefix) })
        #expect(!identifiers.isEmpty)
    }

    // MARK: - Regular check reminders

    @Test(arguments: [
        (RegularCheckFrequency.quarterly, AppConstants.Notification.RegularCheck.quarterlyMonths),
        (RegularCheckFrequency.halfYearly, AppConstants.Notification.RegularCheck.halfYearlyMonths),
        (RegularCheckFrequency.yearly, [AppConstants.Notification.RegularCheck.yearlyMonth]),
    ])
    func regularCheckFrequencySchedulesAnnualRepeatingTriggers(frequency: RegularCheckFrequency, expectedMonths: [Int]) throws {
        userPreferencesRepository.setStoredPreferences(
            TestDataFactory.createCustomUserPreferences(regularCheck: frequency)
        )
        let scheduler = makeScheduler()

        _ = scheduler.scheduleReminders()

        let regularChecks = notificationCenter.pendingRequests.filter {
            $0.identifier.hasPrefix(AppConstants.Notification.RequestIdentifier.regularCheckPrefix)
        }
        #expect(regularChecks.count == expectedMonths.count)

        let triggers = regularChecks.compactMap { $0.trigger as? UNCalendarNotificationTrigger }
        #expect(triggers.compactMap(\.dateComponents.month).sorted() == expectedMonths.sorted())
        #expect(triggers.allSatisfy { $0.repeats })
        #expect(triggers.allSatisfy { $0.dateComponents.day == 1 })
        #expect(triggers.allSatisfy { $0.dateComponents.timeZone == TimeZone.current })
    }

    // MARK: - Pending request removal

    @Test func removeNonSnoozePendingRemindersPreservesSnoozedRequest() async throws {
        let scheduler = makeScheduler()
        let content = UNMutableNotificationContent()
        notificationCenter.seedPendingRequest(UNNotificationRequest(
            identifier: AppConstants.Notification.RequestIdentifier.snoozedRegularCheck,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)))
        notificationCenter.seedPendingRequest(UNNotificationRequest(
            identifier: AppConstants.Notification.expiryBatchIdentifier(for: 0),
            content: content,
            trigger: nil))
        notificationCenter.seedPendingRequest(UNNotificationRequest(
            identifier: "\(AppConstants.Notification.RequestIdentifier.regularCheckPrefix)0",
            content: content,
            trigger: nil))

        await scheduler.removeNonSnoozePendingReminders()

        #expect(notificationCenter.pendingRequests.map(\.identifier) == [AppConstants.Notification.RequestIdentifier.snoozedRegularCheck])
    }

    // MARK: - Failure handling

    @Test func addFailureIsLoggedButSchedulingStillSucceeds() throws {
        itemRepository.addItem(try TestDataFactory.createExpiringItem(daysUntilExpiration: 7))
        notificationCenter.shouldFailToSchedule = true
        let scheduler = makeScheduler()

        let result = scheduler.scheduleReminders()

        #expect((try? result.get()) != nil) // fire-and-forget contract: add errors are logged, not returned
        #expect(logger.getLogCount(for: "error") > 0)
    }

    // MARK: - Category registration

    @Test func initRegistersAllNotificationCategories() {
        _ = makeScheduler()

        let identifiers = Set(notificationCenter.registeredCategories.map(\.identifier))
        #expect(identifiers == [
            AppConstants.Notification.CategoryIdentifier.regularCheck,
            AppConstants.Notification.CategoryIdentifier.expiryBatch,
            AppConstants.Notification.CategoryIdentifier.persistentExpiryReminder,
        ])

        let expiryBatch = notificationCenter.registeredCategories.first {
            $0.identifier == AppConstants.Notification.CategoryIdentifier.expiryBatch
        }
        #expect(expiryBatch?.actions.map(\.identifier) == [
            AppConstants.Notification.ActionIdentifier.keepRemindingMe,
            AppConstants.Notification.ActionIdentifier.openApp,
        ])
    }
}

// MARK: - Background task constant regression (B1)

struct BackgroundModeConstantsTests {
    /// `earliestBeginDate` must be computed per access — a stored `let` freezes the date
    /// at first use and every later background-task submission reuses the stale timestamp.
    @Test func earliestBeginDateIsComputedPerAccess() async throws {
        let first = AppConstants.BackgroundMode.earliestBeginDate
        #expect(abs(first.timeIntervalSinceNow - 24 * 60 * 60) < 5)

        try await Task.sleep(for: .milliseconds(1100))

        let second = AppConstants.BackgroundMode.earliestBeginDate
        #expect(second > first)
        #expect(abs(second.timeIntervalSinceNow - 24 * 60 * 60) < 5)
    }
}
