import SwiftUI
import UserNotifications

struct LockScreenView: View {
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var savingsStore = SavingsStore.shared

    // In-app banner state
    @State private var bannerStore: Store? = nil
    @State private var bannerCard: String  = ""
    @State private var bannerCashback: String = ""
    @State private var showBanner: Bool = false

    private var simulateStores: [Store] {
        Array(locationManager.stores.prefix(7))
    }

    private var bestCard: CardOption? {
        guard locationManager.isNearStore else { return nil }
        let mcc = locationManager.stores
            .first(where: { $0.name == locationManager.currentStoreName })?.mcc ?? "5411"
        return RewardDataService.shared.getBestCard(
            forMCC: mcc,
            userCards: UserDefaultsStore.userCards
        )
    }

    private var currentCategory: String {
        locationManager.stores
            .first(where: { $0.name == locationManager.currentStoreName })?.category ?? ""
    }

    private var totalSaved: Double { savingsStore.totalSaved }

    private var topCategories: [(String, Double)] {
        savingsStore.savingsByCategory
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { ($0.key, $0.value) }
    }

    private var annualPace: Double {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return (totalSaved / Double(dayOfYear)) * 365
    }

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f.string(from: Date())
    }

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "0D1B2A").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Fake lock screen clock ───────────────────────────
                    VStack(spacing: 4) {
                        Text(timeString)
                            .font(.system(size: 72, weight: .thin))
                            .foregroundColor(.white)
                        Text(dateString)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 24)

                    VStack(spacing: 16) {

                        // ── Notification preview card ────────────────────
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: "0D3B30"))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "bolt.fill")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(Color(hex: "14B8A6"))
                                    )
                                Text("TAPSMART")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("now")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.4))
                            }

                            Text(locationManager.isNearStore
                                 ? "You're at \(locationManager.currentStoreName)"
                                 : "Walk into a store to see a live alert")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundColor(.white)

                            if locationManager.isNearStore, let card = bestCard {
                                HStack(spacing: 10) {
                                    Text("\(card.name) · \(card.cashback) back")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color(hex: "22C55E"))
                                        .cornerRadius(20)

                                    // ── Apple Pay button — wired up ──────
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                        Text("Apple Pay")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.12))
                                    .cornerRadius(20)
                                    .onTapGesture {
                                        ApplePayHandler.shared.presentPayment(
                                            cardName:  card.name,
                                            storeName: locationManager.currentStoreName
                                        ) {
                                            let rate = Double(
                                                card.cashback.replacingOccurrences(of: "%", with: "")
                                            ) ?? 1.0
                                            SavingsStore.shared.recordSaving(
                                                storeName:       locationManager.currentStoreName,
                                                category:        locationManager.currentStoreCategory,
                                                cardName:        card.name,
                                                bestCashbackPct: rate,
                                                usedBestCard:    true
                                            )
                                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        }
                                    }
                                }

                                Text("\(currentCategory) · \(card.category)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.45))
                                    .lineLimit(2)
                            } else {
                                Text("Simulate entering a store:")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(20)

                        // ── Savings summary card ─────────────────────────
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: "0D3B30"))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "dollarsign.circle.fill")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(Color(hex: "14B8A6"))
                                    )
                                Text("TAPSMART SAVINGS")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            Text("$\(totalSaved, specifier: "%.0f")")
                                .font(.system(size: 52, weight: .black, design: .rounded))
                                .foregroundColor(Color(hex: "22C55E"))

                            Text("saved this year · on pace for $\(annualPace, specifier: "%.0f") total")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))

                            if !topCategories.isEmpty {
                                let maxVal = topCategories.first?.1 ?? 1
                                VStack(spacing: 10) {
                                    ForEach(topCategories, id: \.0) { cat, val in
                                        HStack(spacing: 12) {
                                            Text(cat)
                                                .font(.system(size: 14))
                                                .foregroundColor(.white.opacity(0.6))
                                                .frame(width: 72, alignment: .leading)
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Capsule()
                                                        .fill(Color.white.opacity(0.08))
                                                    Capsule()
                                                        .fill(barColor(cat))
                                                        .frame(width: max(8, geo.size.width * CGFloat(val / maxVal)))
                                                }
                                            }
                                            .frame(height: 8)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }

            // ── Bottom: store pills or Leave Store ───────────────────────
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color(hex: "0D1B2A").opacity(0), Color(hex: "0D1B2A")],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 24)

                if locationManager.isNearStore {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            locationManager.resetStore()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Leave Store")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "14B8A6"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(hex: "0D1B2A"))
                    }
                    .transition(.opacity)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(simulateStores) { store in
                                Button {
                                    triggerSimulate(store)
                                } label: {
                                    Text(store.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 12)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }
                    .transition(.opacity)
                }
            }
            .background(Color(hex: "0D1B2A"))
        }
        .animation(.spring(response: 0.35), value: locationManager.isNearStore)
        .animation(.spring(response: 0.35), value: locationManager.currentStoreName)
        // ── In-app notification banner overlay ──────────────────────────
        .overlay(alignment: .top) {
            if showBanner, let store = bannerStore {
                InAppNotificationBanner(
                    storeName: store.name,
                    cardName: bannerCard,
                    cashback: bannerCashback
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Simulate + banner

    private func triggerSimulate(_ store: Store) {
        withAnimation(.spring(response: 0.3)) {
            locationManager.simulateEnterStore(store)
        }

        let best = RewardDataService.shared.getBestCard(
            forMCC: store.mcc,
            userCards: UserDefaultsStore.userCards
        )
        bannerStore    = store
        bannerCard     = best?.name     ?? "Citi Double Cash"
        bannerCashback = best?.cashback ?? "2%"

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            showBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.easeOut(duration: 0.35)) {
                showBanner = false
            }
        }
    }

    private func barColor(_ category: String) -> Color {
        switch category {
        case "Grocery": return Color(hex: "22C55E")
        case "Dining":  return Color(hex: "14B8A6")
        case "Gas":     return Color(hex: "F59E0B")
        default:        return Color(hex: "8B5CF6")
        }
    }
}

// MARK: - In-App Notification Banner

struct InAppNotificationBanner: View {
    let storeName: String
    let cardName: String
    let cashback: String

    var body: some View {
        HStack(spacing: 14) {
            Image("TapSmartLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("TAPSMART")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("now")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
                Text("You're at \(storeName)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text("\(cardName) earns \(cashback) here — tap to pay")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "0D1B2A").opacity(0.7))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 8)
        .padding(.horizontal, 12)
    }
}

#Preview {
    LockScreenView()
        .environmentObject(LocationManager())
}
