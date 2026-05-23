import SwiftUI

// MARK: - CardsView
// Shows the ranked card list for the current store (geofence or manual pick).
//
// Free tier: 5 uses, cards shown clearly.
// At limit:  card list blurred with a premium lock overlay.
//            Apple Pay button hidden.
//            Upgrade nudge banner shown.
//
// When the user taps a TapSmart notification, NotificationContext carries
// the store name + MCC into this view, which:
//   1. Pre-selects that store and shows ranked cards
//   2. Shows a sticky "Pay with Apple Pay" button at the bottom (premium only)

struct CardsView: View {
    @EnvironmentObject var locationManager:     LocationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var notifContext:        NotificationContext

    @State private var manualStore:        Store?  = nil
    @State private var showComparePicker   = false
    @State private var showUpgradeNudge    = false   // animated nudge after limit hit

    // ── Active store resolution ──────────────────────────────────────────
    private var activeStore: Store? {
        if notifContext.hasContext {
            return Store(
                name:       notifContext.storeName,
                coordinate: locationManager.stores.first(
                    where: { $0.name == notifContext.storeName })?.coordinate
                    ?? locationManager.stores.first?.coordinate
                    ?? .init(latitude: 37.3, longitude: -122.0),
                category:   categoryForMCC(notifContext.mcc),
                mcc:        notifContext.mcc,
                radius:     100
            )
        }
        return manualStore
            ?? locationManager.stores.first(where: { $0.name == locationManager.currentStoreName })
    }

    private var activeMCC: String { activeStore?.mcc ?? "5411" }

    private var allCards: [CardOption] {
        RewardDataService.shared.getAllCards(
            forMCC:    activeMCC,
            userCards: UserDefaultsStore.userCards
        )
    }

    private var bestCard: CardOption? { allCards.first(where: { $0.isBest }) }

    private var showPayButton: Bool {
        guard !subscriptionManager.isAtLimit else { return false }
        return notifContext.hasContext || locationManager.isNearStore || manualStore != nil
    }

    private var isLocked: Bool {
        subscriptionManager.isAtLimit
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "0D1B2A").ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header ───────────────────────────────────────────────
                headerSection

                // ── Store picker ─────────────────────────────────────────
                if !locationManager.isNearStore && !notifContext.hasContext {
                    storePickerSection
                }

                // ── Card list ────────────────────────────────────────────
                cardListSection
            }

            // ── Sticky Apple Pay button ──────────────────────────────────
            if showPayButton, let best = bestCard {
                applePayButton(for: best)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // ── Upgrade nudge banner (slides in from top) ────────────────
            if showUpgradeNudge {
                upgradeNudgeBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 8)
            }
        }
        .animation(.spring(response: 0.4), value: showPayButton)
        .animation(.spring(response: 0.4), value: isLocked)
        .animation(.spring(response: 0.35), value: showUpgradeNudge)
        .sheet(isPresented: $subscriptionManager.showPaywall) {
            PaywallView().environmentObject(subscriptionManager)
        }
        .sheet(isPresented: $showComparePicker) {
            ComparePickerView()
        }
        .onChange(of: locationManager.isNearStore) { _, near in
            if near { manualStore = nil }
        }
        .onChange(of: subscriptionManager.isAtLimit) { _, atLimit in
            if atLimit {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    showUpgradeNudge = true
                }
                // auto-dismiss after 6s
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showUpgradeNudge = false
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("💳 Best Card Right Now")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: "14B8A6"))

            if let store = activeStore {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "22C55E"))
                    Text(store.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text("·")
                        .foregroundColor(.white.opacity(0.4))
                    Text(store.category)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.55))
                }
            } else {
                Text("Walk into a store or pick one below")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.45))
            }

            // Usage pill
            usagePill

            // Notification context dismiss chip
            if notifContext.hasContext {
                notifContextChip
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    private var usagePill: some View {
        Group {
            if !subscriptionManager.isPremium {
                HStack(spacing: 6) {
                    Image(systemName: subscriptionManager.isAtLimit ? "lock.fill" : "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(subscriptionManager.isAtLimit
                                         ? Color(hex: "F97316")
                                         : Color(hex: "F59E0B"))
                    Text(subscriptionManager.isAtLimit
                         ? "Free limit reached — upgrade to unlock"
                         : "\(subscriptionManager.usesRemaining) free use\(subscriptionManager.usesRemaining == 1 ? "" : "s") left this month")
                        .font(.system(size: 13))
                        .foregroundColor(subscriptionManager.isAtLimit
                                         ? Color(hex: "F97316")
                                         : .white.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    (subscriptionManager.isAtLimit
                        ? Color(hex: "F97316")
                        : Color(hex: "F59E0B")).opacity(0.1)
                )
                .cornerRadius(20)
                .animation(.spring(response: 0.3), value: subscriptionManager.isAtLimit)
            }
        }
    }

    private var notifContextChip: some View {
        Button {
            withAnimation(.spring(response: 0.3)) { notifContext.clear() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "14B8A6"))
                Text("Showing cards for notification store")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color(hex: "14B8A6").opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: "14B8A6").opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(20)
        }
    }

    // MARK: - Store Picker

    private var storePickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SIMULATE A STORE VISIT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.35))
                Spacer()
                if manualStore != nil {
                    Button {
                        withAnimation(.spring(response: 0.3)) { manualStore = nil }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                            Text("Clear")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "14B8A6"))
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(locationManager.stores) { store in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                manualStore = manualStore?.id == store.id ? nil : store
                                if !subscriptionManager.isAtLimit {
                                    subscriptionManager.recordUse()
                                }
                            }
                        } label: {
                            Text(store.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(
                                    manualStore?.id == store.id
                                        ? Color(hex: "14B8A6")
                                        : .white.opacity(0.65)
                                )
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    manualStore?.id == store.id
                                        ? Color(hex: "14B8A6").opacity(0.18)
                                        : Color.white.opacity(0.07)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            manualStore?.id == store.id
                                                ? Color(hex: "14B8A6").opacity(0.5)
                                                : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Card List

    @ViewBuilder
    private var cardListSection: some View {
        let hasStore = activeStore != nil || locationManager.isNearStore

        if !hasStore {
            Spacer()
            VStack(spacing: 16) {
                Text("📍")
                    .font(.system(size: 52))
                Text("Pick a store above to see\nyour best card ranked")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }
            Spacer()
        } else if isLocked {
            // ── Locked state: blurred cards + upgrade overlay ─────────────
            lockedCardList
        } else {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(allCards) { card in
                        CardRow(
                            bank:      card.bank,
                            bankColor: card.bankColor,
                            name:      card.name,
                            category:  card.category,
                            percent:   card.cashback,
                            isBest:    card.isBest,
                            isDebit:   card.isDebit
                        )
                    }
                    if allCards.isEmpty { noCardsState }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, showPayButton ? 110 : 40)
            }
        }
    }

    // MARK: - Locked Card List

    private var lockedCardList: some View {
        ZStack {
            // Blurred real cards underneath
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(allCards.prefix(3)) { card in
                        CardRow(
                            bank:      card.bank,
                            bankColor: card.bankColor,
                            name:      card.isBest ? "????? ?????" : card.name,
                            category:  card.isBest ? "Tap to unlock" : card.category,
                            percent:   card.isBest ? "?%" : card.cashback,
                            isBest:    card.isBest,
                            isDebit:   card.isDebit
                        )
                    }
                    // Extra ghost rows so there's content to blur
                    ForEach(0..<2, id: \.self) { _ in
                        ghostCardRow
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .blur(radius: 8)
            .allowsHitTesting(false)

            // Gradient fade overlay
            LinearGradient(
                colors: [
                    Color(hex: "0D1B2A").opacity(0),
                    Color(hex: "0D1B2A").opacity(0.6),
                    Color(hex: "0D1B2A").opacity(0.85)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            // Lock overlay card
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "F97316").opacity(0.15))
                        .frame(width: 72, height: 72)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color(hex: "F97316"))
                }

                VStack(spacing: 8) {
                    Text("You've used all 5 free looks")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Upgrade to Premium to see your best card at every store, every time.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 8)
                }

                // What they're missing
                VStack(spacing: 0) {
                    lockedFeatureRow(icon: "creditcard.fill",         color: "14B8A6", text: "Best card ranked for every store")
                    Divider().background(Color.white.opacity(0.07))
                    lockedFeatureRow(icon: "bell.badge.fill",         color: "F97316", text: "Full card name in notifications")
                    Divider().background(Color.white.opacity(0.07))
                    lockedFeatureRow(icon: "applelogo",               color: "22C55E", text: "One-tap Apple Pay with best card")
                }
                .background(Color.white.opacity(0.05))
                .cornerRadius(14)

                Button {
                    subscriptionManager.showPaywall = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16))
                        Text("Upgrade to Premium — $4.99/mo")
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
                    .shadow(color: Color(hex: "14B8A6").opacity(0.4), radius: 12, x: 0, y: 6)
                }

                Button {
                    // do nothing — just dismiss the nudge
                } label: {
                    Text("Maybe later")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
        }
    }

    private func lockedFeatureRow(icon: String, color: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: color))
                .frame(width: 36, height: 36)
                .background(Color(hex: color).opacity(0.12))
                .cornerRadius(9)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: color))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var ghostCardRow: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.08))
                .frame(width: 60, height: 36)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 140, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 100, height: 11)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.06))
                .frame(width: 36, height: 28)
        }
        .padding(18)
        .background(Color.white.opacity(0.04))
        .cornerRadius(14)
    }

    // MARK: - Upgrade Nudge Banner (slides down from top)

    private var upgradeNudgeBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "F97316").opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "F97316"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Free limit reached")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text("Upgrade to keep seeing your best card")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Button {
                subscriptionManager.showPaywall = true
                withAnimation(.easeOut(duration: 0.25)) { showUpgradeNudge = false }
            } label: {
                Text("Upgrade")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: "F59E0B"))
                    .cornerRadius(10)
            }

            Button {
                withAnimation(.easeOut(duration: 0.25)) { showUpgradeNudge = false }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "0D1B2A").opacity(0.8))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "F97316").opacity(0.4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 12)
    }

    // MARK: - Apple Pay Button

    private func applePayButton(for card: CardOption) -> some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color(hex: "0D1B2A").opacity(0), Color(hex: "0D1B2A")],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)

            Button {
                guard ApplePayHandler.isAvailable else { return }
                let storeName = activeStore?.name ?? "Store"
                ApplePayHandler.shared.presentPayment(
                    cardName:  card.name,
                    storeName: storeName
                ) {
                    let rate = Double(
                        card.cashback.replacingOccurrences(of: "%", with: "")
                    ) ?? 1.0
                    SavingsStore.shared.recordSaving(
                        storeName:       storeName,
                        category:        activeStore?.category ?? "Shopping",
                        cardName:        card.name,
                        bestCashbackPct: rate,
                        usedBestCard:    true
                    )
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    notifContext.clear()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Pay")
                        .font(.system(size: 20, weight: .bold))

                    Divider()
                        .frame(height: 22)
                        .background(Color.white.opacity(0.4))
                        .padding(.horizontal, 4)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(card.name)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        Text("\(card.cashback) back here")
                            .font(.system(size: 11))
                            .opacity(0.75)
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
            .background(Color(hex: "0D1B2A"))
        }
    }

    // MARK: - Empty / no cards state

    private var noCardsState: some View {
        VStack(spacing: 14) {
            Text("💳")
                .font(.system(size: 48))
            Text("No cards in your wallet")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text("Go to Settings → My Cards to add the cards you own.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04))
        .cornerRadius(16)
        .padding(.top, 20)
    }

    // MARK: - Helpers

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
}

#Preview {
    CardsView()
        .environmentObject(LocationManager())
        .environmentObject(SubscriptionManager.shared)
        .environmentObject(NotificationContext())
}
