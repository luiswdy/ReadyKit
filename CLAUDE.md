# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

Open `ReadyKit.xcodeproj` in Xcode. There is no CLI build script — use Xcode or `xcodebuild`:

```sh
# Build
xcodebuild -project ReadyKit.xcodeproj -scheme ReadyKit -destination 'platform=iOS Simulator,name=iPhone 16e' build

# Run all tests
xcodebuild -project ReadyKit.xcodeproj -scheme ReadyKit -testPlan ReadyKit -destination 'platform=iOS Simulator,name=iPhone 16e' test

# Run a single test class
xcodebuild -project ReadyKit.xcodeproj -scheme ReadyKit -destination 'platform=iOS Simulator,name=iPhone 16e' test -only-testing:ReadyKitTests/AddItemToEmergencyKitUseCaseTests
```

Tests use Swift Testing (`@Test`, `#expect`) — not XCTest. Test targets:
- `ReadyKitAlertTests/` — unit tests for use cases, mappers, entities
- `ReadyKitAlertUITests/` — UI tests

Reset the test database by passing `--reset` as a launch argument (handled in `DependencyContainer.createModelContainerForTesting()`).

## Architecture

Clean Architecture with four layers. Dependencies only point inward (Presentation/Data/Infrastructure → Domain, never the reverse).

```
Domain/          ← pure Swift, no framework imports
  Entities/      ← Item, EmergencyKit, UserPreferences (value types, validated in init)
  Repositories/  ← protocols: EmergencyKitRepository, ItemRepository, ReminderScheduler, …
  UseCases/      ← one file per use case, takes repository protocols, returns Result<_, Error>

Data/            ← SwiftData persistence
  Models/        ← ItemModel, EmergencyKitModel (@Model classes)
  Mappers/       ← ItemMapper, EmergencyKitMapper (Model ↔ Domain)
  Repositories/  ← SwiftDataItemRepository, SwiftDataEmergencyKitRepository
  Services/      ← DefaultReminderScheduler, NotificationDelegate

Infrastructure/
  BackgroundTasks/  ← ReminderBackgroundTaskScheduler (BGProcessingTask)
  Services/         ← IOSBackgroundModeService, UserNotificationPermissionService

Presentation/
  ViewModels/    ← @Observable @MainActor classes, one per screen
  Views/         ← SwiftUI views, consume ViewModels
```

**Dependency injection**: `DependencyContainer` (in `App/DependencyInjection/`) is an `ObservableObject` passed via `.environmentObject`. All lazy vars are instantiated on first access. Inject it in tests by constructing it with mock repositories.

**SwiftData**: `ModelContext` is main-actor bound. All `SwiftDataItemRepository` and `SwiftDataEmergencyKitRepository` methods assert `Thread.isMainThread`. `scheduleReminders()` is therefore `@MainActor`.

**Notification system** (two paths chosen at `scheduleReminders()` time):
- *Path A* — items beyond the lead window: schedules 3 one-shot batch notifications (`expiry-batch-0/1/2`). User can tap "Keep reminding me" to transition to Path B.
- *Path B* — items expiring/expired: schedules a single `repeats: true` persistent daily reminder (`persistent-expiry-reminder`) with `interruptionLevel = .timeSensitive`.
- Regular-check reminders (quarterly/half-yearly/yearly) use `repeats: true` with only month/day components so they recur annually without an app open.

## Key Conventions

**Entities validate in `init`**: `Item` and `EmergencyKit` throw on invalid input (empty name, zero quantity, duplicate item IDs). Always construct via `try Item(...)` / `try EmergencyKit(...)`.

**Use cases return `Result<_, Error>`** (synchronous). `RescheduleRemindersUseCase.execute()` is the exception — it is `async @MainActor` because it awaits `removeNonSnoozePendingReminders()`.

**Testing**: Mock repositories live in `ReadyKitAlertTests/TestUtilities/MockRepositories.swift` and `MockServices.swift`. Use `TestDataFactory` (in `TestHelpers.swift`) to construct valid test fixtures.

**Localization**: All user-visible strings use `String(localized:comment:)`. Translations are in `Resources/Localizable.xcstrings` (single catalog, multi-language). Add new strings there; Xcode manages the `.lproj` stubs.

**App constants**: All magic values (notification identifiers, category strings, validation ranges, UI dimensions) live in `AppConstants.swift`. Use the typed enums — never inline raw strings for notification identifiers.

## Behavioral Guidelines

**Think before coding.** State assumptions explicitly. If multiple interpretations exist, present them — don't pick silently. If a simpler approach exists, say so. If something is unclear, stop and ask.

**Simplicity first.** Minimum code that solves the problem. No features beyond what was asked, no abstractions for single-use code, no error handling for impossible scenarios. If you write 200 lines and it could be 50, rewrite it.

**Surgical changes.** Touch only what you must. Don't improve adjacent code, comments, or formatting. Match existing style. If your changes create orphaned imports or variables, remove them — but don't remove pre-existing dead code unless asked.

**Goal-driven execution.** For multi-step tasks, state a brief plan with verifiable success criteria before implementing. Strong criteria let you loop independently; weak ones ("make it work") require constant clarification.
