//
//  ItemDetailView.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/15.
//

import SwiftUI
import PhotosUI
import SwiftData
import AVFoundation

struct ItemDetailViewBody: View {
    private let dependencyContainer: DependencyContainer
    private let dismiss: DismissAction
    @Binding var showingDeleteConfirmation: Bool
    @State private var viewModel: ItemDetailViewModel
    @State private var showingPhotoViewer = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var currentPhotoData: Data?
    @State private var showingPhotoOptions = false
    @State private var showingImagePicker = false
    @State private var showingPhotoLibrary = false
    @State private var showingCameraPermissionAlert = false

    init(item: Item, emergencyKit: EmergencyKit, dependencyContainer: DependencyContainer, dismiss: DismissAction, showingDeleteConfirmation: Binding<Bool>) {
        self.dependencyContainer = dependencyContainer
        _viewModel = State(wrappedValue: ItemDetailViewModel(item: item, emergencyKit: emergencyKit, dependencyContainer: dependencyContainer))
        self.dismiss = dismiss
        _showingDeleteConfirmation = showingDeleteConfirmation
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isEditing {
                    editingView
                } else {
                    detailView
                }
            }
            .navigationTitle(viewModel.item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.isEditing {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isEditing {
                        HStack {
                            Button("Cancel") {
                                viewModel.cancelEditing()
                            }

                            Button("Save") {
                                Task {
                                    _ = await viewModel.saveChanges()
                                    // Editing will be automatically disabled in the viewModel
                                }
                            }
                            .disabled(viewModel.isLoading)
                        }
                    } else {
                        Menu {
                            Button("Edit") {
                                viewModel.startEditing()
                            }

                            Button("Delete", role: .destructive) {
                                showingDeleteConfirmation = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("Delete Item", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        let result = await viewModel.deleteItem()
                        switch result {
                        case .success:
                            dismiss()
                        case .failure:
                            break
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete '\(viewModel.item.name)'? This action cannot be undone.")
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
            .disabled(viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Processing...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(AppConstants.UI.opacity))
                }
            }
        }
        .fullScreenCover(isPresented: $showingPhotoViewer) {
            if let photoData = viewModel.item.photo {
                PhotoViewerView(imageData: photoData)
            }
        }
        .confirmationDialog("Select Photo", isPresented: $showingPhotoOptions, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") {
                    CameraPermissionHelper.checkCameraPermissionAndShowCamera(
                        onAuthorized: { showingImagePicker = true },
                        onDenied: { showingCameraPermissionAlert = true }
                    )
                }
            }

            Button("Choose from Library") {
                showingPhotoLibrary = true
            }

            if currentPhotoData != nil {
                Button("Remove Photo", role: .destructive) {
                    Task { @MainActor in
                        viewModel.editedPhoto = nil
                        currentPhotoData = nil
                        selectedPhoto = nil
                    }
                }
            }

            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: .camera) { imageData in
                Task { @MainActor in
                    viewModel.editedPhoto = imageData
                    currentPhotoData = imageData
                }
            }
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            ImagePicker(sourceType: .photoLibrary) { imageData in
                Task { @MainActor in
                    viewModel.editedPhoto = imageData
                    currentPhotoData = imageData
                }
            }
        }
        .alert("Camera Access Required", isPresented: $showingCameraPermissionAlert) {
            Button("Cancel", role: .cancel) {
                // Do nothing, just dismiss the alert
            }
            Button("Open Settings") {
                AppSettingsHelper.openAppSettings()
            }
        } message: {
            Text("Camera access is required to take photos. Please enable camera access in Settings to use this feature.")
        }
        .onChange(of: viewModel.isEditing) { _, isEditing in
            Task { @MainActor in
                if isEditing {
                    // Reset photoData to current item photo when starting to edit
                    viewModel.editedPhoto = viewModel.item.photo
                    currentPhotoData = viewModel.item.photo
                } else {
                    // Clear local photoData when not editing
                    viewModel.editedPhoto = nil
                    currentPhotoData = nil
                    selectedPhoto = nil
                }
            }
        }
    }

    private var detailView: some View {
        Form {
            Section("Item Information") {
                LabeledContent("Name", value: viewModel.item.name)
                LabeledContent("Quantity", value: viewModel.formatQuantity())
                LabeledContent("Emergency Kit", value: viewModel.emergencyKit.name)
            }

            Section("Expiration") {
                let status = viewModel.formatExpirationStatus()
                LabeledContent("Status") {
                    Text(status.text)
                        .foregroundColor(status.color)
                }

                if let expirationDate = viewModel.item.expirationDate {
                    LabeledContent("Expiration Date") {
                        Text(expirationDate, style: .date)
                    }
                }
            }

            if let notes = viewModel.item.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }

            if let photoData = viewModel.item.photo,
               let uiImage = UIImage(data: photoData) {
                Section("Photo") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: AppConstants.UI.Thumbnail.width, height: AppConstants.UI.Thumbnail.height)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
                        .onTapGesture {
                            showingPhotoViewer = true
                        }
                }
            }
        }
    }

    private var editingView: some View {
        Form {
            Section("Item Information") {
                TextField("Name", text: $viewModel.editedName)
                    .textInputAutocapitalization(.words)

                HStack {
                    TextField("Quantity", text: $viewModel.editedQuantityValue)
                        .keyboardType(.numberPad)

                    TextField("Unit", text: $viewModel.editedQuantityUnit)
                        .textInputAutocapitalization(.never)
                }
            }

            Section("Expiration") {
                Toggle("Has Expiration Date", isOn: $viewModel.hasExpirationDate)

                if viewModel.hasExpirationDate {
                    DatePicker(
                        "Expiration Date",
                        selection: Binding(
                            get: { viewModel.editedExpirationDate ?? Date() },
                            set: { viewModel.editedExpirationDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                }
            }

            Section("Photo") {
                Button {
                    showingPhotoOptions = true
                } label: {
                    PhotoDisplayContent(
                        editedPhoto: currentPhotoData,
                        onDelete: {
                            Task { @MainActor in
                                viewModel.editedPhoto = nil
                                currentPhotoData = nil
                                selectedPhoto = nil
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }

            Section("Notes") {
                TextField("Notes (optional)", text: $viewModel.editedNotes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
    }
}

/// Detail view for viewing and editing individual items
struct ItemDetailView: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    private let item: Item
    private let emergencyKit: EmergencyKit
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false

    init(item: Item, emergencyKit: EmergencyKit) {
        self.item = item
        self.emergencyKit = emergencyKit
    }

    var body: some View {
        ItemDetailViewBody(
            item: item,
            emergencyKit: emergencyKit,
            dependencyContainer: dependencyContainer,
            dismiss: dismiss,
            showingDeleteConfirmation: $showingDeleteConfirmation
        )
    }

}

/// A view component that displays photo content for the item detail editor
struct PhotoDisplayContent: View {
    let editedPhoto: Data?
    let onDelete: () -> Void

    var body: some View {
        HStack {
            // Show newly selected photo if available, otherwise show original photo
            if let photoData = editedPhoto, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: AppConstants.UI.Thumbnail.width, height: AppConstants.UI.Thumbnail.height)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            } else {
                RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                    .fill(Color.gray.opacity(AppConstants.UI.opacity))
                    .frame(width: AppConstants.UI.Thumbnail.width, height: AppConstants.UI.Thumbnail.height)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
        }
    }
}

#Preview("Expired Item") {
    let schema = Schema([
        EmergencyKitModel.self,
        ItemModel.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    let dependencyContainer = DependencyContainer(modelContext: ModelContext(container))

    let sampleEmergencyKit = try! EmergencyKit(
        name: "Home Emergency Kit",
        location: "Basement Storage"
    )

    let expiredItem = try! Item(
        name: "Canned Beans",
        expirationDate: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
        notes: "Expired last month, need to replace",
        quantityValue: 2,
        quantityUnitName: "cans"
    )

    ItemDetailView(item: expiredItem, emergencyKit: sampleEmergencyKit)
        .modelContainer(container)
        .environmentObject(dependencyContainer)
}

#Preview("Expiring Soon") {
    let schema = Schema([
        EmergencyKitModel.self,
        ItemModel.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    let dependencyContainer = DependencyContainer(modelContext: ModelContext(container))

    let sampleEmergencyKit = try! EmergencyKit(
        name: "Office First Aid Kit",
        location: "Conference Room"
    )

    let expiringSoonItem = try! Item(
        name: "Pain Medication",
        expirationDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
        notes: "Check expiration date weekly",
        quantityValue: 20,
        quantityUnitName: "tablets"
    )

    ItemDetailView(item: expiringSoonItem, emergencyKit: sampleEmergencyKit)
        .modelContainer(container)
        .environmentObject(dependencyContainer)
}

#Preview("No Expiration Date") {
    let schema = Schema([
        EmergencyKitModel.self,
        ItemModel.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    let dependencyContainer = DependencyContainer(modelContext: ModelContext(container))

    let sampleEmergencyKit = try! EmergencyKit(
        name: "Car Emergency Kit",
        location: "Trunk"
    )

    let noExpirationItem = try! Item(
        name: "Flashlight",
        expirationDate: nil,
        notes: "Battery-powered LED flashlight with extra batteries stored separately",
        quantityValue: 1,
        quantityUnitName: "piece"
    )

    ItemDetailView(item: noExpirationItem, emergencyKit: sampleEmergencyKit)
        .modelContainer(container)
        .environmentObject(dependencyContainer)
}
