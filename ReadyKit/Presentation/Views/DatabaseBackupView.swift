//
//  DatabaseBackupView.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/18/25.
//

import SwiftUI
import UniformTypeIdentifiers

/// View for managing database backup and restore operations
struct DatabaseBackupView: View {
    @State private var viewModel = DatabaseBackupViewModel()

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Database Backup")
                .navigationBarTitleDisplayMode(.large)
        }
        .fileImporter(
            isPresented: $viewModel.showingFilePicker,
            allowedContentTypes: [UTType.data],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                // Filter only database-related files
                let filteredUrls = urls.filter { url in
                    let fileName = url.lastPathComponent
                    return fileName.hasSuffix(".store") ||
                           fileName.hasSuffix(".store-shm") ||
                           fileName.hasSuffix(".store-wal")
                }

                if filteredUrls.isEmpty {
                    viewModel.errorMessage = "Please select valid database files (.store, .store-shm, .store-wal)"
                } else {
                    viewModel.validateRestoreFiles(filteredUrls)
                }
            case .failure(let error):
                viewModel.errorMessage = "Failed to select files: \(error.localizedDescription)"
            }
        }
        .alert("Confirm Restore", isPresented: $viewModel.showingRestoreConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.selectedRestoreFiles = []
            }
            Button("Restore", role: .destructive) {
                Task {
                    _ = await viewModel.performRestore()
                    viewModel.showingRestoreConfirmation = false
                }
            }
        } message: {
            if viewModel.existingFilesWillBeReplaced {
                Text("This will replace your existing database. All current data will be lost. This action cannot be undone.")
            } else {
                Text("This will restore the selected database files. Continue?")
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
        .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") {
                viewModel.clearSuccess()
            }
        } message: {
            if let successMessage = viewModel.successMessage {
                Text(successMessage)
            }
        }
        .background(
            ShareSheetPresenter(
                isPresented: $viewModel.showingShareSheet,
                items: viewModel.filesToShare
            )
        )
    }

    private var contentView: some View {
        Form {
            databaseInfoSection
            backupSection
            restoreSection
            warningSection
        }
        .disabled(viewModel.isProcessing)
        .overlay {
            if viewModel.isProcessing {
                ProgressView("Processing...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
    }

    private var databaseInfoSection: some View {
        Section("Database Information") {
            LabeledContent("Current Size", value: viewModel.getDatabaseSize())
            LabeledContent("Files Included") {
                VStack(alignment: .leading, spacing: 2) {
                    Text("• \(AppConstants.Database.defaultDatabaseFilename)")
                    Text("• \(AppConstants.Database.defaultDatabaseFilename)-shm")
                    Text("• \(AppConstants.Database.defaultDatabaseFilename)-wal")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }

    private var backupSection: some View {
        Section("Backup") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Export your database files for backup or transfer")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button {
                    viewModel.prepareBackup()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Database Files")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isProcessing)
            }
            .padding(.vertical, 4)
        }
    }

    private var restoreSection: some View {
        Section("Restore") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Import database files to restore your data")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button {
                    viewModel.initiateRestore()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import Database Files")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isProcessing)
            }
            .padding(.vertical, 4)
        }
    }

    private var warningSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Important Notes")
                        .font(.headline)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("• Backup files contain all your emergency kit data")
                    Text("• Restoring will replace all current data")
                    Text("• Close and restart the app after restoring")
                    Text("• Keep backups in a secure location")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

/// Share sheet for sharing files
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DatabaseBackupView()
}
