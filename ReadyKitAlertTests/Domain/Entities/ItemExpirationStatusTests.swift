//
//  ItemExpirationStatusTests.swift
//  ReadyKitTests
//
//  Created by Luis Wu on 2026/7/12.
//

import Foundation
import Testing
@testable import ReadyKit

/// Boundary tests for the shared expiry date math. Semantics must mirror
/// `SwiftDataItemRepository`'s predicates: expired = strictly before now,
/// expiring = within `now ... now + days`.
struct ItemExpirationStatusTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private let now = Date.testDate(year: 2026, month: 1, day: 10)

    private func item(expiring date: Date?) throws -> Item {
        try TestDataFactory.createValidItem(expirationDate: date)
    }

    @Test func nilExpirationDateIsNoExpiration() throws {
        let item = try item(expiring: nil)
        #expect(item.expirationStatus(leadDays: 30, now: now, calendar: calendar) == .noExpiration)
        #expect(!item.isExpired(now: now))
        #expect(!item.isExpiring(withinDays: 30, now: now, calendar: calendar))
    }

    @Test func expiredYesterdayReportsDaysAgo() throws {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let item = try item(expiring: yesterday)
        #expect(item.expirationStatus(leadDays: 30, now: now, calendar: calendar) == .expired(daysAgo: 1))
        #expect(item.isExpired(now: now))
        #expect(!item.isExpiring(withinDays: 30, now: now, calendar: calendar))
    }

    // Boundary: expiration exactly at `now` is NOT expired (repository predicate is `< now`),
    // and IS expiring (predicate is `>= now`).
    @Test func expirationExactlyNowIsExpiringNotExpired() throws {
        let item = try item(expiring: now)
        #expect(!item.isExpired(now: now))
        #expect(item.isExpiring(withinDays: 30, now: now, calendar: calendar))
        #expect(item.expirationStatus(leadDays: 30, now: now, calendar: calendar) == .expiringSoon(daysLeft: 0))
    }

    // Boundary: exactly leadDays out → expiringSoon; one day past the window → ok.
    @Test func leadWindowBoundary() throws {
        let atBoundary = try item(expiring: calendar.date(byAdding: .day, value: 30, to: now)!)
        #expect(atBoundary.expirationStatus(leadDays: 30, now: now, calendar: calendar) == .expiringSoon(daysLeft: 30))
        #expect(atBoundary.isExpiring(withinDays: 30, now: now, calendar: calendar))

        let beyondBoundary = try item(expiring: calendar.date(byAdding: .day, value: 31, to: now)!)
        #expect(beyondBoundary.expirationStatus(leadDays: 30, now: now, calendar: calendar) == .ok(daysLeft: 31))
        #expect(!beyondBoundary.isExpiring(withinDays: 30, now: now, calendar: calendar))
    }

    @Test func expiredOneSecondAgoIsExpired() throws {
        let item = try item(expiring: now.addingTimeInterval(-1))
        #expect(item.isExpired(now: now))
        #expect(item.expirationStatus(leadDays: 30, now: now, calendar: calendar) == .expired(daysAgo: 0))
    }
}
