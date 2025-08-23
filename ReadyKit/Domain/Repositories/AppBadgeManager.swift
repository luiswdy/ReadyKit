//
//  AppBadgeManager.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/14/25.
//

// Domain/AppBadgeManager.swift
protocol AppBadgeManager {
    func setBadge(count: Int) async throws
}
