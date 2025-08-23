//
//  ShareSheetPresenter.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/18/25.
//

import SwiftUI
import UIKit

/// A custom presenter for the share sheet that avoids SwiftUI presentation conflicts
struct ShareSheetPresenter: UIViewRepresentable {
    @Binding var isPresented: Bool
    let items: [URL]
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if isPresented && !items.isEmpty {
            presentShareSheet(from: uiView)
        }
    }
    
    private func presentShareSheet(from view: UIView) {
        guard let windowScene = view.window?.windowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        // Find the topmost presented view controller
        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Exclude problematic activity types that cause CloudKit/sharing errors
        activityViewController.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .collaborationCopyLink,
            .collaborationInviteWithLink,
            .markupAsPDF,
            .openInIBooks,
            .postToFacebook,
            .postToFlickr,
            .postToTencentWeibo,
            .postToTwitter,
            .postToVimeo,
            .postToWeibo,
            .print,
            .sharePlay,
            .addToHomeScreen
        ]
        
        // Configure for iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Present with a delay to avoid conflicts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            topViewController.present(activityViewController, animated: true) {
                // Reset the presentation flag when the sheet is dismissed
                DispatchQueue.main.async {
                    self.isPresented = false
                }
            }
        }
    }
}
