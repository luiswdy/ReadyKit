//
//  Item.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/10/25.
//

import Foundation

enum ItemValidationError: Error, Equatable {
    case emptyName(_ providedName: String)
    case invalidQuantityValue(_ providedValue: Int)
    case invalidQuantityValueInput(_ providedString: String)
    case emptyQuantityUnitName(_ providedUnitName: String)
    case nilExpirationDate
    case tooManyYearsFromToday(_ providedDate: Date)
}

enum ItemError: Error, Equatable {
    case noSuchItem(_ providedId: UUID)
}

struct Item: Equatable {
    let id: UUID
    var name: String
    var expirationDate: Date?
    var notes: String?
    var quantityValue: Int
    var quantityUnitName: String
    var photo: Data? = nil

    init(id: UUID = UUID(), name: String, expirationDate: Date? = nil, notes: String? = nil, quantityValue: Int, quantityUnitName: String, photo: Data? = nil) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ItemValidationError.emptyName(name)
        }
        guard quantityValue > 0 else {
            throw ItemValidationError.invalidQuantityValue(quantityValue)
        }
        guard !quantityUnitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ItemValidationError.emptyQuantityUnitName(quantityUnitName)
        }
        self.id = id
        self.name = name
        self.expirationDate = expirationDate
        self.notes = notes
        self.quantityValue = quantityValue
        self.quantityUnitName = quantityUnitName
        self.photo = photo
    }
}
