//
//  CameraPermissionHelper.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/15.
//

import AVFoundation
import UIKit

/// A utility class for handling camera permission requests and status checks
struct CameraPermissionHelper {
    
    /// Checks camera permission and executes appropriate actions based on the authorization status
    /// - Parameters:
    ///   - onAuthorized: Closure to execute when camera access is authorized
    ///   - onDenied: Closure to execute when camera access is denied or restricted
    static func checkCameraPermissionAndShowCamera(
        onAuthorized: @escaping () -> Void,
        onDenied: @escaping () -> Void
    ) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Camera access is already granted, execute authorized action
            onAuthorized()
            
        case .notDetermined:
            // Camera access has not been requested yet, request access
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        // Access was granted, execute authorized action
                        onAuthorized()
                    } else {
                        // Access was denied, execute denied action
                        onDenied()
                    }
                }
            }
            
        case .denied, .restricted:
            // Camera access is denied or restricted, execute denied action
            onDenied()
            
        @unknown default:
            // Handle any future cases by showing the denied action
            onDenied()
        }
    }
    
    /// Opens the app settings page where users can enable camera permissions
    static func openAppSettings() {
        AppSettingsHelper.openAppSettings()
    }
}
