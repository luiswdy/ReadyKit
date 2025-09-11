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
    let onMoveItem: ((Item, EmergencyKit) async -> Result<Void, Error>)?
    let currentKit: EmergencyKit?
    let availableKits: [EmergencyKit]
    let existingItem: Item?

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
    @State private var selectedKit: EmergencyKit?

    @Environment(\.dismiss) private var dismiss

    init(
        onSave: @escaping (String, Int, String, Date?, String?, Data?) async -> Result<Void, Error>,
        onMoveItem: ((Item, EmergencyKit) async -> Result<Void, Error>)? = nil,
        currentKit: EmergencyKit? = nil,
        availableKits: [EmergencyKit] = [],
        existingItem: Item? = nil,
        initialName: String? = nil,
        initialQuantityText: String? = nil,
        initialUnit: String? = nil,
        initialHasExpirationDate: Bool? = nil,
        initialExpirationDate: Date? = nil,
        initialNotes: String? = nil,
        initialPhotoData: Data? = nil
    ) {
        self.onSave = onSave
        self.onMoveItem = onMoveItem
        self.currentKit = currentKit
        self.availableKits = availableKits
        self.existingItem = existingItem
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
                itemDetailsSection
                expirationSection
                photoSection
                notesSection

                // Show emergency kit section only when editing an existing item
                if isEditing {
                    emergencyKitSection
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
                photoDialogButtons
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
            setupInitialValues()
        }
    }

    // MARK: - View Components

    private var isEditing: Bool {
        existingItem != nil
    }

    private var itemDetailsSection: some View {
        Section("Item Details") {
            TextField("Item Name", text: $name)
                .textInputAutocapitalization(.words)

            quantityAndUnitRow
            customUnitField
        }
    }

    private var quantityAndUnitRow: some View {
        HStack {
            TextField("Quantity", text: $quantityText)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            unitPicker
        }
    }

    private var unitPicker: some View {
        Picker("Unit", selection: $selectedPickerUnit) {
            Text("Select Unit").tag("") // Empty option
            ForEach(commonUnits, id: \.self) { unitOption in
                Text(unitOption).tag(unitOption)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .onChange(of: selectedPickerUnit) { oldValue, newValue in
            if !newValue.isEmpty {
                unit = newValue
            }
        }
    }

    private var customUnitField: some View {
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

    private var expirationSection: some View {
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
    }

    private var photoSection: some View {
        Section("Photo") {
            Button {
                showingPhotoOptions = true
            } label: {
                photoDisplay
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var photoDisplay: some View {
        HStack {
            let hasPhoto = photoData != nil && UIImage(data: photoData!) != nil
            if hasPhoto {
                existingPhotoView
            } else {
                photoPlaceholder
            }
        }
    }

    private var existingPhotoView: some View {
        Group {
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
        }
    }

    private var photoPlaceholder: some View {
        RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
            .fill(Color.gray.opacity(AppConstants.UI.opacity))
            .frame(width: AppConstants.UI.Thumbnail.width, height: AppConstants.UI.Thumbnail.height)
            .overlay(
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            )
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("Notes (optional)", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var emergencyKitSection: some View {
        Section("Emergency Kit") {
            kitPicker
            kitSelectionDisplay
        }
    }

    private var kitPicker: some View {
        Picker("Select Kit", selection: $selectedKit) {
            ForEach(availableKits, id: \.id) { kit in
                Text(kit.name).tag(Optional(kit))
            }
        }
        .pickerStyle(MenuPickerStyle())
    }

    private var kitSelectionDisplay: some View {
        Group {
            if let selectedKit = selectedKit {
                Text("Selected Kit: \(selectedKit.name)")
                    .foregroundColor(.secondary)
            } else {
                Text("No kit selected")
                    .foregroundColor(.gray)
            }
        }
    }

    private var photoDialogButtons: some View {
        Group {
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
    }

    // MARK: - Helper Methods

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

        // If editing an existing item, we might want to move it to a new kit
        if let existingItem = existingItem, let onMoveItem = onMoveItem, let currentKit = currentKit, currentKit != selectedKit {
            // Move item to selected kit
            let result = await onMoveItem(existingItem, selectedKit!)
            switch result {
            case .success:
                // Item moved, now save the new details
                let saveResult = await onSave(trimmedName, quantity, trimmedUnit, finalExpirationDate, finalNotes, photoData)
                switch saveResult {
                case .success:
                    break
                case .failure(let error):
                    errorMessage = "Failed to save item: \(error.localizedDescription)"
                }
            case .failure(let error):
                errorMessage = "Failed to move item: \(error.localizedDescription)"
            }
        } else {
            // New item or no kit change, just save the item
            let result = await onSave(trimmedName, quantity, trimmedUnit, finalExpirationDate, finalNotes, photoData)
            switch result {
            case .success:
                break
            case .failure(let error):
                errorMessage = "Failed to save item: \(error.localizedDescription)"
            }
        }

        isSaving = false
    }

    private func setupInitialValues() {
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
            // Set a default unit for new items to ensure canSave validation passes
            unit = "pieces"
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

        // Initialize selectedKit with current kit
        selectedKit = currentKit
    }
}
