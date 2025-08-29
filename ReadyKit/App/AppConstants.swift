//
//  AppConstants.swift
//  ReadyKit
//
//  Created by Luis Wu on 8/10/25.
//

import CoreGraphics
import Foundation

enum AppConstants {

    enum ErrorAppNamespace {
        static let appName = "ReadyKit"
    }

    enum UserPreferences {
        static let defaultNotificationHour = 12 // Default to 12 PM
        static let defaultNotificationMinute = 0 // Default to 0 minutes
        static let defaultNotificationSecond = 0 // Default to 0 seconds
        static let defaultExpiryReminderLeadDays = 30 // Default to 30 days
        static let defaultRegularCheckFrequency: RegularCheckFrequency = .quarterly // Default to quarterly checks
    }

    enum UserDefaultUserPreferencesKey {
        static let userPreferencesKey = "userPreferences"
    }

    enum Validation {
        static let hourRange = 0...23
        static let minuteRange = 0...59
        static let expiryReminderLeadDaysRange = 1...365
        static let minimumQuantityValue = 0
        static let maxYearsInPast = 10
    }

    enum Database {
        static let defaultDatabaseFilename = "default.store"
        static let defaultSearchPathDirectory: FileManager.SearchPathDirectory = .documentDirectory
        static let defaultSearchPathDomainMask: FileManager.SearchPathDomainMask = .userDomainMask
    }

    enum UI {
        static let opacity = 0.3
        static let cornerRadius: CGFloat = 8.0
        static let wheelPickerMaxWidth: CGFloat = 80
        static let formHeight: CGFloat = 120
        static let animationDuration: Double = 0.3

        enum Spacing {
            static let small: CGFloat = 8.0
            static let medium: CGFloat = 16.0
            static let large: CGFloat = 24.0
        }

        enum Thumbnail {
            static let width: CGFloat = 60
            static let height: CGFloat = 60
        }

        enum SystemImage {
            static let fontSize: CGFloat = 60.0
        }
    }

    enum Log {
        static let directory = AppConstants.Database.defaultSearchPathDirectory
        static let domainMask = AppConstants.Database.defaultSearchPathDomainMask
        static let filePrefix = "ReadyKit_"
        static let fileSize: UInt64 = 1024 * 1024 // 1 MB
        static let fileCount = 5 // Keep last 5 log files
        #if DEBUG
        static let level: LogLevel = .info
        #else
        static let level: LogLevel = .warning
        #endif
    }

    enum BackgroundMode {
        static let taskIdentifier = "io.wdy.ReadyKitApp.refresh"
    }

    enum MaxExpirationYearsFromNow {
        static let value = 25 // Maximum expiration date set to 25 years from now
    }

    enum Notification {
        enum ActionIdentifier {
            static let snoozeAnHour = "SNOOZE_AN_HOUR_ACTION"
            static let snoozeADay = "SNOOZE_A_DAY_ACTION"
        }

        enum CategoryIdentifier {
            static let regularCheck = "REGULAR_CHECK_CATEGORY"
            static let expiringItems = "EXPIRING_ITEMS_CATEGORY"
        }

        enum RegularCheck {
            static let quarterlyMonths = [1, 4, 7, 10]
            static let halfYearlyMonths = [1, 7]
            static let yearlyMonth = 1
        }
    }
}
