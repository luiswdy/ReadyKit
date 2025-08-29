//
//  ItemRepository.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/11.
//

protocol ItemRepository {
    func fetchAllItems() throws -> [Item]
    func fetchExpiring(within days: Int) throws -> [Item]
    func fetchExpired() throws -> [Item]
    func save(item: Item, to emergencyKit: EmergencyKit) throws
    func delete(item: Item) throws
    func fetchItemWithEarliestExpiration() throws -> Item?
}
