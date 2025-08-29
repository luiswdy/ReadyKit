//
//  DefaultLogger.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/17/25.
//

import Foundation

#if DEBUG
import os
#endif

enum LogLevel: Int, Comparable, CaseIterable {
    case debug = 0, info, warning, error, fatal

    var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .fatal: return "FATAL"
        }
    }

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

final class DefaultLogger: Logger {
    private let directory: URL
    private let maxFileSize: UInt64
    private let maxFileCount: Int
    private let logLevel: LogLevel
    private let filePrefix: String
    private let fileExtension = "log"
    private let queue = DispatchQueue(label: "LogFileManagerQueue")
    private var fileHandle: FileHandle?
    private var currentFileURL: URL

    static let shared: DefaultLogger = {
        let logURL = FileManager.default.urls(for: AppConstants.Log.directory, in: .userDomainMask).first!
        return DefaultLogger(directory: logURL,
                              maxFileSize: AppConstants.Log.fileSize,
                              maxFileCount: AppConstants.Log.fileCount,
                              logLevel: AppConstants.Log.level,
                              filePrefix: AppConstants.Log.filePrefix)
    }()

    private init(directory: URL? = nil,
                 maxFileSize: UInt64,
                 maxFileCount: Int,
                 logLevel: LogLevel,
                 filePrefix: String) {
        let dir = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.directory = dir
        self.maxFileSize = maxFileSize
        self.maxFileCount = maxFileCount
        self.logLevel = logLevel
        self.filePrefix = filePrefix
        self.currentFileURL = dir.appendingPathComponent("\(filePrefix)0.\(fileExtension)")
        createLogFileIfNeeded()
        openFileHandle()
    }

    deinit {
        close()
    }

    // MARK: - Public Logging Methods



    func logInfo(_ message: String) { log(message, level: .info) }
    func logWarning(_ message: String) { log(message, level: .warning) }
    func logError(_ message: String) { log(message, level: .error) }
    func logDebug(_ message: String) { log(message, level: .debug) }
    func logFatal(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] [\(LogLevel.fatal.description)] \(message)\n"
        queue.sync { [weak self] in
            self?.write(logEntry, isFatal: true)
        }
    }

    func close() {
        queue.sync {
            do {
                try fileHandle?.synchronize()
                try fileHandle?.close()
            } catch {
                logError("Failed to close log file: \(error.localizedDescription)")
            }
            fileHandle = nil
        }
    }

    // MARK: - Private File Management

    private func createLogFileIfNeeded() {
        if !FileManager.default.fileExists(atPath: currentFileURL.path) {
            FileManager.default.createFile(atPath: currentFileURL.path, contents: nil)
        }
    }

    private func openFileHandle() {
        do {
            fileHandle = try FileHandle(forWritingTo: currentFileURL)
            fileHandle?.seekToEndOfFile()
        } catch {
            fileHandle = nil
            logError("Failed to open log file: \(error.localizedDescription). Logger disabled.")
        }
    }

    private func write(_ entry: String, isFatal: Bool) {
        guard let data = entry.data(using: .utf8) else { return }
        rotateIfNeeded(adding: UInt64(data.count))
        do {
            fileHandle?.write(data)
            try fileHandle?.synchronize()
            if isFatal {
                // If a fatal error occurs, close the file handle and set it to nil
                try fileHandle?.close()
                fileHandle = nil
                assertionFailure("Fatal log entry written. Log file closed.")
            }
        } catch {
            logError("Failed to write log entry: \(error.localizedDescription)")
        }
    }

    private func rotateIfNeeded(adding size: UInt64) {
        let currentSize = (try? FileManager.default.attributesOfItem(atPath: currentFileURL.path)[.size] as? UInt64) ?? 0
        if currentSize + size > maxFileSize {
            rotateFiles()
        }
    }

    private func rotateFiles() {
        // Close current file handle before rotating
        do {
            try fileHandle?.synchronize()
            try fileHandle?.close()
        } catch {
            logError("Failed to close log file before rotation: \(error.localizedDescription)")
        }
        fileHandle = nil
        for i in stride(from: maxFileCount - 1, through: 0, by: -1) {
            let oldURL = directory.appendingPathComponent("\(filePrefix)\(i).\(fileExtension)")
            let newURL = directory.appendingPathComponent("\(filePrefix)\(i + 1).\(fileExtension)")
            if FileManager.default.fileExists(atPath: oldURL.path) {
                if i + 1 >= maxFileCount {
                    try? FileManager.default.removeItem(at: oldURL)
                } else {
                    try? FileManager.default.moveItem(at: oldURL, to: newURL)
                }
            }
        }
        currentFileURL = directory.appendingPathComponent("\(filePrefix)0.\(fileExtension)")
        FileManager.default.createFile(atPath: currentFileURL.path, contents: nil)
        openFileHandle()
    }

    // MARK: - Private Logging Method

    private func log(_ message: String, level: LogLevel) {
        guard level >= logLevel else { return }
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] [\(level.description)] \(message)\n"
        queue.async { [weak self] in
            self?.write(logEntry, isFatal: false)
        }

        #if DEBUG
        let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "io.wdy.ReadyKitApp", category: "DefaultLogger")
        let osLogType: OSLogType
        switch level {
        case .debug:
            osLogType = .debug
        case .info, .warning:
            osLogType = .info
        case .error:
            osLogType = .error
        case .fatal:
            osLogType = .fault
        }
        os_log("%{public}@", log: log, type: osLogType, logEntry)
        #endif
    }
}
