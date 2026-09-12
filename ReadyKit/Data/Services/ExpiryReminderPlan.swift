//
//  ExpiryReminderPlan.swift
//  ReadyKit
//
//  Created by Luis Wu on 2026/7/12.
//

import Foundation

/// Pure computation of the Path A expiry notification schedule. Given the earliest
/// expiration date, it produces trigger components for:
/// - up to `ExpiryBatch.size` one-shot batch notifications starting when the item
///   enters its lead window,
/// - one last-chance notification the day before expiry,
/// - `ExpiredFallback.size` one-shot daily fallback notifications from expiry day on,
///   covering the case where the user never opens the app and the background task
///   never runs (iOS gives no guarantee), so the app is not silent after expiry.
///
/// All candidates are resolved to a concrete fire date (day at the user's notification
/// hour/minute) and dropped if that datetime is not in the future — a calendar trigger
/// with a past date would silently never fire. Batch candidates on or after the
/// last-chance day are dropped so short lead windows never double-notify.
struct ExpiryReminderPlan {
    let batchTriggers: [DateComponents]
    let lastChanceTrigger: DateComponents?
    let fallbackTriggers: [DateComponents]

    static func plan(earliestExpiration: Date,
                     leadDays: Int,
                     notificationHour: Int,
                     notificationMinute: Int,
                     now: Date = Date(),
                     calendar: Calendar = .current) -> ExpiryReminderPlan {
        func candidate(onDayOf date: Date) -> (components: DateComponents, fireDate: Date)? {
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = notificationHour
            components.minute = notificationMinute
            components.timeZone = calendar.timeZone
            guard let fireDate = calendar.date(from: components) else { return nil }
            return (components, fireDate)
        }
        func futureTrigger(onDayOf date: Date) -> (components: DateComponents, fireDate: Date)? {
            guard let c = candidate(onDayOf: date), c.fireDate > now else { return nil }
            return c
        }

        let lastChanceDay = calendar.date(byAdding: .day, value: -1, to: earliestExpiration)
        // The cap applies even when the last-chance trigger itself is already past,
        // so batch one-shots can never land on or after the day before expiry.
        let lastChanceCap = lastChanceDay.flatMap { candidate(onDayOf: $0)?.fireDate }
        let lastChance = lastChanceDay.flatMap { futureTrigger(onDayOf: $0) }

        var batch: [DateComponents] = []
        if let startDate = calendar.date(byAdding: .day, value: -leadDays, to: earliestExpiration) {
            for i in 0..<AppConstants.Notification.ExpiryBatch.size {
                guard let batchDay = calendar.date(byAdding: .day, value: i, to: startDate),
                      let candidate = futureTrigger(onDayOf: batchDay) else { continue }
                // Stop at the last-chance day so short lead windows don't duplicate it
                // or extend past the expiry date.
                if let lastChanceCap = lastChanceCap, candidate.fireDate >= lastChanceCap {
                    break
                }
                batch.append(candidate.components)
            }
        }

        var fallbacks: [DateComponents] = []
        for j in 0..<AppConstants.Notification.ExpiredFallback.size {
            guard let fallbackDay = calendar.date(byAdding: .day, value: j, to: earliestExpiration),
                  let candidate = futureTrigger(onDayOf: fallbackDay) else { continue }
            fallbacks.append(candidate.components)
        }

        return ExpiryReminderPlan(
            batchTriggers: batch,
            lastChanceTrigger: lastChance?.components,
            fallbackTriggers: fallbacks
        )
    }
}
