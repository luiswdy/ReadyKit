//
//  ContentView.swift
//  ReadyKit
//
//  Created by Luis Wu on 6/28/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    private let logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
        
    }

    var body: some View {
        ContentViewBody(dependencyContainer: dependencyContainer)
            .onAppear {
                updateAppBadgeForExpiringAndExpiredItems()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active || newPhase == .background {
                    updateAppBadgeForExpiringAndExpiredItems()
                }
            }
    }
    
    
    
    private func updateAppBadgeForExpiringAndExpiredItems() {
        let result = dependencyContainer.updateAppBadgeForExpiringAndExpiredItemsUseCase.execute()
        switch result {
        case .success:
            logger.logInfo("App badge updated successfully.")
        case .failure(let error):
            logger.logError("Failed to update app badge: \(error.localizedDescription)")
        }
    }
}

private struct ContentViewBody: View {
    let dependencyContainer: DependencyContainer
    @State private var viewModel: ContentViewModel
    
    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
        _viewModel = State(
            wrappedValue: ContentViewModel(
                updateAppBadgeUseCase: dependencyContainer.updateAppBadgeForExpiringAndExpiredItemsUseCase
            )
        )
    }
    
    var body: some View {
        MainTabView()
            .environmentObject(dependencyContainer)
    }
}

#Preview {
    let schema = Schema([
        EmergencyKitModel.self,
        ItemModel.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    let dependencyContainer = DependencyContainer(modelContext: ModelContext(container))
    
    ContentView()
        .modelContainer(container)
        .environmentObject(dependencyContainer)
}
