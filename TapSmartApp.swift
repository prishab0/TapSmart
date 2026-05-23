import SwiftUI
import UserNotifications

@main
struct TapSmartApp: App {

    @StateObject private var locationManager      = LocationManager()
    @StateObject private var subscriptionManager  = SubscriptionManager.shared

    init() {
        // ── CRITICAL: wire up the delegate FIRST before any notification
        // can fire. On real devices, lazy init via `_ = shared` causes a
        // race where foreground notifications are silently dropped because
        // the delegate isn't set yet when willPresent is called.
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

        TapSmartApp.applyNavBarAppearance()

        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in }

        // ── DEMO MODE ─────────────────────────────────────────────────────
        // TODO: Remove before App Store submission.
        DemoDataSeeder.seedIfNeeded()
        UserDefaultsStore.hasSeenOnboarding = false  // always show onboarding on launch
        // ─────────────────────────────────────────────────────────────────

        Task.detached(priority: .background) {
            _ = RewardDataService.shared.allCards
        }
        Task.detached(priority: .background) {
            await SubscriptionManager.shared.loadProduct()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(subscriptionManager)
        }
    }

    // MARK: - Nav bar appearance (call once on launch + after onboarding dismisses)

    static func applyNavBarAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(red: 0.051, green: 0.106, blue: 0.165, alpha: 1)
        navAppearance.titleTextAttributes      = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance   = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance    = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(red: 0.082, green: 0.722, blue: 0.651, alpha: 1)
    }
}
