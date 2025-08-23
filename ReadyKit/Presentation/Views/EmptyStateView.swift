//
//  EmptyStateView.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/14/25.
//

import SwiftUI

/// Common views used throughout the app
struct LoadingView: View {
    var body: some View {
        VStack(spacing: AppConstants.UI.Spacing.medium) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let systemImage: String
    let actionTitle: LocalizedStringKey?
    let action: (() -> Void)?

    init(
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        systemImage: String,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: AppConstants.UI.Spacing.large) {
            Image(systemName: systemImage)
                .font(.system(size: AppConstants.UI.SystemImage.fontSize))
                .foregroundColor(.secondary)

            VStack(spacing: AppConstants.UI.Spacing.small) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: AppConstants.UI.Spacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: AppConstants.UI.SystemImage.fontSize))
                .foregroundColor(.red)

            Text("Something went wrong")
                .font(.headline)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let retryAction = retryAction {
                Button("Retry", action: retryAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview("Loading View") {
    LoadingView()
}

#Preview("Empty State - No Action") {
    EmptyStateView(
        title: "No Items Found",
        message: "There are no items to display at the moment.",
        systemImage: "tray"
    )
}

#Preview("Empty State - With Action") {
    EmptyStateView(
        title: "No Emergency Kits Yet",
        message: "Create your first emergency kit to get started organizing your supplies.",
        systemImage: "archivebox",
        actionTitle: "Create Emergency Kit"
    ) {
        print("Create action tapped")
    }
}

#Preview("Error View - No Retry") {
    ErrorView(
        message: "Unable to load data. Please check your connection and try again.",
        retryAction: nil
    )
}

#Preview("Error View - With Retry") {
    ErrorView(
        message: "Failed to save changes. Please try again.",
        retryAction: {
            print("Retry action tapped")
        }
    )
}
