//
//  DatabaseBackupViewModel.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/18/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// ViewModel for managing database backup and restore operations
@Observable
@MainActor
final class DatabaseBackupViewModel {

    // MARK: - State
    var isProcessing = false
    var errorMessage: LocalizedStringKey?
    var successMessage: LocalizedStringKey?
    var showingFilePicker = false
    var showingShareSheet = false
    var showingRestoreConfirmation = false
    var filesToShare: [URL] = []
    var selectedRestoreFiles: [URL] = []
    var existingFilesWillBeReplaced = false

    // MARK: - Dependencies
    private let logger: Logger
    private let fileManager: FileManager

    // MARK: - Constants
    private let databaseName = AppConstants.Database.defaultDatabaseFilename
    private let documentsDirectory: URL
    private let databaseFiles: [String]
    private let sleepTime: UInt64 = 200_000_000 // 0.2 seconds in nanoseconds
    private let dbSuffix = ".store"
    private let dbShmSuffix = ".store-shm"
    private let dbWalSuffix = ".store-wal"
    private let dbBackupSuffix = ".backup"
    private let baseName: String

    init(logger: Logger = DefaultLogger.shared, fileManager: FileManager = .default) {
        self.logger = logger
        self.fileManager = fileManager
        self.documentsDirectory = fileManager.urls(for: AppConstants.Database.defaultSearchPathDirectory, in: AppConstants.Database.defaultSearchPathDomainMask).first ?? {
            fatalError("Documents directory could not be found")
        }()
        self.baseName = databaseName.replacingOccurrences(of: dbSuffix, with: "")
        self.databaseFiles = [
            "\(baseName)\(dbSuffix)",
            "\(baseName)\(dbShmSuffix)",
            "\(baseName)\(dbWalSuffix)"
        ]
    }

    // MARK: - Backup Operations

    /// Prepares database files for sharing/backup
    func prepareBackup() {
        guard !isProcessing else { return }

        isProcessing = true
        errorMessage = nil
        successMessage = nil

        var filesToBackup: [URL] = []

        for fileName in databaseFiles {
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: fileURL.path) {
                filesToBackup.append(fileURL)
                logger.logInfo("Found database file for backup: \(fileName)")
            } else {
                logger.logInfo("Database file not found (this may be normal): \(fileName)")
            }
        }

        guard !filesToBackup.isEmpty else {
            errorMessage = "No database files found to backup"
            isProcessing = false
            return
        }

        filesToShare = filesToBackup
        isProcessing = false

        // Use Task to ensure proper async handling
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: sleepTime)
            self.showingShareSheet = true
        }

        logger.logInfo("Database backup prepared with \(filesToBackup.count) files")
    }

    // MARK: - Restore Operations

    /// Initiates the file picker for restore
    func initiateRestore() {
        selectedRestoreFiles = []
        existingFilesWillBeReplaced = false
        showingFilePicker = true
    }

    /// Validates selected files and checks for existing files
    func validateRestoreFiles(_ urls: [URL]) {
        selectedRestoreFiles = urls

        // Check if we have the required files
        let fileNames = urls.map { $0.lastPathComponent }
        let hasStoreFile = fileNames.contains { $0.hasSuffix(dbSuffix) }

        guard hasStoreFile else {
            errorMessage = "Please select a valid .store database file"
            return
        }

        // Check if existing files will be replaced
        existingFilesWillBeReplaced = checkForExistingFiles(urls)
        showingRestoreConfirmation = true
    }

    /// Performs the actual restore operation
    func performRestore() async -> Bool {
        isProcessing = true
        errorMessage = nil
        successMessage = nil

        var backupURLs: [URL] = [] // To store backup URLs for existing files
        do {
            // Validate files before restoring
            guard validateDatabaseFiles(selectedRestoreFiles) else {
                errorMessage = "Selected files are not valid database files"
                isProcessing = false
                return false
            }

            // Backup existing files if they will be replaced
            for file in databaseFiles {
                let fileURL = documentsDirectory.appendingPathComponent(file)
                if fileManager.fileExists(atPath: fileURL.path) {
                    let backupURL = documentsDirectory.appendingPathComponent("\(file)\(dbBackupSuffix)")
                    // make sure backup URL does not already exist
                    if fileManager.fileExists(atPath: backupURL.path) {
                        try fileManager.removeItem(at: backupURL)
                    }
                    try fileManager.moveItem(at: fileURL, to: backupURL)
                    backupURLs.append(backupURL)
                    logger.logInfo("Backed up existing file: \(file) to \(backupURL)")
                }
            }

            // Copy files to documents directory, replacing if needed
            for fileURL in selectedRestoreFiles {
                let fileName = fileURL.lastPathComponent
                let fileExtension = fileURL.pathExtension
                let destinationURL = documentsDirectory.appendingPathComponent("\(baseName).\(fileExtension)")

                // Start accessing security-scoped resource for file importer files
                let isSecurityScoped = fileURL.startAccessingSecurityScopedResource()
                defer {
                    if isSecurityScoped {
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                }

                // Remove destination if exists to avoid copy error
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }

                try fileManager.copyItem(at: fileURL, to: destinationURL)
                logger.logInfo("Restored database file: \(fileName)")
            }

            successMessage = "Database restored successfully. Restart the app to see changes."

            // Optionally, you can also delete the backup files after successful restore
            for backupURL in backupURLs {
                do {
                    try fileManager.removeItem(at: backupURL)
                    logger.logInfo("Removed backup file: \(backupURL.lastPathComponent)")
                } catch {
                    logger.logError("Failed to remove backup file \(backupURL.lastPathComponent): \(error.localizedDescription)")
                }
            }

            isProcessing = false
            return true

        } catch {
            errorMessage = "Failed to restore database: \(error.localizedDescription)"
            logger.logError("Database restore failed: \(error)")
            isProcessing = false

            // Restore any backed up files if available
            for backupURL in backupURLs {
                let originalFileName = backupURL.lastPathComponent.replacingOccurrences(of: dbBackupSuffix, with: "")
                let originalFileURL = documentsDirectory.appendingPathComponent(originalFileName)
                do {
                    try fileManager.moveItem(at: backupURL, to: originalFileURL)
                    logger.logInfo("Restored backup file: \(originalFileName)")
                } catch {
                    logger.logError("Failed to restore backup file \(originalFileName): \(error.localizedDescription)")
                }
            }
            return false
        }
    }

    // MARK: - Validation

    /// Validates that the selected files are valid database files
    private func validateDatabaseFiles(_ urls: [URL]) -> Bool {
        var hasValidStore = false

        for url in urls {
            let fileName = url.lastPathComponent

            // Only check for valid extensions
            guard fileName.hasSuffix(dbSuffix) ||
                    fileName.hasSuffix(dbShmSuffix) ||
                    fileName.hasSuffix(dbWalSuffix) else {
                logger.logError("Invalid database file extension: \(fileName)")
                return false
            }

            // For files from file importer, we need to access security-scoped resource
            var isAccessible = false
            let isSecurityScoped = url.startAccessingSecurityScopedResource()
            defer {
                if isSecurityScoped {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            // Check if file is accessible
            isAccessible = fileManager.isReadableFile(atPath: url.path)

            // Main .store file must be accessible
            if fileName.hasSuffix(dbSuffix) {
                guard isAccessible else {
                    logger.logError("Main database file is not accessible: \(fileName)")
                    return false
                }
                hasValidStore = true
                logger.logInfo("Valid main database file: \(fileName)")
            } else {
                // .shm and .wal files are optional
                if !isAccessible {
                    logger.logInfo("Auxiliary file not accessible (this is normal): \(fileName)")
                } else {
                    logger.logInfo("Valid auxiliary database file: \(fileName)")
                }
            }
        }

        if !hasValidStore {
            logger.logError("No valid .store file found in selection")
            return false
        }
        return true
    }

    /// Checks if any of the restore files will replace existing files
    private func checkForExistingFiles(_ urls: [URL]) -> Bool {
        for url in urls {
            // Map the selected file to the destination file name in app's documents directory
            let fileExtension = url.pathExtension
            let destinationFileName = "\(baseName).\(fileExtension)"
            let destinationURL = documentsDirectory.appendingPathComponent(destinationFileName)

            if fileManager.fileExists(atPath: destinationURL.path) {
                logger.logInfo("Existing file will be replaced: \(destinationFileName)")
                return true
            }
        }
        return false
    }

    // MARK: - Utility

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    func clearError() {
        errorMessage = nil
    }

    func clearSuccess() {
        successMessage = nil
    }

    /// Gets the current database size for display
    func getDatabaseSize() -> String {
        var totalSize: Int64 = 0

        for fileName in databaseFiles {
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            do {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            } catch {
                // File might not exist, which is normal for .shm and .wal files
                continue
            }
        }

        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}
