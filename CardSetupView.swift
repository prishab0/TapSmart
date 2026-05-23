import SwiftUI

@MainActor
struct CardSetupView: View {

    @State private var ownedCards:    [String] = UserDefaultsStore.userCards
    @State private var searchText:    String   = ""
    @State private var showLinkSheet: Bool     = false
    @State private var selectedCard:  RewardRate? = nil  // card tapped for detail sheet
    @State private var typeFilter:    CardType? = nil    // nil = All, .credit, .debit

    private var hasPlaidLink: Bool { PlaidService.shared.hasLinkedAccount }

    // Cards matching the search query and active type filter
    private var searchResults: [RewardRate] {
        RewardDataService.shared.search(searchText, type: typeFilter)
    }

    // Cards the user has already added, in catalog order
    private var myCards: [RewardRate] {
        RewardDataService.shared.allCards.filter { ownedCards.contains($0.cardId) }
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // ── Search bar ────────────────────────────────
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.4))
                            .font(.system(size: 16))

                        TextField("", text: $searchText)
                            .placeholder(when: searchText.isEmpty) {
                                Text("Search cards e.g. \"Chase\", \"debit\", \"5% grocery\"")
                                    .foregroundColor(.white.opacity(0.3))
                                    .font(.system(size: 15))
                            }
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                            .autocorrectionDisabled()

                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.3))
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSearching
                                    ? Color(hex: "14B8A6").opacity(0.5)
                                    : Color.white.opacity(0.1),
                                lineWidth: 1.5
                            )
                    )
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                    // ── Type filter tabs ──────────────────────────
                    typeFilterTabs
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    if isSearching || typeFilter != nil {
                        // ── Filtered / Search results ─────────────
                        searchResultsSection
                    } else {
                        // ── Normal view: Plaid + My Cards + Full list ──
                        // plaidLinkBanner
                            // .padding(.horizontal, 20)
                            // .padding(.bottom, 8)

                        if !myCards.isEmpty {
                            myCardsSection
                        }

                        allCardsSection
                    }
                }
            }
        }
        .navigationTitle("My Cards")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear   { ownedCards = UserDefaultsStore.userCards }
        .sheet(isPresented: $showLinkSheet, onDismiss: {
            ownedCards = UserDefaultsStore.userCards
        }) {
            LinkCardView()
        }
        // Card detail / select sheet
        .sheet(item: $selectedCard) { card in
            CardDetailSheet(
                card: card,
                isOwned: ownedCards.contains(card.cardId),
                onToggle: {
                    toggle(card.cardId)
                }
            )
        }
    }

    // MARK: - Type filter tabs

    @ViewBuilder
    private var typeFilterTabs: some View {
        HStack(spacing: 8) {
            ForEach(
                [(label: "All", value: Optional<CardType>.none),
                 (label: "Credit", value: Optional<CardType>.some(.credit)),
                 (label: "Debit",  value: Optional<CardType>.some(.debit))],
                id: \.label
            ) { tab in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        typeFilter = tab.value
                    }
                } label: {
                    Text(tab.label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(typeFilter == tab.value ? .white : .white.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            typeFilter == tab.value
                                ? Color(hex: "14B8A6")
                                : Color.white.opacity(0.07)
                        )
                        .cornerRadius(20)
                }
            }
            Spacer()
        }
    }

    // MARK: - Search / filtered results

    @ViewBuilder
    private var searchResultsSection: some View {
        if searchResults.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "creditcard.trianglebadge.exclamationmark")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.2))
                Text(searchText.isEmpty
                     ? "No cards found for this filter."
                     : "No cards found for \"\(searchText)\"")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.35))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
        } else {
            sectionHeader("\(searchResults.count) RESULT\(searchResults.count == 1 ? "" : "S")")

            ForEach(searchResults) { card in
                cardRow(card)
            }

            footerHint
        }
    }

    // MARK: - My Cards section

    @ViewBuilder
    private var myCardsSection: some View {
        sectionHeader("MY CARDS — \(myCards.count) ADDED")

        ForEach(myCards) { card in
            cardRow(card)
        }

        Rectangle()
            .fill(Color.white.opacity(0.04))
            .frame(height: 8)
            .padding(.vertical, 8)
    }

    // MARK: - All cards section

    @ViewBuilder
    private var allCardsSection: some View {
        sectionHeader(hasPlaidLink ? "OR TOGGLE CARDS MANUALLY" : "ALL CARDS — TOGGLE ONES YOU OWN")

        ForEach(RewardDataService.shared.allCards) { card in
            cardRow(card)
        }

        footerHint
    }

    // MARK: - Shared card row

    @ViewBuilder
    private func cardRow(_ card: RewardRate) -> some View {
        let owned = ownedCards.contains(card.cardId)

        HStack(spacing: 14) {
            // Bank badge
            Text(card.bank)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.white)
                .minimumScaleFactor(0.7)
                .frame(width: 54, height: 32)
                .background(Color(hex: card.bankColor))
                .cornerRadius(6)

            // Card name + note
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if isSearching {
                        highlightedText(card.name, query: searchText)
                            .font(.system(size: 16, weight: .semibold))
                    } else {
                        Text(card.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(card.isDebit ? .white.opacity(0.6) : .white)
                    }
                    // Debit pill
                    if card.isDebit {
                        Text("DEBIT")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(Color(hex: "94A3B8"))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(hex: "94A3B8").opacity(0.15))
                            .cornerRadius(3)
                    }
                }
                Text(card.note)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.45))
                    .lineLimit(1)
            }

            Spacer()

            // Tap-to-select chevron + owned indicator
            HStack(spacing: 10) {
                if owned {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "14B8A6"))
                } else {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.25))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.2))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
        .background(owned ? Color(hex: "14B8A6").opacity(0.07) : Color.clear)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedCard = card      // open detail sheet on tap
        }
    }

    // MARK: - Plaid banner

    @ViewBuilder
    private var plaidLinkBanner: some View {
        Button { showLinkSheet = true } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "14B8A6").opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: hasPlaidLink
                          ? "checkmark.shield.fill"
                          : "link.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "14B8A6"))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(hasPlaidLink ? "Cards Linked via Plaid" : "Link Cards Automatically")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(hasPlaidLink
                         ? "Tap to manage or add more cards"
                         : "Securely verify ownership in seconds")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(Color(hex: "14B8A6").opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "14B8A6").opacity(0.3), lineWidth: 1.5)
            )
            .cornerRadius(14)
        }
    }

    // MARK: - Helpers

    private func toggle(_ cardId: String) {
        withAnimation(.spring(response: 0.3)) {
            if ownedCards.contains(cardId) {
                ownedCards.removeAll { $0 == cardId }
            } else {
                ownedCards.append(cardId)
            }
            UserDefaultsStore.userCards = ownedCards
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white.opacity(0.35))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 10)
    }

    private var footerHint: some View {
        Text("Tap any card to view details or add it to your wallet.")
            .font(.system(size: 13))
            .foregroundColor(.white.opacity(0.3))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
    }

    private func highlightedText(_ text: String, query: String) -> Text {
        let q = query.lowercased()
        guard let range = text.lowercased().range(of: q) else {
            return Text(text).foregroundColor(.white)
        }
        let before = String(text[text.startIndex..<range.lowerBound])
        let match  = String(text[range])
        let after  = String(text[range.upperBound...])
        return Text(before).foregroundColor(.white)
             + Text(match).foregroundColor(Color(hex: "14B8A6")).bold()
             + Text(after).foregroundColor(.white)
    }
}

// MARK: - Card Detail Sheet

@MainActor
struct CardDetailSheet: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss

    let card: RewardRate
    let isOwned: Bool
    let onToggle: () -> Void

    @State private var locallyOwned: Bool = false

    private let mccLabels: [String: String] = [
        "5411": "Groceries", "5812": "Dining", "5541": "Gas",
        "5999": "Shopping", "5912": "Pharmacy", "5734": "Electronics",
        "5251": "Hardware", "4511": "Travel", "7011": "Hotels",
        "4111": "Transit", "5940": "Streaming", "default": "All purchases"
    ]

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // ── Card header ───────────────────────────────
                    VStack(spacing: 14) {
                        Text(card.bank)
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 48)
                            .background(Color(hex: card.bankColor))
                            .cornerRadius(10)

                        HStack(spacing: 8) {
                            Text(card.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            if card.isDebit {
                                Text("DEBIT")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(Color(hex: "94A3B8"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color(hex: "94A3B8").opacity(0.15))
                                    .cornerRadius(5)
                            }
                        }

                        Text(card.note)
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "14B8A6"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 24)

                    // ── Reward rates breakdown ────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        Text("REWARD RATES")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.leading, 4)

                        ForEach(rateRows(), id: \.label) { row in
                            HStack {
                                Text(row.label)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text(row.rate)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(
                                        row.rate == "0%" || row.rate == "0"
                                            ? .white.opacity(0.3)
                                            : Color(hex: "14B8A6")
                                    )
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)

                    // ── Debit info banner ─────────────────────────
                    if card.isDebit {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(Color(hex: "94A3B8"))
                                .font(.system(size: 18))
                            Text("Debit cards pull directly from your bank account. They typically earn no rewards, so a credit card will almost always be the better choice for cashback.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                                .lineSpacing(3)
                        }
                        .padding(16)
                        .background(Color(hex: "94A3B8").opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "94A3B8").opacity(0.25), lineWidth: 1)
                        )
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }

                    // ── Add / Remove button ───────────────────────
                    VStack(spacing: 12) {
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

                        Button { dismiss() } label: {
                            Text("Done")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear { locallyOwned = isOwned }
    }

    private struct RateRow {
        let label: String
        let rate: String
    }

    private func rateRows() -> [RateRow] {
        let svc = RewardDataService.shared
        let allMCCs = [
            ("5411", "Groceries"), ("5812", "Dining"), ("5541", "Gas"),
            ("5999", "Shopping"), ("5912", "Pharmacy"), ("5734", "Electronics"),
            ("5251", "Hardware"), ("4511", "Travel"), ("7011", "Hotels"),
            ("4111", "Transit"), ("5940", "Streaming")
        ]
        var rows: [RateRow] = allMCCs.compactMap { (mcc, label) in
            guard card.rates[mcc] != nil else { return nil }
            return RateRow(label: label, rate: svc.formatRate(svc.rate(for: card, mcc: mcc)))
        }
        // Always add a default/everything-else row
        let defaultRate = svc.formatRate(card.rates["default"] ?? 0)
        rows.append(RateRow(label: "Everything else", rate: defaultRate))
        return rows
    }
}

// MARK: - Placeholder helper

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: .leading) {
            if shouldShow { placeholder() }
            self
        }
    }
}

#Preview {
    NavigationStack {
        CardSetupView()
    }
}
