//
//  ItemMapper.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/10/25.
//

struct ItemMapper {
    static func toDomain(_ model: ItemModel) throws -> Item {
        try Item(
            id: model.id,
            name: model.name,
            expirationDate: model.expirationDate,
            notes: model.notes,
            quantityValue: model.quantityValue,
            quantityUnitName: model.quantityUnitName,
            photo: model.photo
        )
    }

    static func toModel(_ entity: Item, emergencyKit: EmergencyKitModel?) -> ItemModel {
        ItemModel(
            id: entity.id,
            name: entity.name,
            expirationDate: entity.expirationDate,
            notes: entity.notes,
            emergencyKit: emergencyKit,
            quantityValue: entity.quantityValue,
            quantityUnitName: entity.quantityUnitName,
            photo: entity.photo
        )
    }
}
