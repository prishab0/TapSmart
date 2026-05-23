import SwiftUI

struct RecommendView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var savingsStore = SavingsStore.shared
    @State private var expanded: String? = nil

    private var ownedCards: [String] { UserDefaultsStore.userCards }

    private var recommendations: [CardRecommendation] {
        CardRecommendationEngine.shared.recommendations(
            records:      savingsStore.records,
            ownedCardIds: ownedCards
        )
    }

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()

            if subscriptionManager.isPremium {
                // ── Full premium experience ───────────────────────
                premiumContent
            } else {
                // ── Premium gate ──────────────────────────────────
                premiumGate
            }
        }
    }

    // MARK: - Premium Content (unchanged from original)

    private var premiumContent: some View {
        ScrollView {
            VStack(spacing: 24) {

                // ── Best by category ──────────────────────────────
                VStack(spacing: 12) {
                    Text("🏆 Best Card Per Category")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: "14B8A6"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 30)

                    Text("Your top card for each spending category. Tap the card to pay with Apple Pay.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.55))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(3)

                    CategoryBestGrid(ownedCards: ownedCards)
                }

                Divider()
                    .background(Color.white.opacity(0.08))
                    .padding(.vertical, 4)

                // ── Cards worth getting ───────────────────────────
                VStack(spacing: 12) {
                    Text("💡 Cards Worth Getting")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: "14B8A6"))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Based on where you actually shop, these cards would earn you the most extra cash back.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.55))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(3)

                    if savingsStore.records.isEmpty {
                        emptyState
                    } else if recommendations.isEmpty {
                        allOwnedState
                    } else {
                        ForEach(Array(recommendations.prefix(10).enumerated()),
                                id: \.element.id) { idx, rec in
                            RecommendationCard(
                                rec:        rec,
                                rank:       idx + 1,
                                isExpanded: expanded == rec.card.cardId
                            ) {
                                withAnimation(.spring(response: 0.35)) {
                                    expanded = expanded == rec.card.cardId
                                        ? nil
                                        : rec.card.cardId
                                }
                            }
                        }

                        disclaimer
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Premium Gate

    private var premiumGate: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Hero ─────────────────────────────────────────
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "14B8A6").opacity(0.12))
                            .frame(width: 110, height: 110)
                        Circle()
                            .fill(Color(hex: "14B8A6").opacity(0.08))
                            .frame(width: 86, height: 86)
                        VStack(spacing: 2) {
                            Text("💡")
                                .font(.system(size: 44))
                        }
                    }
                    .padding(.top, 40)

                    Text("For You")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)

                    Text("Personalised card picks based on\nyour real spending habits.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)

                // ── Blurred preview ───────────────────────────────
                VStack(spacing: 10) {
                    Text("WHAT YOU'D SEE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)

                    ZStack {
                        // Blurred fake content
                        VStack(spacing: 12) {
                            // Fake category grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(previewCategories, id: \.name) { cat in
                                    fakeGridCell(cat)
                                }
                            }

                            // Fake recommendation card
                            fakeRecommendationCard
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(16)
                        .blur(radius: 6)

                        // Lock overlay
                        VStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white)
                            Text("Premium members see their best\ncard for every category")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                        }
                        .padding(20)
                        .background(Color.black.opacity(0.55))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 24)

                // ── Feature list ──────────────────────────────────
                VStack(spacing: 0) {
                    gateFeatureRow(
                        icon: "square.grid.2x2.fill",
                        color: "14B8A6",
                        title: "Best card per category",
                        sub: "Grocery, dining, gas, travel and more"
                    )
                    Divider().background(Color.white.opacity(0.07))
                    gateFeatureRow(
                        icon: "lightbulb.fill",
                        color: "F59E0B",
                        title: "Cards worth getting",
                        sub: "Ranked by how much extra you'd earn"
                    )
                    Divider().background(Color.white.opacity(0.07))
                    gateFeatureRow(
                        icon: "applelogo",
                        color: "22C55E",
                        title: "One-tap Apple Pay",
                        sub: "Pay with the right card instantly"
                    )
                    Divider().background(Color.white.opacity(0.07))
                    gateFeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        color: "C084FC",
                        title: "Projected annual gains",
                        sub: "See exactly how much more you'd earn"
                    )
                }
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.bottom, 28)

                // ── CTA ───────────────────────────────────────────
                VStack(spacing: 12) {
                    Button {
                        subscriptionManager.showPaywall = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16))
                            Text("Unlock For You — $4.99/mo")
                                .font(.system(size: 17, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "14B8A6"), Color(hex: "0E9488")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Color(hex: "14B8A6").opacity(0.35), radius: 12, x: 0, y: 6)
                    }

                    Text("Already subscribed?")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.35))
                    + Text(" Restore Purchase")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "14B8A6"))

                }
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $subscriptionManager.showPaywall) {
            PaywallView().environmentObject(subscriptionManager)
        }
    }

    // MARK: - Gate preview helpers

    private struct PreviewCategory {
        let name: String
        let icon: String
        let color: String
        let rate: String
        let card: String
    }

    private let previewCategories: [PreviewCategory] = [
        PreviewCategory(name: "Grocery",  icon: "cart.fill",     color: "22C55E", rate: "6%",  card: "Amex BCP"),
        PreviewCategory(name: "Dining",   icon: "fork.knife",    color: "F97316", rate: "4%",  card: "Amex Gold"),
        PreviewCategory(name: "Gas",      icon: "fuelpump.fill", color: "D97706", rate: "5%",  card: "Citi CC"),
        PreviewCategory(name: "Shopping", icon: "bag.fill",      color: "C084FC", rate: "5%",  card: "Freedom"),
    ]

    private func fakeGridCell(_ cat: PreviewCategory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: cat.icon)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: cat.color))
                    .frame(width: 26, height: 26)
                    .background(Color(hex: cat.color).opacity(0.15))
                    .cornerRadius(6)
                Text(cat.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
            Text(cat.rate)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundColor(Color(hex: cat.color))
            Text(cat.card)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var fakeRecommendationCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: "F59E0B").opacity(0.15)).frame(width: 34, height: 34)
                Text("1").font(.system(size: 14, weight: .black)).foregroundColor(Color(hex: "F59E0B"))
            }
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(hex: "1A56DB"))
                .frame(width: 46, height: 28)
                .overlay(Text("CHASE").font(.system(size: 8, weight: .black)).foregroundColor(.white))

            VStack(alignment: .leading, spacing: 3) {
                Text("Chase Sapphire Preferred")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text("+3% on Travel")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "14B8A6"))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("+$142/yr")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(Color(hex: "22C55E"))
                Text("projected")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(14)
        .background(Color(hex: "22C55E").opacity(0.06))
        .cornerRadius(14)
    }

    private func gateFeatureRow(icon: String, color: String, title: String, sub: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: color))
                .frame(width: 40, height: 40)
                .background(Color(hex: color).opacity(0.12))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(sub)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: color).opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Empty / complete states

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("🛒").font(.system(size: 52))
            Text("No spending history yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text("Simulate a few store visits on the Cards tab to unlock personalised card recommendations.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04))
        .cornerRadius(16)
        .padding(.top, 8)
    }

    private var allOwnedState: some View {
        VStack(spacing: 16) {
            Text("🏆").font(.system(size: 52))
            Text("You've got the best cards")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text("Every card in our catalog that would earn you more is already in your wallet.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04))
        .cornerRadius(16)
        .padding(.top, 8)
    }

    private var disclaimer: some View {
        Text("Estimates based on your visit history at ~$50/trip. Actual earnings depend on your real spend amounts.")
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.25))
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }
}

// MARK: - CategoryBestGrid

private struct CategoryBestGrid: View {
    let ownedCards: [String]

    private let categories: [(name: String, mcc: String, icon: String, color: String)] = [
        ("Grocery",     "5411", "cart.fill",        "22C55E"),
        ("Dining",      "5812", "fork.knife",        "F97316"),
        ("Gas",         "5541", "fuelpump.fill",     "D97706"),
        ("Shopping",    "5999", "bag.fill",          "C084FC"),
        ("Pharmacy",    "5912", "cross.fill",        "94A3B8"),
        ("Electronics", "5734", "desktopcomputer",   "60A5FA"),
        ("Travel",      "4511", "airplane",          "14B8A6"),
        ("Hotels",      "7011", "building.2.fill",   "F59E0B"),
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        if ownedCards.isEmpty {
            Text("Add cards in Settings to see your best card per category.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.04))
                .cornerRadius(14)
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(categories, id: \.mcc) { cat in
                    CategoryBestCell(
                        categoryName: cat.name,
                        mcc:          cat.mcc,
                        icon:         cat.icon,
                        color:        cat.color,
                        ownedCards:   ownedCards
                    )
                }
            }
        }
    }
}

// MARK: - CategoryBestCell

private struct CategoryBestCell: View {
    let categoryName: String
    let mcc: String
    let icon: String
    let color: String
    let ownedCards: [String]

    private var best: CardOption? {
        RewardDataService.shared.getBestCard(forMCC: mcc, userCards: ownedCards)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: color))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: color).opacity(0.15))
                    .cornerRadius(7)
                Text(categoryName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }

            if let best = best {
                Text(best.cashback)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: color))

                HStack(spacing: 6) {
                    Text(best.bank)
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(Color(hex:
                            RewardDataService.shared.allCards
                                .first(where: { $0.bank == best.bank })?
                                .bankColor ?? "444444"
                        ))
                        .cornerRadius(4)
                    Text(best.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }

                Button {
                    ApplePayHandler.shared.presentPayment(
                        cardName:  best.name,
                        storeName: categoryName
                    ) {
                        let rate = Double(
                            best.cashback.replacingOccurrences(of: "%", with: "")
                        ) ?? 1.0
                        SavingsStore.shared.recordSaving(
                            storeName:       categoryName,
                            category:        categoryName,
                            cardName:        best.name,
                            bestCashbackPct: rate,
                            usedBestCard:    true
                        )
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "applelogo")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Pay")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.black)
                    .cornerRadius(8)
                }
                .padding(.top, 2)

            } else {
                Text("—")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white.opacity(0.2))
                Text("No card")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: color).opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(14)
    }
}

// MARK: - RecommendationCard

private struct RecommendationCard: View {
    let rec:        CardRecommendation
    let rank:       Int
    let isExpanded: Bool
    let onTap:      () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(rankColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Text("\(rank)")
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(rankColor)
                    }
                    Text(rec.card.bank)
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.7)
                        .frame(width: 50, height: 30)
                        .background(Color(hex: rec.card.bankColor))
                        .cornerRadius(6)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(rec.card.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Text("+\(rec.topCategoryGain, specifier: "%.0f")% on \(rec.topCategory)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "14B8A6"))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("+$\(rec.projectedAnnualGain, specifier: "%.0f")/yr")
                            .font(.system(size: 17, weight: .black))
                            .foregroundColor(Color(hex: "22C55E"))
                        Text("projected")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.leading, 4)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    Divider().background(Color.white.opacity(0.08))
                    VStack(spacing: 10) {
                        Text("WHERE YOU'D GAIN")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.35))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 14)
                        ForEach(rec.breakdown) { gain in
                            CategoryGainRow(gain: gain)
                        }
                        Text(rec.card.note)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.45))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 6)
                            .padding(.bottom, 14)
                    }
                    .padding(.horizontal, 16)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(rank == 1 ? Color(hex: "22C55E").opacity(0.07) : Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    rank == 1 ? Color(hex: "22C55E").opacity(0.3) : Color.white.opacity(0.08),
                    lineWidth: rank == 1 ? 1.5 : 1
                )
        )
        .cornerRadius(16)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "F59E0B")
        case 2: return Color(hex: "94A3B8")
        case 3: return Color(hex: "CD7C2F")
        default: return Color(hex: "14B8A6")
        }
    }
}

// MARK: - CategoryGainRow

private struct CategoryGainRow: View {
    let gain: CategoryGain

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconFor(gain.category))
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "14B8A6"))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(gain.category)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text("~$\(gain.annualSpend, specifier: "%.0f")/yr spend")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(gain.currentBestRate, specifier: "%.1f")%")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.35))
                        .strikethrough()
                    Text("→")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.system(size: 12))
                    Text("\(gain.newCardRate, specifier: "%.1f")%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "14B8A6"))
                }
                Text("+$\(gain.extraEarned, specifier: "%.0f")/yr")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(Color(hex: "22C55E"))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private func iconFor(_ category: String) -> String {
        switch category {
        case "Grocery":     return "cart.fill"
        case "Dining":      return "fork.knife"
        case "Gas":         return "fuelpump.fill"
        case "Shopping":    return "bag.fill"
        case "Pharmacy":    return "cross.fill"
        case "Electronics": return "desktopcomputer"
        case "Hardware":    return "hammer.fill"
        default:            return "dollarsign.circle.fill"
        }
    }
}

#Preview {
    RecommendView()
        .environmentObject(SubscriptionManager.shared)
}
