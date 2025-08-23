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
        let documentsURL = FileManager.default.urls(for: AppConstants.Database.defaultSearchPathDirectory, in: .userDomainMask).first!
        let storeUrl = documentsURL.appendingPathComponent(AppConstants.Database.defaultDatabaseFilename)
        let schema = Schema([
            EmergencyKitModel.self,
            ItemModel.self,
        ])
        
        // Create a single ModelConfiguration with both URL and schema
        let modelConfiguration = ModelConfiguration(schema: schema, url: storeUrl, cloudKitDatabase: .none)

        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            dependencyContainer = DependencyContainer(modelContext: ModelContext(sharedModelContainer))
        } catch {
            logger.logFatal("Could not create ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
        self.dependencyContainer.reminderBackgroundTaskScheduler.registerTask()
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

                    var result = dependencyContainer.reminderScheduler.removePendingReminders()
                    switch result {
                    case .success:
                        logger.logInfo("Successfully removed all pending reminders.")
                    case .failure(let error):
                        logger.logError("Failed to remove pending reminders: \(error.localizedDescription)")
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
