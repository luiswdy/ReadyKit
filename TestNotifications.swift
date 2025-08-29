import UserNotifications
import Foundation

// Test script to check notification setup
func testNotificationSetup() {
    print("=== Testing Notification Setup ===")
    
    // Check current categories
    UNUserNotificationCenter.current().getNotificationCategories { categories in
        print("Current notification categories: \(categories.count)")
        for category in categories {
            print("- Category ID: \(category.identifier)")
            print("  Actions count: \(category.actions.count)")
            for action in category.actions {
                print("    - Action ID: \(action.identifier), Title: \(action.title)")
            }
        }
    }
    
    // Check pending notifications
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
        print("\nPending notifications: \(requests.count)")
        for request in requests {
            print("- ID: \(request.identifier)")
            print("  Category: \(request.content.categoryIdentifier)")
            print("  Title: \(request.content.title)")
        }
    }
    
    // Manual test - schedule a notification with snooze
    let content = UNMutableNotificationContent()
    content.title = "Test Regular Check"
    content.body = "This should have a snooze button"
    content.categoryIdentifier = "REGULAR_CHECK_CATEGORY"
    content.sound = .default
    
    // Create the snooze action and category
    let snoozeAction = UNNotificationAction(
        identifier: "SNOOZE_ACTION",
        title: "Snooze",
        options: []
    )
    
    let category = UNNotificationCategory(
        identifier: "REGULAR_CHECK_CATEGORY",
        actions: [snoozeAction],
        intentIdentifiers: [],
        options: []
    )
    
    UNUserNotificationCenter.current().setNotificationCategories([category])
    
    // Schedule test notification for 5 seconds from now
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
    let request = UNNotificationRequest(identifier: "test-snooze", content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error scheduling test notification: \(error)")
        } else {
            print("Test notification scheduled successfully")
        }
    }
}