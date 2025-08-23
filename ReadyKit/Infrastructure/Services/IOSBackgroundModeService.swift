//
//  IOSBackgroundModeService.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/15/25.
//

import UIKit

/// iOS-specific implementation of BackgroundModeService
final class IOSBackgroundModeService: BackgroundModeService {
    
    var isBackgroundAppRefreshEnabled: Bool {
        return UIApplication.shared.backgroundRefreshStatus == .available
    }
    
    var backgroundRefreshStatus: BackgroundRefreshStatus {
        switch UIApplication.shared.backgroundRefreshStatus {
        case .available:
            return .available
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }
    
    func openBackgroundAppRefreshSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}
