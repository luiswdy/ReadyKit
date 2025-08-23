//
//  EmergencyKitCardView.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/15.
//

import SwiftUI

/// Reusable card component for displaying emergency kit information
struct EmergencyKitCardView: View {
    let emergencyKit: EmergencyKit
    let itemCount: Int
    let expiredCount: Int
    let expiringCount: Int

    @State private var showingPhotoViewer = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.UI.Spacing.medium) {
            HStack {
                // Emergency kit photo or placeholder
                if let photoData = emergencyKit.photo,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: AppConstants.UI.Thumbnail.width, height: AppConstants.UI.Thumbnail.height)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
                        .onTapGesture {
                            showingPhotoViewer = true
                        }
                } else {
                    RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                        .fill(Color.gray.opacity(AppConstants.UI.opacity))
                        .frame(width: AppConstants.UI.Thumbnail.width, height: AppConstants.UI.Thumbnail.height)
                        .overlay {
                            Image(systemName: "archivebox")
                                .foregroundColor(.gray)
                                .font(.title2)
                        }
                }

                VStack(alignment: .leading, spacing: AppConstants.UI.Spacing.small) {
                    Text(emergencyKit.name)
                        .font(.headline)
                        .lineLimit(1)

                    if !emergencyKit.location.isEmpty {
                        Label(emergencyKit.location, systemImage: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: AppConstants.UI.Spacing.medium) {
                        Label("\(itemCount)", systemImage: "cube.box")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if expiredCount > 0 {
                            Label("\(expiredCount)", systemImage: "clock.badge.exclamationmark")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        if expiringCount > 0 {
                            Label("\(expiringCount)", systemImage: "clock.badge.exclamationmark")
                                .font(.caption)
                                .foregroundColor(.orange)

                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingPhotoViewer) {
            if let photoData = emergencyKit.photo {
                PhotoViewerView(imageData: photoData)
            }
        }
    }
}

#Preview {
    VStack(spacing: AppConstants.UI.Spacing.medium) {
        // Card with no photo, some expired and expiring items
        EmergencyKitCardView(
            emergencyKit: try! EmergencyKit(
                name: "Home Emergency Kit",
                location: "Basement Storage"
            ),
            itemCount: 12,
            expiredCount: 2,
            expiringCount: 3
        )

        // Card with no expired items
        EmergencyKitCardView(
            emergencyKit: try! EmergencyKit(
                name: "Office First Aid Kit",
                location: "Conference Room"
            ),
            itemCount: 8,
            expiredCount: 0,
            expiringCount: 1
        )

        // Card with no location
        EmergencyKitCardView(
            emergencyKit: try! EmergencyKit(
                name: "Car Emergency Supplies",
                location: "Living Room"
            ),
            itemCount: 5,
            expiredCount: 0,
            expiringCount: 0
        )
    }
    .padding()
}
