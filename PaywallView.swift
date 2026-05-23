import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var isRestoring  = false

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // ── Hero ──────────────────────────────────────
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "14B8A6").opacity(0.15))
                                .frame(width: 100, height: 100)
                            Text("💳")
                                .font(.system(size: 52))
                        }
                        .padding(.top, 48)

                        Text("TapSmart Premium")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)

                        Text("You've used all 5 free\nrecommendations this month.")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)

                    // ── Blurred preview of what's locked ──────────
                    VStack(spacing: 10) {
                        Text("WHAT YOU'RE MISSING")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.35))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                        // Blurred card recommendation preview
                        ZStack {
                            VStack(spacing: 10) {
                                LockedPreviewRow(
                                    icon: "cart.fill",
                                    color: "22C55E",
                                    label: "Grocery",
                                    cardName: "Amex Blue Cash Preferred",
                                    cashback: "6%"
                                )
                                LockedPreviewRow(
                                    icon: "fork.knife",
                                    color: "F97316",
                                    label: "Dining",
                                    cardName: "Amex Gold Card",
                                    cashback: "4%"
                                )
                                LockedPreviewRow(
                                    icon: "fuelpump.fill",
                                    color: "D97706",
                                    label: "Gas",
                                    cardName: "Citi Custom Cash",
                                    cashback: "5%"
                                )
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(16)
                            .blur(radius: 5)

                            // Lock overlay
                            VStack(spacing: 10) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                Text("Upgrade to see your best card\nfor every category & store")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(20)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 24)

                    // ── Feature list ──────────────────────────────
                    VStack(spacing: 0) {
                        PaywallFeatureRow(
                            icon:  "infinity",
                            color: "14B8A6",
                            title: "Unlimited recommendations",
                            sub:   "See your best card every time, every store"
                        )
                        Divider().background(Color.white.opacity(0.07))
                        PaywallFeatureRow(
                            icon:  "bell.badge.fill",
                            color: "F97316",
                            title: "Full notification alerts",
                            sub:   "Card name and cashback % always revealed"
                        )
                        Divider().background(Color.white.opacity(0.07))
                        PaywallFeatureRow(
                            icon:  "lightbulb.fill",
                            color: "C084FC",
                            title: "For You tab — unlocked",
                            sub:   "Best card per category + personalised picks"
                        )
                        Divider().background(Color.white.opacity(0.07))
                        PaywallFeatureRow(
                            icon:  "chart.line.uptrend.xyaxis",
                            color: "22C55E",
                            title: "Regular stops & tips",
                            sub:   "Alerts based on your real shopping habits"
                        )
                    }
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)

                    // ── Price callout ─────────────────────────────
                    VStack(spacing: 6) {
                        Text("$4.99 / month")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                        Text("Cancel anytime in your App Store settings")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.top, 28)
                    .padding(.bottom, 24)

                    // ── CTA buttons ───────────────────────────────
                    VStack(spacing: 12) {
                        Button {
                            isPurchasing = true
                            Task {
                                await subscriptionManager.purchase()
                                isPurchasing = false
                                if subscriptionManager.isPremium { dismiss() }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if isPurchasing {
                                    ProgressView().tint(.white).scaleEffect(0.85)
                                } else {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 16))
                                }
                                Text(isPurchasing ? "Processing…" : "Upgrade to Premium")
                                    .font(.system(size: 18, weight: .bold))
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
                        }
                        .disabled(isPurchasing || isRestoring)

                        Button {
                            isRestoring = true
                            Task {
                                await subscriptionManager.restorePurchases()
                                isRestoring = false
                            }
                        } label: {
                            Text(isRestoring ? "Restoring…" : "Restore Purchase")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(hex: "14B8A6"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "14B8A6").opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "14B8A6").opacity(0.3), lineWidth: 1.5)
                                )
                                .cornerRadius(12)
                        }
                        .disabled(isPurchasing || isRestoring)

                        Button { dismiss() } label: {
                            Text("Maybe later")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.3))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - LockedPreviewRow

private struct LockedPreviewRow: View {
    let icon: String
    let color: String
    let label: String
    let cardName: String
    let cashback: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: color))
                .frame(width: 32, height: 32)
                .background(Color(hex: color).opacity(0.15))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                Text(cardName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()

            Text(cashback)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(Color(hex: color))
        }
    }
}

// MARK: - PaywallFeatureRow

private struct PaywallFeatureRow: View {
    let icon:  String
    let color: String
    let title: String
    let sub:   String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: color))
                .frame(width: 40, height: 40)
                .background(Color(hex: color).opacity(0.12))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(sub)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: color))
                .font(.system(size: 18))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager.shared)
}
