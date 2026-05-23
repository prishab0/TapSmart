import SwiftUI

// MARK: - SavingsView Empty State

struct SavingsEmptyState: View {
    let onAddManual: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: "14B8A6").opacity(0.08))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(Color(hex: "14B8A6").opacity(0.05))
                    .frame(width: 110, height: 110)
                Text("💳")
                    .font(.system(size: 60))
            }

            VStack(spacing: 10) {
                Text("No savings yet")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Walk into any store and TapSmart will\nrecommend your best card and track\nevery dollar you save.")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }

            VStack(spacing: 12) {
                HowItWorksRow(icon: "location.fill",         color: "22C55E", text: "Walk into a store")
                HowItWorksRow(icon: "creditcard.fill",       color: "14B8A6", text: "Use the recommended card")
                HowItWorksRow(icon: "dollarsign.circle.fill", color: "F59E0B", text: "Savings logged automatically")
            }
            .padding(20)
            .background(Color.white.opacity(0.04))
            .cornerRadius(16)

            Button(action: onAddManual) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Log a card use manually")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(Color(hex: "14B8A6"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "14B8A6").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "14B8A6").opacity(0.3), lineWidth: 1.5)
                )
                .cornerRadius(14)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

private struct HowItWorksRow: View {
    let icon: String
    let color: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: color))
                .frame(width: 36, height: 36)
                .background(Color(hex: color).opacity(0.12))
                .cornerRadius(10)

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.75))

            Spacer()
        }
    }
}

// MARK: - SavingsSummaryShareSheet

enum SavingsSummaryShareSheet {
    static func summary(from store: SavingsStore) -> String {
        let total = store.totalSaved
        let byCard = Dictionary(grouping: store.records, by: \.cardName)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
            .sorted { $0.value > $1.value }
        let topCard   = byCard.first
        let month     = Double(Calendar.current.component(.month, from: Date()))
        let projected = month > 0 ? (total / month) * 12 : 0

        var lines: [String] = [
            "💳 My TapSmart Savings",
            "",
            "Total saved this year: $\(String(format: "%.2f", total))",
            "On pace to save $\(String(format: "%.0f", projected)) total",
        ]

        if let top = topCard {
            lines.append("Top card: \(top.key) (+$\(String(format: "%.2f", top.value)))")
        }

        let streak = store.currentStreak
        if streak > 1 {
            lines.append("Current streak: \(streak) visits 🔥")
        }

        lines += [
            "",
            "Get TapSmart — always pay with your best card.",
            "https://apps.apple.com/app/tapsmart"
        ]

        return lines.joined(separator: "\n")
    }
}
