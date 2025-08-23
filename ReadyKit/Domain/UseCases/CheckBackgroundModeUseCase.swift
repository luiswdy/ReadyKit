//
//  CheckBackgroundModeUseCase.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/15/25.
//

import Foundation

/// Use case for checking background mode status and handling user interactions
protocol CheckBackgroundModeUseCase {
    func isBackgroundModeEnabled() -> Bool
    func getBackgroundRefreshStatus() -> BackgroundRefreshStatus
    func promptUserToEnableBackgroundMode()
}

final class DefaultCheckBackgroundModeUseCase: CheckBackgroundModeUseCase {
    private let backgroundModeService: BackgroundModeService
    
    init(backgroundModeService: BackgroundModeService) {
        self.backgroundModeService = backgroundModeService
    }
    
    func isBackgroundModeEnabled() -> Bool {
        return backgroundModeService.isBackgroundAppRefreshEnabled
    }
    
    func getBackgroundRefreshStatus() -> BackgroundRefreshStatus {
        return backgroundModeService.backgroundRefreshStatus
    }
    
    func promptUserToEnableBackgroundMode() {
        backgroundModeService.openBackgroundAppRefreshSettings()
    }
}
