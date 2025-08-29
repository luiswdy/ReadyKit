//
//  ItemFormView.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/15.
//

import SwiftUI
import PhotosUI

/// Form for adding and editing items
struct ItemFormView: View {
    let onSave: (String, Int, String, Date?, String?, Data?) async -> Result<Void, Error>

    // Optional initial values for editing mode
    private let initialName: String?
    private let initialQuantityText: String?
    private let initialUnit: String?
    private let initialHasExpirationDate: Bool?
    private let initialExpirationDate: Date?
    private let initialNotes: String?
    private let initialPhotoData: Data?

    @State private var name = ""
    @State private var quantityText = ""
    @State private var unit = ""
    @State private var selectedPickerUnit = "" // Add separate state for picker
    @State private var hasExpirationDate = false
    @State private var expirationDate = Date()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage: LocalizedStringKey?
    @State private var showingPhotoOptions = false
    @State private var showingImagePicker = false
    @State private var showingPhotoLibrary = false
    @State private var showingCameraPermissionAlert = false

    @Environment(\.dismiss) private var dismiss

    init(
        onSave: @escaping (String, Int, String, Date?, String?, Data?) async -> Result<Void, Error>,
        initialName: String? = nil,
        initialQuantityText: String? = nil,
        initialUnit: String? = nil,
        initialHasExpirationDate: Bool? = nil,
        initialExpirationDate: Date? = nil,
        initialNotes: String? = nil,
        initialPhotoData: Data? = nil
    ) {
        self.onSave = onSave
        self.initialName = initialName
        self.initialQuantityText = initialQuantityText
        self.initialUnit = initialUnit
        self.initialHasExpirationDate = initialHasExpirationDate
        self.initialExpirationDate = initialExpirationDate
        self.initialNotes = initialNotes
        self.initialPhotoData = initialPhotoData
    }

    // Common units for quick selection
    // Common units for quick selection - breaking up the expression to fix compiler issue
    private var commonUnits: [String] {
        var units = [
            String(localized: "pieces", comment: "Unit type: pieces"),
            String(localized: "cans", comment: "Unit type: cans"),
            String(localized: "bottles", comment: "Unit type: bottles"),
            String(localized: "boxes", comment: "Unit type: boxes"),
            String(localized: "packets", comment: "Unit type: packets"),
            String(localized: "tablets", comment: "Unit type: tablets")
        ]

        // Add Traditional Chinese only unit (as box can refer to 箱 and 盒)
        if Locale.current.language.languageCode?.identifier == "zh" {
            units.append("箱")   // don't need translation
        }

        return units
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $name)
                        .textInputAutocapitalization(.words)

                    HStack {
                        TextField("Quantity", text: $quantityText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Picker("Unit", selection: $selectedPickerUnit) {
                            Text("Select Unit").tag("") // Empty option
                            ForEach(commonUnits, id: \.self) { unitOption in
                                Text(unitOption).tag(unitOption)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: selectedPickerUnit) { _, newValue in
                            if !newValue.isEmpty {
                                unit = newValue
                            }
                        }
                    }

                    TextField("Custom Unit", text: $unit)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                        .overlay(
                            HStack {
                                Spacer()
                                if !unit.isEmpty {
                                    Button(action: {
                                        unit = ""
                                        selectedPickerUnit = "" // Ensure picker selection is cleared
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .padding(.trailing, 8)
                                }
                            }
                        )
                        .onChange(of: unit) { _, newValue in
                            // If user types in the text field, clear the picker selection
                            if !newValue.isEmpty && selectedPickerUnit != newValue {
                                selectedPickerUnit = ""
                            }
                        }
                }

                Section("Expiration") {
                    Toggle("Has Expiration Date", isOn: $hasExpirationDate)

                    if hasExpirationDate {
                        DatePicker(
                            "Expiration Date",
                            selection: $expirationDate,
                            displayedComponents: .date
                        )
                    }
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
                                    .frame(width: AppConstants.UI.Thumbnail.width, height: AppConstants.UI.Thumbnail.height)
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

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveItem()
                        }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .disabled(isSaving)
            .overlay {
                if isSaving {
                    ProgressView("Saving...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(AppConstants.UI.opacity))
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
        }
        .onAppear {
            // Set initial values from parameters
            if let initialName = initialName {
                name = initialName
            }
            if let initialQuantityText = initialQuantityText {
                quantityText = initialQuantityText
            }
            if let initialUnit = initialUnit {
                unit = initialUnit
            } else if unit.isEmpty {
                unit = String(localized: "pieces", comment: "Unit type: pieces")
            }
            if let initialHasExpirationDate = initialHasExpirationDate {
                hasExpirationDate = initialHasExpirationDate
            }
            if let initialExpirationDate = initialExpirationDate {
                expirationDate = initialExpirationDate
            }
            if let initialNotes = initialNotes {
                notes = initialNotes
            }
            if let initialPhotoData = initialPhotoData {
                photoData = initialPhotoData
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !quantityText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(quantityText) != nil &&
        Int(quantityText)! > 0
    }

    private func saveItem() async {
        isSaving = true
        errorMessage = nil

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let quantity = Int(quantityText), quantity > 0 else {
            errorMessage = "Please enter a valid quantity"
            isSaving = false
            return
        }

        // Validate expiration date if set
        if hasExpirationDate {
            let today = Calendar.current.startOfDay(for: Date())
            let selectedDate = Calendar.current.startOfDay(for: expirationDate)

            if selectedDate < today {
                errorMessage = "Expiration date set in the past"
                isSaving = false
                return
            }

            // Optional: Check if date is too far in the future
            let maxYearsFromNow = Calendar.current.date(byAdding: .year, value: AppConstants.MaxExpirationYearsFromNow.value, to: Date()) ?? Date()
            if expirationDate > maxYearsFromNow {
                errorMessage = "Expiration date cannot be more than \(AppConstants.MaxExpirationYearsFromNow.value) years in the future"
                isSaving = false
                return
            }
        }

        let finalExpirationDate = hasExpirationDate ? expirationDate : nil
        let finalNotes = trimmedNotes.isEmpty ? nil : trimmedNotes

        let result = await onSave(trimmedName, quantity, trimmedUnit, finalExpirationDate, finalNotes, photoData)
        switch result {
        case .success:
            break
        case .failure(let error):
            errorMessage = "Failed to save item: \(error.localizedDescription)"
        }

        isSaving = false
    }

    // Remove the checkCameraPermissionAndShowCamera and openAppSettings methods - they are now handled by CameraPermissionHelper
}

#Preview("Empty Form") {
    ItemFormView { name, quantity, unit, expirationDate, notes, photo in
        // Mock save action - shows basic empty form state
        print("Creating item: \(name), \(quantity) \(unit)")
        try? await Task.sleep(nanoseconds: 500_000_000)
        return .success(())
    }
}

#Preview("Pre-filled Food Item") {
    ItemFormView(
        onSave: { name, quantity, unit, expirationDate, notes, photo in
            print("Creating food item: \(name), \(quantity) \(unit)")
            if let expirationDate = expirationDate {
                print("Expires: \(expirationDate)")
            }
            try? await Task.sleep(nanoseconds: 800_000_000)
            return .success(())
        },
        initialName: "Canned Tomatoes",
        initialQuantityText: "6",
        initialUnit: "cans",
        initialHasExpirationDate: true,
        initialExpirationDate: Calendar.current.date(byAdding: .year, value: 2, to: Date()),
        initialNotes: "Store in cool, dry place. Great for pasta sauce and soups."
    )
}

#Preview("Medical Supply") {
    ItemFormView(
        onSave: { name, quantity, unit, expirationDate, notes, photo in
            print("Creating medical item: \(name), \(quantity) \(unit)")
            if let expirationDate = expirationDate {
                print("Critical expiration: \(expirationDate)")
            }
            try? await Task.sleep(nanoseconds: 600_000_000)
            return .success(())
        },
        initialName: "Ibuprofen",
        initialQuantityText: "50",
        initialUnit: "tablets",
        initialHasExpirationDate: true,
        initialExpirationDate: Calendar.current.date(byAdding: .month, value: 18, to: Date()),
        initialNotes: "200mg tablets. Take with food. Check expiration regularly."
    )
}

#Preview("Non-Expiring Item") {
    ItemFormView(
        onSave: { name, quantity, unit, expirationDate, notes, photo in
            print("Creating non-expiring item: \(name), \(quantity) \(unit)")
            try? await Task.sleep(nanoseconds: 400_000_000)
            return .success(())
        },
        initialName: "Emergency Flashlight",
        initialQuantityText: "2",
        initialUnit: "pieces",
        initialHasExpirationDate: false,
        initialNotes: "LED flashlights with hand crank. No batteries required. Test monthly."
    )
}

#Preview("Validation Error") {
    ItemFormView(
        onSave: { name, quantity, unit, expirationDate, notes, photo in
            print("Attempting to save invalid item: \(name)")
            try? await Task.sleep(nanoseconds: 300_000_000)
            return .failure(ItemValidationError.nilExpirationDate) // Always fail to show error state
        },
        initialName: "Test Item",
        initialQuantityText: "1",
        initialUnit: "piece"
    )
}

#Preview("Past Expiration Date") {
    ItemFormView(
        onSave: { name, quantity, unit, expirationDate, notes, photo in
            print("This should trigger validation error for past date")
            try? await Task.sleep(nanoseconds: 200_000_000)
            return .success(())
        },
        initialName: "Old Medicine",
        initialQuantityText: "10",
        initialUnit: "tablets",
        initialHasExpirationDate: true,
        initialExpirationDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())
    )
}
