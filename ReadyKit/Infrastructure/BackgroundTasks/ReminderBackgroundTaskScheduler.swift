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
                  let bgProcessingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }

            Task {
                await self.handleReminderTask(task: bgProcessingTask)
            }
        }

        if success {
            logger.logInfo("Background task registered successfully: \(taskIdentifier)")
        } else {
            logger.logError("Failed to register background task: \(taskIdentifier)")
        }
    }

    @MainActor
    private func handleReminderTask(task: BGProcessingTask) async {
        // NOTE: Pause the debugger and use the command to test
        // background task :
        // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"io.wdy.ReadyKitApp.refresh"]

        // Schedule the next refresh
        logger.logInfo("Handling background reminder task...")
        scheduleNextRefresh()

        let result = reminderScheduler.removeNonSnoozePendingReminders()
        switch result {
        case .success:
            logger.logInfo("Successfully removed non-snooze pending reminders")
        case .failure(let error):
            logger.logError("Failed to remove non-snooze pending reminders: \(error.localizedDescription)")
        }
        // Run on main thread
        await MainActor.run {
            let result = reminderScheduler.scheduleReminders()
            switch result {
            case .success:
                logger.logInfo("Successfully scheduled reminders")
            case .failure(let error):
                logger.logError("Failed to schedule reminders: \(error.localizedDescription)")
            }
        }

        // Set the task expiration handler
        task.expirationHandler = { [weak self] in
            self?.logger.logWarning("Background task expired before completion.")
            task.setTaskCompleted(success: false)
        }

        // Mark the task as completed
        logger.logInfo("Background reminder task completed successfully.")
        task.setTaskCompleted(success: true)
    }

    func scheduleNextRefresh() {
        guard backgroundModeService.isBackgroundAppRefreshEnabled else {
            logger.logWarning("Background App Refresh is disabled - cannot schedule background tasks")
            return
        }

        let processingTaskRequest = BGProcessingTaskRequest(identifier: taskIdentifier)
        processingTaskRequest.requiresNetworkConnectivity = false
        processingTaskRequest.requiresExternalPower = false
        processingTaskRequest.earliestBeginDate = AppConstants.BackgroundMode.earliestBeginDate
        do {
            try BGTaskScheduler.shared.submit(processingTaskRequest)
            logger.logInfo("Background processing task scheduled successfully: \(taskIdentifier)")
        } catch {
            logger.logError("Could not schedule background processing task: \(error)")
        }
    }
}
