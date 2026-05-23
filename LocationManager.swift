import Foundation
import CoreLocation
import UserNotifications

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let clManager = CLLocationManager()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentStoreName: String = ""
    @Published var currentStoreCategory: String = ""
    @Published var isNearStore: Bool = false
    @Published var stores: [Store] = []

    override init() {
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        requestPermission()

        Task { [weak self] in
            guard let self else { return }
            let coord = self.clManager.location?.coordinate
                ?? CLLocationCoordinate2D(latitude: 37.3175, longitude: -122.0421)
            let built = StoreDatabase.shared.makeStores(near: coord)
            self.stores = built
            self.setupGeofences()
        }
    }

    func requestPermission() {
        clManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysPermission() {
        clManager.requestAlwaysAuthorization()
    }

    func setupGeofences() {
        for region in clManager.monitoredRegions {
            clManager.stopMonitoring(for: region)
        }
        for store in stores {
            let region = CLCircularRegion(
                center: store.coordinate,
                radius: store.radius,
                identifier: store.name
            )
            region.notifyOnEntry = true
            region.notifyOnExit  = true
            clManager.startMonitoring(for: region)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.authorizationStatus = status
            guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }
            manager.startUpdatingLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        manager.stopUpdatingLocation()
        Task { @MainActor [weak self] in
            guard let self else { return }
            let built = StoreDatabase.shared.makeStores(near: loc.coordinate)
            self.stores = built
            self.setupGeofences()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didEnterRegion region: CLRegion) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let store = self.stores.first(where: { $0.name == region.identifier }) else { return }
            self.currentStoreName     = store.name
            self.currentStoreCategory = store.category
            self.isNearStore          = true
            if UserDefaultsStore.isCategoryEnabled(store.category) {
                // Snapshot the locked state BEFORE recordUse() increments the counter.
                // recordUse() pushes usesThisMonth from 4→5 on the 5th entry, which
                // would make isAtLimit true *during* sendNotification — causing the
                // 5th (last free) notification to show the upgrade prompt instead of
                // the real card. Capturing first ensures use #5 stays unlocked and
                // only use #6+ trigger the locked notification.
                let wasAlreadyAtLimit = SubscriptionManager.shared.isAtLimit
                _ = SubscriptionManager.shared.recordUse()
                self.sendNotification(for: store, locked: wasAlreadyAtLimit)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didExitRegion region: CLRegion) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if self.currentStoreName == region.identifier {
                self.currentStoreName     = ""
                self.currentStoreCategory = ""
                self.isNearStore          = false
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     monitoringDidFailFor region: CLRegion?,
                                     withError error: Error) {
        print("TapSmart geofence error: \(error.localizedDescription)")
    }

    // MARK: - Simulate (LockScreenView / demo)

    func simulateEnterStore(_ store: Store) {
        // Clear throttle keys so simulate always fires during testing
        UserDefaults.standard.removeObject(forKey: "ts_notif_day_\(store.name)")
        UserDefaults.standard.removeObject(forKey: "ts_notif_week_\(store.name)")
        UserDefaults.standard.synchronize()

        self.currentStoreName     = store.name
        self.currentStoreCategory = store.category
        self.isNearStore          = true

        // Snapshot locked state BEFORE recordUse() so the 5th simulated
        // use still shows the real card (same fix as the geofence path above).
        let wasAlreadyAtLimit = SubscriptionManager.shared.isAtLimit
        _ = SubscriptionManager.shared.recordUse()
        sendNotification(for: store, locked: wasAlreadyAtLimit)
    }

    func resetStore() {
        self.currentStoreName     = ""
        self.currentStoreCategory = ""
        self.isNearStore          = false
    }

    // MARK: - Send Notification

    // `locked` must be captured by the caller BEFORE calling recordUse(), so
    // that the 5th (last free) notification correctly shows the real card name.
    // If we re-read isAtLimit here, recordUse() will have already incremented
    // usesThisMonth to 5, making isAtLimit true and incorrectly locking the
    // 5th use instead of the 6th.
    func sendNotification(for store: Store, locked: Bool) {
        // ── Frequency throttle ────────────────────────────────────────────
        let freq = UserDefaultsStore.notifFrequency
        if freq == .oncePerDay {
            let key = "ts_notif_day_\(store.name)"
            if let last = UserDefaults.standard.object(forKey: key) as? Date,
               Calendar.current.isDateInToday(last) { return }
            UserDefaults.standard.set(Date(), forKey: key)
        } else if freq == .oncePerWeek {
            let key = "ts_notif_week_\(store.name)"
            if let last = UserDefaults.standard.object(forKey: key) as? Date,
               let diff = Calendar.current.dateComponents([.day], from: last, to: Date()).day,
               diff < 7 { return }
            UserDefaults.standard.set(Date(), forKey: key)
        }

        // ── Resolve best card ─────────────────────────────────────────────
        let userCards = UserDefaultsStore.userCards
        let best      = RewardDataService.shared.getBestCard(forMCC: store.mcc, userCards: userCards)

        // ── Build content ─────────────────────────────────────────────────
        //
        //  FREE (uses remaining):
        //    Title:    "You're at Trader Joe's"
        //    Subtitle: "Tap to pay with Apple Pay"
        //    Body:     "Amex Blue Cash Preferred earns 6% here"
        //
        //  AT LIMIT (locked):
        //    Title:    "You're at Trader Joe's"
        //    Subtitle: "🔒 Upgrade to reveal your best card"
        //    Body:     "Your best card earns ??% here — tap to unlock"
        //
        // userInfo always carries storeName + mcc so the deep-link tap
        // (NotificationSetup.swift) can route to CardsView correctly.
        // bestCard/cashback are empty when locked → CardsView shows paywall.

        let content = UNMutableNotificationContent()
        content.categoryIdentifier = "CARD_RECOMMENDATION"
        content.sound = .default

        if locked {
            content.title    = "You're at \(store.name)"
            content.subtitle = "🔒 Upgrade to reveal your best card"
            content.body     = "Your best card earns ??% here — tap to unlock"
            content.userInfo = [
                "storeName": store.name,
                "mcc":       store.mcc,
                "bestCard":  "",   // empty → NotificationContext.hasContext = false
                "cashback":  "",   // → CardsView falls through to locked/paywall state
                "isLocked":  true,
            ]
        } else {
            let cardName = best?.name     ?? "your best card"
            let cashback = best?.cashback ?? "rewards"
            content.title    = "You're at \(store.name)"
            content.subtitle = "Tap to pay with Apple Pay"
            content.body     = "\(cardName) earns \(cashback) here"
            content.userInfo = [
                "storeName": store.name,
                "mcc":       store.mcc,
                "bestCard":  cardName,
                "cashback":  cashback,
                "isLocked":  false,
            ]
        }

        let request = UNNotificationRequest(
            identifier: "store-\(store.name)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil   // deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("TapSmart notification error: \(error)")
            } else {
                let state = locked
                    ? "LOCKED — upgrade prompt"
                    : "\(best?.name ?? "?") \(best?.cashback ?? "?")"
                print("TapSmart notification sent for \(store.name) — \(state)")
            }
        }
    }
}
