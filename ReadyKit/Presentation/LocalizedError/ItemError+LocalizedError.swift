//
//  ItemError+LocalizedError.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/18/25.
//

import SwiftUICore

extension ItemError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noSuchItem(let providedUUID):
            return String(localized: "No such item UUID: \(providedUUID.uuidString)", comment: "Error when an item with the provided ID does not exist.")
        }
    }
}
