//
//  DependencyContainer.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/13.
//
import SwiftUI
import SwiftData
import UserNotifications

final class DependencyContainer: ObservableObject {

    // MARK: - Core Dependencies
    private let modelContext: ModelContext

    #if DEBUG
    // MARK: - Test Infrastructure (DEBUG only)
    /// Test-only database management utilities
    /// This section is completely excluded from production builds
    private static func resetDatabaseForTesting() {
        guard CommandLine.arguments.contains(LaunchArgument.reset) else { return }

        let documentsURL = FileManager.default.urls(for: AppConstants.Database.defaultSearchPathDirectory, in: .userDomainMask).first!
        let storeUrl = documentsURL.appendingPathComponent(AppConstants.Database.defaultDatabaseFilename)

        do {
            if FileManager.default.fileExists(atPath: storeUrl.path) {
                try FileManager.default.removeItem(at: storeUrl)
                print("[DependencyContainer] DEBUG: Nuked SwiftData store at \(storeUrl)")
            }
        } catch {
            print("[DependencyContainer] DEBUG: Failed to nuke SwiftData store: \(error)")
        }
    }

    /// Creates a ModelContainer with optional test database reset
    /// Only available in DEBUG builds
    static func createModelContainerForTesting() -> ModelContainer {
        let schema = Schema([
            EmergencyKitModel.self,
            ItemModel.self,
        ])

        let modelConfiguration: ModelConfiguration
        if CommandLine.arguments.contains(LaunchArgument.uiTesting) {
            // UI tests get a fresh, isolated in-memory store on every launch.
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            // Reset the on-disk store if requested, then use the normal file-backed store.
            resetDatabaseForTesting()
            let documentsURL = FileManager.default.urls(for: AppConstants.Database.defaultSearchPathDirectory, in: .userDomainMask).first!
            let storeUrl = documentsURL.appendingPathComponent(AppConstants.Database.defaultDatabaseFilename)
            modelConfiguration = ModelConfiguration(schema: schema, url: storeUrl, cloudKitDatabase: .none)
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("[DependencyContainer] DEBUG: Could not create ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    /// An isolated, freshly-cleared `UserDefaults` suite for UI testing, or `nil` in normal runs.
    /// Keeps UI tests from reading or mutating the real `.standard` preferences.
    static func uiTestingUserDefaults() -> UserDefaults? {
        let suiteName = AppConstants.UserDefaultUserPreferencesKey.uiTestSuiteName
        guard CommandLine.arguments.contains(LaunchArgument.uiTesting),
              let suite = UserDefaults(suiteName: suiteName) else {
            return nil
        }
        suite.removePersistentDomain(forName: suiteName)
        return suite
    }
    #endif

    // MARK: - Repositories
    lazy var emergencyKitRepository: EmergencyKitRepository = SwiftDataEmergencyKitRepository(context: modelContext)
    lazy var itemRepository: ItemRepository = SwiftDataItemRepository(context: modelContext)
    lazy var userPreferencesRepository: UserPreferencesRepository = {
        #if DEBUG
        return UserDefaultsUserPreferencesRepository(userDefaults: Self.uiTestingUserDefaults() ?? .standard)
        #else
        return UserDefaultsUserPreferencesRepository()
        #endif
    }()
    lazy var notificationPermissionService: NotificationPermissionService = {
        #if DEBUG
        if CommandLine.arguments.contains(LaunchArgument.uiTesting) {
            return UITestingNotificationPermissionService()
        }
        #endif
        return UserNotificationPermissionService()
    }()

    // MARK: - Services
    lazy var reminderScheduler: ReminderScheduler = DefaultReminderScheduler(
        repository: itemRepository,
        notificationCenter: userNotificationCenter,
        userPreferencesRepository: userPreferencesRepository
    )

    lazy var notificationDelegate: NotificationDelegate = NotificationDelegate(
        reminderScheduler: reminderScheduler,
        loadUserPreferencesUseCase: LoadUserPreferencesUseCase(userPreferencesRepository: userPreferencesRepository),
        notificationCenter: userNotificationCenter
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

    // Register DuplicateItemInEmergencyKit use case
    lazy var duplicateItemInEmergencyKitUseCase: DuplicateItemInEmergencyKitUseCase = {
        DuplicateItemInEmergencyKitUseCase(itemRepository: itemRepository)
    }()

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

    private let userNotificationCenter: UNUserNotificationCenter

    init(modelContext: ModelContext, userNotificationCenter: UNUserNotificationCenter = .current()) {
        self.userNotificationCenter = userNotificationCenter
        self.modelContext = modelContext
        self.userNotificationCenter.delegate = notificationDelegate
    }
}

#if DEBUG
/// Treats notification permission as granted so UI tests can exercise the settings
/// pickers deterministically, without depending on the simulator's system permission.
private final class UITestingNotificationPermissionService: NotificationPermissionService {
    func checkPermission() async -> NotificationPermission { .granted }
    func requestPermission() async -> NotificationPermission { .granted }
}
#endif
