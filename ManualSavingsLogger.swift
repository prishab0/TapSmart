import SwiftUI

// MARK: - ManualSavingsLogger
//
// A sheet the user can open from SavingsView to log a card use that
// wasn't captured automatically (e.g. they forgot their phone, or
// the geofence didn't fire). Surfaces in SavingsView via a "+" button
// in the navigation bar.
//
// Wire-up: in ContentView / SavingsView navigation toolbar, add:
//   .toolbar {
//       ToolbarItem(placement: .navigationBarTrailing) {
//           Button { showLogger = true } label: {
//               Image(systemName: "plus.circle.fill")
//                   .foregroundColor(Color(hex: "14B8A6"))
//           }
//       }
//   }
//   .sheet(isPresented: $showLogger) { ManualSavingsLogger() }

struct ManualSavingsLogger: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss

    // Step state
    @State private var step: Step = .store

    // Selections
    @State private var selectedCategory: String = ""
    @State private var selectedStore: String = ""
    @State private var customStore: String = ""
    @State private var selectedCardId: String = ""
    @State private var spendAmount: String = ""
    @State private var didSave = false

    private var ownedCards: [RewardRate] {
        RewardDataService.shared.allCards
            .filter { UserDefaultsStore.userCards.contains($0.cardId) && !$0.isDebit }
    }

    private var mccForCategory: String {
        switch selectedCategory {
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

    private var bestCardForCategory: RewardRate? {
        RewardDataService.shared.allCards
            .filter { UserDefaultsStore.userCards.contains($0.cardId) }
            .max { RewardDataService.shared.rate(for: $0, mcc: mccForCategory) <
                   RewardDataService.shared.rate(for: $1, mcc: mccForCategory) }
    }

    private var selectedCard: RewardRate? {
        RewardDataService.shared.allCards.first { $0.cardId == selectedCardId }
    }

    private var spendDouble: Double { Double(spendAmount) ?? 50.0 }

    private var savingsPreview: Double {
        guard let card = selectedCard else { return 0 }
        let rate = RewardDataService.shared.rate(for: card, mcc: mccForCategory)
        return max(0, (rate - 1.0) / 100.0 * spendDouble)
    }

    private var storeName: String {
        customStore.trimmingCharacters(in: .whitespaces).isEmpty
            ? selectedStore : customStore.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 16))

                    Spacer()

                    Text("Log Card Use")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    // Invisible balance
                    Text("Cancel")
                        .foregroundColor(.clear)
                        .font(.system(size: 16))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Step indicator
                StepDots(current: step.index, total: 3)
                    .padding(.bottom, 24)

                // Step content
                ScrollView {
                    VStack(spacing: 0) {
                        switch step {
                        case .store:    storeStep
                        case .card:     cardStep
                        case .confirm:  confirmStep
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .animation(.spring(response: 0.35), value: step)
    }

    // MARK: - Step 1: Store & Category

    private var storeStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                emoji: "🏪",
                title: "Where did you shop?",
                subtitle: "Pick a category, then name the store."
            )

            // Category grid
            let cats = [
                ("Grocery",     "cart.fill",        "22C55E"),
                ("Dining",      "fork.knife",        "F97316"),
                ("Gas",         "fuelpump.fill",     "D97706"),
                ("Shopping",    "bag.fill",          "C084FC"),
                ("Pharmacy",    "cross.fill",        "94A3B8"),
                ("Electronics", "desktopcomputer",   "60A5FA"),
                ("Hardware",    "hammer.fill",       "F97316"),
                ("Travel",      "airplane",          "14B8A6"),
                ("Hotels",      "building.2.fill",   "F59E0B"),
            ]

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                ForEach(cats, id: \.0) { (name, icon, color) in
                    Button {
                        withAnimation { selectedCategory = name }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: icon)
                                .font(.system(size: 20))
                                .foregroundColor(
                                    selectedCategory == name
                                        ? .white
                                        : Color(hex: color)
                                )
                                .frame(width: 44, height: 44)
                                .background(
                                    selectedCategory == name
                                        ? Color(hex: color)
                                        : Color(hex: color).opacity(0.15)
                                )
                                .cornerRadius(12)

                            Text(name)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(
                                    selectedCategory == name
                                        ? .white
                                        : .white.opacity(0.6)
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedCategory == name
                                ? Color(hex: color).opacity(0.15)
                                : Color.white.opacity(0.04)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedCategory == name
                                        ? Color(hex: color).opacity(0.5)
                                        : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                        .cornerRadius(12)
                    }
                }
            }

            if !selectedCategory.isEmpty {
                // Store name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("STORE NAME")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))

                    // Quick picks for the selected category
                    let quickPicks = quickPickStores(for: selectedCategory)
                    if !quickPicks.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(quickPicks, id: \.self) { store in
                                    Button {
                                        selectedStore = store
                                        customStore = ""
                                    } label: {
                                        Text(store)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(
                                                selectedStore == store
                                                    ? Color(hex: "14B8A6")
                                                    : .white.opacity(0.6)
                                            )
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(
                                                selectedStore == store
                                                    ? Color(hex: "14B8A6").opacity(0.15)
                                                    : Color.white.opacity(0.06)
                                            )
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }
                    }

                    // Custom store input
                    HStack(spacing: 10) {
                        Image(systemName: "pencil")
                            .foregroundColor(.white.opacity(0.35))
                            .font(.system(size: 14))

                        TextField("", text: $customStore)
                            .placeholder(when: customStore.isEmpty) {
                                Text("Or type a custom store name…")
                                    .foregroundColor(.white.opacity(0.3))
                                    .font(.system(size: 15))
                            }
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                            .onChange(of: customStore) { _, v in
                                if !v.isEmpty { selectedStore = "" }
                            }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))

                // Amount field
                VStack(alignment: .leading, spacing: 8) {
                    Text("HOW MUCH DID YOU SPEND?")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))

                    HStack(spacing: 4) {
                        Text("$")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(hex: "14B8A6"))

                        TextField("50", text: $spendAmount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(.white)

                        Spacer()
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)

                    Text("Leave blank to use the default $50 estimate.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            if canProceedFromStore {
                nextButton("Choose Card") {
                    withAnimation { step = .card }
                }
            }
        }
    }

    // MARK: - Step 2: Card selection

    private var cardStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                emoji: "💳",
                title: "Which card did you use?",
                subtitle: "Pick the card you actually paid with."
            )

            if let best = bestCardForCategory {
                // Best card highlight
                VStack(alignment: .leading, spacing: 6) {
                    Text("RECOMMENDED FOR \(selectedCategory.uppercased())")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "14B8A6").opacity(0.8))

                    cardPickerRow(card: best, isSelected: selectedCardId == best.cardId, isBest: true)
                }

                if ownedCards.filter({ $0.cardId != best.cardId }).count > 0 {
                    Text("YOUR OTHER CARDS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                        .padding(.top, 4)
                }
            }

            ForEach(ownedCards.filter { $0.cardId != bestCardForCategory?.cardId }) { card in
                cardPickerRow(card: card, isSelected: selectedCardId == card.cardId, isBest: false)
            }

            if !selectedCardId.isEmpty {
                nextButton("Review") {
                    withAnimation { step = .confirm }
                }
                .padding(.top, 8)
            }
        }
    }

    private func cardPickerRow(card: RewardRate, isSelected: Bool, isBest: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.25)) { selectedCardId = card.cardId }
        } label: {
            HStack(spacing: 14) {
                Text(card.bank)
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 30)
                    .background(Color(hex: card.bankColor))
                    .cornerRadius(6)

                VStack(alignment: .leading, spacing: 3) {
                    Text(card.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    let rate = RewardDataService.shared.rate(for: card, mcc: mccForCategory)
                    Text(RewardDataService.shared.formatRate(rate) + " here")
                        .font(.system(size: 13))
                        .foregroundColor(
                            isBest
                                ? Color(hex: "22C55E")
                                : .white.opacity(0.45)
                        )
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "14B8A6"))
                }
            }
            .padding(14)
            .background(
                isSelected
                    ? Color(hex: "14B8A6").opacity(0.12)
                    : Color.white.opacity(0.05)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected
                            ? Color(hex: "14B8A6").opacity(0.4)
                            : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 3: Confirm

    private var confirmStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                emoji: "✅",
                title: "Looks good?",
                subtitle: "Review and confirm your savings."
            )

            // Summary card
            VStack(spacing: 0) {
                summaryRow(label: "Store", value: storeName)
                Divider().background(Color.white.opacity(0.07))
                summaryRow(label: "Category", value: selectedCategory)
                Divider().background(Color.white.opacity(0.07))
                if let card = selectedCard {
                    summaryRow(label: "Card", value: card.name)
                    Divider().background(Color.white.opacity(0.07))
                    let rate = RewardDataService.shared.rate(for: card, mcc: mccForCategory)
                    summaryRow(label: "Cashback rate", value: RewardDataService.shared.formatRate(rate))
                    Divider().background(Color.white.opacity(0.07))
                }
                summaryRow(
                    label: "Spend amount",
                    value: "$\(String(format: "%.2f", spendDouble))"
                )
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(14)

            // Savings preview
            VStack(spacing: 6) {
                Text("YOU SAVED")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))

                Text("+$\(savingsPreview, specifier: "%.2f")")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "22C55E"))

                if let best = bestCardForCategory, let used = selectedCard, best.cardId != used.cardId {
                    let bestRate = RewardDataService.shared.rate(for: best, mcc: mccForCategory)
                    let usedRate = RewardDataService.shared.rate(for: used, mcc: mccForCategory)
                    let missed   = max(0, (bestRate - usedRate) / 100.0 * spendDouble)
                    if missed > 0.01 {
                        Text("(\(best.name) would have saved $\(missed, specifier: "%.2f") more)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "F97316"))
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Color(hex: "22C55E").opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "22C55E").opacity(0.3), lineWidth: 1.5)
            )
            .cornerRadius(16)

            // Confirm button
            Button {
                guard let card = selectedCard else { return }
                let usedBest = bestCardForCategory?.cardId == card.cardId
                SavingsStore.shared.recordSaving(
                    storeName:       storeName,
                    category:        selectedCategory,
                    cardName:        card.name,
                    bestCashbackPct: RewardDataService.shared.rate(for: card, mcc: mccForCategory), spendAmount:     spendDouble,
                    usedBestCard:    usedBest
                )
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation { didSave = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
            } label: {
                HStack(spacing: 10) {
                    if didSave {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }
                    Text(didSave ? "Saved!" : "Record Saving")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(didSave ? Color(hex: "22C55E") : Color(hex: "14B8A6"))
                .cornerRadius(14)
            }
            .disabled(didSave)
            .animation(.spring(response: 0.3), value: didSave)

            Button {
                withAnimation { step = .card }
            } label: {
                Text("← Back")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
        }
    }

    // MARK: - Helpers

    private var canProceedFromStore: Bool {
        !selectedCategory.isEmpty && !storeName.isEmpty
    }

    private func stepHeader(emoji: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(emoji)
                .font(.system(size: 40))
            Text(title)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.55))
                .lineSpacing(3)
        }
    }

    private func nextButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color(hex: "14B8A6"))
                .cornerRadius(14)
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func quickPickStores(for category: String) -> [String] {
        switch category {
        case "Grocery":     return ["Trader Joe's","Whole Foods","Kroger","Safeway","Amazon Fresh","Costco"]
        case "Dining":      return ["Starbucks","Chipotle","McDonald's","Chick-fil-A","Panera Bread"]
        case "Gas":         return ["Shell","Chevron","Arco","76 Station"]
        case "Shopping":    return ["Target","Walmart","Amazon"]
        case "Pharmacy":    return ["CVS","Walgreens"]
        case "Electronics": return ["Best Buy","Apple Store","Micro Center"]
        case "Hardware":    return ["Home Depot","Lowe's","Ace Hardware"]
        case "Travel":      return ["United","Delta","Southwest","Alaska Airlines"]
        case "Hotels":      return ["Marriott","Hyatt","Hilton","IHG"]
        default:            return []
        }
    }

    // MARK: - Step enum

    enum Step: Int {
        case store = 0, card = 1, confirm = 2
        var index: Int { rawValue }
    }
}

// MARK: - StepDots

private struct StepDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color(hex: "14B8A6") : Color.white.opacity(0.2))
                    .frame(width: i == current ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.35), value: current)
            }
        }
    }
}
