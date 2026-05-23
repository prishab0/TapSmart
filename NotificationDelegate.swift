import UserNotifications

// FIX: Without this delegate, iOS silently suppresses banner notifications
// when the app is in the foreground (which it always is when tapping store pills).
//
// Wire this up in TapSmartApp.swift (or wherever your @main is):
//
//   @main
//   struct TapSmartApp: App {
//       @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//       ...
//   }
//
//   class AppDelegate: NSObject, UIApplicationDelegate {
//       func application(_ application: UIApplication,
//                        didFinishLaunchingWithOptions ...) -> Bool {
//           UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
//           return true
//       }
//   }
//
// OR if you're already using an AppDelegate, just add the one line:
//   UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationDelegate()

    // Called when a notification arrives while the app is in the FOREGROUND.
    // Without this, iOS drops it silently — no banner, no sound, nothing.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show the banner + play sound even while the app is open
        completionHandler([.banner, .sound])
    }

    // Called when the user taps the notification banner.
    // Extend this to deep-link into the app if needed.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
