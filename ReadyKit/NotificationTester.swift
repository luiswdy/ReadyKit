import UserNotifications
import Foundation

// Test helper to schedule a local notification with snooze button
class NotificationTester {
    static func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Regular Check"
        content.body = "⏰ Test notification with snooze button"
        content.sound = .default
        content.categoryIdentifier = "REGULAR_CHECK_CATEGORY"
        
        // Schedule for 5 seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test-snooze-notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling test notification: \(error.localizedDescription)")
            } else {
                print("Test notification scheduled successfully - will appear in 5 seconds")
            }
        }
    }
    
    static func checkNotificationSetup() {
        UNUserNotificationCenter.current().getNotificationCategories { categories in
            print("=== Notification Categories ===")
            print("Total categories: \(categories.count)")
            
            for category in categories {
                print("Category ID: \(category.identifier)")
                print("  Actions: \(category.actions.count)")
                for action in category.actions {
                    print("    - \(action.identifier): '\(action.title)'")
                }
            }
        }
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("\n=== Pending Notifications ===")
            print("Total pending: \(requests.count)")
            
            for request in requests {
                print("ID: \(request.identifier)")
                print("  Category: \(request.content.categoryIdentifier)")
                print("  Title: \(request.content.title)")
            }
        }
    }
}