//
//  EmergencyKitMapper.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/10/25.
//

struct EmergencyKitMapper {
    static func toDomain(_ model: EmergencyKitModel) throws -> EmergencyKit {
        try EmergencyKit(
            id: model.id,
            name: model.name,
            items: try model.items.map { try ItemMapper.toDomain($0) },
            photo: model.photo,
            location: model.location
        )
    }

    static func toModel(_ entity: EmergencyKit) -> EmergencyKitModel {
        let emergencyKitModel = EmergencyKitModel(
            id: entity.id,
            name: entity.name,
            items: [],
            photo: entity.photo,
            location: entity.location
        )
        emergencyKitModel.items = entity.items.map { ItemMapper.toModel($0, emergencyKit: emergencyKitModel) }
        return emergencyKitModel
    }
}
