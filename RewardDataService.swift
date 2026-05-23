import Foundation

// MARK: - Card Type

enum CardType: String, Codable {
    case credit
    case debit
}

// MARK: - RewardRate

struct RewardRate: Identifiable {
    let cardId: String
    let bank: String
    let bankColor: String
    let name: String
    let note: String
    let rates: [String: Double]
    let cardType: CardType          // NEW — .credit or .debit

    var id: String { cardId }
    var isDebit: Bool { cardType == .debit }
}

// MARK: - RewardDataService

class RewardDataService {
    static let shared = RewardDataService()

    // MCC codes used throughout the app
    // 5411 = Grocery, 5812 = Dining, 5541 = Gas, 5999 = Shopping/Rotating,
    // 5912 = Pharmacy, 5734 = Electronics, 5251 = Hardware, 4511 = Travel/Airlines,
    // 7011 = Hotels, 4111 = Transit, 5940 = Streaming (custom)

    let allCards: [RewardRate] = [

        // ── Chase (Credit) ───────────────────────────────────────────────────
        RewardRate(cardId: "cff",
                   bank: "CHASE", bankColor: "1A56DB",
                   name: "Chase Freedom Flex",
                   note: "5% rotating, 3% dining & pharmacy",
                   rates: ["5411": 5, "5812": 3, "5541": 2, "5999": 5,
                           "5912": 3, "5734": 1, "5251": 1, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "cfu",
                   bank: "CHASE", bankColor: "1A56DB",
                   name: "Chase Freedom Unlimited",
                   note: "1.5% everything, 3% dining & pharmacy",
                   rates: ["5411": 1.5, "5812": 3, "5541": 1.5, "5999": 1.5,
                           "5912": 3, "5734": 1.5, "5251": 1.5, "default": 1.5],
                   cardType: .credit),

        RewardRate(cardId: "csp",
                   bank: "CHASE", bankColor: "1A56DB",
                   name: "Chase Sapphire Preferred",
                   note: "3x dining & travel, 2x groceries",
                   rates: ["5411": 3, "5812": 3, "5541": 1, "5999": 1,
                           "4511": 3, "7011": 3, "4111": 3, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "csr",
                   bank: "CHASE", bankColor: "0A3D8F",
                   name: "Chase Sapphire Reserve",
                   note: "3x dining & travel, Priority Pass",
                   rates: ["5411": 1, "5812": 3, "5541": 1, "5999": 1,
                           "4511": 3, "7011": 3, "4111": 3, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "ink_cash",
                   bank: "CHASE", bankColor: "1A56DB",
                   name: "Ink Business Cash",
                   note: "5% office & internet, 2% gas & dining",
                   rates: ["5411": 1, "5812": 2, "5541": 2, "5734": 5,
                           "5912": 1, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "ink_unl",
                   bank: "CHASE", bankColor: "1A56DB",
                   name: "Ink Business Unlimited",
                   note: "1.5% everything",
                   rates: ["default": 1.5],
                   cardType: .credit),

        RewardRate(cardId: "amazon_chase",
                   bank: "CHASE", bankColor: "FF9900",
                   name: "Amazon Prime Rewards Visa",
                   note: "5% Amazon & Whole Foods",
                   rates: ["5411": 5, "5812": 2, "5541": 2, "5999": 1,
                           "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "southwest_plus",
                   bank: "CHASE", bankColor: "304CB2",
                   name: "Southwest Rapid Rewards Plus",
                   note: "2x Southwest & hotels",
                   rates: ["4511": 2, "7011": 2, "5812": 1, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "united_explorer",
                   bank: "CHASE", bankColor: "002244",
                   name: "United Explorer Card",
                   note: "2x United & dining",
                   rates: ["4511": 2, "5812": 2, "7011": 1, "default": 1],
                   cardType: .credit),

        // ── American Express (Credit) ─────────────────────────────────────────
        RewardRate(cardId: "abcp",
                   bank: "AMEX", bankColor: "006FCF",
                   name: "Amex Blue Cash Preferred",
                   note: "6% groceries, 6% streaming, 3% gas",
                   rates: ["5411": 6, "5812": 1, "5541": 3, "5940": 6,
                           "4111": 3, "5999": 1, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "abce",
                   bank: "AMEX", bankColor: "006FCF",
                   name: "Amex Blue Cash Everyday",
                   note: "3% groceries, 3% online, 3% gas",
                   rates: ["5411": 3, "5812": 1, "5541": 3, "5999": 1,
                           "5734": 3, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "amexgold",
                   bank: "AMEX", bankColor: "B8860B",
                   name: "Amex Gold Card",
                   note: "4x dining & groceries, 3x flights",
                   rates: ["5411": 4, "5812": 4, "5541": 1, "4511": 3,
                           "5999": 1, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "amexplat",
                   bank: "AMEX", bankColor: "A8A9AD",
                   name: "Amex Platinum",
                   note: "5x flights & hotels, lounge access",
                   rates: ["4511": 5, "7011": 5, "5812": 1, "5411": 1,
                           "5541": 1, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "amex_green",
                   bank: "AMEX", bankColor: "007B40",
                   name: "Amex Green Card",
                   note: "3x travel, dining & transit",
                   rates: ["5812": 3, "4511": 3, "7011": 3, "4111": 3,
                           "5411": 1, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "amex_biz_gold",
                   bank: "AMEX", bankColor: "B8860B",
                   name: "Amex Business Gold",
                   note: "4x on top 2 categories each month",
                   rates: ["5411": 4, "5812": 4, "5541": 4, "5734": 4,
                           "4511": 4, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "delta_gold",
                   bank: "AMEX", bankColor: "003366",
                   name: "Delta SkyMiles Gold Amex",
                   note: "2x Delta, dining & groceries",
                   rates: ["4511": 2, "5812": 2, "5411": 2, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "delta_plat",
                   bank: "AMEX", bankColor: "003366",
                   name: "Delta SkyMiles Platinum Amex",
                   note: "3x Delta, 2x dining & groceries",
                   rates: ["4511": 3, "5812": 2, "5411": 2, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "hilton_honors",
                   bank: "AMEX", bankColor: "003580",
                   name: "Hilton Honors Amex",
                   note: "7x Hilton, 5x dining & groceries",
                   rates: ["7011": 7, "5812": 5, "5411": 5, "5541": 3, "default": 3],
                   cardType: .credit),

        RewardRate(cardId: "marriott_bonvoy_amex",
                   bank: "AMEX", bankColor: "8B1A1A",
                   name: "Marriott Bonvoy Brilliant Amex",
                   note: "6x Marriott, 3x dining & grocery",
                   rates: ["7011": 6, "5812": 3, "5411": 3, "default": 2],
                   cardType: .credit),

        // ── Citi (Credit) ────────────────────────────────────────────────────
        RewardRate(cardId: "ccc",
                   bank: "CITI", bankColor: "C8102E",
                   name: "Citi Custom Cash",
                   note: "5% top spend category (up to $500/mo)",
                   rates: ["5411": 5, "5812": 5, "5541": 5, "5912": 5,
                           "5734": 5, "5251": 5, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "cdc",
                   bank: "CITI", bankColor: "C8102E",
                   name: "Citi Double Cash",
                   note: "2% everywhere (1% + 1% on payment)",
                   rates: ["default": 2],
                   cardType: .credit),

        RewardRate(cardId: "citi_premier",
                   bank: "CITI", bankColor: "C8102E",
                   name: "Citi Strata Premier",
                   note: "3x hotels, groceries, dining, gas & air",
                   rates: ["5411": 3, "5812": 3, "5541": 3, "7011": 3,
                           "4511": 3, "5999": 1, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "citi_rewards_plus",
                   bank: "CITI", bankColor: "C8102E",
                   name: "Citi Rewards+",
                   note: "2x groceries & gas, rounds up to 10pts",
                   rates: ["5411": 2, "5541": 2, "5812": 1, "default": 1],
                   cardType: .credit),

        // ── Capital One (Credit) ─────────────────────────────────────────────
        RewardRate(cardId: "coqs",
                   bank: "CAP1", bankColor: "CC0000",
                   name: "Capital One Quicksilver",
                   note: "1.5% everywhere",
                   rates: ["default": 1.5],
                   cardType: .credit),

        RewardRate(cardId: "co_savor",
                   bank: "CAP1", bankColor: "CC0000",
                   name: "Capital One Savor Cash Rewards",
                   note: "3% dining, grocery & streaming",
                   rates: ["5812": 3, "5411": 3, "5940": 3, "5999": 1, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "co_venture",
                   bank: "CAP1", bankColor: "CC0000",
                   name: "Capital One Venture Rewards",
                   note: "2x miles everywhere",
                   rates: ["default": 2],
                   cardType: .credit),

        RewardRate(cardId: "co_venture_x",
                   bank: "CAP1", bankColor: "9B1B1B",
                   name: "Capital One Venture X",
                   note: "2x everywhere, 10x hotels & rental cars",
                   rates: ["7011": 10, "default": 2],
                   cardType: .credit),

        // ── Wells Fargo (Credit) ─────────────────────────────────────────────
        RewardRate(cardId: "wf_active_cash",
                   bank: "WF", bankColor: "CC0000",
                   name: "Wells Fargo Active Cash",
                   note: "2% cash rewards everywhere",
                   rates: ["default": 2],
                   cardType: .credit),

        RewardRate(cardId: "wf_autograph",
                   bank: "WF", bankColor: "CC0000",
                   name: "Wells Fargo Autograph",
                   note: "3x dining, travel, gas & transit",
                   rates: ["5812": 3, "4511": 3, "5541": 3, "4111": 3,
                           "5940": 3, "5411": 1, "default": 1],
                   cardType: .credit),

        // ── Bank of America (Credit) ─────────────────────────────────────────
        RewardRate(cardId: "boa_customized",
                   bank: "BOA", bankColor: "E31837",
                   name: "Bank of America Customized Cash",
                   note: "3% chosen category, 2% grocery & wholesale",
                   rates: ["5411": 2, "5812": 3, "5541": 3, "5734": 3,
                           "5999": 2, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "boa_unlimited",
                   bank: "BOA", bankColor: "E31837",
                   name: "Bank of America Unlimited Cash",
                   note: "1.5% everywhere",
                   rates: ["default": 1.5],
                   cardType: .credit),

        RewardRate(cardId: "boa_premium",
                   bank: "BOA", bankColor: "E31837",
                   name: "Bank of America Premium Rewards",
                   note: "2x travel & dining, 1.5x everything else",
                   rates: ["5812": 2, "4511": 2, "7011": 2, "5411": 1.5,
                           "default": 1.5],
                   cardType: .credit),

        // ── Discover (Credit) ────────────────────────────────────────────────
        RewardRate(cardId: "disc_it",
                   bank: "DISC", bankColor: "FF6600",
                   name: "Discover it Cash Back",
                   note: "5% rotating quarterly categories",
                   rates: ["5411": 5, "5812": 5, "5541": 5, "5999": 5,
                           "5912": 5, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "disc_chrome",
                   bank: "DISC", bankColor: "FF6600",
                   name: "Discover it Chrome",
                   note: "2% gas & dining, 1% everything",
                   rates: ["5541": 2, "5812": 2, "default": 1],
                   cardType: .credit),

        // ── US Bank (Credit) ─────────────────────────────────────────────────
        RewardRate(cardId: "usb_altitude_connect",
                   bank: "USB", bankColor: "002F6C",
                   name: "US Bank Altitude Connect",
                   note: "4x travel, 2x grocery, gas & streaming",
                   rates: ["4511": 4, "7011": 4, "5411": 2, "5541": 2,
                           "5940": 2, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "usb_altitude_reserve",
                   bank: "USB", bankColor: "002F6C",
                   name: "US Bank Altitude Reserve",
                   note: "3x travel & mobile wallet",
                   rates: ["4511": 3, "7011": 3, "5812": 3, "5411": 1, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "usb_cash_plus",
                   bank: "USB", bankColor: "002F6C",
                   name: "US Bank Cash+",
                   note: "5% two chosen categories, 2% one everyday",
                   rates: ["5812": 5, "5941": 5, "5912": 5, "5411": 2,
                           "5541": 2, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "usb_shopper",
                   bank: "USB", bankColor: "002F6C",
                   name: "US Bank Shopper Cash Rewards",
                   note: "6% two chosen retailers, 3% one everyday",
                   rates: ["5999": 6, "5411": 3, "default": 1],
                   cardType: .credit),

        // ── Bilt (Credit) ────────────────────────────────────────────────────
        RewardRate(cardId: "bilt",
                   bank: "BILT", bankColor: "1A1A1A",
                   name: "Bilt Mastercard",
                   note: "1x rent (no fee), 3x dining, 2x travel",
                   rates: ["5812": 3, "4511": 2, "7011": 2, "5411": 1, "default": 1],
                   cardType: .credit),

        // ── Store / Co-Brand (Credit) ────────────────────────────────────────
        RewardRate(cardId: "costco_citi",
                   bank: "CITI", bankColor: "005DAA",
                   name: "Costco Anywhere Visa",
                   note: "4% gas, 3% dining & travel, 2% Costco",
                   rates: ["5541": 4, "5812": 3, "4511": 3, "7011": 3,
                           "5411": 2, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "target_red",
                   bank: "TARGET", bankColor: "CC0000",
                   name: "Target RedCard Credit",
                   note: "5% at Target & Target.com",
                   rates: ["5999": 5, "5411": 5, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "apple_card",
                   bank: "APPLE", bankColor: "1C1C1E",
                   name: "Apple Card",
                   note: "3% Apple, 2% Apple Pay, 1% physical",
                   rates: ["5734": 3, "5812": 2, "5411": 2, "5541": 2,
                           "5999": 2, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "paypal_cashback",
                   bank: "SYNC", bankColor: "003087",
                   name: "PayPal Cashback Mastercard",
                   note: "3% PayPal, 2% everywhere else",
                   rates: ["default": 2],
                   cardType: .credit),

        // ── Barclays (Credit) ────────────────────────────────────────────────
        RewardRate(cardId: "jetblue_plus",
                   bank: "BARC", bankColor: "0033A0",
                   name: "JetBlue Plus Card",
                   note: "6x JetBlue, 2x dining & grocery",
                   rates: ["4511": 6, "5812": 2, "5411": 2, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "aadvantage_aviator",
                   bank: "BARC", bankColor: "0078D2",
                   name: "AAdvantage Aviator Red",
                   note: "2x American Airlines purchases",
                   rates: ["4511": 2, "5812": 1, "default": 1],
                   cardType: .credit),

        // ── Hotel / Airline Co-brand (Credit) ────────────────────────────────
        RewardRate(cardId: "world_of_hyatt",
                   bank: "CHASE", bankColor: "5C2D91",
                   name: "World of Hyatt Credit Card",
                   note: "4x Hyatt, 2x dining, gym & transit",
                   rates: ["7011": 4, "5812": 2, "4111": 2, "5411": 1, "default": 1],
                   cardType: .credit),

        RewardRate(cardId: "ihg_premier",
                   bank: "CHASE", bankColor: "006241",
                   name: "IHG One Rewards Premier",
                   note: "10x IHG, 5x dining & travel, 3x everything",
                   rates: ["7011": 10, "5812": 5, "4511": 5, "5411": 3,
                           "5541": 3, "default": 3],
                   cardType: .credit),

        RewardRate(cardId: "marriott_bonvoy_bold",
                   bank: "CHASE", bankColor: "8B1A1A",
                   name: "Marriott Bonvoy Bold",
                   note: "3x Marriott, 2x groceries & dining",
                   rates: ["7011": 3, "5411": 2, "5812": 2, "default": 1],
                   cardType: .credit),

        // ── Credit Unions / Other (Credit) ───────────────────────────────────
        RewardRate(cardId: "pnc_cash_unlimited",
                   bank: "PNC", bankColor: "FF6600",
                   name: "PNC Cash Unlimited Visa",
                   note: "1.5% everywhere",
                   rates: ["default": 1.5],
                   cardType: .credit),

        RewardRate(cardId: "navy_fed_cashrewards",
                   bank: "NFCU", bankColor: "003087",
                   name: "Navy Federal cashRewards",
                   note: "1.75% everywhere (1.5% base + 0.25% bonus)",
                   rates: ["default": 1.75],
                   cardType: .credit),

        RewardRate(cardId: "penfed_platinum",
                   bank: "PENF", bankColor: "002F6C",
                   name: "PenFed Platinum Rewards Visa",
                   note: "5x gas, 3x grocery",
                   rates: ["5541": 5, "5411": 3, "5812": 1, "default": 1],
                   cardType: .credit),

        // ── Debit Cards ──────────────────────────────────────────────────────
        // Debit cards earn 0% rewards. They appear in rankings so users can
        // see them listed, but credit cards will always rank above them.

        RewardRate(cardId: "debit_chase",
                   bank: "CHASE", bankColor: "1A56DB",
                   name: "Chase Total Checking Debit",
                   note: "No rewards · Standard debit card",
                   rates: ["default": 0],
                   cardType: .debit),

        RewardRate(cardId: "debit_boa",
                   bank: "BOA", bankColor: "E31837",
                   name: "Bank of America Debit",
                   note: "No rewards · Standard debit card",
                   rates: ["default": 0],
                   cardType: .debit),

        RewardRate(cardId: "debit_wellsfargo",
                   bank: "WF", bankColor: "CC0000",
                   name: "Wells Fargo Debit",
                   note: "No rewards · Standard debit card",
                   rates: ["default": 0],
                   cardType: .debit),

        RewardRate(cardId: "debit_citi",
                   bank: "CITI", bankColor: "C8102E",
                   name: "Citi Debit",
                   note: "No rewards · Standard debit card",
                   rates: ["default": 0],
                   cardType: .debit),

        RewardRate(cardId: "debit_usbank",
                   bank: "USB", bankColor: "002F6C",
                   name: "US Bank Debit",
                   note: "No rewards · Standard debit card",
                   rates: ["default": 0],
                   cardType: .debit),

        RewardRate(cardId: "debit_cap1",
                   bank: "CAP1", bankColor: "CC0000",
                   name: "Capital One 360 Debit",
                   note: "No rewards · Standard debit card",
                   rates: ["default": 0],
                   cardType: .debit),

        RewardRate(cardId: "debit_ally",
                   bank: "ALLY", bankColor: "4A0066",
                   name: "Ally Bank Debit",
                   note: "No rewards · Standard debit card",
                   rates: ["default": 0],
                   cardType: .debit),

        RewardRate(cardId: "debit_chime",
                   bank: "CHIME", bankColor: "00D4AA",
                   name: "Chime Debit",
                   note: "No rewards · Standard debit card",
                   rates: ["default": 0],
                   cardType: .debit),

        RewardRate(cardId: "debit_schwab",
                   bank: "SCHW", bankColor: "00A9E0",
                   name: "Charles Schwab Debit",
                   note: "No rewards · Standard debit card",
                   rates: ["default": 0],
                   cardType: .debit),

        RewardRate(cardId: "debit_discover",
                   bank: "DISC", bankColor: "FF6600",
                   name: "Discover Cashback Debit",
                   note: "1% on up to $3,000/mo at select categories",
                   rates: ["5411": 1, "5812": 1, "5541": 1, "5999": 1, "default": 0],
                   cardType: .debit),

        RewardRate(cardId: "debit_target",
                   bank: "TARGET", bankColor: "CC0000",
                   name: "Target RedCard Debit",
                   note: "5% at Target & Target.com (debit version)",
                   rates: ["5999": 5, "5411": 5, "default": 0],
                   cardType: .debit),

        RewardRate(cardId: "debit_amazon",
                   bank: "AMZN", bankColor: "FF9900",
                   name: "Amazon Store Card (Debit-linked)",
                   note: "5% at Amazon for Prime members",
                   rates: ["5999": 5, "5411": 5, "default": 0],
                   cardType: .debit),
    ]

    private let mccLabels: [String: String] = [
        "5411": "Groceries",
        "5812": "Dining",
        "5541": "Gas",
        "5999": "Shopping",
        "5912": "Pharmacy",
        "5734": "Electronics",
        "5251": "Hardware",
        "4511": "Travel / Airlines",
        "7011": "Hotels",
        "4111": "Transit",
        "5940": "Streaming",
    ]

    func rate(for card: RewardRate, mcc: String) -> Double {
        card.rates[mcc] ?? card.rates["default"] ?? 0.0
    }

    func formatRate(_ r: Double) -> String {
        if r == 0 { return "0%" }
        return r.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(r))%" : "\(r)%"
    }

    func getBestCard(forMCC mcc: String, userCards: [String]) -> CardOption? {
        getAllCards(forMCC: mcc, userCards: userCards).first
    }

    func getAllCards(forMCC mcc: String, userCards: [String]) -> [CardOption] {
        let owned  = allCards.filter { userCards.contains($0.cardId) }
        // Sort: first by rate descending, then credit before debit as tiebreak
        let sorted = owned.sorted {
            let r0 = rate(for: $0, mcc: mcc)
            let r1 = rate(for: $1, mcc: mcc)
            if r0 != r1 { return r0 > r1 }
            // Same rate: prefer credit over debit
            if $0.cardType != $1.cardType {
                return $0.cardType == .credit
            }
            return false
        }
        let label = mccLabels[mcc] ?? "All purchases"
        return sorted.enumerated().map { idx, card in
            let r = rate(for: card, mcc: mcc)
            let typeTag = card.isDebit ? " · DEBIT" : ""
            return CardOption(
                bank:      card.bank,
                bankColor: card.bankColor,
                name:      card.name,
                category:  "\(label) · \(card.note)\(typeTag)",
                cashback:  formatRate(r),
                isBest:    idx == 0,
                isDebit:   card.isDebit
            )
        }
    }

    // MARK: - Search

    /// Returns cards matching query. Optional filter for card type.
    func search(_ query: String, type: CardType? = nil) -> [RewardRate] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        var results = q.isEmpty ? allCards : allCards.filter {
            $0.name.lowercased().contains(q) ||
            $0.bank.lowercased().contains(q) ||
            $0.note.lowercased().contains(q) ||
            (q == "debit" && $0.isDebit) ||
            (q == "credit" && !$0.isDebit)
        }
        if let type { results = results.filter { $0.cardType == type } }
        return results
    }
}
