//
//  MainTabView.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/10/25.
//

import SwiftUI
import SwiftData

/// Main tab-based navigation container for the app

struct MainTabView: View {
//    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var dependencyContainer: DependencyContainer

    var body: some View {
        MainTabViewBody(dependencyContainer: dependencyContainer)
    }
}

private struct MainTabViewBody: View {
    @Environment(\.scenePhase) private var scenePhase
    private let dependencyContainer: DependencyContainer
    @State private var viewModel: MainTabViewModel
    
    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
        _viewModel = State(wrappedValue: MainTabViewModel(dependencyContainer: dependencyContainer))
    }
    
    var body: some View {
        TabView {
            EmergencyKitListView()
                .tabItem {
                    Label("Emergency Kits", systemImage: "archivebox.fill")
                }
            
            ReminderSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "bell.fill")
                }
            DatabaseBackupView()
                .tabItem {
                    Label("Backup", systemImage: "externaldrive.fill")
                }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            // Check and request notification permission if needed
            if viewModel.notificationPermission == .notGranted {
                viewModel.requestNotificationPermission()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.loadInitialData()
            }
        }
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
    
    MainTabView()
        .modelContainer(container)
        .environmentObject(dependencyContainer)
}
