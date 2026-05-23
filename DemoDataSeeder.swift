import Foundation

// MARK: - DemoDataSeeder
//
// Seeds realistic multi-month savings data and forces premium mode so the
// paywall never fires during a demo presentation.
//
// HOW TO USE:
//   Call DemoDataSeeder.seedIfNeeded() once in TapSmartApp.init().
//   It only seeds once — guarded by a UserDefaults flag — so repeatedly
//   launching the app won't duplicate records.
//
// TO RESET (e.g. to re-seed or go back to empty):
//   Settings → Reset Savings Data  (clears records but not the seed flag)
//   OR call DemoDataSeeder.resetSeedFlag() then relaunch.
//
// TO DISABLE DEMO MODE before shipping:
//   Delete the DemoDataSeeder.seedIfNeeded() call in TapSmartApp.init().
//   The flag and data will be ignored once the call is removed.

enum DemoDataSeeder {

    private static let seededKey   = "ts_demo_seeded_v1"
    private static let premiumKey  = "ts_demo_premium_override"

    // MARK: - Public API

    /// Call once from TapSmartApp.init(). Safe to call every launch — no-ops after first run.
    static func seedIfNeeded() {
        seedSavingsIfNeeded()
        forcePremium()
    }

    /// Wipe the seed flag so seedIfNeeded() will re-seed on next launch.
    static func resetSeedFlag() {
        UserDefaults.standard.removeObject(forKey: seededKey)
    }

    // MARK: - Premium override

    /// Forces isPremium = true on SubscriptionManager so the paywall never fires.
    /// Called every launch (not guarded) so it survives app restarts.
    private static func forcePremium() {
        // SubscriptionManager.shared is a MainActor singleton; we dispatch to main
        // so this is safe to call from App.init (which runs before the run loop).
        DispatchQueue.main.async {
            SubscriptionManager.shared.enableDemoMode()
        }
    }

    // MARK: - Savings seed

    private static func seedSavingsIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        buildRecords().forEach { inject($0) }
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    /// Injects a pre-built SavingRecord directly into SavingsStore without
    /// going through recordSaving() so we can control the date precisely.
    private static func inject(_ record: SavingRecord) {
        SavingsStore.shared.injectRecord(record)
    }

    // MARK: - Record factory

    private static func buildRecords() -> [SavingRecord] {
        var records: [SavingRecord] = []
        let cal = Calendar.current
        let now = Date()

        // Helper: date N months ago, on a specific day, at a given hour
        func date(monthsAgo: Int, day: Int, hour: Int = 10) -> Date {
            var comps        = cal.dateComponents([.year, .month], from: now)
            comps.month!    -= monthsAgo
            comps.day        = day
            comps.hour       = hour
            comps.minute     = 0
            return cal.date(from: comps) ?? now
        }

        func rec(
            store: String, category: String, card: String,
            cashbackPct: Double, spend: Double,
            date: Date, usedBest: Bool = true
        ) -> SavingRecord {
            let saving = max(0, (cashbackPct - 1.0) / 100.0 * spend)
            return SavingRecord(
                id:           UUID(),
                storeName:    store,
                category:     category,
                cardName:     card,
                amount:       saving,
                spendAmount:  spend,
                date:         date,
                usedBestCard: usedBest
            )
        }

        // ── 4 months ago ──────────────────────────────────────────────────
        records += [
            rec(store: "Trader Joe's", category: "Grocery",
                card: "Amex Blue Cash Preferred", cashbackPct: 6, spend: 87,
                date: date(monthsAgo: 4, day: 3)),
            rec(store: "Starbucks", category: "Dining",
                card: "Amex Gold Card", cashbackPct: 4, spend: 22,
                date: date(monthsAgo: 4, day: 5)),
            rec(store: "Shell", category: "Gas",
                card: "Chase Freedom Flex", cashbackPct: 5, spend: 61,
                date: date(monthsAgo: 4, day: 9)),
            rec(store: "Trader Joe's", category: "Grocery",
                card: "Amex Blue Cash Preferred", cashbackPct: 6, spend: 94,
                date: date(monthsAgo: 4, day: 14)),
            rec(store: "CVS", category: "Pharmacy",
                card: "Chase Freedom Flex", cashbackPct: 5, spend: 34,
                date: date(monthsAgo: 4, day: 17)),
            rec(store: "Chipotle", category: "Dining",
                card: "Amex Gold Card", cashbackPct: 4, spend: 18,
                date: date(monthsAgo: 4, day: 20)),
            rec(store: "Whole Foods", category: "Grocery",
                card: "Amex Blue Cash Preferred", cashbackPct: 6, spend: 112,
                date: date(monthsAgo: 4, day: 24)),
            rec(store: "Target", category: "Shopping",
                card: "Citi Custom Cash", cashbackPct: 5, spend: 73,
                date: date(monthsAgo: 4, day: 27)),
        ]

        // ── 3 months ago ──────────────────────────────────────────────────
        records += [
            rec(store: "Trader Joe's", category: "Grocery",
                card: "Amex Blue Cash Preferred", cashbackPct: 6, spend: 78,
                date: date(monthsAgo: 3, day: 2)),
            rec(store: "Starbucks", category: "Dining",
                card: "Amex Gold Card", cashbackPct: 4, spend: 19,
                date: date(monthsAgo: 3, day: 4)),
            rec(store: "Shell", category: "Gas",
                card: "Chase Freedom Flex", cashbackPct: 5, spend: 58,
                date: date(monthsAgo: 3, day: 7)),
            rec(store: "Best Buy", category: "Electronics",
                card: "Chase Sapphire Preferred", cashbackPct: 3, spend: 249,
                date: date(monthsAgo: 3, day: 10)),
            rec(store: "Trader Joe's", category: "Grocery",
                card: "Amex Blue Cash Preferred", cashbackPct: 6, spend: 91,
                date: date(monthsAgo: 3, day: 13)),
            rec(store: "McDonald's", category: "Dining",
                card: "Amex Gold Card", cashbackPct: 4, spend: 14,
                date: date(monthsAgo: 3, day: 16)),
            // One non-optimal use to make the optimization ring realistic (~90%)
            rec(store: "Chevron", category: "Gas",
                card: "Citi Double Cash", cashbackPct: 2, spend: 55,
                date: date(monthsAgo: 3, day: 19), usedBest: false),
            rec(store: "Whole Foods", category: "Grocery",
                card: "Amex Blue Cash Preferred", cashbackPct: 6, spend: 103,
                date: date(monthsAgo: 3, day: 22)),
            rec(store: "Walgreens", category: "Pharmacy",
                card: "Chase Freedom Flex", cashbackPct: 5, spend: 28,
                date: date(monthsAgo: 3, day: 25)),
            rec(store: "Target", category: "Shopping",
                card: "Citi Custom Cash", cashbackPct: 5, spend: 89,
                date: date(monthsAgo: 3, day: 28)),
        ]

        // ── 2 months ago ──────────────────────────────────────────────────
        records += [
            rec(store: "Trader Joe's", category: "Grocery",
                card: "Amex Blue Cash Preferred", cashbackPct: 6, spend: 96,
                date: date(monthsAgo: 2, day: 1)),
            rec(store: "Panera Bread", category: "Dining",
                card: "Amex Gold Card", cashbackPct: 4, spend: 27,
                date: date(monthsAgo: 2, day: 3)),
            rec(store: "Shell", category: "Gas",
                card: "Chase Freedom Flex", cashbackPct: 5, spend: 64,
                date: date(monthsAgo: 2, day: 6)),
            rec(store: "Trader Joe's", category: "Grocery",
                card: "Amex Blue Cash Preferred", cashbackPct: 6, spend: 82,
                date: date(monthsAgo: 2, day: 9)),
            rec(store: "Home Depot", category: "Hardware",
                card: "Chase Sapphire Preferred", cashbackPct: 3, spend: 134,
                date: date(monthsAgo: 2, day: 12)),
            rec(store: "Starbucks", category: "Dining",
                card: "Amex Gold Card", cashbackPct: 4, spend: 24,
                date: date(monthsAgo: 2, day: 15)),
            rec(store: "Whole Foods", category: "Grocery",
                card: "Amex Blue Cash Preferred", cashbackPct: 6, spend: 119,
                date: date(monthsAgo: 2, day: 18)),
            rec(store: "CVS", category: "Pharmacy",
                card: "Chase Freedom Flex", cashbackPct: 5, spend: 41,
                date: date(monthsAgo: 2, day: 21)),
            rec(store: "Target", category: "Shopping",
                card: "Citi Custom Cash", cashbackPct: 5, spend: 67,
                date: date(monthsAgo: 2, day: 24)),
            rec(store: "Chipotle", category: "Dining",
                card: "Amex Gold Card", cashbackPct: 4, spend: 21,
                date: date(monthsAgo: 2, day: 27)),
        ]

        // ── Last month ────────────────────────────────────────────────────
        records += [
            rec(store: "Trader Joe's", category: "Grocery",
                card: "Amex Blue Cash Preferred", cashbackPct: 6, spend: 88,
                date: date(monthsAgo: 1, day: 2)),
            rec(store: "Starbucks", category: "Dining",
                card: "Amex Gold Card", cashbackPct: 4, spend: 23,
                date: date(monthsAgo: 1, day: 4)),
            rec(store: "Shell", category: "Gas",
                card: "Chase Freedom Flex", cashbackPct: 5, spend: 70,
                date: date(monthsAgo: 1, day: 7)),
            rec(store: "Whole Foods", category: "Grocery",
                card: "Amex Blue Cash Preferred", cashbackPct: 6, spend: 107,
                date: date(monthsAgo: 1, day: 10)),
            rec(store: "Best Buy", category: "Electronics",
                card: "Chase Sapphire Preferred", cashbackPct: 3, spend: 189,
                date: date(monthsAgo: 1, day: 13)),
            rec(store: "Chipotle", category: "Dining",
                card: "Amex Gold Card", cashbackPct: 4, spend: 17,
                date: date(monthsAgo: 1, day: 16)),
            rec(store: "Trader Joe's", category: "Grocery",
                card: "Amex Blue Cash Preferred", cashbackPct: 6, spend: 93,
                date: date(monthsAgo: 1, day: 19)),
            rec(store: "Target", category: "Shopping",
                card: "Citi Custom Cash", cashbackPct: 5, spend: 81,
                date: date(monthsAgo: 1, day: 22)),
            rec(store: "Walgreens", category: "Pharmacy",
                card: "Chase Freedom Flex", cashbackPct: 5, spend: 36,
                date: date(monthsAgo: 1, day: 25)),
            rec(store: "McDonald's", category: "Dining",
                card: "Amex Gold Card", cashbackPct: 4, spend: 12,
                date: date(monthsAgo: 1, day: 28)),
        ]

        // ── This month (current, builds the active streak) ────────────────
        records += [
            rec(store: "Trader Joe's", category: "Grocery",
                card: "Amex Blue Cash Preferred", cashbackPct: 6, spend: 95,
                date: date(monthsAgo: 0, day: 2)),
            rec(store: "Starbucks", category: "Dining",
                card: "Amex Gold Card", cashbackPct: 4, spend: 21,
                date: date(monthsAgo: 0, day: 5)),
            rec(store: "Shell", category: "Gas",
                card: "Chase Freedom Flex", cashbackPct: 5, spend: 66,
                date: date(monthsAgo: 0, day: 8)),
            rec(store: "Whole Foods", category: "Grocery",
                card: "Amex Blue Cash Preferred", cashbackPct: 6, spend: 110,
                date: date(monthsAgo: 0, day: 11)),
            rec(store: "Chipotle", category: "Dining",
                card: "Amex Gold Card", cashbackPct: 4, spend: 19,
                date: date(monthsAgo: 0, day: 14)),
        ]

        return records.sorted { $0.date < $1.date }
    }
}
