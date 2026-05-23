import UserNotifications
import UIKit

class NotificationSetup: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationSetup()

    private override init() {
        super.init()
        // Set delegate immediately on init — do NOT wait for setupCategories
        UNUserNotificationCenter.current().delegate = self
        setupCategories()
    }

    func setupCategories() {
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: [.destructive]
        )

        let category = UNNotificationCategory(
            identifier: "CARD_RECOMMENDATION",
            actions: [dismissAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // CRITICAL: This is what makes the banner show while app is foregrounded
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo  = response.notification.request.content.userInfo
        let storeName = userInfo["storeName"] as? String ?? ""
        let mcc       = userInfo["mcc"]       as? String ?? "5411"
        let bestCard  = userInfo["bestCard"]  as? String ?? ""
        let cashback  = userInfo["cashback"]  as? String ?? ""

        guard response.actionIdentifier != "DISMISS" else {
            completionHandler()
            return
        }

        var components        = URLComponents()
        components.scheme     = "tapsmart"
        components.host       = "cards"
        components.queryItems = [
            URLQueryItem(name: "store",    value: storeName),
            URLQueryItem(name: "mcc",      value: mcc),
            URLQueryItem(name: "card",     value: bestCard),
            URLQueryItem(name: "cashback", value: cashback),
        ]

        if let url = components.url {
            DispatchQueue.main.async {
                UIApplication.shared.open(url)
            }
        }

        completionHandler()
    }
}
