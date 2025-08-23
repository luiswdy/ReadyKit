//
//  ItemModel.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/10/25.
//

import Foundation
import SwiftData

@Model
final class ItemModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var expirationDate: Date?
    var notes: String?
    @Relationship var emergencyKit: EmergencyKitModel?
    var quantityValue: Int
    var quantityUnitName: String
    var photo: Data? = nil

    init(id: UUID, name: String, expirationDate: Date?, notes: String?, emergencyKit: EmergencyKitModel?, quantityValue: Int, quantityUnitName: String, photo: Data? = nil) {
        self.id = id
        self.name = name
        self.expirationDate = expirationDate
        self.notes = notes
        self.emergencyKit = emergencyKit
        self.quantityValue = quantityValue
        self.quantityUnitName = quantityUnitName
        self.photo = photo
    }
}
