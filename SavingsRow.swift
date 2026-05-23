import SwiftUI

struct SavingsRow: View {
    let category: String
    let amount: String
    let percent: Double
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(category)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 80, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 5)
                        .fill(color)
                        .frame(width: geo.size.width * percent)
                }
            }
            .frame(height: 10)

            Text(amount)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, alignment: .trailing)
        }
    }
}
