import Foundation

struct DuplicateItemInEmergencyKitUseCase {
    private let itemRepository: ItemRepository

    init(itemRepository: ItemRepository) {
        self.itemRepository = itemRepository
    }

    func execute(item: Item, emergencyKit: EmergencyKit) throws {
        try itemRepository.duplicate(item: item, to: emergencyKit)
    }
}
