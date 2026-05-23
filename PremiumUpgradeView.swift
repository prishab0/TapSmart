import SwiftUI

struct PremiumUpgradeView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var activated = false

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.yellow)
                }

                Text("TapSmart Premium")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Unlock unlimited card comparisons\nand recommendations.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal)

                VStack(spacing: 0) {
                    premiumFeatureRow("infinity",                   "14B8A6", "Unlimited comparisons",   "See your best card every time")
                    Divider().background(Color.white.opacity(0.07))
                    premiumFeatureRow("bell.badge.fill",           "F97316", "Full notification alerts", "Card name & cashback always revealed")
                    Divider().background(Color.white.opacity(0.07))
                    premiumFeatureRow("chart.line.uptrend.xyaxis", "22C55E", "Savings tracking",         "Charts, streaks & milestones")
                }
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 20)

                VStack(spacing: 4) {
                    Text("$4.99 / month")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.white)
                    Text("Cancel anytime in App Store settings")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }

                // ── Demo upgrade button (no real payment) ─────────────────
                Button {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    activated = true
                    subscriptionManager.enableDemoMode()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if activated {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text("Premium Activated!")
                                .fontWeight(.bold)
                                .font(.system(size: 18))
                        } else {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Upgrade to Premium — $4.99/mo")
                                .fontWeight(.bold)
                                .font(.system(size: 18))
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(activated ? Color.green : Color.yellow)
                    .cornerRadius(16)
                    .animation(.spring(response: 0.3), value: activated)
                }
                .padding(.horizontal, 20)

                // ── Demo reset button ─────────────────────────────────────
                Button {
                    subscriptionManager.resetUsageForTesting()
                    dismiss()
                } label: {
                    Text("Reset to Free (Demo)")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.25))
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Upgrade")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color(hex: "0D1B2A"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func premiumFeatureRow(_ icon: String, _ color: String, _ title: String, _ sub: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: color))
                .frame(width: 38, height: 38)
                .background(Color(hex: color).opacity(0.12))
                .cornerRadius(10)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(sub)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: color))
                .font(.system(size: 17))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

#Preview {
    NavigationStack {
        PremiumUpgradeView()
            .environmentObject(SubscriptionManager.shared)
    }
}
