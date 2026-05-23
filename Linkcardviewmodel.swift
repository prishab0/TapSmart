import Foundation
import Combine

// MARK: - MatchedCardItem
// The display model shown in LinkCardView's list

struct MatchedCardItem: Identifiable {
    let id:          String          // cardId e.g. "abcp"
    let cardId:      String
    let displayName: String          // Human-readable, from Plaid or our catalog
    let lastFour:    String?
    let confidence:  CardMatchResult.Confidence
}

// MARK: - LinkCardViewModel

@MainActor
final class LinkCardViewModel: ObservableObject {

    // MARK: - Published state

    @Published var isLoading:       Bool            = false
    @Published var showPlaidLink:   Bool            = false
    @Published var linkToken:       String?         = nil
    @Published var matchedCards:    [MatchedCardItem] = []
    @Published var errorMessage:    String?         = nil

    var hasLinkedAccount: Bool { PlaidService.shared.hasLinkedAccount }

    // MARK: - Step 1: Fetch link token and open Plaid Link

    func startLinkFlow() {
        errorMessage = nil
        isLoading    = true

        Task {
            do {
                // User ID: use a stable anonymous identifier so Plaid can
                // deduplicate across sessions without exposing PII.
                let userId   = stableUserId()
                let token    = try await PlaidService.shared.createLinkToken(userId: userId)
                linkToken    = token
                showPlaidLink = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - Step 2: Handle Plaid Link success

    func handleLinkSuccess(publicToken: String) {
        isLoading = true
        Task {
            do {
                // Exchange public token for access token (stored in Keychain by PlaidService)
                try await PlaidService.shared.exchangePublicToken(publicToken)
                // Fetch accounts and match them
                try await fetchAndMatchCards()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - Step 2b: Handle Plaid Link exit (user cancelled or error)

    func handleLinkExit(error: Error?) {
        showPlaidLink = false
        if let error {
            // Only surface non-cancellation errors
            let msg = error.localizedDescription
            if !msg.lowercased().contains("cancel") {
                errorMessage = msg
            }
        }
    }

    // MARK: - Step 3: Fetch cards from Plaid and sync to UserDefaults

    private func fetchAndMatchCards() async throws {
        let plaidCards = try await PlaidService.shared.fetchLinkedCards()
        let results    = PlaidCardMatcher.shared.matchAll(plaidCards)

        // Build display items
        matchedCards = results.map { result in
            let catalogName = RewardDataService.shared.allCards
                .first(where: { $0.cardId == result.cardId })?.name
                ?? result.plaidCard.name

            return MatchedCardItem(
                id:          result.cardId,
                cardId:      result.cardId,
                displayName: catalogName,
                lastFour:    result.plaidCard.mask,
                confidence:  result.confidence
            )
        }

        // Merge with any manually-toggled cards the user already had
        let linkedIds  = results.map(\.cardId)
        let existing   = UserDefaultsStore.userCards
        let merged     = Array(Set(existing + linkedIds))
        UserDefaultsStore.userCards = merged
    }

    // MARK: - Load existing linked cards on appear

    func loadExistingLinkedCards() {
        guard PlaidService.shared.hasLinkedAccount else { return }
        isLoading = true
        Task {
            do {
                try await fetchAndMatchCards()
            } catch {
                // Silently fail on load — don't alarm the user if Plaid is slow
                print("TapSmart: could not refresh Plaid cards — \(error)")
            }
            isLoading = false
        }
    }

    // MARK: - Remove linked account

    func removeLinkedAccount() {
        PlaidService.shared.removeLinkedAccount()
        matchedCards = []

        // Remove Plaid-linked card IDs from UserDefaults.
        // We keep any cards the user manually toggled on.
        // Since we can't distinguish them here without extra bookkeeping,
        // we reset to the default full set — user can re-toggle manually.
        UserDefaults.standard.removeObject(forKey: "ts_userCards")
        errorMessage = nil
    }

    // MARK: - Private helpers

    /// Returns a stable, anonymous user identifier (UUID stored in UserDefaults).
    /// Does NOT use any PII — Plaid only needs it to deduplicate link sessions.
    private func stableUserId() -> String {
        let key = "ts_plaid_user_id"
        if let existing = UserDefaults.standard.string(forKey: key) { return existing }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }
}
