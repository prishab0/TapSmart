import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var locationManager:     LocationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var savingsStore = SavingsStore.shared
    @State private var bgLocation        = UserDefaultsStore.backgroundLocationEnabled
    @State private var notifFreq         = UserDefaultsStore.notifFrequency
    @State private var notifCategories   = UserDefaultsStore.notifCategories
    @State private var showResetConfirm  = false
    @State private var cardCount         = UserDefaultsStore.userCards.count

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // ── PREMIUM ────────────────────────────────
                    settingsSectionHeader("PREMIUM")

                    NavigationLink(destination: PremiumUpgradeView()) {
                        VStack(spacing: 0) {
                            HStack(spacing: 14) {
                                iconBadge("crown.fill", color: "FACC15")

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(subscriptionManager.isPremium ? "Premium Active" : "Upgrade to Premium")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)

                                    Text(subscriptionManager.isPremium
                                         ? "Unlimited recommendations unlocked"
                                         : "\(subscriptionManager.usesRemaining) of 5 free uses left this month")
                                        .font(.system(size: 13))
                                        .foregroundColor(
                                            subscriptionManager.isAtLimit
                                                ? Color(hex: "F97316")
                                                : .white.opacity(0.45)
                                        )
                                }

                                Spacer()

                                if !subscriptionManager.isPremium {
                                    Text("PRO")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.yellow)
                                        .cornerRadius(8)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            // Usage bar + upgrade nudge (free tier only)
                            if !subscriptionManager.isPremium {
                                VStack(spacing: 8) {
                                    // Progress bar
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.white.opacity(0.08))
                                                .frame(height: 6)
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(subscriptionManager.isAtLimit
                                                      ? Color(hex: "F97316")
                                                      : Color(hex: "14B8A6"))
                                                .frame(
                                                    width: geo.size.width * CGFloat(subscriptionManager.usesThisMonth) / 5.0,
                                                    height: 6
                                                )
                                                .animation(.spring(response: 0.4), value: subscriptionManager.usesThisMonth)
                                        }
                                    }
                                    .frame(height: 6)

                                    Text(subscriptionManager.isAtLimit
                                         ? "You've hit your limit — upgrade for unlimited access at $4.99/mo"
                                         : "Upgrade to Premium for unlimited recommendations — $4.99/mo")
                                        .font(.system(size: 12))
                                        .foregroundColor(subscriptionManager.isAtLimit
                                                         ? Color(hex: "F97316")
                                                         : .white.opacity(0.35))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 14)
                            }
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(14)
                    }

                    // ── Card Setup ────────────────────────────────
                    settingsSectionHeader("CARD SETUP")

                    VStack(spacing: 0) {
                        NavigationLink(destination: CardSetupView()) {
                            HStack(spacing: 14) {
                                iconBadge("creditcard.fill", color: "14B8A6")
                                Text("My Cards")
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(cardCount) cards")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.4))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                    }
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(14)
                    .onAppear { cardCount = UserDefaultsStore.userCards.count }

                    // ── Notifications ─────────────────────────────
                    settingsSectionHeader("NOTIFICATIONS")

                    VStack(spacing: 0) {

                        HStack(spacing: 14) {
                            iconBadge("bell.fill", color: "14B8A6")
                            Text("Alert Frequency")
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                            Spacer()
                            Picker("", selection: $notifFreq) {
                                ForEach(UserDefaultsStore.NotifFrequency.allCases,
                                        id: \.self) { f in
                                    Text(f.rawValue).tag(f)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color(hex: "14B8A6"))
                            .onChange(of: notifFreq) { _, v in
                                UserDefaultsStore.notifFrequency = v
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)

                        Divider().background(Color.white.opacity(0.08))

                        HStack(spacing: 14) {
                            iconBadge("location.fill", color: "14B8A6")
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Background Location")
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                Text("Improves geofence accuracy")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            Spacer()
                            Toggle("", isOn: $bgLocation)
                                .tint(Color(hex: "14B8A6"))
                                .labelsHidden()
                                .onChange(of: bgLocation) { _, enabled in
                                    UserDefaultsStore.backgroundLocationEnabled = enabled
                                    if enabled {
                                        locationManager.requestAlwaysPermission()
                                    }
                                }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(14)

                    settingsSectionHeader("NOTIFY ME FOR")

                    VStack(spacing: 0) {
                        ForEach(Array(UserDefaultsStore.allNotifCategories.enumerated()),
                                id: \.element) { idx, category in

                            HStack(spacing: 14) {
                                iconBadge(categoryIcon(category),
                                          color: categoryColor(category))
                                Text(category)
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { notifCategories.contains(category) },
                                    set: { enabled in
                                        if enabled {
                                            notifCategories.insert(category)
                                        } else {
                                            notifCategories.remove(category)
                                        }
                                        UserDefaultsStore.notifCategories = notifCategories
                                    }
                                ))
                                .tint(Color(hex: "14B8A6"))
                                .labelsHidden()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)

                            if idx < UserDefaultsStore.allNotifCategories.count - 1 {
                                Divider().background(Color.white.opacity(0.08))
                            }
                        }
                    }
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(14)

                    settingsSectionHeader("SAVINGS DATA")

                    VStack(spacing: 0) {
                        HStack(spacing: 14) {
                            iconBadge("dollarsign.circle.fill", color: "22C55E")
                            Text("Total Saved")
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                            Spacer()
                            Text("$\(savingsStore.totalSaved, specifier: "%.2f")")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(hex: "22C55E"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { cardCount = UserDefaultsStore.userCards.count }
    }

    private func settingsSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white.opacity(0.4))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
    }

    private func iconBadge(_ systemName: String, color: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 15))
            .foregroundColor(Color(hex: color))
            .frame(width: 32, height: 32)
            .background(Color(hex: color).opacity(0.15))
            .cornerRadius(8)
    }

    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "Grocery":     return "cart.fill"
        case "Dining":      return "fork.knife"
        case "Gas":         return "fuelpump.fill"
        case "Shopping":    return "bag.fill"
        case "Pharmacy":    return "cross.fill"
        case "Electronics": return "desktopcomputer"
        case "Hardware":    return "hammer.fill"
        default:            return "bell.fill"
        }
    }

    private func categoryColor(_ category: String) -> String {
        switch category {
        case "Grocery":     return "22C55E"
        case "Dining":      return "F97316"
        case "Gas":         return "D97706"
        case "Shopping":    return "C084FC"
        case "Pharmacy":    return "94A3B8"
        case "Electronics": return "60A5FA"
        case "Hardware":    return "F97316"
        default:            return "14B8A6"
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(LocationManager())
            .environmentObject(SubscriptionManager.shared)
    }
}
