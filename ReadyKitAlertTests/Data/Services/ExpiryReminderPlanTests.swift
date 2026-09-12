//
//  ExpiryReminderPlanTests.swift
//  ReadyKitTests
//
//  Created by Luis Wu on 2026/7/12.
//

import Foundation
import Testing
@testable import ReadyKit

/// Pure tests over the Path A trigger planner: fixed `now`, fixed UTC calendar, no mocks.
struct ExpiryReminderPlanTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    // Case 1: nominal — full chain scheduled at the user's notification time.
    @Test func nominalPlanSchedulesBatchLastChanceAndFallbacks() {
        let now = date(2026, 1, 10)
        let expiry = date(2026, 2, 19) // 40 days out, leadDays 30 → window starts Jan 20

        let plan = ExpiryReminderPlan.plan(
            earliestExpiration: expiry, leadDays: 30,
            notificationHour: 9, notificationMinute: 30,
            now: now, calendar: calendar)

        #expect(plan.batchTriggers.count == AppConstants.Notification.ExpiryBatch.size)
        #expect(plan.batchTriggers.compactMap(\.day) == [20, 21, 22])
        #expect(plan.batchTriggers.allSatisfy { $0.month == 1 && $0.year == 2026 })

        #expect(plan.lastChanceTrigger?.month == 2)
        #expect(plan.lastChanceTrigger?.day == 18)

        #expect(plan.fallbackTriggers.count == AppConstants.Notification.ExpiredFallback.size)
        #expect(plan.fallbackTriggers.compactMap(\.day) == [19, 20, 21, 22, 23, 24, 25])
        #expect(plan.fallbackTriggers.allSatisfy { $0.month == 2 })

        let all = plan.batchTriggers + plan.fallbackTriggers + [plan.lastChanceTrigger!]
        #expect(all.allSatisfy { $0.hour == 9 && $0.minute == 30 })
    }

    // Case 2: lead window starts today but the notification time already passed → batch[0] dropped.
    @Test func batchStartingTodayAfterNotificationTimeDropsFirstTrigger() {
        let now = date(2026, 1, 10, 12, 0)
        let expiry = date(2026, 2, 9, 12, 0) // window starts Jan 10 (today)

        let plan = ExpiryReminderPlan.plan(
            earliestExpiration: expiry, leadDays: 30,
            notificationHour: 9, notificationMinute: 0, // 09:00 already passed at 12:00
            now: now, calendar: calendar)

        #expect(plan.batchTriggers.compactMap(\.day) == [11, 12])
    }

    // Case 3: lead window starts today and the notification time is still ahead → batch[0] kept.
    @Test func batchStartingTodayBeforeNotificationTimeKeepsFirstTrigger() {
        let now = date(2026, 1, 10, 12, 0)
        let expiry = date(2026, 2, 9, 12, 0)

        let plan = ExpiryReminderPlan.plan(
            earliestExpiration: expiry, leadDays: 30,
            notificationHour: 18, notificationMinute: 0, // 18:00 still ahead at 12:00
            now: now, calendar: calendar)

        #expect(plan.batchTriggers.compactMap(\.day) == [10, 11, 12])
    }

    // Case 4: leadDays = 3 — batch capped before the last-chance day, no duplicate trigger.
    @Test func leadDaysThreeCapsBatchBeforeLastChance() {
        let now = date(2026, 1, 10)
        let expiry = date(2026, 1, 15, 12, 0)

        let plan = ExpiryReminderPlan.plan(
            earliestExpiration: expiry, leadDays: 3,
            notificationHour: 9, notificationMinute: 0,
            now: now, calendar: calendar)

        #expect(plan.batchTriggers.compactMap(\.day) == [12, 13])
        #expect(plan.lastChanceTrigger?.day == 14)

        // Exactly one trigger fires on the day before expiry.
        let allDays = plan.batchTriggers.compactMap(\.day) + [plan.lastChanceTrigger?.day].compactMap { $0 }
        #expect(allDays.filter { $0 == 14 }.count == 1)
    }

    // Case 5: very short lead windows shrink the batch instead of extending past expiry.
    @Test func shortLeadWindowsShrinkBatch() {
        let now = date(2026, 1, 10)
        let expiry = date(2026, 1, 15, 12, 0)

        let twoDay = ExpiryReminderPlan.plan(
            earliestExpiration: expiry, leadDays: 2,
            notificationHour: 9, notificationMinute: 0,
            now: now, calendar: calendar)
        #expect(twoDay.batchTriggers.compactMap(\.day) == [13])
        #expect(twoDay.lastChanceTrigger?.day == 14)

        let oneDay = ExpiryReminderPlan.plan(
            earliestExpiration: expiry, leadDays: 1,
            notificationHour: 9, notificationMinute: 0,
            now: now, calendar: calendar)
        #expect(oneDay.batchTriggers.isEmpty)
        #expect(oneDay.lastChanceTrigger?.day == 14)
    }

    // Case 6: expiry tomorrow with today's notification time already past → no last-chance,
    // fallbacks start tomorrow.
    @Test func expiryTomorrowAfterNotificationTimeDropsLastChance() {
        let now = date(2026, 1, 10, 12, 0)
        let expiry = date(2026, 1, 11, 8, 0)

        let plan = ExpiryReminderPlan.plan(
            earliestExpiration: expiry, leadDays: 30,
            notificationHour: 9, notificationMinute: 0, // today's 09:00 already passed
            now: now, calendar: calendar)

        #expect(plan.batchTriggers.isEmpty)
        #expect(plan.lastChanceTrigger == nil)
        #expect(plan.fallbackTriggers.compactMap(\.day) == [11, 12, 13, 14, 15, 16, 17])
    }

    // Case 7: expiry already past → only the fallback triggers still in the future survive.
    @Test func pastExpiryKeepsOnlyFutureFallbacks() {
        let now = date(2026, 1, 10, 12, 0)
        let expiry = date(2026, 1, 5, 12, 0)

        let plan = ExpiryReminderPlan.plan(
            earliestExpiration: expiry, leadDays: 30,
            notificationHour: 9, notificationMinute: 0,
            now: now, calendar: calendar)

        #expect(plan.batchTriggers.isEmpty)
        #expect(plan.lastChanceTrigger == nil)
        // Fallback days are Jan 5–11 at 09:00; only Jan 11 is still ahead of Jan 10 12:00.
        #expect(plan.fallbackTriggers.compactMap(\.day) == [11])
    }

    // Case 8: every trigger carries the planning calendar's timezone.
    @Test func triggersCarryCalendarTimezone() {
        let now = date(2026, 1, 10)
        let expiry = date(2026, 2, 19)

        let plan = ExpiryReminderPlan.plan(
            earliestExpiration: expiry, leadDays: 30,
            notificationHour: 9, notificationMinute: 0,
            now: now, calendar: calendar)

        let all = plan.batchTriggers + plan.fallbackTriggers + [plan.lastChanceTrigger].compactMap { $0 }
        #expect(!all.isEmpty)
        #expect(all.allSatisfy { $0.timeZone == calendar.timeZone })
    }
}
