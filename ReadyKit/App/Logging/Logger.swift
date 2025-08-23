//
//  Logger.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/17/25.
//

public protocol Logger {
    func logDebug(_ message: String)
    func logInfo(_ message: String)
    func logWarning(_ message: String)
    func logError(_ message: String)
    func logFatal(_ message: String)
}
