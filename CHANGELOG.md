# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2025-09-28

### Added
- Move items between emergency kits from the item edit UI and item detail actions. Users can now select a target kit when editing an item and move it while preserving all item properties (name, quantity, expiration, notes, photo).
- Duplicate items inside a kit using swipe actions or contextual menus. Duplicated items retain all properties but receive a unique identifier.

### Changed
- Improved item editing flows and swipe actions to support duplication and moving items.
- UI: Added a kit picker in the item edit form and a "Copy" swipe action on item rows.
- Increased testability: added defensive accessibility identifiers for item actions to stabilize UI tests.

### Fixed
- Fixed several UI test flakiness issues related to swipe actions, photo picker interactions, and item manipulation.
- Resolved edge cases when moving items between kits where duplicate IDs could be generated.

### Notes for Developers
- The new move and duplicate features add use-cases and corresponding use-case classes. See `Domain/UseCases/DuplicateItemInEmergencyKit.swift` and related repository methods.
- The database reset for UI tests (`--reset`) is available in DEBUG builds only and implemented via the DependencyContainer to avoid any risk in production builds.

## [1.1.0] - 2025-09-07

### Added
- Notification snooze actions (hour/day) for regular check reminders.
- NotificationDelegate to handle notification actions and rescheduling.
- First expiring item alert notification.
- NotificationTester utility for local notification testing.
- Additional localized strings for notification actions and alerts.
- New CODE_OF_CONDUCT.md file.

### Changed
- Bumped version and build numbers to 1.1.0.
- Enhanced notification scheduling mechanism: improved regular check and expiry reminders, added earliest expiring item alerts.
- Improved privacy descriptions and localization.
- Updated license to CC BY-NC-SA 4.0 with additional data usage restrictions.
- Logging now uses OSLog in debug builds.
- Minimum iOS requirement updated to 17.0.

### Fixed
- Corrected logic to avoid removing snoozed reminders when rescheduling notifications.
- Improved timezone handling for notification scheduling.

### Removed
- Deprecated or unused notification rescheduling error messages.

## [1.0.0] - 2025-08-29

### Added
- Initial project setup with core features for emergency kit management.
- Implemented privacy-focused design with local-only data storage.
- Added localization for Traditional Chinese.
- Implemented notification scheduling and handling.
- Added logging for easier debugging.
- Created `PrivacyInfo.xcprivacy` to declare data usage.

### Changed
- Bumped version and build numbers.
- Revised and localized privacy descriptions.
- Enhanced notification scheduling mechanism.

### Fixed
- Corrected essential properties in `PrivacyInfo.xcprivacy`.

### Removed
- Reverted changes related to camera and photo library privacy descriptions.
