//
//  RescheduleReminders.swift
//  ReadyKit
//
//  Created by Luis Wu on 6/28/25.
//

typealias RescheduleRemindersResult = Result<Void, Error>

final class RescheduleRemindersUseCase {
    private let reminderScheduler: ReminderScheduler
    
    init(reminderScheduler: ReminderScheduler) {
        self.reminderScheduler = reminderScheduler
    }
    
    func execute() async -> RescheduleRemindersResult {
        await reminderScheduler.removeNonSnoozePendingReminders()
        return reminderScheduler.scheduleReminders()
    }
}
