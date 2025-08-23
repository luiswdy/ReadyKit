//
//  BackgroundModeStatusViewModel.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/15/25.
//

import Foundation

/// ViewModel for managing background mode status display and user interactions
@MainActor
@Observable
final class BackgroundModeStatusViewModel {
    var isBackgroundModeEnabled: Bool = false
    var backgroundRefreshStatus: BackgroundRefreshStatus = .denied
    
    private let checkBackgroundModeUseCase: CheckBackgroundModeUseCase
    
    init(checkBackgroundModeUseCase: CheckBackgroundModeUseCase) {
        self.checkBackgroundModeUseCase = checkBackgroundModeUseCase
        refreshBackgroundModeStatus()
    }
    
    func refreshBackgroundModeStatus() {
        isBackgroundModeEnabled = checkBackgroundModeUseCase.isBackgroundModeEnabled()
        backgroundRefreshStatus = checkBackgroundModeUseCase.getBackgroundRefreshStatus()
    }
    
    func openSettings() {
        checkBackgroundModeUseCase.promptUserToEnableBackgroundMode()
    }

    // MARK: - Helper Properties
    var statusMessage: String {
        switch backgroundRefreshStatus {
        case .available:
            return String(localized: "Background App Refresh is enabled", comment: "Message shown when background refresh is available")
        case .denied:
            return String(localized: "Background App Refresh is disabled", comment: "Message shown when background refresh is denied")
        case .restricted:
            return String(localized: "Background App Refresh is restricted", comment: "Message shown when background refresh is restricted")
        }
    }
    
    var statusColor: String {
        switch backgroundRefreshStatus {
        case .available:
            return "green"
        case .denied, .restricted:
            return "orange"
        }
    }
    
    var showEnableButton: Bool {
        return backgroundRefreshStatus == .denied
    }
}
