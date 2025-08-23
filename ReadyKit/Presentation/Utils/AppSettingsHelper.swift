//
//  AppSettingsHelper.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/19.
//

import UIKit

/// A utility helper for managing app settings and system-level interactions
struct AppSettingsHelper {
    
    /// Opens the app's settings page in the iOS Settings app
    /// This allows users to modify app permissions, notifications, and other system-level settings
    static func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        UIApplication.shared.open(settingsUrl)
    }
}
