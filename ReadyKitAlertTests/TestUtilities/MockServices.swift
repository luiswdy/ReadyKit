//
//  MockServices.swift
//  ReadyKitTests
//
//  Created by Claude on 8/22/25.
//

import Foundation
import UserNotifications
@testable import ReadyKit

// MARK: - Mock Notification Permission Service

final class MockNotificationPermissionService: NotificationPermissionService {
    
    // Test configuration
    var shouldGrantPermission = true
    var currentPermission: NotificationPermission = .notGranted
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "TestError", code: 1, userInfo: nil)
    
    func checkPermission() async -> NotificationPermission {
        return currentPermission
    }
    
    func requestPermission() async -> NotificationPermission {
        if shouldGrantPermission {
            currentPermission = .granted
        } else {
            currentPermission = .notGranted
        }
        return currentPermission
    }
    
    // Test helper methods
    func reset() {
        shouldGrantPermission = true
        currentPermission = .notGranted
        shouldThrowError = false
    }
    
    func setPermission(_ permission: NotificationPermission) {
        currentPermission = permission
    }
}

// MARK: - Mock Background Mode Service

final class MockBackgroundModeService: BackgroundModeService {
    
    // Test configuration
    var _isBackgroundAppRefreshEnabled = true
    var _backgroundRefreshStatus: BackgroundRefreshStatus = .available
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "TestError", code: 1, userInfo: nil)
    
    var isBackgroundAppRefreshEnabled: Bool {
        return _isBackgroundAppRefreshEnabled
    }
    
    var backgroundRefreshStatus: BackgroundRefreshStatus {
        return _backgroundRefreshStatus
    }
    
    func openBackgroundAppRefreshSettings() {
        // Mock implementation - does nothing in tests
    }
    
    // Test helper methods
    func reset() {
        _isBackgroundAppRefreshEnabled = true
        _backgroundRefreshStatus = .available
        shouldThrowError = false
    }
    
    func setBackgroundRefreshEnabled(_ enabled: Bool) {
        _isBackgroundAppRefreshEnabled = enabled
        _backgroundRefreshStatus = enabled ? .available : .denied
    }
    
    func setBackgroundRefreshStatus(_ status: BackgroundRefreshStatus) {
        _backgroundRefreshStatus = status
        _isBackgroundAppRefreshEnabled = (status == .available)
    }
}

// MARK: - Mock App Badge Manager

final class MockAppBadgeManager: AppBadgeManager {
    
    private(set) var currentBadgeNumber: Int = 0
    
    // Test configuration
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "TestError", code: 1, userInfo: nil)
    
    func setBadge(count: Int) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        
        currentBadgeNumber = max(0, count) // Badge number cannot be negative
    }
    
    // Test helper methods
    func reset() {
        currentBadgeNumber = 0
        shouldThrowError = false
    }
    
    func getBadgeNumber() -> Int {
        return currentBadgeNumber
    }
    
    func clearBadge() async throws {
        try await setBadge(count: 0)
    }
}

// MARK: - Mock Reminder Scheduler

final class MockReminderScheduler: ReminderScheduler {
    func scheduleDummyRegularCheckRemindersAndExpiredReminders() {
        // Implement if needed for tests
        // Currently left empty as it's not the focus of most tests
    }


    // Test state tracking
    private(set) var removePendingRemindersCalled = false
    private(set) var scheduleRemindersCalled = false
    private(set) var schedulePersistentExpiryReminderCalled = false
    private(set) var persistentExpiryReminderPreferences: UserPreferences?
    private(set) var callCount = 0

    // Test configuration
    var shouldSucceed = true
    var errorToReturn: Error = DefaultReminderSchedulerError.failedToScheduleReminders(NSError(domain: "TestError", code: 1, userInfo: nil))

    func removeNonSnoozePendingReminders() async {
        removePendingRemindersCalled = true
        callCount += 1
    }

    @MainActor func scheduleReminders() -> ReminderSchedulerResult {
        scheduleRemindersCalled = true
        callCount += 1

        if shouldSucceed {
            return .success(())
        } else {
            return .failure(errorToReturn)
        }
    }

    func schedulePersistentExpiryReminder(userPreferences: UserPreferences) async {
        schedulePersistentExpiryReminderCalled = true
        persistentExpiryReminderPreferences = userPreferences
        callCount += 1
    }

    // Test helper methods
    func reset() {
        removePendingRemindersCalled = false
        scheduleRemindersCalled = false
        schedulePersistentExpiryReminderCalled = false
        persistentExpiryReminderPreferences = nil
        callCount = 0
        shouldSucceed = true
    }
    
    func setError(_ error: Error) {
        errorToReturn = error
        shouldSucceed = false
    }
    
    func setShouldSucceed(_ succeed: Bool) {
        shouldSucceed = succeed
    }
}

// MARK: - Mock Logger

final class MockLogger: Logger {
    
    // Test state tracking
    private(set) var loggedMessages: [(level: String, message: String)] = []
    
    func logDebug(_ message: String) {
        loggedMessages.append((level: "debug", message: message))
    }
    
    func logInfo(_ message: String) {
        loggedMessages.append((level: "info", message: message))
    }
    
    func logWarning(_ message: String) {
        loggedMessages.append((level: "warning", message: message))
    }
    
    func logError(_ message: String) {
        loggedMessages.append((level: "error", message: message))
    }
    
    func logFatal(_ message: String) {
        loggedMessages.append((level: "fatal", message: message))
    }
    
    // Test helper methods
    func reset() {
        loggedMessages.removeAll()
    }
    
    func getLoggedMessages(for level: String) -> [String] {
        return loggedMessages.filter { $0.level == level }.map { $0.message }
    }
    
    func getAllLoggedMessages() -> [String] {
        return loggedMessages.map { $0.message }
    }
    
    func getLogCount(for level: String) -> Int {
        return loggedMessages.filter { $0.level == level }.count
    }
}

// MARK: - Mock User Notification Center

final class MockUserNotificationCenter: UserNotificationCenter {

    // Test state tracking
    private(set) var pendingRequests: [UNNotificationRequest] = []
    private(set) var removedIdentifiers: [String] = []
    private(set) var removedDeliveredIdentifiers: [String] = []
    private(set) var registeredCategories: Set<UNNotificationCategory> = []
    private(set) var removeAllPendingCalled = false

    weak var delegate: UNUserNotificationCenterDelegate?

    // Test configuration
    var shouldFailToSchedule = false
    var errorToThrow: Error = NSError(domain: "TestError", code: 1, userInfo: nil)

    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?) {
        if shouldFailToSchedule {
            completionHandler?(errorToThrow)
        } else {
            pendingRequests.append(request)
            completionHandler?(nil)
        }
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        return pendingRequests
    }

    func removeAllPendingNotificationRequests() {
        removeAllPendingCalled = true
        pendingRequests.removeAll()
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(contentsOf: identifiers)
        pendingRequests.removeAll { request in
            identifiers.contains(request.identifier)
        }
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removedDeliveredIdentifiers.append(contentsOf: identifiers)
    }

    func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        registeredCategories = categories
    }

    // Test helper methods
    func reset() {
        pendingRequests.removeAll()
        removedIdentifiers.removeAll()
        removedDeliveredIdentifiers.removeAll()
        registeredCategories = []
        removeAllPendingCalled = false
        shouldFailToSchedule = false
    }

    /// Seeds a pending request directly (e.g. a snoozed reminder that should survive removal).
    func seedPendingRequest(_ request: UNNotificationRequest) {
        pendingRequests.append(request)
    }
    
    func getPendingRequestCount() -> Int {
        return pendingRequests.count
    }
    
    func hasPendingRequest(withIdentifier identifier: String) -> Bool {
        return pendingRequests.contains { $0.identifier == identifier }
    }
}
