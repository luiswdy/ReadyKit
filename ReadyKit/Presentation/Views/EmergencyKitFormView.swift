//
//  EmergencyKitFormView.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/14/25.
//

import SwiftUI
import PhotosUI
import UIKit

/// Form for creating and editing emergency kits
struct EmergencyKitFormView: View {
    let onSave: (String, String, Data?) async -> Result<Void, Error>
    let emergencyKit: EmergencyKit?

    @State private var name = ""
    @State private var location = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var isSaving = false
    @State private var errorMessage: LocalizedStringKey?
    @State private var showingImagePicker = false
    @State private var showingPhotoOptions = false
    @State private var showingPhotoLibrary = false
    @State private var showingCameraPermissionAlert = false

    @Environment(\.dismiss) private var dismiss

    init(onSave: @escaping (String, String, Data?) async -> Result<Void, Error>, emergencyKit: EmergencyKit? = nil) {
        self.onSave = onSave
        self.emergencyKit = emergencyKit
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Emergency Kit Details") {
                    TextField("Emergency Kit Name", text: $name)
                        .textInputAutocapitalization(.words)

                    TextField("Location", text: $location)
                        .textInputAutocapitalization(.words)
                }

                Section("Photo") {
                    Button {
                        showingPhotoOptions = true
                    } label: {
                        HStack {
                            let hasPhoto = photoData != nil && UIImage(data: photoData!) != nil
                            if hasPhoto {
                                let uiImage = UIImage(data: photoData!)!
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: AppConstants.UI.Thumbnail.width, height: AppConstants.UI.Thumbnail.height)
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
                                Button(role: .destructive) {
                                    photoData = nil
                                    selectedPhoto = nil
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            } else {
                                let placeholder = RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                                    .fill(Color.gray.opacity(AppConstants.UI.opacity))
                                    .frame(width: AppConstants.UI.Thumbnail.height, height: AppConstants.UI.Thumbnail.height)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                    )
                                placeholder
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle(emergencyKit == nil ? "Emergency Kit" : "Edit \(emergencyKit!.name)")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isSaving = true
                        Task {
                            let result = await onSave(name, location, photoData)
                            isSaving = false

                            switch result {
                            case .success:
                                dismiss()
                            case .failure(let error):
                                errorMessage = LocalizedStringKey("Error saving emergency kit: \(error.localizedDescription)")
                            }
                        }
                    }) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(name.isEmpty || location.isEmpty)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
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

                if photoData != nil {
                    Button("Remove Photo", role: .destructive) {
                        photoData = nil
                        selectedPhoto = nil
                    }
                }

                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: .camera) { imageData in
                    photoData = imageData
                }
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                ImagePicker(sourceType: .photoLibrary) { imageData in
                    photoData = imageData
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
            .photosPicker(
                isPresented: .constant(false), // We'll handle this manually
                selection: $selectedPhoto,
                matching: .images
            )
            .onChange(of: selectedPhoto) { oldItem, newItem in
                if let newItem = newItem, newItem != oldItem {
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            photoData = data
                        }
                    }
                }
            }
        }
        .onAppear {
            if let emergencyKit = emergencyKit {
                name = emergencyKit.name
                location = emergencyKit.location
                photoData = emergencyKit.photo
            }
        }
    }
}

#Preview("New Emergency Kit") {
    EmergencyKitFormView { name, location, photo in
        // Mock save operation - always succeeds in preview
        try? await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
        print("Creating new emergency kit: \(name) at \(location)")
        return .success(())
    }
}

#Preview("Edit Emergency Kit") {
    let sampleEmergencyKit = try! EmergencyKit(
        name: "Home Emergency Kit",
        location: "Basement Storage"
    )

    EmergencyKitFormView(
        onSave: { name, location, photo in
            // Mock save operation - always succeeds in preview
            try? await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
            print("Updating emergency kit: \(name) at \(location)")
            return .success(())
        },
        emergencyKit: sampleEmergencyKit
    )
}
