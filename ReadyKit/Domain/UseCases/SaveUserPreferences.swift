//
//  SaveUserPreferences.swift
//  ReadyKit
//
//  Created by Luis Wu on 6/28/25.
//

struct SaveUserPreferencesRequest {
    let preferences: UserPreferences
}

typealias SaveUserPreferencesResult = Result<Void, Error>

final class SaveUserPreferencesUseCase {
    private let userPreferencesRepository: UserPreferencesRepository
    
    init(userPreferencesRepository: UserPreferencesRepository) {
        self.userPreferencesRepository = userPreferencesRepository
    }
    
    func execute(request: SaveUserPreferencesRequest) -> SaveUserPreferencesResult {
        userPreferencesRepository.save(request.preferences)
        return .success(())
    }
}
