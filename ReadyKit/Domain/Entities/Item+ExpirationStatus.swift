//
//  Item+ExpirationStatus.swift
//  ReadyKit
//
//  Created by Luis Wu on 2026/7/12.
//

import Foundation

/// Expiry state of an item relative to a reference date and the user's lead window.
enum ExpirationStatus: Equatable {
    case noExpiration
    case expired(daysAgo: Int)
    case expiringSoon(daysLeft: Int)
    case ok(daysLeft: Int)
}

/// Single source of truth for expiry date math. The boundary semantics deliberately
/// mirror `SwiftDataItemRepository`'s predicates (`expired` = strictly before now;
/// `expiring` = within `now ... now + days`) so views and repository never disagree.
extension Item {
    func expirationStatus(leadDays: Int, now: Date = Date(), calendar: Calendar = .current) -> ExpirationStatus {
        guard let expirationDate = expirationDate else {
            return .noExpiration
        }

        if expirationDate < now {
            let daysAgo = calendar.dateComponents([.day], from: expirationDate, to: now).day ?? 0
            return .expired(daysAgo: daysAgo)
        }

        let daysLeft = calendar.dateComponents([.day], from: now, to: expirationDate).day ?? 0
        return daysLeft <= leadDays ? .expiringSoon(daysLeft: daysLeft) : .ok(daysLeft: daysLeft)
    }

    func isExpired(now: Date = Date()) -> Bool {
        guard let expirationDate = expirationDate else { return false }
        return expirationDate < now
    }

    func isExpiring(withinDays days: Int, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let expirationDate = expirationDate,
              let cutoffDate = calendar.date(byAdding: .day, value: days, to: now) else { return false }
        return expirationDate >= now && expirationDate <= cutoffDate
    }
}
