//
//  BackgroundModeService.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/15/25.
//

import Foundation

/// Protocol for checking and managing background app refresh status
protocol BackgroundModeService {
    /// Returns true if background app refresh is enabled for the app
    var isBackgroundAppRefreshEnabled: Bool { get }
    
    /// Returns the current background refresh status
    var backgroundRefreshStatus: BackgroundRefreshStatus { get }
    
    /// Opens the app's settings page where users can enable background app refresh
    func openBackgroundAppRefreshSettings()
}

/// Enum representing the possible background refresh statuses
enum BackgroundRefreshStatus {
    case available
    case denied
    case restricted
}
