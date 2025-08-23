//
//  BackgroundModeStatusView.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/15/25.
//

import SwiftUI
import SwiftData

/// SwiftUI view component for displaying background mode status and allowing users to enable it
struct BackgroundModeStatusView: View {
    @State private var viewModel: BackgroundModeStatusViewModel

    init(dependencyContainer: DependencyContainer) {
        self._viewModel = State(
            wrappedValue: BackgroundModeStatusViewModel(
                checkBackgroundModeUseCase: dependencyContainer.checkBackgroundModeUseCase
            )
        )
    }

    var body: some View {
        Group {
            if !viewModel.isBackgroundModeEnabled {
                VStack(alignment: .leading, spacing: AppConstants.UI.Spacing.small) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)

                        Text("Background App Refresh")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()

                        if viewModel.showEnableButton {
                            Button("Enable") {
                                viewModel.openSettings()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .buttonStyle(.bordered)
                        }
                    }

                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Enable Background App Refresh to receive timely expiration reminders when the app is not active.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(Color.orange.opacity(AppConstants.UI.opacity))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(AppConstants.UI.opacity), lineWidth: 1)
                )
            }
        }
        .onAppear {
            viewModel.refreshBackgroundModeStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh status when app comes back to foreground
            viewModel.refreshBackgroundModeStatus()
        }
    }
}

/// Inline variant for use in settings or other views
struct InlineBackgroundModeStatusView: View {
    @State private var viewModel: BackgroundModeStatusViewModel

    init(dependencyContainer: DependencyContainer) {
        self._viewModel = State(
            wrappedValue: BackgroundModeStatusViewModel(
                checkBackgroundModeUseCase: dependencyContainer.checkBackgroundModeUseCase
            )
        )
    }

    var body: some View {
        HStack {
            Image(systemName: "app.badge")
                .foregroundColor(colorForStatus)

            VStack(alignment: .leading, spacing: AppConstants.UI.Spacing.small) {
                Text("Background App Refresh")
                    .font(.body)

                Text(viewModel.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if viewModel.showEnableButton {
                Button("Enable") {
                    viewModel.openSettings()
                }
                .font(.caption)
                .foregroundColor(.blue)
            } else if viewModel.isBackgroundModeEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .onAppear {
            viewModel.refreshBackgroundModeStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            viewModel.refreshBackgroundModeStatus()
        }
    }

    private var colorForStatus: Color {
        switch viewModel.backgroundRefreshStatus {
        case .available:
            return .green
        case .denied, .restricted:
            return .orange
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: EmergencyKitModel.self)
    let dependencyContainer = DependencyContainer(modelContext: ModelContext(container))

    VStack(spacing: AppConstants.UI.Spacing.large) {
        BackgroundModeStatusView(dependencyContainer: dependencyContainer)

        InlineBackgroundModeStatusView(dependencyContainer: dependencyContainer)
    }
    .padding()
}
