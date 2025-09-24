//
//  DefaultReminderSchedulerError+LocalizedError.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/18/25.
//

import SwiftUI

extension DefaultReminderSchedulerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .failedToLoadPreferences(let error):
            return String(localized: "Failed to load preferences: \(error.localizedDescription)", comment: "Error loading user preferences for reminders")
        case .failedToScheduleReminders(let error):
            return String(localized: "Failed to schedule reminders: \(error.localizedDescription)", comment: "Error scheduling reminders using the reminder scheduler")
        }
    }
}
