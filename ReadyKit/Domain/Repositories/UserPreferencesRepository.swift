//
//  UserPreferencesStore.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/11.
//

protocol UserPreferencesRepository {
    func save(_ preferences: UserPreferences)
    func load() -> UserPreferences
}
