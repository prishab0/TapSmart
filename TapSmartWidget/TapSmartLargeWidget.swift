import WidgetKit
import SwiftUI
import Foundation

// MARK: - TapSmartLargeWidget
// Registered in TapSmartWidgetBundle:
//
//   var body: some Widget {
//       TapSmartWidget()
//       TapSmartLargeWidget()
//   }
//
// The large widget shows:
//   • Total saved + projected annual
//   • Month-by-month mini bar chart
//   • Last 3 transactions
//   • Deep-link to Savings tab
//
// NOTE: TapSmartEntry, TapSmartProvider, WidgetSavingRecord, and Color(hex:)
// are all defined in TapSmartWidget.swift (same widget target, internal access).

struct TapSmartLargeEntryView: View {
    var entry: TapSmartEntry
    @Environment(\.widgetFamily) var family

    private let monthAbbr = ["J","F","M","A","M","J","J","A","S","O","N","D"]

    private var records: [WidgetSavingRecord] {
        TapSmartProvider().loadRecords()
    }

    private var monthlyTrend: [Int: Double] {
        let cal  = Calendar.current
        let year = cal.component(.year, from: Date())
        return Dictionary(
            grouping: records.filter { cal.component(.year, from: $0.date) == year },
            by: { cal.component(.month, from: $0.date) }
        ).mapValues { $0.reduce(0) { $0 + $1.amount } }
    }

    private var recentThree: [WidgetSavingRecord] {
        records.sorted { $0.date > $1.date }.prefix(3).map { $0 }
    }

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A")

            VStack(alignment: .leading, spacing: 12) {

                // ── Top row: hero numbers ──────────────────────
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "14B8A6"))
                            Text("TAPSMART")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "14B8A6"))
                        }
                        Text("$\(entry.totalSaved, specifier: "%.2f")")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "4ADE80"))
                            .minimumScaleFactor(0.6)
                        Text("saved this year")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                        Text("~$\(entry.projectedYearly, specifier: "%.0f") projected")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "14B8A6"))
                    }
                    Spacer()
                    Link(destination: URL(string: "tapsmart://savings")!) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "14B8A6").opacity(0.7))
                    }
                }

                // ── Mini bar chart ─────────────────────────────
                let currentMonth = Calendar.current.component(.month, from: Date())
                let maxVal = (1...currentMonth).map { monthlyTrend[$0] ?? 0 }.max() ?? 1

                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(1...currentMonth, id: \.self) { m in
                        let amt  = monthlyTrend[m] ?? 0
                        let frac = CGFloat(amt / max(maxVal, 0.01))
                        let isNow = m == currentMonth

                        VStack(spacing: 2) {
                            Capsule()
                                .fill(
                                    isNow
                                        ? Color(hex: "14B8A6")
                                        : amt > 0
                                            ? Color(hex: "14B8A6").opacity(0.4)
                                            : Color.white.opacity(0.06)
                                )
                                .frame(height: max(frac * 44, amt > 0 ? 3 : 0))
                            Text(monthAbbr[m - 1])
                                .font(.system(size: 8))
                                .foregroundColor(
                                    isNow
                                        ? Color(hex: "14B8A6")
                                        : .white.opacity(0.3)
                                )
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 56)
                .padding(.vertical, 4)

                Divider()
                    .background(Color.white.opacity(0.1))

                // ── Recent transactions ────────────────────────
                if recentThree.isEmpty {
                    Text("No savings logged yet")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                } else {
                    VStack(spacing: 6) {
                        ForEach(recentThree, id: \.id) { rec in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color(hex: "14B8A6").opacity(0.2))
                                    .frame(width: 6, height: 6)
                                Text(rec.storeName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(1)
                                Spacer()
                                Text("+$\(rec.amount, specifier: "%.2f")")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(hex: "4ADE80"))
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Widget Declaration

struct TapSmartLargeWidget: Widget {
    let kind = "TapSmartLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TapSmartProvider()) { entry in
            TapSmartLargeEntryView(entry: entry)
                .containerBackground(Color(hex: "0D1B2A"), for: .widget)
        }
        .configurationDisplayName("TapSmart Savings (Large)")
        .description("Month-by-month chart plus recent transactions.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemLarge) {
    TapSmartLargeWidget()
} timeline: {
    TapSmartEntry(date: .now, totalSaved: 42.50,
                  recentCard: "Amex BCP", recentStore: "Trader Joe's",
                  projectedYearly: 510)
}
