//
//  ReadyKitApp.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/10/25.
//

import SwiftUI
import SwiftData

@main
struct ReadyKitApp: App {
    @Environment(\.scenePhase) private var scenePhase

    private var sharedModelContainer: ModelContainer
    private var dependencyContainer: DependencyContainer
    private let logger: Logger = DefaultLogger.shared

    init() {
        // Use DependencyContainer's safe model container creation
        #if DEBUG
        // In DEBUG builds, use the test-aware container creation
        sharedModelContainer = DependencyContainer.createModelContainerForTesting()
        #else
        // In RELEASE builds, use standard production container creation
        sharedModelContainer = Self.createProductionModelContainer()
        #endif

        dependencyContainer = DependencyContainer(modelContext: ModelContext(sharedModelContainer))
        self.dependencyContainer.reminderBackgroundTaskScheduler.registerTask()
    }

    /// Creates a production ModelContainer without any test logic
    /// This method is only used in RELEASE builds
    private static func createProductionModelContainer() -> ModelContainer {
        let documentsURL = FileManager.default.urls(for: AppConstants.Database.defaultSearchPathDirectory, in: .userDomainMask).first!
        let storeUrl = documentsURL.appendingPathComponent(AppConstants.Database.defaultDatabaseFilename)

        DefaultLogger.shared.logInfo("storeUrl: \(storeUrl)")

        let schema = Schema([
            EmergencyKitModel.self,
            ItemModel.self,
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, url: storeUrl, cloudKitDatabase: .none)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            DefaultLogger.shared.logFatal("Could not create ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .environmentObject(dependencyContainer)
                .onAppear {
                    let checkBackgroundModeResult = dependencyContainer.checkBackgroundModeUseCase.getBackgroundRefreshStatus()

                    guard checkBackgroundModeResult == .available else {
                        logger.logInfo("Background refresh is not available.")
                        return
                    }

                    var result = dependencyContainer.reminderScheduler.removeNonSnoozePendingReminders()
                    switch result {
                    case .success:
                        logger.logInfo("Successfully removed non-snooze pending reminders.")
                    case .failure(let error):
                        logger.logError("Failed to remove non-snooze pending reminders: \(error.localizedDescription)")
                    }
                    result = dependencyContainer.reminderScheduler.scheduleReminders()
                    switch result {
                    case .success:
                        logger.logInfo("Successfully scheduled reminders.")
                    case .failure(let error):
                        logger.logError("Failed to schedule reminders: \(error.localizedDescription)")
                    }
                }
                .onChange(of: scenePhase) { oldValue, newValue in
                    if newValue == .background {
                        dependencyContainer.reminderBackgroundTaskScheduler.scheduleNextRefresh()
                    }
                }
        }
    }
}
