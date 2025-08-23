import SwiftUI
import PhotosUI
import SwiftData

/// Main screen showing all emergency kits
struct EmergencyKitListViewBody: View {
    @State private var viewModel: EmergencyKitListViewModel
    @State private var showingCreateForm = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showingDeleteConfirmation = false
    @State private var emergencyKitToDelete: EmergencyKit?

    init(dependencyContainer: DependencyContainer) {
        _viewModel = State(wrappedValue: EmergencyKitListViewModel(dependencyContainer: dependencyContainer))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.emergencyKits.isEmpty {
                    LoadingView()
                } else if viewModel.hasEmergencyKits {
                    emergencyKitsListView
                } else {
                    EmptyStateView(
                        title: "No Emergency Kits Yet",
                        message: "Create your first emergency kit to get started.",
                        systemImage: "archivebox",
                        actionTitle: "Create Emergency Kit"
                    ) {
                        showingCreateForm = true
                    }
                }
            }
            .navigationTitle("Emergency Kits")
            .searchable(text: $viewModel.searchText, prompt: "Search emergency kits")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .refreshable {
                viewModel.refresh()
            }
            .onAppear {
                // Refresh emergency kit data when returning to list view
                // This ensures we have the latest data including any item changes
                viewModel.refresh()
            }
            .sheet(isPresented: $showingCreateForm) {
                EmergencyKitFormView { name, location, photo in
                    let result = viewModel.createEmergencyKit(
                        name: name,
                        location: location,
                        photo: photo
                    )

                    switch result {
                    case .success:
                        showingCreateForm = false
                    case .failure:
                        break
                    }
                    return result
                }
            }
            .sheet(isPresented: $viewModel.showingEditForm) {
                EmergencyKitFormView(
                    onSave: { name, location, photo in
                        guard let emergencyKitToEdit = viewModel.emergencyKitToEdit else { return .failure(EmergencyKitError.nilEmergencyKitId) }
                        let result = viewModel.updateEmergencyKit(
                            emergencyKitToEdit,
                            name: name,
                            location: location,
                            photo: photo
                        )

                        switch result {
                        case .success:
                            viewModel.showingEditForm = false
                            viewModel.emergencyKitToEdit = nil
                        case .failure(_):
                            break
                        }
                        return result
                    },
                    emergencyKit: viewModel.emergencyKitToEdit
                )
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
            .alert("Confirm Deletion", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let emergencyKitToDelete = emergencyKitToDelete {
                        viewModel.deleteEmergencyKit(emergencyKitToDelete)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this emergency kit?")
            }
        }
    }

    private var emergencyKitsListView: some View {
        List {
            ForEach(viewModel.filteredEmergencyKits, id: \.id) { emergencyKit in
                NavigationLink(destination: EmergencyKitDetailView(emergencyKit: emergencyKit)) {
                    EmergencyKitCardView(
                        emergencyKit: emergencyKit,
                        itemCount: viewModel.itemCount(for: emergencyKit),
                        expiredCount: viewModel.expiredItemsCount(for: emergencyKit),
                        expiringCount: viewModel.expiringItemsCount(for: emergencyKit)
                    )
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .swipeActions(edge: .trailing) {
                    Button {
                        viewModel.editEmergencyKit(emergencyKit)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)

                    Button {
                        emergencyKitToDelete = emergencyKit
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
            }
            .onDelete(perform: deleteEmergencyKits)
        }
        .listStyle(PlainListStyle())
        .photosPicker(
            isPresented: $viewModel.showingPhotoSelection,
            selection: $selectedPhoto,
            matching: .images
        )
        .onChange(of: selectedPhoto) { _, newPhoto in
            Task {
                if let newPhoto = newPhoto {
                    if let data = try? await newPhoto.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            let result = viewModel.updateEmergencyKitPhoto(data)
                            switch result {
                            case .success:
                                selectedPhoto = nil
                            case .failure(let error):
                                viewModel.errorMessage = "Failed to update emergency kit photo: \(error.localizedDescription)"
                            }
                        }
                    } else {
                        await MainActor.run {
                            viewModel.errorMessage = "Failed to load photo data."
                            selectedPhoto = nil
                        }
                    }
                } else {
                    await MainActor.run {
                        let result = viewModel.updateEmergencyKitPhoto(nil)
                        switch result {
                        case .success:
                            selectedPhoto = nil
                        case .failure(let error):
                            viewModel.errorMessage = "Failed to remove emergency kit photo: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
  }

    private func deleteEmergencyKits(offsets: IndexSet) {
        for index in offsets {
            let emergencyKit = viewModel.filteredEmergencyKits[index]
            viewModel.deleteEmergencyKit(emergencyKit)
        }
    }
}

struct EmergencyKitListView: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer

    var body: some View {
        EmergencyKitListViewBody(dependencyContainer: dependencyContainer)
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

    EmergencyKitListView()
        .modelContainer(container)
        .environmentObject(dependencyContainer)
}
