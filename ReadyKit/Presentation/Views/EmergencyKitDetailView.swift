//
//  EmergencyKitDetailView.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/15.
//

import SwiftUI
import SwiftData

struct EmergencyKitDetailViewBody: View {
    private let dependencyContainer: DependencyContainer
    @State private var viewModel: EmergencyKitDetailViewModel
    @State private var showingDeleteConfirmation = false
    @State private var pendingDeleteItem: Item? = nil

    init(emergencyKit: EmergencyKit, dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
        _viewModel = State(wrappedValue: EmergencyKitDetailViewModel(emergencyKit: emergencyKit, container: dependencyContainer))
    }

    var body: some View {
        Group {
            if viewModel.hasItems {
                itemsListView
            } else {
                EmptyStateView(
                    title: "No Items Yet",
                    message: "Add your first item to this emergency kit.",
                    systemImage: "cube.box",
                    actionTitle: "Add Item"
               ) {
                    viewModel.showingAddItemForm = true
                }
            }
        }
        .navigationTitle(viewModel.emergencyKit.name)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.searchText, prompt: "Search items")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.showingAddItemForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable {
            viewModel.refreshEmergencyKit()
        }
        .sheet(isPresented: $viewModel.showingAddItemForm, onDismiss: {
            // Refresh emergency kit data after adding item
            viewModel.refreshEmergencyKit()
        }) {
            ItemFormView(
                onSave: { name, quantity, unit, expirationDate, notes, photo in
                    let result = viewModel.addItem(
                        name: name,
                        quantityValue: quantity,
                        quantityUnit: unit,
                        expirationDate: expirationDate,
                        notes: notes,
                        photo: photo
                    )

                    switch result {
                    case .success:
                        viewModel.showingAddItemForm = false
                    case .failure:
                        break // viewModel will handle showing the error
                    }
                    return result
                }
            )
        }
        .sheet(isPresented: $viewModel.showingItemDetail, onDismiss: {
            // Refresh emergency kit data when item detail view is dismissed
            // This handles cases where items were edited or deleted
            viewModel.refreshEmergencyKit()
        }) {
            if let selectedItem = viewModel.selectedItem {
                ItemDetailView(item: selectedItem, emergencyKit: viewModel.emergencyKit)
                    .environmentObject(dependencyContainer)
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
        .alert("Delete Item?", isPresented: $showingDeleteConfirmation, actions: {
            Button(String(localized: "Delete"), role: .destructive) {
                if let item = pendingDeleteItem {
                    _ = viewModel.deleteItem(item)
                    pendingDeleteItem = nil
                }
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteItem = nil
            }
        }, message: {
            Text("Are you sure you want to delete this item?")
        })
    }

    private var itemsListView: some View {
        List {
            ForEach(viewModel.filteredItems, id: \.id) { item in
                ItemListItemView(
                    item: item,
                    expirationStatus: viewModel.formatExpirationStatus(for: item),
                    onTap: { viewModel.selectItem(item) },
                    onDuplicate: { viewModel.duplicateItem(item) },
                    onDelete: {
                        pendingDeleteItem = item
                        showingDeleteConfirmation = true
                    }
                )
            }
        }
        .listStyle(PlainListStyle())
    }
}

/// Detail view for a specific emergency kit showing all its items
struct EmergencyKitDetailView: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    private let emergencyKit: EmergencyKit

    init(emergencyKit: EmergencyKit) {
        self.emergencyKit = emergencyKit
    }

    var body: some View {
        EmergencyKitDetailViewBody(
            emergencyKit:  emergencyKit,
            dependencyContainer: dependencyContainer
        )
        .environmentObject(dependencyContainer)
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

    let sampleEmergencyKit = try! EmergencyKit(
        name: "Emergency Food Supply",
        location: "Kitchen Pantry"
    )

    return NavigationStack {
        EmergencyKitDetailView(emergencyKit: sampleEmergencyKit)
            .modelContainer(container)
            .environmentObject(dependencyContainer)
    }
}
