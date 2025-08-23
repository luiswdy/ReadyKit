# ReadyKit

ReadyKit is an iOS app designed to help you organize and manage your emergency kits, supplies, and preparedness plans. With ReadyKit, you can track items, set reminders for expiration dates, and ensure your family is always ready for emergencies.

## Features
- Create and manage multiple emergency kits
- Add, edit, and remove items in each kit
- Track item quantities, expiration dates, and notes
- Receive reminders for expiring or expired items
- Backup and restore your kits
- Localized for multiple languages

## Architecture
ReadyKit uses a modular, clean architecture with clear separation of concerns:

- **App/**: App entry point, configuration, and dependency injection
- **Data/**: Data models, repositories, and mappers for data persistence
- **Domain/**: Core business logic, entities, and use cases
- **Infrastructure/**: System integrations and background tasks
- **Presentation/**: UI views, view models, utilities, and localized errors
- **Resources/**: Assets, localization files, and privacy info

## Folder Structure
```
ReadyKit/
  App/                # App entry, DI, logging
  Data/               # Models, repositories, mappers
  Domain/             # Entities, repositories, use cases
  Infrastructure/     # Background tasks, services
  Presentation/       # Views, view models, utils
  Resources/          # Assets, localization, privacy
  ReadyKit.xcodeproj/ # Xcode project files
  ...
```

## Getting Started

### Requirements
- Xcode 15 or later
- iOS 16.0 or later
- Swift 5.8 or later

### Build & Run
1. Clone this repository:
   ```sh
   git clone <repo-url>
   ```
2. Open `ReadyKit.xcodeproj` in Xcode.
3. Select a simulator or device and press **Run** (⌘R).

## Localization
ReadyKit supports multiple languages. To add or update translations, edit the files in `Resources/Localizable.xcstrings`.

## Testing
- **Unit Tests**: Located in `ReadyKitAlertTests/`
- **UI Tests**: Located in `ReadyKitAlertUITests/`

Run all tests in Xcode using **Product > Test** (⌘U).

## Contributing
Contributions are welcome! Please open issues or submit pull requests for improvements or bug fixes.

## License
See LICENSE.md for license details.

---

**This project is open source software and is provided under its license terms. It comes with no warranties or guarantees, express or implied. Use of this software is at your own risk.**

© 2025 ReadyKit Contributors. All rights reserved.
