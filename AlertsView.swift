import SwiftUI

struct AlertsView: View {

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var savingsStore = SavingsStore.shared
    @State private var alerts: [ProactiveAlert] = []
    @State private var cardOfMonth: CardOfTheMonth? = nil

    // Split alerts into regular-stops vs everything else
    private var regularStopAlerts: [ProactiveAlert] {
        alerts.filter { $0.title.hasPrefix("Regular stop:") }
    }

    private var otherAlerts: [ProactiveAlert] {
        alerts.filter { !$0.title.hasPrefix("Regular stop:") }
    }

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    // ── Header ────────────────────────────────────
                    Text("⚡ Proactive Alerts")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: "14B8A6"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 30)

                    Text("TapSmart learns your habits and tells you when to act.")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // ── 1. Streak banner ──────────────────────────
                    StreakBanner(
                        current: savingsStore.currentStreak,
                        best:    savingsStore.bestStreak
                    )

                    // ── 2. Card of the Month ──────────────────────
                    if let cotm = cardOfMonth {
                        CardOfTheMonthCard(cotm: cotm)
                    } else {
                        CardOfTheMonthPlaceholder()
                    }

                    // ── 3. Regular Stops & Tips (Premium only) ────
                    regularStopsSection

                    // ── 4. Other alerts (free) ────────────────────
                    if !otherAlerts.isEmpty {
                        Text("TIPS & MILESTONES")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.35))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)

                        ForEach(otherAlerts) { alert in
                            AlertCard(
                                icon:    alert.icon,
                                title:   alert.title,
                                message: alert.message,
                                color:   alert.colorHex
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear { regenerate() }
        .onChange(of: savingsStore.records.count) { regenerate() }
    }

    // MARK: - Regular Stops Section

    @ViewBuilder
    private var regularStopsSection: some View {
        if subscriptionManager.isPremium {
            // ── Premium: show real regular stop alerts ────────────
            if !regularStopAlerts.isEmpty {
                VStack(spacing: 12) {
                    Text("REGULAR STOPS & TIPS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)

                    ForEach(regularStopAlerts) { alert in
                        RegularStopAlertCard(alert: alert)
                    }
                }
            }
        } else {
            // ── Free: locked preview ──────────────────────────────
            regularStopsLockedSection
        }
    }

    private var regularStopsLockedSection: some View {
        VStack(spacing: 12) {
            Text("REGULAR STOPS & TIPS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.35))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

            ZStack(alignment: .bottom) {
                // Blurred fake cards underneath
                VStack(spacing: 10) {
                    ForEach(fakeRegularStops, id: \.title) { fake in
                        fakeStopCard(fake)
                    }
                }
                .blur(radius: 5)
                .allowsHitTesting(false)

                // Gradient fade
                LinearGradient(
                    colors: [
                        Color(hex: "0D1B2A").opacity(0),
                        Color(hex: "0D1B2A").opacity(0.5),
                        Color(hex: "0D1B2A").opacity(0.92)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                // Lock card
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "22C55E").opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "22C55E"))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Regular Stops & Tips")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Text("Know your best card before you even walk in.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.55))
                                .lineSpacing(2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Mini feature bullets
                    VStack(spacing: 8) {
                        lockedBullet(icon: "mappin.circle.fill",   color: "22C55E", text: "Alerts for your most-visited stores")
                        lockedBullet(icon: "creditcard.fill",      color: "14B8A6", text: "Best card shown for each regular stop")
                        lockedBullet(icon: "applelogo",            color: "F59E0B", text: "One-tap Apple Pay from the alert")
                    }

                    Button {
                        subscriptionManager.showPaywall = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                            Text("Unlock with Premium — $4.99/mo")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "22C55E"), Color(hex: "16A34A")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color(hex: "22C55E").opacity(0.35), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "0D1B2A").opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "22C55E").opacity(0.3), lineWidth: 1.5)
                        )
                )
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $subscriptionManager.showPaywall) {
            PaywallView().environmentObject(subscriptionManager)
        }
    }

    // MARK: - Fake regular stop data (for the blurred preview)

    private struct FakeStop {
        let title: String
        let message: String
        let icon: String
        let color: String
    }

    private let fakeRegularStops: [FakeStop] = [
        FakeStop(
            title:   "Regular stop: Trader Joe's",
            message: "You've visited 8 times. Use your Amex Blue Cash Preferred (6% back) every time you're here.",
            icon:    "🛒",
            color:   "22C55E"
        ),
        FakeStop(
            title:   "Regular stop: Starbucks",
            message: "You've visited 5 times. Use your Amex Gold Card (4% back) every time you're here.",
            icon:    "🍽️",
            color:   "F97316"
        ),
    ]

    private func fakeStopCard(_ fake: FakeStop) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(fake.icon)
                .font(.system(size: 28))
                .frame(width: 44)
            VStack(alignment: .leading, spacing: 6) {
                Text(fake.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Text(fake.message)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(3)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: fake.color).opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: fake.color).opacity(0.3), lineWidth: 1.5)
        )
        .cornerRadius(14)
    }

    private func lockedBullet(icon: String, color: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: color))
                .frame(width: 28, height: 28)
                .background(Color(hex: color).opacity(0.12))
                .cornerRadius(7)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))
            Spacer()
        }
    }

    // MARK: - Data

    private func regenerate() {
        let userCards = UserDefaultsStore.userCards
        alerts = ProactiveAlertsEngine.shared.generateAlerts(
            savings:   savingsStore.records,
            userCards: userCards
        )
        cardOfMonth = ProactiveAlertsEngine.shared.cardOfTheMonth(
            savings:   savingsStore.records,
            userCards: userCards
        )
    }
}

// MARK: - RegularStopAlertCard

struct RegularStopAlertCard: View {
    let alert: ProactiveAlert

    private var storeName: String {
        alert.title.replacingOccurrences(of: "Regular stop: ", with: "")
    }

    private var cardInfo: (name: String, cashback: String)? {
        let msg = alert.message
        guard let useRange  = msg.range(of: "Use your "),
              let parenOpen = msg.range(of: " (", range: useRange.upperBound..<msg.endIndex),
              let parenClose = msg.range(of: "% back)", range: parenOpen.upperBound..<msg.endIndex)
        else { return nil }
        let name     = String(msg[useRange.upperBound..<parenOpen.lowerBound])
        let cashback = String(msg[parenOpen.upperBound..<parenClose.lowerBound]) + "%"
        return (name, cashback)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                Text(alert.icon)
                    .font(.system(size: 32))
                    .frame(width: 50)
                VStack(alignment: .leading, spacing: 8) {
                    Text(alert.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text(alert.message)
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.75))
                        .lineSpacing(4)
                }
            }
            .padding(20)

            if let info = cardInfo {
                Divider().background(Color.white.opacity(0.08))
                Button {
                    ApplePayHandler.shared.presentPayment(
                        cardName:  info.name,
                        storeName: storeName
                    ) {
                        let mcc  = ProactiveAlertsEngine.shared.mccForStore(storeName)
                        let rate = Double(info.cashback.replacingOccurrences(of: "%", with: "")) ?? 1.0
                        SavingsStore.shared.recordSaving(
                            storeName:       storeName,
                            category:        categoryForMCC(mcc),
                            cardName:        info.name,
                            bestCashbackPct: rate,
                            usedBestCard:    true
                        )
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "applelogo")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Pay with \(info.name)")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Text(info.cashback + " back")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "22C55E"))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.black.opacity(0.35))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: alert.colorHex).opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: alert.colorHex).opacity(0.35), lineWidth: 1.5)
        )
        .cornerRadius(16)
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
        default:     return "Shopping"
        }
    }
}

// MARK: - CardOfTheMonthCard

struct CardOfTheMonthCard: View {
    let cotm: CardOfTheMonth
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack {
                    Spacer()
                    Text("⭐").font(.system(size: 22))
                    Text("CARD OF\nTHE MONTH")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(Color(hex: "F59E0B"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(1)
                    Spacer()
                }
                .frame(width: 56)
                .padding(.vertical, 18)
                .background(Color(hex: "F59E0B").opacity(0.10))

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text(cotm.forMonth.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(Color(hex: "F59E0B").opacity(0.8))
                        Spacer()
                        Text(cotm.card.bank)
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color(hex: cotm.card.bankColor))
                            .cornerRadius(5)
                    }
                    Text(cotm.card.name)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2).minimumScaleFactor(0.85)
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "22C55E"))
                        Text("+\(cotm.topCategoryGain, specifier: "%.0f")% on \(cotm.topCategory) · +$\(cotm.projectedAnnualGain, specifier: "%.0f")/yr projected")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "22C55E"))
                    }
                    if cotm.signOnValue > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "gift.fill").font(.system(size: 13)).foregroundColor(Color(hex: "F59E0B"))
                            Text(cotm.signOnBonus).font(.system(size: 13)).foregroundColor(.white.opacity(0.75)).lineSpacing(2)
                        }
                    }
                    Button {
                        withAnimation(.spring(response: 0.3)) { expanded.toggle() }
                    } label: {
                        HStack(spacing: 4) {
                            Text(expanded ? "Show less" : "See full details")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "F59E0B"))
                            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "F59E0B"))
                        }
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 16).padding(.vertical, 18)
            }

            if expanded {
                VStack(alignment: .leading, spacing: 14) {
                    Divider().background(Color.white.opacity(0.1))
                    Text("WHY THIS CARD?")
                        .font(.system(size: 11, weight: .bold)).foregroundColor(.white.opacity(0.4))
                    Text(cotm.card.note)
                        .font(.system(size: 15)).foregroundColor(.white.opacity(0.75)).lineSpacing(3)
                    if cotm.signOnValue > 0 {
                        HStack(spacing: 0) {
                            bonusStat(label: "Bonus Value",  value: "$\(Int(cotm.signOnValue))",                        color: "F59E0B")
                            Divider().frame(height: 40).background(Color.white.opacity(0.1))
                            bonusStat(label: "Min. Spend",   value: cotm.signOnSpend > 0 ? "$\(Int(cotm.signOnSpend))" : "None", color: "14B8A6")
                            Divider().frame(height: 40).background(Color.white.opacity(0.1))
                            bonusStat(label: "Extra/yr",     value: "+$\(Int(cotm.projectedAnnualGain))",               color: "22C55E")
                        }
                        .background(Color.white.opacity(0.04)).cornerRadius(10)
                    }
                    if let url = cotm.affiliateURL {
                        Link(destination: url) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.up.right.square.fill").font(.system(size: 16))
                                Text("Apply Now").font(.system(size: 17, weight: .bold))
                                Spacer()
                                Text("Opens in Safari").font(.system(size: 12)).opacity(0.6)
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 18).padding(.vertical, 16)
                            .background(Color(hex: "F59E0B")).cornerRadius(14)
                        }
                    }
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill").font(.system(size: 13))
                            .foregroundColor(Color(hex: "F59E0B").opacity(0.6)).padding(.top, 1)
                        Text("Offers may change — always verify current terms before applying. TapSmart may earn a referral fee at no cost to you.")
                            .font(.system(size: 12)).foregroundColor(.white.opacity(0.4)).lineSpacing(3)
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 18)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "F59E0B").opacity(0.12), Color(hex: "F59E0B").opacity(0.05)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "F59E0B").opacity(0.4), lineWidth: 1.5))
        .cornerRadius(16)
    }

    private func bonusStat(label: String, value: String, color: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 18, weight: .black, design: .rounded)).foregroundColor(Color(hex: color))
            Text(label).font(.system(size: 10, weight: .semibold)).foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
    }
}

// MARK: - CardOfTheMonthPlaceholder

private struct CardOfTheMonthPlaceholder: View {
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color(hex: "F59E0B").opacity(0.12)).frame(width: 56, height: 56)
                Text("⭐").font(.system(size: 26))
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("Card of the Month")
                    .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                Text("Keep shopping with your cards — after a full month of history TapSmart will recommend the one card worth adding to your wallet.")
                    .font(.system(size: 13)).foregroundColor(.white.opacity(0.5)).lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(Color(hex: "F59E0B").opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "F59E0B").opacity(0.2), lineWidth: 1.5))
        .cornerRadius(16)
    }
}

// MARK: - StreakBanner

struct StreakBanner: View {
    let current: Int
    let best: Int

    private var emoji: String {
        switch current {
        case 0:     return "💤"
        case 1...2: return "✅"
        case 3...5: return "🔥"
        default:    return "🚀"
        }
    }

    private var title: String {
        switch current {
        case 0:  return best > 0 ? "Streak ended — best was \(best)" : "No streak yet"
        case 1:  return "Streak started!"
        default: return "\(current) visit streak"
        }
    }

    private var message: String {
        switch current {
        case 0:     return best > 0 ? "Use the recommended card next visit to start a new one." : "Use the recommended card on your next visit to start a streak."
        case 1...2: return "Keep using the best card each visit to build your streak."
        case 3...5: return "You're on a roll! Keep using the optimal card every visit."
        default:    return "Incredible consistency — you're maximising every purchase."
        }
    }

    private var color: String {
        switch current {
        case 0:     return "94A3B8"
        case 1...2: return "14B8A6"
        case 3...5: return "F97316"
        default:    return "22C55E"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color(hex: color).opacity(0.15)).frame(width: 64, height: 64)
                VStack(spacing: 0) {
                    Text(emoji).font(.system(size: 24))
                    if current > 0 {
                        Text("\(current)").font(.system(size: 14, weight: .black)).foregroundColor(Color(hex: color))
                    }
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                Text(message).font(.system(size: 14)).foregroundColor(.white.opacity(0.6)).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                if best > 0 && current < best {
                    Text("Personal best: \(best)")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(Color(hex: color).opacity(0.8)).padding(.top, 2)
                }
            }
            Spacer()
        }
        .padding(18)
        .background(Color(hex: color).opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: color).opacity(0.3), lineWidth: 1.5))
        .cornerRadius(16)
        .animation(.spring(response: 0.4), value: current)
    }
}

// MARK: - AlertCard

struct AlertCard: View {
    let icon: String
    let title: String
    let message: String
    let color: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(icon).font(.system(size: 32)).frame(width: 50)
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                Text(message).font(.system(size: 17)).foregroundColor(.white.opacity(0.75)).lineSpacing(4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: color).opacity(0.1))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: color).opacity(0.35), lineWidth: 1.5))
        .cornerRadius(16)
    }
}

#Preview {
    AlertsView()
        .environmentObject(SubscriptionManager.shared)
}

