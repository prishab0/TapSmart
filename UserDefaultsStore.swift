import Foundation

enum UserDefaultsStore {

    // MARK: - Keys
    private static let cardsKey           = "ts_userCards"
    private static let savingsKey         = "ts_savings"
    private static let notifFreqKey       = "ts_notifFreq"
    private static let bgLocKey           = "ts_bgLocation"
    private static let onboardingKey      = "ts_hasSeenOnboarding"
    private static let monthlyGoalKey     = "ts_monthlyGoal"
    private static let notifCategoriesKey = "ts_notifCategories"

    // MARK: - User's owned cards
    static var userCards: [String] {
        get {
            guard let data = UserDefaults.standard.data(forKey: cardsKey),
                  let arr  = try? JSONDecoder().decode([String].self, from: data)
            else {
                // Default wallet includes Discover Cashback Debit so the demo
                // shows a real-rewards debit card alongside credit cards.
                return ["cff","abcp","amexgold","ccc","csp","cdc","coqs","debit_discover"]
            }
            return arr
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: cardsKey)
            }
        }
    }

    // MARK: - Onboarding
    static var hasSeenOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: onboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: onboardingKey) }
    }

    // MARK: - Monthly savings goal (0 = not set)
    static var monthlyGoal: Double {
        get { UserDefaults.standard.double(forKey: monthlyGoalKey) }
        set { UserDefaults.standard.set(newValue, forKey: monthlyGoalKey) }
    }

    // MARK: - Notification frequency
    enum NotifFrequency: String, CaseIterable {
        case always       = "Every visit"
        case oncePerDay   = "Once per day per store"
        case oncePerWeek  = "Once per week per store"
    }

    static var notifFrequency: NotifFrequency {
        get {
            NotifFrequency(rawValue:
                UserDefaults.standard.string(forKey: notifFreqKey) ?? ""
            ) ?? .always
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: notifFreqKey) }
    }

    // MARK: - Background location toggle
    static var backgroundLocationEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: bgLocKey) }
        set { UserDefaults.standard.set(newValue, forKey: bgLocKey) }
    }

    // MARK: - Notification categories
    // All categories enabled by default. Empty set = all allowed.
    static let allNotifCategories: [String] = [
        "Grocery", "Dining", "Gas", "Shopping", "Pharmacy", "Electronics", "Hardware"
    ]

    static var notifCategories: Set<String> {
        get {
            guard let data = UserDefaults.standard.data(forKey: notifCategoriesKey),
                  let arr  = try? JSONDecoder().decode([String].self, from: data)
            else {
                return Set(allNotifCategories)
            }
            return Set(arr)
        }
        set {
            if let data = try? JSONEncoder().encode(Array(newValue)) {
                UserDefaults.standard.set(data, forKey: notifCategoriesKey)
            }
        }
    }

    static func isCategoryEnabled(_ category: String) -> Bool {
        notifCategories.contains(category)
    }
}
