//
//  CheckNotificationPermission.swift
//  ReadyKit
//
//  Created by Luis Wu on 6/28/25.
//

final class CheckNotificationPermissionUseCase {
    private let notificationPermissionHandler: NotificationPermissionService
    
    init(notificationPermissionRepository: NotificationPermissionService) {
        self.notificationPermissionHandler = notificationPermissionRepository
    }
    
    func execute() async -> NotificationPermission{
        return await notificationPermissionHandler.checkPermission()
    }
}
