import UserNotifications
import Foundation

// Diagnostic tool to check notification setup
class NotificationDiagnostic {
    static func diagnose() {
        print("=== Notification Diagnostic ===")
        
        // Check delegate
        let delegate = UNUserNotificationCenter.current().delegate
        print("Delegate set: \(delegate != nil)")
        print("Delegate type: \(type(of: delegate))")
        
        // Check permissions
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Authorization status: \(settings.authorizationStatus.rawValue)")
            print("Alert setting: \(settings.alertSetting.rawValue)")
            print("Sound setting: \(settings.soundSetting.rawValue)")
            print("Badge setting: \(settings.badgeSetting.rawValue)")
            print("Notification center setting: \(settings.notificationCenterSetting.rawValue)")
            print("Lock screen setting: \(settings.lockScreenSetting.rawValue)")
        }
        
        // Check pending notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("Pending notifications: \(requests.count)")
            for request in requests {
                print("- ID: \(request.identifier)")
                print("  Category: \(request.content.categoryIdentifier)")
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    print("  Trigger: Calendar - \(trigger.dateComponents)")
                } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                    print("  Trigger: Time interval - \(trigger.timeInterval)s")
                }
            }
        }
        
        // Check delivered notifications
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            print("Delivered notifications: \(notifications.count)")
            for notification in notifications {
                print("- ID: \(notification.request.identifier)")
            }
        }
    }
}