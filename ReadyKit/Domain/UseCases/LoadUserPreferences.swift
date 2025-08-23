//
//  LoadUserPreferences.swift
//  ReadyKit
//
//  Created by Luis Wu on 6/28/25.
//

typealias LoadUserPreferencesResult = Result<UserPreferences, Error>

final class LoadUserPreferencesUseCase {
    private let userPreferencesRepository: UserPreferencesRepository
    
    init(userPreferencesRepository: UserPreferencesRepository) {
        self.userPreferencesRepository = userPreferencesRepository
    }
    
    func execute() -> LoadUserPreferencesResult {
        return .success(userPreferencesRepository.load())
    }
}
