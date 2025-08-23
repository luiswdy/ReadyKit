//
//  NotificationPermissionService.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/11.
//

enum NotificationPermission {
    case granted
    case notGranted
}

protocol NotificationPermissionService {
    func requestPermission() async -> NotificationPermission
    func checkPermission() async -> NotificationPermission
}

