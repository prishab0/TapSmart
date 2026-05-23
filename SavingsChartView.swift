import SwiftUI

// MARK: - SavingsChartView
// Drop-in component for SavingsView. Shows month-over-month cashback earned
// as a bar chart, with a category legend below.
//
// Usage inside SavingsView's ScrollView VStack:
//   SavingsChartView(store: store)

struct SavingsChartView: View {

    let store: SavingsStore

    // Month abbreviations Jan-Dec
    private let monthAbbr = ["Jan","Feb","Mar","Apr","May","Jun",
                              "Jul","Aug","Sep","Oct","Nov","Dec"]

    // Full year data (Jan=1 … Dec=12), filling 0 for missing months
    private var monthlyData: [(month: Int, label: String, amount: Double)] {
        let trend = store.monthlyTrend           // [Int: Double]
        let maxMonth = Calendar.current.component(.month, from: Date())
        return (1...maxMonth).map { m in
            (month: m, label: monthAbbr[m - 1], amount: trend[m] ?? 0)
        }
    }

    private var maxAmount: Double {
        max(monthlyData.map(\.amount).max() ?? 1, 0.01)
    }

    // Per-category totals, sorted descending
    private var categoryTotals: [(name: String, amount: Double, color: String)] {
        store.savingsByCategory
            .map { (name: $0.key, amount: $0.value, color: colorForCategory($0.key)) }
            .sorted { $0.amount > $1.amount }
    }

    // Selected bar (nil = none)
    @State private var selectedMonth: Int? = nil

    private var selectedMonthData: (month: Int, label: String, amount: Double)? {
        guard let s = selectedMonth else { return nil }
        return monthlyData.first { $0.month == s }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // ── Section header ──────────────────────────────────
            HStack {
                Text("📊 Monthly Savings")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                if let sel = selectedMonthData {
                    Text("\(sel.label): $\(sel.amount, specifier: "%.2f")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "14B8A6"))
                        .transition(.opacity)
                }
            }

            // ── Bar chart ───────────────────────────────────────
            GeometryReader { geo in
                let barCount  = monthlyData.count
                let totalGap  = CGFloat(barCount - 1) * 6
                let barWidth  = (geo.size.width - totalGap) / CGFloat(barCount)
                let chartH    = geo.size.height - 22     // leave room for labels

                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(monthlyData, id: \.month) { item in
                        let fraction = CGFloat(item.amount / maxAmount)
                        let barH     = max(fraction * chartH, item.amount > 0 ? 4 : 0)
                        let isSelected = selectedMonth == item.month

                        VStack(spacing: 4) {
                            Spacer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    isSelected
                                        ? Color(hex: "14B8A6")
                                        : item.amount > 0
                                            ? Color(hex: "14B8A6").opacity(0.45)
                                            : Color.white.opacity(0.07)
                                )
                                .frame(width: barWidth, height: barH)
                                .overlay(
                                    isSelected
                                        ? RoundedRectangle(cornerRadius: 4)
                                              .stroke(Color(hex: "14B8A6"), lineWidth: 1.5)
                                        : nil
                                )
                                .animation(.spring(response: 0.3), value: isSelected)

                            Text(item.label)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(
                                    isSelected
                                        ? Color(hex: "14B8A6")
                                        : .white.opacity(0.4)
                                )
                                .frame(width: barWidth)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25)) {
                                selectedMonth = (selectedMonth == item.month) ? nil : item.month
                            }
                        }
                    }
                }
            }
            .frame(height: 130)

            // ── Category breakdown legend ────────────────────────
            if !categoryTotals.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.1))

                Text("By category")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))

                // Filter by selected month if one is tapped
                let filteredTotals: [(name: String, amount: Double, color: String)] = {
                    guard let sel = selectedMonth else { return categoryTotals }
                    let recs = store.records.filter {
                        Calendar.current.component(.month, from: $0.date) == sel
                    }
                    let bycat = Dictionary(grouping: recs, by: \.category)
                        .mapValues { $0.reduce(0) { $0 + $1.amount } }
                    return bycat
                        .map { (name: $0.key, amount: $0.value, color: colorForCategory($0.key)) }
                        .filter { $0.amount > 0 }
                        .sorted { $0.amount > $1.amount }
                }()

                let maxCat = filteredTotals.map(\.amount).max() ?? 1

                VStack(spacing: 10) {
                    ForEach(filteredTotals, id: \.name) { item in
                        HStack(spacing: 10) {
                            Text(item.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 76, alignment: .leading)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white.opacity(0.07))
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(hex: item.color))
                                        .frame(width: geo.size.width * CGFloat(item.amount / maxCat))
                                        .animation(.spring(response: 0.4), value: item.amount)
                                }
                            }
                            .frame(height: 8)

                            Text("$\(item.amount, specifier: "%.2f")")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: item.color))
                                .frame(width: 52, alignment: .trailing)
                        }
                    }
                }
            }

            // ── Projected annual callout ─────────────────────────
            let month  = Double(Calendar.current.component(.month, from: Date()))
            let yearly = month > 0 ? (store.totalSaved / month) * 12 : 0
            if yearly > 0 {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundColor(Color(hex: "22C55E"))
                        .font(.system(size: 16))
                    Text("On pace to save **$\(Int(yearly))** this year")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.65))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "22C55E").opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "22C55E").opacity(0.25), lineWidth: 1)
                )
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.04))
        .cornerRadius(18)
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
}

#Preview {
    ScrollView {
        SavingsChartView(store: SavingsStore.shared)
            .padding(20)
    }
    .background(Color(hex: "0D1B2A"))
}
