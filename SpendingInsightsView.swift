import SwiftUI

// MARK: - SpendingInsightsView
// Reachable via the chart icon in the Savings tab toolbar.
// Shows a full breakdown of savings by category, by card, and recent trends.

struct SpendingInsightsView: View {

    @ObservedObject private var store = SavingsStore.shared

    // Per-card totals sorted descending
    private var byCard: [(name: String, amount: Double, color: String)] {
        Dictionary(grouping: store.records, by: \.cardName)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
            .map { (name: $0.key, amount: $0.value, color: "14B8A6") }
            .sorted { $0.amount > $1.amount }
    }

    // Per-category totals sorted descending
    private var byCategory: [(name: String, amount: Double, color: String)] {
        store.savingsByCategory
            .map { (name: $0.key, amount: $0.value, color: colorForCategory($0.key)) }
            .sorted { $0.amount > $1.amount }
    }

    private var maxCard: Double     { byCard.map(\.amount).max() ?? 1 }
    private var maxCategory: Double { byCategory.map(\.amount).max() ?? 1 }

    // Best-card usage rate
    private var bestCardRate: Double {
        guard !store.records.isEmpty else { return 0 }
        let usedBest = store.records.filter { $0.usedBestCard }.count
        return Double(usedBest) / Double(store.records.count)
    }

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()

            if store.records.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        summaryRow
                        categorySection
                        cardSection
                        optimizationSection
                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Spending Insights")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color(hex: "0D1B2A"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - Extracted sections

    private var summaryRow: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "dollarsign.circle.fill",
                color: "22C55E",
                value: "$\(String(format: "%.2f", store.totalSaved))",
                label: "Total Saved"
            )
            statCard(
                icon: "checkmark.circle.fill",
                color: "14B8A6",
                value: "\(Int(bestCardRate * 100))%",
                label: "Best Card Used"
            )
            statCard(
                icon: "list.number",
                color: "F59E0B",
                value: "\(store.records.count)",
                label: "Transactions"
            )
        }
    }

    private var categorySection: some View {
        sectionCard(title: "💰 By Category") {
            VStack(spacing: 14) {
                ForEach(byCategory, id: \.name) { item in
                    InsightBarRow(
                        leading: Text(categoryEmoji(item.name)).font(.system(size: 20)),
                        label: item.name,
                        amount: item.amount,
                        fraction: item.amount / maxCategory,
                        color: item.color
                    )
                }
            }
        }
    }

    private var cardSection: some View {
        sectionCard(title: "💳 By Card") {
            VStack(spacing: 14) {
                ForEach(byCard.prefix(8), id: \.name) { item in
                    CardInsightRow(item: item, maxCard: maxCard)
                }
            }
        }
    }

    private var optimizationSection: some View {
        sectionCard(title: "🎯 Optimization Rate") {
            OptimizationRingRow(
                bestCardRate: bestCardRate,
                totalCount: store.records.count,
                usedBestCount: store.records.filter { $0.usedBestCard }.count
            )
        }
    }

    // MARK: - Sub-views

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("📊")
                .font(.system(size: 52))
            Text("No data yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            Text("Start using TapSmart at stores to see your spending insights here.")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 32)
    }

    private func statCard(icon: String, color: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: color))
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.45))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(hex: color).opacity(0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: color).opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(14)
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            content()
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    // MARK: - Helpers

    private func colorForCategory(_ name: String) -> String {
        switch name {
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

    private func categoryEmoji(_ name: String) -> String {
        switch name {
        case "Grocery":     return "🛒"
        case "Dining":      return "🍽️"
        case "Gas":         return "⛽"
        case "Shopping":    return "🛍️"
        case "Pharmacy":    return "💊"
        case "Electronics": return "💻"
        case "Hardware":    return "🔨"
        default:            return "💳"
        }
    }
}

// MARK: - InsightBarRow
// Extracted to help the type-checker (avoids GeometryReader inside ForEach body)

private struct InsightBarRow<Leading: View>: View {
    let leading: Leading
    let label: String
    let amount: Double
    let fraction: Double
    let color: String

    var body: some View {
        HStack(spacing: 12) {
            leading.frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(label)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("$\(String(format: "%.2f", amount))")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: color))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.07))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: color))
                            .frame(width: geo.size.width * CGFloat(fraction))
                            .animation(.spring(response: 0.5), value: fraction)
                    }
                }
                .frame(height: 6)
            }
        }
    }
}

// MARK: - CardInsightRow

private struct CardInsightRow: View {
    let item: (name: String, amount: Double, color: String)
    let maxCard: Double

    private var cardInfo: RewardRate? {
        RewardDataService.shared.allCards.first { $0.name == item.name }
    }

    var body: some View {
        HStack(spacing: 12) {
            if let info = cardInfo {
                Text(info.bank)
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 26)
                    .background(Color(hex: info.bankColor))
                    .cornerRadius(5)
            } else {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 42, height: 26)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    Text("$\(String(format: "%.2f", item.amount))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "14B8A6"))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.07))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: "14B8A6"))
                            .frame(width: geo.size.width * CGFloat(item.amount / maxCard))
                            .animation(.spring(response: 0.5), value: item.amount)
                    }
                }
                .frame(height: 6)
            }
        }
    }
}

// MARK: - OptimizationRingRow

private struct OptimizationRingRow: View {
    let bestCardRate: Double
    let totalCount: Int
    let usedBestCount: Int

    private var ringColor: String {
        bestCardRate >= 0.8 ? "22C55E" : bestCardRate >= 0.5 ? "F59E0B" : "F97316"
    }

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: bestCardRate)
                    .stroke(
                        Color(hex: ringColor),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: bestCardRate)
                Text("\(Int(bestCardRate * 100))%")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.white)
            }
            .frame(width: 76, height: 76)

            VStack(alignment: .leading, spacing: 6) {
                let missed = totalCount - usedBestCount
                Text("Used best card \(usedBestCount) of \(totalCount) times")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.75))
                    .lineSpacing(3)
                if missed > 0 {
                    Text("\(missed) time\(missed == 1 ? "" : "s") a better card was available")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "F97316"))
                        .lineSpacing(3)
                } else {
                    Text("Perfect streak — always optimal!")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "22C55E"))
                }
            }
        }
    }
}

// MARK: - TransactionDetailView
// Navigated to from SavingsView and AllTransactionsView.

struct TransactionDetailView: View {
    let record: SavingRecord
    @Environment(\.dismiss) private var dismiss

    private var cardInfo: RewardRate? {
        RewardDataService.shared.allCards.first { $0.name == record.cardName }
    }

    private var categoryColor: String {
        switch record.category {
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

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    savingsCallout
                    detailTable
                    cardBadge
                    notOptimalWarning
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color(hex: "0D1B2A"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(categoryEmoji(record.category))
                .font(.system(size: 52))
                .padding(.top, 32)
            Text(record.storeName)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text(record.date, style: .date)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var savingsCallout: some View {
        VStack(spacing: 6) {
            Text("YOU SAVED")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
            Text("+$\(String(format: "%.2f", record.amount))")
                .font(.system(size: 56, weight: .black, design: .rounded))
                .foregroundColor(Color(hex: "22C55E"))
            Text("above 1% baseline on $\(String(format: "%.2f", record.spendAmount)) spent")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.45))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "22C55E").opacity(0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "22C55E").opacity(0.25), lineWidth: 1.5)
        )
        .cornerRadius(16)
    }

    private var detailTable: some View {
        VStack(spacing: 0) {
            detailRow(label: "Store",           value: record.storeName)
            Divider().background(Color.white.opacity(0.07))
            detailRow(label: "Category",        value: record.category)
            Divider().background(Color.white.opacity(0.07))
            detailRow(label: "Card Used",       value: record.cardName)
            Divider().background(Color.white.opacity(0.07))
            detailRow(label: "Amount Spent",    value: "$\(String(format: "%.2f", record.spendAmount))")
            Divider().background(Color.white.opacity(0.07))
            detailRow(label: "Cashback Earned", value: "+$\(String(format: "%.2f", record.amount))")
            Divider().background(Color.white.opacity(0.07))
            detailRow(
                label: "Optimal Card?",
                value: record.usedBestCard ? "✓ Yes" : "✗ No",
                valueColor: record.usedBestCard ? "22C55E" : "F97316"
            )
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
    }

    @ViewBuilder
    private var cardBadge: some View {
        if let info = cardInfo {
            HStack(spacing: 14) {
                Text(info.bank)
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 34)
                    .background(Color(hex: info.bankColor))
                    .cornerRadius(7)
                VStack(alignment: .leading, spacing: 3) {
                    Text(info.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(info.note)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: categoryColor).opacity(0.07))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: categoryColor).opacity(0.25), lineWidth: 1)
            )
            .cornerRadius(12)
        }
    }

    @ViewBuilder
    private var notOptimalWarning: some View {
        if !record.usedBestCard {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color(hex: "F97316"))
                    .font(.system(size: 18))
                Text("A better card was available for this purchase. Check the Cards tab next time you visit \(record.storeName).")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(3)
            }
            .padding(16)
            .background(Color(hex: "F97316").opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "F97316").opacity(0.25), lineWidth: 1)
            )
            .cornerRadius(12)
        }
    }

    // MARK: - Helpers

    private func detailRow(label: String, value: String, valueColor: String = "FFFFFF") -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: valueColor))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func categoryEmoji(_ name: String) -> String {
        switch name {
        case "Grocery":     return "🛒"
        case "Dining":      return "🍽️"
        case "Gas":         return "⛽"
        case "Shopping":    return "🛍️"
        case "Pharmacy":    return "💊"
        case "Electronics": return "💻"
        case "Hardware":    return "🔨"
        default:            return "💳"
        }
    }
}

#Preview {
    NavigationStack {
        SpendingInsightsView()
    }
}
