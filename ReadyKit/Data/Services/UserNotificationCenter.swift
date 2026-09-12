//
//  UserNotificationCenter.swift
//  ReadyKit
//
//  Created by Luis Wu on 2026/7/12.
//

import UserNotifications

/// Seam over `UNUserNotificationCenter` covering only the methods the app uses,
/// so `DefaultReminderScheduler` and `NotificationDelegate` can be unit-tested
/// with a mock. `UNUserNotificationCenter` conforms as-is.
protocol UserNotificationCenter: AnyObject {
    var delegate: UNUserNotificationCenterDelegate? { get set }
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?)
    func pendingNotificationRequests() async -> [UNNotificationRequest]
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
    func setNotificationCategories(_ categories: Set<UNNotificationCategory>)
}

extension UserNotificationCenter {
    /// Async form of `add` so callers can guarantee the request is committed
    /// before releasing a background execution assertion.
    func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            add(request) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

extension UNUserNotificationCenter: UserNotificationCenter {}
