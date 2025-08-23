//
//  ReminderBackgroundTaskScheduler.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/15.
//

import BackgroundTasks

final class ReminderBackgroundTaskScheduler {
    private let reminderScheduler: ReminderScheduler
    private let backgroundModeService: BackgroundModeService
    private let taskIdentifier = AppConstants.BackgroundMode.taskIdentifier
    private let logger: Logger

    init(reminderScheduler: ReminderScheduler, backgroundModeService: BackgroundModeService, logger: Logger = DefaultLogger.shared) {
        self.reminderScheduler = reminderScheduler
        self.backgroundModeService = backgroundModeService
        self.logger = logger
    }

    func registerTask() {
        let success = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let self = self,
                  let bgAppRefreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }

            Task {
                await self.handleReminderTask(task: bgAppRefreshTask)
            }
        }

        if success {
            logger.logInfo("Background task registered successfully: \(taskIdentifier)")
        } else {
            logger.logError("Failed to register background task: \(taskIdentifier)")
        }
    }

    @MainActor
    private func handleReminderTask(task: BGAppRefreshTask) async {
        // NOTE: Pause the debugger and use the command to test
        // background task :
        // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"io.wdy.ReadyKitApp.refresh"]

        // Schedule the next refresh
        scheduleNextRefresh()

        let result = reminderScheduler.removePendingReminders()
        logger.logInfo("Removing pending reminders... result: \(result)")
        // Run on main thread
        await MainActor.run {
            let result = reminderScheduler.scheduleReminders()
            logger.logInfo("Scheduling reminders... result: \(result)")
        }

        // Set the task expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // Mark the task as completed
        task.setTaskCompleted(success: true)
    }

    func scheduleNextRefresh() {
        guard backgroundModeService.isBackgroundAppRefreshEnabled else {
            logger.logWarning("Background App Refresh is disabled - cannot schedule background tasks")
            return
        }

        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 7 * 24 * 60 * 60) // 7 days from now

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.logInfo("Background task scheduled successfully: \(taskIdentifier)")
        } catch {
            logger.logError("Could not schedule background task: \(error)")
        }
    }
}
