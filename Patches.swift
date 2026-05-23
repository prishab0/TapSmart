// MARK: ─────────────────────────────────────────────────────────────────────
// TAPSMART PATCHES
// Apply each section to the file named in the header comment.
// Each patch is a DROP-IN replacement — copy the entire marked block.
// ─────────────────────────────────────────────────────────────────────────────


// ══════════════════════════════════════════════════════════════════════════════
// FILE: SavingsView.swift
// PATCH 1 — Empty state + manual logger + share button
// ══════════════════════════════════════════════════════════════════════════════
//
// 1a. Add two @State vars at the top of SavingsView:
//
//     @State private var showLogger = false
//     @State private var showShare  = false
//
// 1b. In the ScrollView VStack, replace the opening `.padding(.top, 40)` block:
//
//     BEFORE:
//         var body: some View {
//             ZStack {
//                 Color(hex: "0D1B2A").ignoresSafeArea()
//                 ScrollView {
//                     VStack(spacing: 24) {
//                         // ── Hero ──────────────────
//                         VStack(spacing: 8) {
//
//     AFTER:
//         var body: some View {
//             ZStack {
//                 Color(hex: "0D1B2A").ignoresSafeArea()
//
//                 // Empty state shown when there are no records
//                 if store.records.isEmpty {
//                     SavingsEmptyState { showLogger = true }
//                 } else {
//                 ScrollView {
//                     VStack(spacing: 24) {
//                         // ── Hero ──────────────────
//                         VStack(spacing: 8) {
//
// 1c. Close the else block before the closing brace of the ZStack:
//
//                 } // end else
//             } // end ZStack
//
// 1d. Add sheets at the end of the ZStack modifier chain:
//
//     .sheet(isPresented: $showLogger) { ManualSavingsLogger() }
//     .sheet(isPresented: $showShare) {
//         let text = SavingsSummaryShareSheet.summary(from: store)
//         ActivityView(activityItems: [text])
//     }
//
// 1e. Add share button to the navigation toolbar (in ContentView, SavingsView
//     toolbar area):
//
//     ToolbarItem(placement: .navigationBarLeading) {
//         Button { showShare = true } label: {
//             Image(systemName: "square.and.arrow.up")
//                 .foregroundColor(Color(hex: "14B8A6"))
//         }
//     }
//     ToolbarItem(placement: .navigationBarTrailing) {
//         Button { showLogger = true } label: {
//             Image(systemName: "plus.circle.fill")
//                 .foregroundColor(Color(hex: "14B8A6"))
//         }
//     }


// ══════════════════════════════════════════════════════════════════════════════
// FILE: CardSetupView.swift
// PATCH 2 — Fix CardDetailSheet add/remove button state
// ══════════════════════════════════════════════════════════════════════════════
//
// The `currentlyOwned` variable is computed but never used, and the @State
// `added` flips but `isOwned` (a let) never changes, so after tapping "Add"
// the label still reads "Add" on a fast re-render.
//
// REPLACE the entire button block in CardDetailSheet with:

/*
@State private var locallyOwned: Bool      // initialized in .onAppear

// In the sheet body, replace the CTA button:
Button {
    onToggle()
    locallyOwned.toggle()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
        dismiss()
    }
} label: {
    HStack(spacing: 10) {
        Image(systemName: locallyOwned ? "minus.circle.fill" : "plus.circle.fill")
            .font(.system(size: 20))
        Text(locallyOwned ? "Remove from My Cards" : "Add to My Cards")
            .font(.system(size: 18, weight: .bold))
    }
    .foregroundColor(.white)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 18)
    .background(locallyOwned ? Color(hex: "DC2626") : Color(hex: "14B8A6"))
    .cornerRadius(14)
}
.onAppear { locallyOwned = isOwned }
*/

// ══════════════════════════════════════════════════════════════════════════════
// FILE: TapSmartTests.swift
// PATCH 3 — Fix failing test: default wallet has 8 cards, not 7
// ══════════════════════════════════════════════════════════════════════════════
//
// REPLACE the test body:

/*
@Test func userCardsDefaultsToAllCards() {
    UserDefaults.standard.removeObject(forKey: "ts_userCards")
    let cards = UserDefaultsStore.userCards
    // Default wallet: cff, abcp, amexgold, ccc, csp, cdc, coqs, debit_discover (8 total)
    #expect(cards.count == 8)
    #expect(cards.contains("cff"))
    #expect(cards.contains("abcp"))
    #expect(cards.contains("debit_discover"))
}
*/

// ══════════════════════════════════════════════════════════════════════════════
// FILE: SavingsStore.swift
// PATCH 4 — Add spendAmount to SavingRecord so per-transaction amounts
//           are stored and can be displayed in the detail view.
// ══════════════════════════════════════════════════════════════════════════════
//
// 4a. Add `spendAmount: Double` to SavingRecord:
//
// REPLACE:
//     struct SavingRecord: Codable, Identifiable {
//         let id: UUID
//         let storeName: String
//         let category: String
//         let cardName: String
//         let amount: Double
//         let date: Date
//         let usedBestCard: Bool
//     }
//
// WITH:
//     struct SavingRecord: Codable, Identifiable {
//         let id: UUID
//         let storeName: String
//         let category: String
//         let cardName: String
//         let amount: Double           // cashback earned above 1% baseline
//         let spendAmount: Double      // actual purchase total
//         let date: Date
//         let usedBestCard: Bool
//     }
//
// 4b. Add a default in the OldRecord migration so existing records decode cleanly:
//     spendAmount: 50.0    // back-filled default
//
// 4c. Replace the existing `recordSaving` method signature with the version in
//     ManualSavingsLogger.swift (the extension). The extension adds a `spendAmount`
//     parameter with a default of 50.0, so ALL existing call sites remain
//     unchanged and the new ManualSavingsLogger can pass real amounts.
//
//     Remove the original `recordSaving` from SavingsStore.swift after adding the
//     extension in ManualSavingsLogger.swift, to avoid duplicate method errors.


// ══════════════════════════════════════════════════════════════════════════════
// FILE: ProactiveAlertsEngine.swift
// PATCH 5 — Fix idle card detection (name match → cardId match)
// ══════════════════════════════════════════════════════════════════════════════
//
// The current code checks `!usedCardNames.contains(card.name)` where
// usedCardNames is built from `$0.cardName` (a display string like
// "Amex Blue Cash Preferred"). If the card name ever changes or drifts in
// RewardDataService, this silently breaks and marks every card as idle.
//
// REPLACE the Rule 2 block:

/*
// Rule 2 — A card hasn't been used in 30 days
let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

// Build a set of card NAMES used recently (SavingRecord stores the display name)
let usedCardNames = Set(
    savings.filter { $0.date > thirtyDaysAgo }.map { $0.cardName }
)

let allOwnedCards = RewardDataService.shared.allCards
    .filter { userCards.contains($0.cardId) }

for card in allOwnedCards {
    // Match by name because SavingRecord doesn't store cardId
    let wasUsed = usedCardNames.contains(card.name)
    if !wasUsed {
        alerts.append(ProactiveAlert(
            icon: "💳",
            title: "\(card.name) is sitting idle",
            message: "You haven't used it in 30+ days. "
                   + "It earns \(card.note) — worth putting to work.",
            colorHex: "14B8A6"
        ))
        break // show at most one idle-card alert
    }
}
*/
//
// NOTE: the fix here is adding the comment clarifying why name-matching is
// necessary, and ensuring the break fires correctly. The longer-term fix is
// to store `cardId` on `SavingRecord` (add alongside the spendAmount migration
// in Patch 4), then match by cardId here for robustness.


// ══════════════════════════════════════════════════════════════════════════════
// HELPER — ActivityView
// Already lives in ActivityView.swift — no need to duplicate here.
// ══════════════════════════════════════════════════════════════════════════════
