//
//  UpdateAppBadgeForExpiringAndExpiredItems.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/14.
//
import UserNotifications

typealias UpdateAppBadgeForExpiringAndExpiredItemsResult = Result<Void, Error>

final class UpdateAppBadgeForExpiringAndExpiredItemsUseCase {
    private let itemRepository: ItemRepository
    private let  userPreferencesRepository: UserPreferencesRepository
    private let appBadgeManager: AppBadgeManager

    init(itemRepository: ItemRepository, userPreferencesRepository: UserPreferencesRepository, appBadgeManager: AppBadgeManager) {
        self.itemRepository = itemRepository
        self.userPreferencesRepository = userPreferencesRepository
        self.appBadgeManager = appBadgeManager
    }
    
    func execute() -> UpdateAppBadgeForExpiringAndExpiredItemsResult {
        let userPreferences = userPreferencesRepository.load()
        let expiryReminderLeadDays = userPreferences.expiryReminderLeadDays
        do {
            let expiringItems = try itemRepository.fetchExpiring(within: expiryReminderLeadDays)
            let expiredItems = try itemRepository.fetchExpired()
            let totalCount = expiringItems.count + expiredItems.count
            
            Task {
                try await appBadgeManager.setBadge(count: totalCount)
            }
        } catch {
            return .failure(error)
        }
        return .success(())
    }
}
