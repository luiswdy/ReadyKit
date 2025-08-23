//
//  DependencyContainer.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/13.
//
import SwiftUI
import SwiftData

final class DependencyContainer: ObservableObject {

    // MARK: - Core Dependencies
    private let modelContext: ModelContext

    // MARK: - Repositories
    lazy var emergencyKitRepository: EmergencyKitRepository = SwiftDataEmergencyKitRepository(context: modelContext)
    lazy var itemRepository: ItemRepository = SwiftDataItemRepository(context: modelContext)
    lazy var userPreferencesRepository : UserPreferencesRepository = UserDefaultsUserPreferencesRepository()
    lazy var notificationPermissionService: NotificationPermissionService = UserNotificationPermissionService()

    // MARK: - Services
    lazy var reminderScheduler: ReminderScheduler = DefaultReminderScheduler(
        repository: itemRepository,
        notificationCenter: UNUserNotificationCenter.current(),
        userPreferencesRepository: userPreferencesRepository
    )

    lazy var backgroundModeService: BackgroundModeService = IOSBackgroundModeService()

    // MARK: - Managers
    lazy var appBadgeManager: AppBadgeManager = DefaultAppBadgeManager()

    // MARK: - Use Cases - Emergency Kit
    lazy var fetchAllEmergencyKitUseCase = FetchAllEmergencyKitsUseCase(
        repository: emergencyKitRepository
    )

    lazy var createEmergencyKitUseCase = CreateEmergencyKitUseCase(
        repository: emergencyKitRepository
    )

    lazy var deleteEmergencyKitUseCase = DeleteEmergencyKitUseCase(
        repository: emergencyKitRepository
    )

    lazy var editEmergencyKitUseCase = EditEmergencyKitUseCase(
        repository: emergencyKitRepository
    )

    // MARK: - Use Cases - Item
    lazy var addItemToEmergencyKitUseCase = AddItemToEmergencyKitUseCase(
        repository: emergencyKitRepository
    )

    lazy var editItemInEmergencyKitUseCase = EditItemInEmergencyKitUseCase(
        repository: emergencyKitRepository
    )

    lazy var deleteItemInEmergencyKitUseCase = DeleteItemInEmergencyKitUseCase(
        emergencyKitRepository: emergencyKitRepository,
        itemRepository: itemRepository
    )

    lazy var fetchItemInEmergencyKitUseCase = FetchItemInEmergencyKitUseCase(
        repository: emergencyKitRepository
    )

    // MARK: - Use Cases - User Preferences
    lazy var loadUserPreferencesUseCase = LoadUserPreferencesUseCase(
        userPreferencesRepository: userPreferencesRepository
    )

    lazy var saveUserPreferencesUseCase = SaveUserPreferencesUseCase(
        userPreferencesRepository: userPreferencesRepository
    )

    // MARK: - Use Cases - Notifications
    lazy var checkNotificationPermissionUseCase = CheckNotificationPermissionUseCase(
        notificationPermissionRepository: notificationPermissionService
    )

    lazy var requestNotificationPermissionUseCase = RequestNotificationPermissionUseCase(
        notificationPermissionRepository: notificationPermissionService
    )

    lazy var rescheduleRemindersUseCase = RescheduleRemindersUseCase(
        reminderScheduler: reminderScheduler
    )

    // MARK: - Use Cases - Background Mode
    lazy var checkBackgroundModeUseCase: CheckBackgroundModeUseCase = DefaultCheckBackgroundModeUseCase(
        backgroundModeService: backgroundModeService
    )

    // MARK: - Use Cases - Update App Badge for Expiring and Expired Items
    lazy var updateAppBadgeForExpiringAndExpiredItemsUseCase = UpdateAppBadgeForExpiringAndExpiredItemsUseCase(itemRepository: itemRepository, userPreferencesRepository: userPreferencesRepository, appBadgeManager: appBadgeManager)

    // MARK: - Background Task
    lazy var reminderBackgroundTaskScheduler = ReminderBackgroundTaskScheduler(
        reminderScheduler: reminderScheduler,
        backgroundModeService: backgroundModeService
    )
    
    // MARK: - Default Values
    private let defaultUserPreferences = UserPreferences(
        dailyNotificationTime: DateComponents(
            hour: AppConstants.UserPreferences.defaultNotificationHour,
            minute: AppConstants.UserPreferences.defaultNotificationMinute
        ),
        expiryReminderLeadDays: AppConstants.UserPreferences.defaultExpiryReminderLeadDays,
        regularCheck: AppConstants.UserPreferences.defaultRegularCheckFrequency
    )

    init(modelContext: ModelContext) {
        // Initialize ModelContext for SwiftData
        self.modelContext = modelContext
        self.emergencyKitRepository = SwiftDataEmergencyKitRepository(context: modelContext)
        self.itemRepository = SwiftDataItemRepository(context: modelContext)
    }
}
