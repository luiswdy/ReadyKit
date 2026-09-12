//
//  ExpirationStatusFormatter.swift
//  ReadyKit
//
//  Created by Luis Wu on 2026/7/12.
//

import SwiftUI

/// Maps an item's `ExpirationStatus` to the user-facing label and color shown in lists
/// and detail screens. Shared by `ItemDetailViewModel` and `EmergencyKitDetailViewModel`.
enum ExpirationStatusFormatter {
    static func format(_ status: ExpirationStatus) -> (text: String, color: Color) {
        switch status {
        case .noExpiration:
            return (String(localized: "No expiration date"), .secondary)
        case .expired(let daysAgo):
            return (String(localized: "Expired \(daysAgo) days ago"), .red)
        case .expiringSoon(let daysLeft):
            return (String(localized: "Expiring in \(daysLeft) days"), .orange)
        case .ok(let daysLeft):
            return (String(localized: "Expires in \(daysLeft) days"), .green)
        }
    }
}
