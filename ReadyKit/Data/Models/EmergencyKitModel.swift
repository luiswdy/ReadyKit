//
//  EmergencyKitModel.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/10/25.
//

import Foundation
import SwiftData

@Model
final class EmergencyKitModel {
    @Attribute(.unique) var id: UUID
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \ItemModel.emergencyKit)
    var items: [ItemModel]
    var photo: Data?
    var location: String

    init(id: UUID, name: String, items: [ItemModel], photo: Data?, location: String) {
        self.id = id
        self.name = name
        self.items = items
        self.photo = photo
        self.location = location
    }
}
