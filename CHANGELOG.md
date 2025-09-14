# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2025-09-14

### Added
- Item duplication functionality using swipe actions for efficient kit management.
- Move items between emergency kits during item editing with kit selector.
- Swipe actions on item list items for quick copy and delete operations.
- Emergency Kit picker in item detail view for moving items between kits.
- Enhanced ItemFormView with support for kit selection and item moving.
- DuplicateItemInEmergencyKit use case for handling item duplication logic.
- Comprehensive test suite for item duplication functionality.
- Hashable conformance for EmergencyKit and Item entities for better UI performance.
- Localized strings for item duplication and moving operations in multiple languages.

### Changed
- Refactored ItemFormView into modular components for better maintainability.
- Enhanced ItemListItemView to support swipe actions with duplicate and delete options.
- Updated EmergencyKitDetailView to use individual item actions instead of bulk operations.
- Improved ItemDetailViewModel with kit selection and item moving capabilities.
- Updated ItemRepository protocol to include duplicate method.
- Enhanced SwiftDataItemRepository with item duplication implementation.
- Refactored view models to support item moving between kits.
- Updated dependency injection container to include new use cases.

### Fixed
- Improved error handling for item duplication and moving operations.
- Enhanced form validation and state management in ItemFormView.
- Better timezone and date handling in item operations.

### Removed
- Removed bulk delete operations in favor of individual item actions.
- Cleaned up unused preview code in ItemFormView.

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
