import SwiftUI
import LinkKit

// MARK: - LinkCardView

/// Presented as a sheet from CardSetupView.
/// Drives the full Plaid Link OAuth flow and surfaces matched cards.
struct LinkCardView: View {

    // Fully qualify SwiftUI.Environment to avoid conflict with LinkKit.Environment
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @StateObject private var vm = LinkCardViewModel()

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {

                    // ── Header ────────────────────────────────────
                    VStack(spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "14B8A6"))

                        Text("Link Your Cards")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("TapSmart uses Plaid to securely verify which cards you own. We never see your account number or balance.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 24)

                    // ── Trust badges ──────────────────────────────
                    HStack(spacing: 0) {
                        TrustBadge(icon: "lock.fill",       label: "256-bit\nencryption")
                        Divider().frame(height: 40).background(Color.white.opacity(0.1))
                        TrustBadge(icon: "eye.slash.fill",  label: "Read-only\naccess")
                        Divider().frame(height: 40).background(Color.white.opacity(0.1))
                        TrustBadge(icon: "creditcard.fill", label: "No account\nnumbers stored")
                    }
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(14)
                    .padding(.horizontal, 20)

                    // ── Linked cards (post-link) ──────────────────
                    if !vm.matchedCards.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("LINKED CARDS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.leading, 4)

                            ForEach(vm.matchedCards) { item in
                                LinkedCardRow(item: item)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // ── Error banner ──────────────────────────────
                    if let error = vm.errorMessage {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color(hex: "F59E0B"))
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "F59E0B").opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }

                    // ── CTA buttons ───────────────────────────────
                    VStack(spacing: 12) {
                        Button { vm.startLinkFlow() } label: {
                            HStack(spacing: 10) {
                                if vm.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.85)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                }
                                Text(vm.hasLinkedAccount ? "Link Another Card" : "Link with Plaid")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(hex: "14B8A6"))
                            .cornerRadius(14)
                        }
                        .disabled(vm.isLoading)

                        if vm.hasLinkedAccount {
                            Button {
                                vm.removeLinkedAccount()
                            } label: {
                                Text("Remove All Linked Cards")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color(hex: "DC2626"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(hex: "DC2626").opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(hex: "DC2626").opacity(0.3), lineWidth: 1.5)
                                    )
                                    .cornerRadius(12)
                            }
                        }

                        Button { dismiss() } label: {
                            Text("Done")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        // ── Plaid Link sheet ──────────────────────────────────────
        .sheet(isPresented: $vm.showPlaidLink) {
            if let token = vm.linkToken {
                PlaidLinkSheetWrapper(
                    linkToken: token,
                    onSuccess: { publicToken, _ in
                        vm.handleLinkSuccess(publicToken: publicToken)
                    },
                    onExit: { error in
                        vm.handleLinkExit(error: error)
                    }
                )
            }
        }
        .onAppear { vm.loadExistingLinkedCards() }
    }
}

// MARK: - LinkedCardRow

private struct LinkedCardRow: View {
    let item: MatchedCardItem

    var body: some View {
        HStack(spacing: 14) {
            if let rewardRate = RewardDataService.shared.allCards
                .first(where: { $0.cardId == item.cardId }) {
                Text(rewardRate.bank)
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 54, height: 32)
                    .background(Color(hex: rewardRate.bankColor))
                    .cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    if let mask = item.lastFour {
                        Text("•••• \(mask)")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    ConfidencePill(confidence: item.confidence)
                }
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: "22C55E"))
                .font(.system(size: 20))
        }
        .padding(16)
        .background(Color(hex: "14B8A6").opacity(0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "14B8A6").opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

// MARK: - ConfidencePill

private struct ConfidencePill: View {
    let confidence: CardMatchResult.Confidence

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }

    private var label: String {
        switch confidence {
        case .exact:    return "Verified"
        case .strong:   return "Matched"
        case .fallback: return "Estimated"
        }
    }

    private var color: Color {
        switch confidence {
        case .exact:    return Color(hex: "22C55E")
        case .strong:   return Color(hex: "14B8A6")
        case .fallback: return Color(hex: "D97706")
        }
    }
}

// MARK: - TrustBadge

private struct TrustBadge: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "14B8A6"))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - PlaidLinkSheetWrapper
// UIViewControllerRepresentable that hosts the real Plaid Link flow.
// LinkKit.Environment conflicts with SwiftUI.Environment — we avoid using
// @Environment(\.dismiss) inside this struct and dismiss via the coordinator instead.

struct PlaidLinkSheetWrapper: UIViewControllerRepresentable {
    let linkToken: String
    let onSuccess: (String, [String: Any]) -> Void
    let onExit:    (Error?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIViewController {
        var config = LinkTokenConfiguration(
            token: linkToken,
            onSuccess: { success in
                onSuccess(success.publicToken, [:])
            }
        )
        config.onExit = { exit in
            onExit(exit.error)
        }

        let result = Plaid.create(config)
        switch result {
        case .success(let handler):
            context.coordinator.handler = handler
            let vc = UIViewController()
            // Defer open() so the vc is in the hierarchy first
            DispatchQueue.main.async {
                handler.open(presentUsing: .viewController(vc))
            }
            return vc
        case .failure(let error):
            onExit(error)
            return UIViewController()
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController,
                                context: Context) {}

    // Keep a strong reference to the handler so ARC doesn't release it
    class Coordinator {
        var parent: PlaidLinkSheetWrapper
        var handler: Handler?
        init(_ parent: PlaidLinkSheetWrapper) { self.parent = parent }
    }
}

// MARK: - Preview

#Preview {
    LinkCardView()
}
