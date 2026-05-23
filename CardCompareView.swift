import SwiftUI

// MARK: - CardCompareView

struct CardCompareView: View {

    let leftId: String
    let rightId: String

    @Environment(\.dismiss) private var dismiss

    private let svc = RewardDataService.shared

    @ObservedObject var premiumManager = PremiumManager.shared
    @State private var showPremiumPopup = false

    private var left: RewardRate? {
        svc.allCards.first { $0.cardId == leftId }
    }

    private var right: RewardRate? {
        svc.allCards.first { $0.cardId == rightId }
    }

    private let categories: [(name: String, mcc: String, icon: String)] = [
        ("Grocery",     "5411", "🛒"),
        ("Dining",      "5812", "🍽️"),
        ("Gas",         "5541", "⛽"),
        ("Shopping",    "5999", "🛍️"),
        ("Pharmacy",    "5912", "💊"),
        ("Electronics", "5734", "💻"),
        ("Hardware",    "5251", "🔨"),
        ("Other",       "5999", "📦"),
    ]

    var body: some View {

        ZStack {

            mainContent
                .blur(radius: showPremiumPopup ? 8 : 0)

            if showPremiumPopup {
                premiumOverlay
            }
        }
        .onAppear {

            if premiumManager.canUseFeature() {

                premiumManager.registerUse()

            } else {

                showPremiumPopup = true
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {

        ZStack {

            Color(hex: "0D1B2A")
                .ignoresSafeArea()

            ScrollView {

                VStack(spacing: 0) {

                    // HEADER

                    HStack {

                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.4))
                        }

                        Spacer()

                        Text("Compare Cards")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)

                        Spacer()

                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                    // REMAINING DEMOS

                    if !premiumManager.isPremiumUser {

                        Text("Free demos left: \(premiumManager.remainingUses())")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.bottom, 18)
                    }

                    // CARD HEADERS

                    HStack(spacing: 12) {

                        cardHeader(left)
                        cardHeader(right)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                    // CATEGORY ROWS

                    VStack(spacing: 0) {

                        ForEach(categories, id: \.mcc) { cat in

                            if let l = left,
                               let r = right {

                                let lRate = svc.rate(for: l, mcc: cat.mcc)
                                let rRate = svc.rate(for: r, mcc: cat.mcc)

                                CompareRow(
                                    icon: cat.icon,
                                    name: cat.name,
                                    leftPct: lRate,
                                    rightPct: rRate,
                                    leftFormatted: svc.formatRate(lRate),
                                    rightFormatted: svc.formatRate(rRate)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // WINNER

                    if let l = left,
                       let r = right {

                        winnerBanner(l, r)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
    }

    // MARK: - Premium Popup

    private var premiumOverlay: some View {

        ZStack {

            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 20) {

                Image(systemName: "lock.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.yellow)

                Text("Demo Limit Reached")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Upgrade to Premium for unlimited card comparisons.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.horizontal)

                Button {

                    showPremiumPopup = false
                    dismiss()

                } label: {

                    Text("Maybe Later")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }

                Button {

                    premiumManager.isPremiumUser = true
                    showPremiumPopup = false

                } label: {

                    Text("Upgrade to Premium")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(14)
                }
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(.ultraThinMaterial)
            .cornerRadius(28)
            .padding()
        }
    }

    // MARK: - Card Header

    private func cardHeader(_ card: RewardRate?) -> some View {

        guard let card else {
            return AnyView(EmptyView())
        }

        return AnyView(

            VStack(spacing: 8) {

                Text(card.bank)
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(hex: card.bankColor))
                    .cornerRadius(8)

                Text(card.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Color.white.opacity(0.05))
            .cornerRadius(14)
        )
    }

    // MARK: - Winner Banner

    private func winnerBanner(_ l: RewardRate, _ r: RewardRate) -> some View {

        let lTotal = categories.reduce(0.0) {
            $0 + svc.rate(for: l, mcc: $1.mcc)
        }

        let rTotal = categories.reduce(0.0) {
            $0 + svc.rate(for: r, mcc: $1.mcc)
        }

        let winnerName: String
        let winnerBank: String

        if lTotal > rTotal {

            winnerName = l.name
            winnerBank = l.bankColor

        } else if rTotal > lTotal {

            winnerName = r.name
            winnerBank = r.bankColor

        } else {

            return AnyView(

                Text("It's a tie across these categories.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.45))
            )
        }

        return AnyView(

            HStack(spacing: 12) {

                Image(systemName: "trophy.fill")
                    .foregroundColor(Color(hex: "F59E0B"))
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 4) {

                    Text("Best overall")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))

                    Text(winnerName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                Text(winnerBank)
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: winnerBank))
                    .cornerRadius(6)
            }
            .padding(16)
            .background(Color(hex: "22C55E").opacity(0.08))
            .cornerRadius(14)
        )
    }
}

// MARK: - CompareRow

private struct CompareRow: View {

    let icon: String
    let name: String
    let leftPct: Double
    let rightPct: Double
    let leftFormatted: String
    let rightFormatted: String

    private var leftWins: Bool {
        leftPct > rightPct
    }

    private var rightWins: Bool {
        rightPct > leftPct
    }

    var body: some View {

        VStack(spacing: 0) {

            HStack(spacing: 0) {

                Text(leftFormatted)
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(
                        leftWins
                        ? Color(hex: "22C55E")
                        : rightWins
                        ? .white.opacity(0.3)
                        : .white.opacity(0.6)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)

                VStack(spacing: 4) {

                    Text(icon)
                        .font(.system(size: 18))

                    Text(name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(width: 80)

                Text(rightFormatted)
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(
                        rightWins
                        ? Color(hex: "22C55E")
                        : leftWins
                        ? .white.opacity(0.3)
                        : .white.opacity(0.6)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }

            Divider()
                .background(Color.white.opacity(0.06))
        }
    }
}

#Preview {
    CardCompareView(
        leftId: "abcp",
        rightId: "cff"
    )
}
