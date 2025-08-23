//
//  UserPreferencesTests.swift
//  ReadyKitTests
//
//  Created by Claude on 8/22/25.
//

import Testing
import Foundation
@testable import ReadyKit

struct UserPreferencesTests {
    
    // MARK: - Initialization Tests
    
    @Test("UserPreferences initialization with default values")
    func testDefaultInitialization() {
        let preferences = UserPreferences()
        
        #expect(preferences.dailyNotificationTime.hour == AppConstants.UserPreferences.defaultNotificationHour)
        #expect(preferences.dailyNotificationTime.minute == AppConstants.UserPreferences.defaultNotificationMinute)
        #expect(preferences.dailyNotificationTime.second == AppConstants.UserPreferences.defaultNotificationSecond)
        #expect(preferences.expiryReminderLeadDays == AppConstants.UserPreferences.defaultExpiryReminderLeadDays)
        #expect(preferences.regularCheck == AppConstants.UserPreferences.defaultRegularCheckFrequency)
    }
    
    @Test("UserPreferences initialization with custom values")
    func testCustomInitialization() {
        let customTime = DateComponents(hour: 14, minute: 30)
        let customLeadDays = 15
        let customFrequency = RegularCheckFrequency.halfYearly
        
        let preferences = UserPreferences(
            dailyNotificationTime: customTime,
            expiryReminderLeadDays: customLeadDays,
            regularCheck: customFrequency
        )
        
        #expect(preferences.dailyNotificationTime.hour == 14)
        #expect(preferences.dailyNotificationTime.minute == 30)
        #expect(preferences.expiryReminderLeadDays == customLeadDays)
        #expect(preferences.regularCheck == customFrequency)
    }
    
    // MARK: - Property Mutation Tests
    
    @Test("UserPreferences properties can be mutated")
    func testPropertyMutation() {
        var preferences = UserPreferences()
        
        let newTime = DateComponents(hour: 18, minute: 45)
        let newLeadDays = 60
        let newFrequency = RegularCheckFrequency.yearly
        
        preferences.dailyNotificationTime = newTime
        preferences.expiryReminderLeadDays = newLeadDays
        preferences.regularCheck = newFrequency
        
        #expect(preferences.dailyNotificationTime.hour == 18)
        #expect(preferences.dailyNotificationTime.minute == 45)
        #expect(preferences.expiryReminderLeadDays == newLeadDays)
        #expect(preferences.regularCheck == newFrequency)
    }
    
    // MARK: - Codable Tests
    
    @Test("UserPreferences can be encoded to JSON")
    func testEncoding() throws {
        let preferences = TestDataFactory.createCustomUserPreferences(
            notificationHour: 16,
            notificationMinute: 45,
            expiryReminderLeadDays: 21,
            regularCheck: .halfYearly
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(preferences)
        
        #expect(!data.isEmpty)
        
        // Verify the JSON structure
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["dailyNotificationTimeHour"] as? Int == 16)
        #expect(json?["dailyNotificationTimeMinute"] as? Int == 45)
        #expect(json?["expiryReminderLeadDays"] as? Int == 21)
    }
    
    @Test("UserPreferences can be decoded from JSON")
    func testDecoding() throws {
        let json: [String: Any] = [
            "dailyNotificationTimeHour": 20,
            "dailyNotificationTimeMinute": 15,
            "expiryReminderLeadDays": 45,
            "regularCheck": "yearly"
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        let preferences = try decoder.decode(UserPreferences.self, from: jsonData)
        
        #expect(preferences.dailyNotificationTime.hour == 20)
        #expect(preferences.dailyNotificationTime.minute == 15)
        #expect(preferences.expiryReminderLeadDays == 45)
        #expect(preferences.regularCheck == .yearly)
    }
    
    @Test("UserPreferences encoding and decoding round trip")
    func testEncodingDecodingRoundTrip() throws {
        let originalPreferences = TestDataFactory.createCustomUserPreferences(
            notificationHour: 9,
            notificationMinute: 30,
            expiryReminderLeadDays: 7,
            regularCheck: .quarterly
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try encoder.encode(originalPreferences)
        let decodedPreferences = try decoder.decode(UserPreferences.self, from: encodedData)
        
        #expect(decodedPreferences.dailyNotificationTime.hour == originalPreferences.dailyNotificationTime.hour)
        #expect(decodedPreferences.dailyNotificationTime.minute == originalPreferences.dailyNotificationTime.minute)
        #expect(decodedPreferences.expiryReminderLeadDays == originalPreferences.expiryReminderLeadDays)
        #expect(decodedPreferences.regularCheck == originalPreferences.regularCheck)
    }
    
    @Test("UserPreferences encoding handles nil hour gracefully")
    func testEncodingWithNilHour() throws {
        var preferences = UserPreferences()
        preferences.dailyNotificationTime = DateComponents(minute: 30) // hour is nil
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(preferences)
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["dailyNotificationTimeHour"] as? Int == AppConstants.UserPreferences.defaultNotificationHour)
        #expect(json?["dailyNotificationTimeMinute"] as? Int == 30)
    }
    
    @Test("UserPreferences encoding handles nil minute gracefully")
    func testEncodingWithNilMinute() throws {
        var preferences = UserPreferences()
        preferences.dailyNotificationTime = DateComponents(hour: 15) // minute is nil
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(preferences)
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["dailyNotificationTimeHour"] as? Int == 15)
        #expect(json?["dailyNotificationTimeMinute"] as? Int == AppConstants.UserPreferences.defaultNotificationMinute)
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("UserPreferences handles edge time values")
    func testEdgeTimeValues() {
        let preferences = TestDataFactory.createCustomUserPreferences(
            notificationHour: 0,
            notificationMinute: 0,
            expiryReminderLeadDays: 1,
            regularCheck: .quarterly
        )
        
        #expect(preferences.dailyNotificationTime.hour == 0)
        #expect(preferences.dailyNotificationTime.minute == 0)
        #expect(preferences.expiryReminderLeadDays == 1)
    }
    
    @Test("UserPreferences handles maximum time values")
    func testMaxTimeValues() {
        let preferences = TestDataFactory.createCustomUserPreferences(
            notificationHour: 23,
            notificationMinute: 59,
            expiryReminderLeadDays: 365,
            regularCheck: .yearly
        )
        
        #expect(preferences.dailyNotificationTime.hour == 23)
        #expect(preferences.dailyNotificationTime.minute == 59)
        #expect(preferences.expiryReminderLeadDays == 365)
    }
    
    // MARK: - DateComponents Tests
    
    @Test("UserPreferences DateComponents only uses hour and minute")
    func testDateComponentsStructure() {
        let preferences = TestDataFactory.createCustomUserPreferences(
            notificationHour: 12,
            notificationMinute: 30
        )
        
        #expect(preferences.dailyNotificationTime.hour == 12)
        #expect(preferences.dailyNotificationTime.minute == 30)
        #expect(preferences.dailyNotificationTime.second == nil)
        #expect(preferences.dailyNotificationTime.day == nil)
        #expect(preferences.dailyNotificationTime.month == nil)
        #expect(preferences.dailyNotificationTime.year == nil)
    }
}

// MARK: - RegularCheckFrequency Tests

struct RegularCheckFrequencyTests {
    
    // MARK: - Localized Description Tests
    
    @Test("RegularCheckFrequency localized descriptions are not empty")
    func testLocalizedDescriptions() {
        let frequencies: [RegularCheckFrequency] = [.quarterly, .halfYearly, .yearly]
        
        for frequency in frequencies {
            let description = frequency.localizedDescription
            #expect(!description.isEmpty, "Localized description should not be empty for \(frequency)")
        }
    }
    
    @Test("RegularCheckFrequency.quarterly has correct localized description")
    func testQuarterlyDescription() {
        let description = RegularCheckFrequency.quarterly.localizedDescription
        #expect(description.contains("Quarterly") || description.contains("quarterly"))
    }
    
    @Test("RegularCheckFrequency.halfYearly has correct localized description")
    func testHalfYearlyDescription() {
        let description = RegularCheckFrequency.halfYearly.localizedDescription
        #expect(description.contains("Half") || description.contains("half"))
    }
    
    @Test("RegularCheckFrequency.yearly has correct localized description")
    func testYearlyDescription() {
        let description = RegularCheckFrequency.yearly.localizedDescription
        #expect(description.contains("Yearly") || description.contains("yearly"))
    }
    
    // MARK: - Codable Tests
    
    @Test("RegularCheckFrequency can be encoded and decoded")
    func testCodable() throws {
        let frequencies: [RegularCheckFrequency] = [.quarterly, .halfYearly, .yearly]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for frequency in frequencies {
            let encodedData = try encoder.encode(frequency)
            let decodedFrequency = try decoder.decode(RegularCheckFrequency.self, from: encodedData)
            #expect(decodedFrequency == frequency)
        }
    }
    
    @Test("RegularCheckFrequency JSON representation")
    func testJSONRepresentation() throws {
        let encoder = JSONEncoder()
        
        let quarterlyData = try encoder.encode(RegularCheckFrequency.quarterly)
        let quarterlyString = String(data: quarterlyData, encoding: .utf8)
        #expect(quarterlyString?.contains("quarterly") == true)
        
        let halfYearlyData = try encoder.encode(RegularCheckFrequency.halfYearly)
        let halfYearlyString = String(data: halfYearlyData, encoding: .utf8)
        #expect(halfYearlyString?.contains("halfYearly") == true)
        
        let yearlyData = try encoder.encode(RegularCheckFrequency.yearly)
        let yearlyString = String(data: yearlyData, encoding: .utf8)
        #expect(yearlyString?.contains("yearly") == true)
    }
    
    // MARK: - Equality Tests
    
    @Test("RegularCheckFrequency equality comparison")
    func testEquality() {
        #expect(RegularCheckFrequency.quarterly == RegularCheckFrequency.quarterly)
        #expect(RegularCheckFrequency.halfYearly == RegularCheckFrequency.halfYearly)
        #expect(RegularCheckFrequency.yearly == RegularCheckFrequency.yearly)
        
        #expect(RegularCheckFrequency.quarterly != RegularCheckFrequency.halfYearly)
        #expect(RegularCheckFrequency.quarterly != RegularCheckFrequency.yearly)
        #expect(RegularCheckFrequency.halfYearly != RegularCheckFrequency.yearly)
    }
}
