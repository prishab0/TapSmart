import Foundation

// MARK: - ProactiveAlert

struct ProactiveAlert: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let message: String
    let colorHex: String
}

// MARK: - CardOfTheMonth

struct CardOfTheMonth {
    let card: RewardRate
    /// Extra cashback projected annually vs. the user's current best card
    let projectedAnnualGain: Double
    /// The MCC category where this card wins most
    let topCategory: String
    /// Gain in percentage points for that category
    let topCategoryGain: Double
    /// Sign-on bonus description (display string)
    let signOnBonus: String
    /// Minimum spend required to earn the bonus
    let signOnSpend: Double
    /// Dollar value of the bonus
    let signOnValue: Double
    /// Month this recommendation is for (display string, e.g. "May 2026")
    let forMonth: String
    /// Affiliate / application URL — opens in Safari
    let affiliateURL: URL?
}

// MARK: - ProactiveAlertsEngine

class ProactiveAlertsEngine {
    static let shared = ProactiveAlertsEngine()

    // MARK: - Card of the Month

    /// Analyses last month's transactions and recommends the single unowned card
    /// that would have earned the most extra cashback, plus its sign-on bonus.
    func cardOfTheMonth(savings: [SavingRecord],
                        userCards: [String]) -> CardOfTheMonth? {

        let cal = Calendar.current
        let now = Date()

        guard let lastMonthDate = cal.date(byAdding: .month, value: -1, to: now) else { return nil }
        let lastMonth = cal.component(.month, from: lastMonthDate)
        let lastYear  = cal.component(.year,  from: lastMonthDate)

        let lastMonthRecords = savings.filter {
            cal.component(.month, from: $0.date) == lastMonth &&
            cal.component(.year,  from: $0.date) == lastYear
        }

        guard lastMonthRecords.count >= 2 else { return nil }

        let svc = RewardDataService.shared

        // Build spend per MCC from last month
        var spendPerMCC: [String: Double] = [:]
        for rec in lastMonthRecords {
            let mcc = mccForCategory(rec.category)
            spendPerMCC[mcc, default: 0] += rec.spendAmount
        }

        // Current best rate per MCC from owned cards
        var currentBestRate: [String: Double] = [:]
        for mcc in spendPerMCC.keys {
            let best = svc.allCards
                .filter { userCards.contains($0.cardId) }
                .map { svc.rate(for: $0, mcc: mcc) }
                .max() ?? 1.0
            currentBestRate[mcc] = best
        }

        // Score every unowned credit card
        let candidates = svc.allCards.filter {
            !userCards.contains($0.cardId) && !$0.isDebit
        }

        struct Scored {
            let card: RewardRate
            let totalGain: Double
            let topCategory: String
            let topGainPct: Double
        }

        let scored: [Scored] = candidates.compactMap { card in
            var totalGain = 0.0
            var topCat = ""
            var topGainPct = 0.0

            for (mcc, spend) in spendPerMCC {
                let newRate = svc.rate(for: card, mcc: mcc)
                let curRate = currentBestRate[mcc] ?? 1.0
                guard newRate > curRate else { continue }
                let gain = (newRate - curRate) / 100.0 * spend * 12.0
                totalGain += gain
                let pctGain = newRate - curRate
                if pctGain > topGainPct {
                    topGainPct = pctGain
                    topCat = categoryForMCC(mcc)
                }
            }
            guard totalGain > 0 else { return nil }
            return Scored(card: card, totalGain: totalGain,
                          topCategory: topCat, topGainPct: topGainPct)
        }

        guard let best = scored.max(by: { $0.totalGain < $1.totalGain }) else { return nil }

        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        let monthLabel = fmt.string(from: lastMonthDate)

        let (bonusDesc, bonusSpend, bonusValue) = signOnBonus(for: best.card.cardId)
        let affiliateURL = affiliateURL(for: best.card.cardId)

        return CardOfTheMonth(
            card:                best.card,
            projectedAnnualGain: best.totalGain,
            topCategory:         best.topCategory,
            topCategoryGain:     best.topGainPct,
            signOnBonus:         bonusDesc,
            signOnSpend:         bonusSpend,
            signOnValue:         bonusValue,
            forMonth:            monthLabel,
            affiliateURL:        affiliateURL
        )
    }

    // MARK: - Regular proactive alerts

    func generateAlerts(savings: [SavingRecord],
                        userCards: [String]) -> [ProactiveAlert] {
        var alerts: [ProactiveAlert] = []

        // Regular stops (3+ visits)
        let visitCounts = Dictionary(grouping: savings, by: \.storeName)
            .filter { $0.value.count >= 3 }
            .sorted { $0.value.count > $1.value.count }

        for (storeName, visits) in visitCounts {
            let mcc      = mccForStore(storeName)
            let bestCard = RewardDataService.shared.getBestCard(forMCC: mcc, userCards: userCards)
            let cardLine = bestCard != nil
                ? "Use your \(bestCard!.name) (\(bestCard!.cashback) back) every time you're here."
                : "Make sure you're using the right card every visit."
            alerts.append(ProactiveAlert(
                icon:     categoryIconForStore(storeName),
                title:    "Regular stop: \(storeName)",
                message:  "You've visited \(visits.count) times. \(cardLine)",
                colorHex: "22C55E"
            ))
        }

        // Idle card (unused 30+ days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let usedCardNames = Set(savings.filter { $0.date > thirtyDaysAgo }.map { $0.cardName })
        let allOwnedCards = RewardDataService.shared.allCards.filter { userCards.contains($0.cardId) }
        for card in allOwnedCards where !usedCardNames.contains(card.name) {
            alerts.append(ProactiveAlert(
                icon: "💳",
                title: "\(card.name) is sitting idle",
                message: "You haven't used it in 30+ days. It earns \(card.note) — worth putting to work.",
                colorHex: "14B8A6"
            ))
            break
        }

        // Savings milestone
        let total = savings.reduce(0) { $0 + $1.amount }
        if total > 0 {
            let nextMilestone = (floor(total / 50) + 1) * 50
            let gap = nextMilestone - total
            alerts.append(ProactiveAlert(
                icon: "🎯",
                title: "$\(String(format: "%.0f", gap)) from your next milestone",
                message: "You've saved $\(String(format: "%.2f", total)) total. Keep using your best cards to reach $\(String(format: "%.0f", nextMilestone)).",
                colorHex: "D97706"
            ))
        }

        // Fallback
        if alerts.isEmpty {
            alerts = [
                ProactiveAlert(icon: "🛒", title: "Good time to go to Target",
                    message: "Chase Freedom Flex gives 5% back on rotating categories there this quarter.",
                    colorHex: "22C55E"),
                ProactiveAlert(icon: "💳", title: "Unused card earning nothing",
                    message: "Your Citi card earns 4% at restaurants. Use it at dinner tonight.",
                    colorHex: "14B8A6"),
                ProactiveAlert(icon: "✈️", title: "847 miles from a free flight",
                    message: "Use your JetBlue card at Target this week to close the gap.",
                    colorHex: "D97706"),
            ]
        }

        return alerts
    }

    // MARK: - Affiliate URL table
    // Replace any placeholder URL with your actual affiliate/referral link.
    // Format: cardId → URL string

    func affiliateURL(for cardId: String) -> URL? {
        // Using switch instead of a dictionary literal — large dict literals
        // cause a Swift compiler assertion crash at runtime on device/simulator.
        let raw: String?
        switch cardId {
        // Chase
        case "cff":               raw = "https://creditcards.chase.com/cash-back-credit-cards/freedom/flex"
        case "cfu":               raw = "https://creditcards.chase.com/cash-back-credit-cards/freedom/unlimited"
        case "csp":               raw = "https://creditcards.chase.com/rewards-credit-cards/sapphire/preferred"
        case "csr":               raw = "https://creditcards.chase.com/rewards-credit-cards/sapphire/reserve"
        case "ink_cash":          raw = "https://creditcards.chase.com/business-credit-cards/ink/cash"
        case "ink_unl":           raw = "https://creditcards.chase.com/business-credit-cards/ink/unlimited"
        case "amazon_chase":      raw = "https://www.amazon.com/dp/B07P5V4XTS"
        case "world_of_hyatt":    raw = "https://creditcards.chase.com/travel-credit-cards/hyatt"
        case "ihg_premier":       raw = "https://creditcards.chase.com/travel-credit-cards/ihg-rewards/premier"
        case "southwest_plus":    raw = "https://creditcards.chase.com/travel-credit-cards/southwest/plus"
        case "united_explorer":   raw = "https://creditcards.chase.com/travel-credit-cards/united/explorer"
        case "marriott_bonvoy_bold": raw = "https://creditcards.chase.com/travel-credit-cards/marriott-bonvoy/bold"
        // American Express
        case "abcp":              raw = "https://www.americanexpress.com/us/credit-cards/card/blue-cash-preferred"
        case "abce":              raw = "https://www.americanexpress.com/us/credit-cards/card/blue-cash-everyday"
        case "amexgold":          raw = "https://www.americanexpress.com/us/credit-cards/card/gold-card"
        case "amexplat":          raw = "https://www.americanexpress.com/us/credit-cards/card/platinum"
        case "amex_green":        raw = "https://www.americanexpress.com/us/credit-cards/card/green-card"
        case "amex_biz_gold":     raw = "https://www.americanexpress.com/us/credit-cards/card/business-gold"
        case "delta_gold":        raw = "https://www.americanexpress.com/us/credit-cards/card/delta-skymiles-gold"
        case "delta_plat":        raw = "https://www.americanexpress.com/us/credit-cards/card/delta-skymiles-platinum"
        case "hilton_honors":     raw = "https://www.americanexpress.com/us/credit-cards/card/hilton-honors"
        case "marriott_bonvoy_amex": raw = "https://www.americanexpress.com/us/credit-cards/card/marriott-bonvoy-brilliant"
        // Citi
        case "ccc":               raw = "https://www.citi.com/credit-cards/citi-custom-cash-credit-card"
        case "cdc":               raw = "https://www.citi.com/credit-cards/citi-double-cash-credit-card"
        case "citi_premier":      raw = "https://www.citi.com/credit-cards/citi-strata-premier"
        case "citi_rewards_plus": raw = "https://www.citi.com/credit-cards/citi-rewards-plus-credit-card"
        case "costco_citi":       raw = "https://www.citi.com/credit-cards/costco-anywhere-visa"
        // Capital One
        case "coqs":              raw = "https://capital.one/3QBFHgV"
        case "co_savor":          raw = "https://capital.one/3QBFHgV"
        case "co_venture":        raw = "https://capital.one/3VJFqY0"
        case "co_venture_x":      raw = "https://capital.one/3VJFqY0"
        // Wells Fargo
        case "wf_active_cash":    raw = "https://www.wellsfargo.com/credit-cards/active-cash"
        case "wf_autograph":      raw = "https://www.wellsfargo.com/credit-cards/autograph"
        // Bank of America
        case "boa_customized":    raw = "https://www.bankofamerica.com/credit-cards/products/cash-back-credit-card"
        case "boa_unlimited":     raw = "https://www.bankofamerica.com/credit-cards/products/unlimited-cash-back-credit-card"
        case "boa_premium":       raw = "https://www.bankofamerica.com/credit-cards/products/premium-rewards-credit-card"
        // Discover
        case "disc_it":           raw = "https://www.discover.com/credit-cards/cash-back/it-card.html"
        case "disc_chrome":       raw = "https://www.discover.com/credit-cards/cash-back/chrome-card.html"
        // US Bank
        case "usb_altitude_connect": raw = "https://www.usbank.com/credit-cards/altitude-connect-visa-signature-credit-card.html"
        case "usb_altitude_reserve": raw = "https://www.usbank.com/credit-cards/altitude-reserve-visa-infinite-credit-card.html"
        case "usb_cash_plus":     raw = "https://www.usbank.com/credit-cards/cash-plus-visa-signature-credit-card.html"
        case "usb_shopper":       raw = "https://www.usbank.com/credit-cards/shopper-cash-rewards-visa-signature-credit-card.html"
        // Bilt
        case "bilt":              raw = "https://www.biltrewards.com/card"
        // Store / Co-brand
        case "target_red":        raw = "https://www.target.com/redcard/about"
        case "apple_card":        raw = "https://www.apple.com/apple-card"
        case "paypal_cashback":   raw = "https://www.paypal.com/us/webapps/mpp/cashback-mastercard"
        // Barclays
        case "jetblue_plus":      raw = "https://www.barclays.com/credit-cards/jetblue-plus-card"
        case "aadvantage_aviator":raw = "https://cards.barclay.com/americanairlines"
        // Other
        case "pnc_cash_unlimited":raw = "https://www.pnc.com/en/personal-banking/banking/credit-cards/cash-unlimited.html"
        case "navy_fed_cashrewards": raw = "https://www.navyfederal.org/loans-cards/credit-cards/cashrewards"
        case "penfed_platinum":   raw = "https://www.penfed.org/credit-cards/platinum-rewards-visa"
        default:                  raw = nil
        }
        guard let raw, let url = URL(string: raw) else { return nil }
        return url
    }

    // MARK: - Sign-on bonus table

    private func signOnBonus(for cardId: String) -> (String, Double, Double) {
        switch cardId {
        case "cff":          return ("$200 cash bonus after $500 spend in first 3 months", 500, 200)
        case "cfu":          return ("$200 cash bonus after $500 spend in first 3 months", 500, 200)
        case "csp":          return ("60,000 points (~$750 in travel) after $4,000 spend in 3 months", 4000, 750)
        case "csr":          return ("60,000 points (~$900 in travel) after $4,000 spend in 3 months", 4000, 900)
        case "ink_cash":     return ("$750 cash bonus after $6,000 spend in first 3 months", 6000, 750)
        case "ink_unl":      return ("$750 cash bonus after $6,000 spend in first 3 months", 6000, 750)
        case "amazon_chase": return ("$100 Amazon gift card upon approval", 0, 100)
        case "world_of_hyatt": return ("30,000 points after $3,000 spend in 3 months", 3000, 450)
        case "ihg_premier":  return ("140,000 points after $3,000 spend in 3 months", 3000, 700)
        case "southwest_plus": return ("50,000 points after $1,000 spend in 3 months", 1000, 500)
        case "united_explorer": return ("50,000 miles after $3,000 spend in 3 months", 3000, 700)
        case "marriott_bonvoy_bold": return ("30,000 points after $1,000 spend in 3 months", 1000, 300)
        case "abcp":         return ("$250 statement credit after $3,000 spend in 6 months", 3000, 250)
        case "abce":         return ("$200 statement credit after $2,000 spend in 6 months", 2000, 200)
        case "amexgold":     return ("60,000 points (~$600 in travel) after $6,000 spend in 6 months", 6000, 600)
        case "amexplat":     return ("80,000 points (~$800 in travel) after $8,000 spend in 6 months", 8000, 800)
        case "amex_green":   return ("40,000 points after $3,000 spend in 6 months", 3000, 400)
        case "amex_biz_gold":return ("70,000 points after $10,000 spend in 3 months", 10000, 700)
        case "delta_gold":   return ("40,000 miles after $2,000 spend in 6 months", 2000, 400)
        case "delta_plat":   return ("50,000 miles after $3,000 spend in 6 months", 3000, 500)
        case "hilton_honors":return ("70,000 Hilton points after $1,000 spend in 3 months", 1000, 350)
        case "marriott_bonvoy_amex": return ("95,000 points after $6,000 spend in 6 months", 6000, 950)
        case "ccc":          return ("$200 cash back after $1,500 spend in first 6 months", 1500, 200)
        case "cdc":          return ("$200 cash back after $1,500 spend in first 6 months", 1500, 200)
        case "citi_premier": return ("60,000 points ($600 cash) after $4,000 spend in 3 months", 4000, 600)
        case "citi_rewards_plus": return ("20,000 points after $1,500 spend in 3 months", 1500, 200)
        case "costco_citi":  return ("No public sign-on bonus — available in-store", 0, 0)
        case "coqs":         return ("$200 cash bonus after $500 spend in first 3 months", 500, 200)
        case "co_savor":     return ("$250 cash bonus after $500 spend in first 3 months", 500, 250)
        case "co_venture":   return ("75,000 miles after $4,000 spend in 3 months", 4000, 750)
        case "co_venture_x": return ("75,000 miles after $4,000 spend in 3 months", 4000, 750)
        case "wf_active_cash": return ("$200 cash rewards after $500 spend in first 3 months", 500, 200)
        case "wf_autograph": return ("20,000 points ($200 cash) after $1,000 spend in 3 months", 1000, 200)
        case "boa_customized": return ("$200 online cash reward after $1,000 spend in first 90 days", 1000, 200)
        case "boa_unlimited": return ("$200 online cash reward after $1,000 spend in first 90 days", 1000, 200)
        case "boa_premium":  return ("60,000 points ($600 in travel) after $4,000 spend in 90 days", 4000, 600)
        case "disc_it":      return ("Cashback Match™ — Discover matches all cash back in year 1", 0, 0)
        case "disc_chrome":  return ("Cashback Match™ — Discover matches all cash back in year 1", 0, 0)
        case "usb_altitude_connect": return ("20,000 points ($200 value) after $1,000 spend in 90 days", 1000, 200)
        case "usb_altitude_reserve": return ("50,000 points after $4,500 spend in 90 days", 4500, 750)
        case "usb_cash_plus":return ("$200 rewards after $1,000 spend in first 120 days", 1000, 200)
        case "usb_shopper":  return ("$250 rewards after $2,000 spend in first 120 days", 2000, 250)
        case "bilt":         return ("No traditional sign-on bonus — earns on rent from day 1", 0, 0)
        case "target_red":   return ("$40 off first purchase on approval", 0, 40)
        case "apple_card":   return ("No sign-on bonus — Daily Cash from day 1", 0, 0)
        case "paypal_cashback": return ("No public sign-on bonus", 0, 0)
        case "jetblue_plus": return ("40,000 bonus points after $1,000 spend in 90 days", 1000, 400)
        case "aadvantage_aviator": return ("60,000 miles after first purchase + $99 annual fee", 1, 600)
        case "pnc_cash_unlimited": return ("$200 cash when you spend $1,000 in first 3 billing cycles", 1000, 200)
        case "navy_fed_cashrewards": return ("$250 bonus for qualifying members", 0, 250)
        case "penfed_platinum": return ("15,000 points after $1,500 spend in first 90 days", 1500, 150)
        default:             return ("Check issuer website for current offer", 0, 0)
        }
    }

    // MARK: - Store → MCC

    func mccForStore(_ name: String) -> String {
        switch name {
        case "Trader Joe's", "Whole Foods", "Kroger",
             "Safeway", "Amazon Fresh", "Costco":   return "5411"
        case "Starbucks", "Chipotle", "McDonald's",
             "Chick-fil-A", "Panera Bread":         return "5812"
        case "Shell", "Chevron", "Arco",
             "76 Station":                          return "5541"
        case "Target", "Walmart":                   return "5999"
        case "CVS", "Walgreens":                    return "5912"
        case "Best Buy":                            return "5734"
        case "Home Depot":                          return "5251"
        default:                                    return "5999"
        }
    }

    // MARK: - Category ↔ MCC helpers

    private func mccForCategory(_ category: String) -> String {
        switch category {
        case "Grocery":     return "5411"
        case "Dining":      return "5812"
        case "Gas":         return "5541"
        case "Shopping":    return "5999"
        case "Pharmacy":    return "5912"
        case "Electronics": return "5734"
        case "Hardware":    return "5251"
        case "Travel":      return "4511"
        case "Hotels":      return "7011"
        default:            return "5999"
        }
    }

    private func categoryForMCC(_ mcc: String) -> String {
        switch mcc {
        case "5411": return "Grocery"
        case "5812": return "Dining"
        case "5541": return "Gas"
        case "5999": return "Shopping"
        case "5912": return "Pharmacy"
        case "5734": return "Electronics"
        case "5251": return "Hardware"
        case "4511": return "Travel"
        case "7011": return "Hotels"
        default:     return "Shopping"
        }
    }

    func categoryIconForStore(_ name: String) -> String {
        switch mccForStore(name) {
        case "5411": return "🛒"
        case "5812": return "🍽️"
        case "5541": return "⛽"
        case "5999": return "🛍️"
        case "5912": return "💊"
        case "5734": return "💻"
        case "5251": return "🔨"
        default:     return "🛒"
        }
    }
}
