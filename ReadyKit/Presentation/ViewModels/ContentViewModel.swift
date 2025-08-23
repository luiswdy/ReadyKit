//
//  ContentViewModel.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/14/25.
//

import Foundation

@Observable
@MainActor
class ContentViewModel {
    private let updateAppBadgeUseCase: UpdateAppBadgeForExpiringAndExpiredItemsUseCase
    private let logger: Logger

    init(updateAppBadgeUseCase: UpdateAppBadgeForExpiringAndExpiredItemsUseCase, logger: Logger = DefaultLogger.shared) {
        self.updateAppBadgeUseCase = updateAppBadgeUseCase
        self.logger = logger
    }

    @MainActor
    func updateAppBadge() {
        let result = updateAppBadgeUseCase.execute()
        switch result {
        case .success:
            logger.logInfo("App badge updated successfully.")
        case .failure(let error):
            logger.logError("Failed to update app badge: \(error.localizedDescription)")
        }
    }
}
