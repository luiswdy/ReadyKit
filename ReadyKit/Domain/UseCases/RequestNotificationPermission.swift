//
//  RequestNotificationPermission.swift
//  ReadyKit
//
//  Created by Luis Wu on 6/28/25.
//

final class RequestNotificationPermissionUseCase {
    private let notificationPermissionHandler: NotificationPermissionService
    
    init(notificationPermissionRepository: NotificationPermissionService) {
        self.notificationPermissionHandler = notificationPermissionRepository
    }
    
    func execute() async -> NotificationPermission {
        return await notificationPermissionHandler.requestPermission()
    }
}
