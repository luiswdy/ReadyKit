//
//  ReminderScheduler.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/11.
//
typealias ReminderSchedulerResult = Result<Void, Error>

protocol ReminderScheduler {
    func removeNonSnoozePendingReminders() async
    @MainActor func scheduleReminders() -> ReminderSchedulerResult
    func schedulePersistentExpiryReminder(userPreferences: UserPreferences)
}
