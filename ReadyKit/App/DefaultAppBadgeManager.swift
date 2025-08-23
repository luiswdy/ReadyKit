//
//  DefaultAppBadgeManager.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/14/25.
//

import UserNotifications

final class DefaultAppBadgeManager: AppBadgeManager {
    private let center: UNUserNotificationCenter

    init(_ center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func setBadge(count: Int) async throws {
        try await center.setBadgeCount(count)
    }
}
