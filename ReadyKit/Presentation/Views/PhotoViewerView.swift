//
//  PhotoViewerView.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/15.
//

import SwiftUI

/// A full-screen photo viewer with zoom and dismiss capabilities
struct PhotoViewerView: View {
    let imageData: Data
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private enum UIConstants {
        static let minScale: CGFloat = 1.0
        static let maxScale: CGFloat = 5.0
        static let doubleTapScale: CGFloat = 2.0
    }

    // MARK: - Computed Properties
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }

    private var toolbarForegroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if let uiImage = UIImage(data: imageData) {
                    ZStack {
                        backgroundColor.ignoresSafeArea()

                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(zoomAndPanGesture(geometry: geometry, uiImage: uiImage))
                            .onTapGesture(count: 2) {
                                handleDoubleTap()
                            }
                    }
                } else {
                    errorView
                }
            }
            .navigationTitle("Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(toolbarForegroundColor)
                }
            }
        }
    }

    // MARK: - Private Views
    private var errorView: some View {
        VStack {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: AppConstants.UI.SystemImage.fontSize))
                .foregroundColor(.gray)
            Text("Unable to load image")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
    }

    // MARK: - Gesture Handlers
    private func zoomAndPanGesture(geometry: GeometryProxy, uiImage: UIImage) -> some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    scale = lastScale * value
                }
                .onEnded { _ in
                    handleZoomEnd()
                },
            DragGesture()
                .onChanged { value in
                    handlePanChanged(value: value)
                }
                .onEnded { _ in
                    handlePanEnd(geometry: geometry, uiImage: uiImage)
                }
        )
    }

    private func handleZoomEnd() {
        lastScale = scale

        // Limit zoom - minimum is fit to screen, maximum is 5x
        if scale < UIConstants.minScale {
            resetToFitScreen()
        } else if scale > UIConstants.maxScale {
            withAnimation(.easeOut(duration: AppConstants.UI.animationDuration)) {
                scale = UIConstants.maxScale
                lastScale = UIConstants.maxScale
            }
        }
    }

    private func handlePanChanged(value: DragGesture.Value) {
        // Only allow panning when zoomed in
        if scale > UIConstants.minScale {
            offset = CGSize(
                width: lastOffset.width + value.translation.width,
                height: lastOffset.height + value.translation.height
            )
        }
    }

    private func handlePanEnd(geometry: GeometryProxy, uiImage: UIImage) {
        lastOffset = offset

        // Constrain panning to keep image within bounds when zoomed
        if scale > UIConstants.minScale {
            constrainOffset(geometry: geometry, uiImage: uiImage)
        }
    }

    private func handleDoubleTap() {
        withAnimation(.easeInOut(duration: AppConstants.UI.animationDuration)) {
            if scale > UIConstants.minScale {
                resetToFitScreen()
            } else {
                scale = UIConstants.doubleTapScale
                lastScale = UIConstants.doubleTapScale
            }
        }
    }

    private func resetToFitScreen() {
        withAnimation(.easeOut(duration: AppConstants.UI.animationDuration)) {
            scale = UIConstants.minScale
            lastScale = UIConstants.minScale
            offset = .zero
            lastOffset = .zero
        }
    }

    private func constrainOffset(geometry: GeometryProxy, uiImage: UIImage) {
        let imageSize = calculateImageSize(uiImage: uiImage, containerSize: geometry.size)
        let scaledImageSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )

        let maxOffsetX = max(0, (scaledImageSize.width - geometry.size.width) / 2)
        let maxOffsetY = max(0, (scaledImageSize.height - geometry.size.height) / 2)

        let constrainedOffset = CGSize(
            width: min(maxOffsetX, max(-maxOffsetX, offset.width)),
            height: min(maxOffsetY, max(-maxOffsetY, offset.height))
        )

        if constrainedOffset != offset {
            withAnimation(.easeOut(duration: AppConstants.UI.animationDuration)) {
                offset = constrainedOffset
                lastOffset = constrainedOffset
            }
        }
    }

    // MARK: - Helper Methods
    private func calculateImageSize(uiImage: UIImage, containerSize: CGSize) -> CGSize {
        let imageAspectRatio = uiImage.size.width / uiImage.size.height
        let containerAspectRatio = containerSize.width / containerSize.height

        if imageAspectRatio > containerAspectRatio {
            // Image is wider than container - fit by width
            let width = containerSize.width
            let height = width / imageAspectRatio
            return CGSize(width: width, height: height)
        } else {
            // Image is taller than container - fit by height
            let height = containerSize.height
            let width = height * imageAspectRatio
            return CGSize(width: width, height: height)
        }
    }
}

#Preview {
    if let imageData = UIImage(systemName: "photo")?.pngData() {
        PhotoViewerView(imageData: imageData)
    }
}
