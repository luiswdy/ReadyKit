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
    
    func execute() -> RescheduleRemindersResult {
        var result = reminderScheduler.removeNonSnoozePendingReminders()
        switch result {
        case .success:
            break
        case .failure(let error):
            return .failure(error)
        }
        
        result = reminderScheduler.scheduleReminders()
        switch result {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
}
