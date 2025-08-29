//
//  UserPreferences.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/11.
//

import Foundation

enum RegularCheckFrequency: String, Codable {
    case quarterly
    case halfYearly
    case yearly
    
    var localizedDescription: String {
        switch self {
        case .quarterly:
            return String(localized: "Quarterly", comment: "Regular check frequency - quarterly")
        case .halfYearly:
            return String(localized: "Half-Yearly", comment: "Regular check frequency - half-yearly")
        case .yearly:
            return String(localized: "Yearly", comment: "Regular check frequency - yearly")
        }
    }
}

struct UserPreferences {
    var dailyNotificationTime: DateComponents = DateComponents(
        timeZone: .current,
        hour: AppConstants.UserPreferences.defaultNotificationHour,
        minute: AppConstants.UserPreferences.defaultNotificationMinute,
        second: AppConstants.UserPreferences.defaultNotificationSecond
    )
    var expiryReminderLeadDays: Int = AppConstants.UserPreferences.defaultExpiryReminderLeadDays
    var regularCheck: RegularCheckFrequency = AppConstants.UserPreferences.defaultRegularCheckFrequency
}

extension UserPreferences: Codable {
    enum CodingKeys: String, CodingKey {
        case dailyNotificationTimeHour
        case dailyNotificationTimeMinute
        case expiryReminderLeadDays
        case regularCheck
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let hour = try container.decode(Int.self, forKey: .dailyNotificationTimeHour)
        let minute = try container.decode(Int.self, forKey: .dailyNotificationTimeMinute)
        self.dailyNotificationTime = DateComponents(hour: hour, minute: minute)

        self.expiryReminderLeadDays = try container.decode(Int.self, forKey: .expiryReminderLeadDays)
        self.regularCheck = try container.decode(RegularCheckFrequency.self, forKey: .regularCheck)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(dailyNotificationTime.hour ?? AppConstants.UserPreferences.defaultNotificationHour, forKey: .dailyNotificationTimeHour)
        try container.encode(dailyNotificationTime.minute ?? AppConstants.UserPreferences.defaultNotificationMinute, forKey: .dailyNotificationTimeMinute)
        try container.encode(expiryReminderLeadDays, forKey: .expiryReminderLeadDays)
        try container.encode(regularCheck, forKey: .regularCheck)
    }
}
