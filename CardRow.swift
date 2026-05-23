import SwiftUI

struct CardRow: View {
    let bank: String
    let bankColor: String
    let name: String
    let category: String
    let percent: String
    let isBest: Bool
    var isDebit: Bool = false      // NEW

    var body: some View {
        HStack(spacing: 14) {
            Text(bank)
                .font(.system(size: 13, weight: .black))
                .foregroundColor(.white)
                .frame(width: 60, height: 36)
                .background(Color(hex: bankColor))
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(isDebit ? .white.opacity(0.55) : .white)

                    // DEBIT badge
                    if isDebit {
                        Text("DEBIT")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(Color(hex: "94A3B8"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "94A3B8").opacity(0.15))
                            .cornerRadius(4)
                    }
                }

                Text(category)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))

                if isBest {
                    Text("✓ Best Choice")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "22C55E"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color(hex: "22C55E").opacity(0.15))
                        .cornerRadius(5)
                }
            }

            Spacer()

            Text(percent)
                .font(.system(size: 28, weight: .black))
                .foregroundColor(
                    isBest
                        ? Color(hex: "22C55E")
                        : isDebit
                            ? .white.opacity(0.25)
                            : .white.opacity(0.4)
                )
        }
        .padding(18)
        .background(Color.white.opacity(isDebit ? 0.03 : 0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isBest
                        ? Color(hex: "22C55E")
                        : isDebit
                            ? Color.white.opacity(0.06)
                            : Color.white.opacity(0.1),
                    lineWidth: isBest ? 2 : 1
                )
        )
        .cornerRadius(14)
    }
}

#Preview {
    VStack(spacing: 12) {
        CardRow(
            bank: "CHASE",
            bankColor: "1A56DB",
            name: "Chase Freedom Flex",
            category: "Groceries · 5% rotating",
            percent: "5%",
            isBest: true,
            isDebit: false
        )
        CardRow(
            bank: "CHASE",
            bankColor: "1A56DB",
            name: "Chase Total Checking Debit",
            category: "Groceries · No rewards",
            percent: "0%",
            isBest: false,
            isDebit: true
        )
    }
    .padding()
    .background(Color(hex: "0D1B2A"))
}
