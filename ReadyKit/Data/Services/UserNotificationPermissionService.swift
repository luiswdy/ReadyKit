//
//  UserNotificationPermissionHandler.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/14.
//
import UserNotifications

final class UserNotificationPermissionService: NotificationPermissionService {
    func checkPermission() async -> NotificationPermission {
        let settings = await UNUserNotificationCenter.current().notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .granted
        case .denied, .notDetermined:
            return .notGranted
        @unknown default:
            return .notGranted
        }
    }

    func requestPermission() async -> NotificationPermission {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            return granted ? .granted : .notGranted
        } catch {
            return .notGranted
        }
    }
}
