import Foundation

// MARK: - Match Result

struct CardMatchResult {
    let cardId:       String      // e.g. "abcp" — key into RewardDataService
    let confidence:   Confidence
    let plaidCard:    PlaidCard

    enum Confidence {
        case exact       // name matched perfectly
        case strong      // issuer + subtype matched
        case fallback    // we picked the generic flat-rate card for this network
    }
}

// MARK: - PlaidCardMatcher

/// Maps a Plaid-returned PlaidCard to one of TapSmart's internal cardId strings.
///
/// Strategy (tried in order):
///   1. Exact name match against a hand-coded keyword table
///   2. Issuer + product-keyword match (catches renamed cards)
///   3. Network fallback (Visa → cdc, Amex → abcp, etc.)
///
/// When you add new cards to RewardDataService, add a corresponding row to
/// `nameRules` below and the matcher will pick it up automatically.
final class PlaidCardMatcher {

    static let shared = PlaidCardMatcher()

    // MARK: - Name-based rules
    // Each rule: (keywords that must ALL appear in the lowercased card name) → cardId
    // Order matters — put more specific rules first.
    private let nameRules: [(keywords: [String], cardId: String)] = [
        // Chase
        (["chase", "freedom", "flex"],              "cff"),
        (["chase", "freedom", "unlimited"],         "cff"),   // map to cff (same category profile)
        (["chase", "sapphire", "preferred"],        "csp"),
        (["chase", "sapphire", "reserve"],          "csp"),   // close enough for our MCC rates

        // Amex
        (["amex", "blue", "cash", "preferred"],     "abcp"),
        (["american express", "blue", "cash", "preferred"], "abcp"),
        (["amex", "gold"],                          "amexgold"),
        (["american express", "gold"],              "amexgold"),
        (["amex", "blue", "cash", "everyday"],      "abcp"),  // everyday → preferred profile

        // Citi
        (["citi", "custom", "cash"],                "ccc"),
        (["citi", "double", "cash"],                "cdc"),
        (["citi", "rewards+"],                      "cdc"),

        // Capital One
        (["capital one", "quicksilver"],            "coqs"),
        (["capital one", "savor"],                  "coqs"),  // treat savor as flat rate fallback
        (["capital one", "venture"],                "coqs"),
    ]

    // MARK: - Issuer keyword → default card for that issuer
    private let issuerFallback: [(keyword: String, cardId: String)] = [
        ("chase",            "csp"),
        ("amex",             "abcp"),
        ("american express", "abcp"),
        ("citi",             "cdc"),
        ("capital one",      "coqs"),
    ]

    // MARK: - Public API

    /// Attempt to match a single PlaidCard.
    /// Returns nil if the card can't be matched to anything in our catalog
    /// (e.g. a debit card that slipped through the credit-card filter).
    func match(_ plaidCard: PlaidCard) -> CardMatchResult? {
        let searchText = combinedText(for: plaidCard)

        // 1. Exact name match
        for rule in nameRules {
            if rule.keywords.allSatisfy({ searchText.contains($0) }) {
                return CardMatchResult(cardId:     rule.cardId,
                                       confidence: .exact,
                                       plaidCard:  plaidCard)
            }
        }

        // 2. Issuer fallback
        for fallback in issuerFallback {
            if searchText.contains(fallback.keyword) {
                return CardMatchResult(cardId:     fallback.cardId,
                                       confidence: .strong,
                                       plaidCard:  plaidCard)
            }
        }

        // 3. Generic network fallback (any credit card → Citi Double Cash 2%)
        if plaidCard.subtype?.lowercased() == "credit card" {
            return CardMatchResult(cardId:     "cdc",
                                   confidence: .fallback,
                                   plaidCard:  plaidCard)
        }

        return nil // debit / unknown — skip
    }

    /// Match a list of PlaidCards, deduplicate by cardId, and return the cardIds.
    /// If two Plaid accounts map to the same cardId (e.g. two Chase Freedom cards)
    /// we keep only one entry — RewardDataService doesn't need duplicates.
    func matchAll(_ plaidCards: [PlaidCard]) -> [CardMatchResult] {
        var seen    = Set<String>()
        var results = [CardMatchResult]()
        for card in plaidCards {
            guard let result = match(card),
                  !seen.contains(result.cardId) else { continue }
            seen.insert(result.cardId)
            results.append(result)
        }
        return results
    }

    // MARK: - Private

    private func combinedText(for card: PlaidCard) -> String {
        [card.name, card.officialName ?? ""]
            .joined(separator: " ")
            .lowercased()
    }
}
