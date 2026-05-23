import SwiftUI
import Charts

struct SavingsView: View {

    @StateObject private var store = SavingsStore.shared
    // These are now bindings driven by SavingsViewWrapper in ContentView
    // so the toolbar buttons actually work.
    @Binding var showLogger: Bool
    @Binding var showShare: Bool

    @State private var monthlyGoal: Double = UserDefaultsStore.monthlyGoal
    @State private var showGoalSheet = false
    @State private var goalInput: String = ""

    // MARK: - Convenience init for previews / standalone use
    init(showLogger: Binding<Bool> = .constant(false),
         showShare: Binding<Bool> = .constant(false)) {
        _showLogger = showLogger
        _showShare  = showShare
    }

    // Savings earned in the current calendar month only
    private var thisMonthSaved: Double {
        let cal = Calendar.current
        let now = Date()
        return store.records
            .filter {
                cal.component(.month, from: $0.date) == cal.component(.month, from: now) &&
                cal.component(.year,  from: $0.date) == cal.component(.year,  from: now)
            }
            .reduce(0) { $0 + $1.amount }
    }

    private var goalProgress: Double {
        guard monthlyGoal > 0 else { return 0 }
        return min(thisMonthSaved / monthlyGoal, 1.0)
    }

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()

            if store.records.isEmpty {
                SavingsEmptyState { showLogger = true }
            } else {
                ScrollView {
                    VStack(spacing: 24) {

                        // ── Hero ──────────────────────────────────────
                        VStack(spacing: 8) {
                            Text("Total Saved This Year")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(hex: "14B8A6"))

                            Text("$\(store.totalSaved, specifier: "%.2f")")
                                .font(.system(size: 76, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "22C55E"))

                            Text(yearRangeLabel())
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.top, 40)

                        // ── Monthly Goal Ring ─────────────────────────
                        Button { showGoalSheet = true } label: {
                            HStack(spacing: 24) {

                                // Progress ring
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.08), lineWidth: 10)
                                        .frame(width: 90, height: 90)

                                    Circle()
                                        .trim(from: 0, to: goalProgress)
                                        .stroke(
                                            goalProgress >= 1.0
                                                ? Color(hex: "22C55E")
                                                : Color(hex: "14B8A6"),
                                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                        )
                                        .frame(width: 90, height: 90)
                                        .rotationEffect(.degrees(-90))
                                        .animation(.spring(response: 0.6), value: goalProgress)

                                    VStack(spacing: 2) {
                                        if monthlyGoal > 0 {
                                            Text("\(Int(goalProgress * 100))%")
                                                .font(.system(size: 20, weight: .black))
                                                .foregroundColor(.white)
                                        } else {
                                            Image(systemName: "plus")
                                                .font(.system(size: 22, weight: .bold))
                                                .foregroundColor(Color(hex: "14B8A6"))
                                        }
                                    }
                                }

                                // Text info
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(monthlyGoal > 0 ? "Monthly Goal" : "Set a Monthly Goal")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)

                                    if monthlyGoal > 0 {
                                        Text("$\(thisMonthSaved, specifier: "%.2f") of $\(monthlyGoal, specifier: "%.0f")")
                                            .font(.system(size: 15))
                                            .foregroundColor(.white.opacity(0.6))

                                        Text(goalProgress >= 1.0
                                             ? "🎉 Goal reached!"
                                             : "$\(monthlyGoal - thisMonthSaved, specifier: "%.2f") to go")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(goalProgress >= 1.0
                                                             ? Color(hex: "22C55E")
                                                             : Color(hex: "14B8A6"))
                                    } else {
                                        Text("Tap to set a savings target\nfor this month")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.45))
                                            .lineSpacing(3)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        goalProgress >= 1.0
                                            ? Color(hex: "22C55E").opacity(0.4)
                                            : Color(hex: "14B8A6").opacity(0.25),
                                        lineWidth: 1.5
                                    )
                            )
                            .cornerRadius(16)
                        }

                        // ── Pace banner ───────────────────────────────
                        let projected = projectedYearlySavings()
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("On pace to save $\(projected, specifier: "%.0f") this year")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                Text("vs ~$\(projected * 0.28, specifier: "%.0f") without TapSmart")
                                    .font(.system(size: 17))
                                    .foregroundColor(Color(hex: "4ADE80"))
                            }
                            Spacer()
                        }
                        .padding(20)
                        .background(Color(hex: "14B8A6").opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: "14B8A6").opacity(0.4), lineWidth: 1.5)
                        )
                        .cornerRadius(14)

                        // ── Category bars ─────────────────────────────
                        let byCat  = store.savingsByCategory
                        let maxCat = byCat.values.max() ?? 1

                        VStack(spacing: 16) {
                            ForEach(categoryRows(byCat: byCat)) { row in
                                SavingsRow(
                                    category: row.name,
                                    amount:   "$\(Int(row.amount))",
                                    percent:  maxCat > 0 ? row.amount / maxCat : 0,
                                    color:    Color(hex: row.colorHex)
                                )
                            }
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(14)

                        // ── Swift Charts monthly trend ────────────────
                        if #available(iOS 16.0, *) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("MONTHLY TREND")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.4))

                                let data = chartData()
                                Chart(data, id: \.month) { point in
                                    BarMark(
                                        x: .value("Month", point.label),
                                        y: .value("Saved",  point.amount)
                                    )
                                    .foregroundStyle(Color(hex: "14B8A6").gradient)
                                    .cornerRadius(4)
                                }
                                .frame(height: 140)
                                .chartXAxis {
                                    AxisMarks(values: .automatic) { _ in
                                        AxisValueLabel()
                                            .foregroundStyle(Color.white.opacity(0.5))
                                            .font(.system(size: 11))
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks(values: .automatic) { _ in
                                        AxisGridLine()
                                            .foregroundStyle(Color.white.opacity(0.07))
                                        AxisValueLabel()
                                            .foregroundStyle(Color.white.opacity(0.4))
                                            .font(.system(size: 11))
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(14)
                        }

                        // ── Recent transactions ───────────────────────
                        VStack(alignment: .leading, spacing: 12) {
                            Text("RECENT")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))

                            ForEach(store.recentRecords) { rec in
                                NavigationLink(destination: TransactionDetailView(record: rec)) {
                                    HStack(spacing: 14) {
                                        Image(systemName: categoryIcon(rec.category))
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: "14B8A6"))
                                            .frame(width: 36, height: 36)
                                            .background(Color(hex: "14B8A6").opacity(0.12))
                                            .cornerRadius(10)

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(rec.storeName)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.white)
                                            Text(rec.cardName)
                                                .font(.system(size: 13))
                                                .foregroundColor(.white.opacity(0.5))
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 3) {
                                            Text("+$\(rec.amount, specifier: "%.2f")")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(Color(hex: "22C55E"))
                                            Text(rec.date, style: .date)
                                                .font(.system(size: 12))
                                                .foregroundColor(.white.opacity(0.35))
                                        }
                                    }
                                    .padding(14)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }

                            if store.records.count > 10 {
                                NavigationLink(destination: AllTransactionsView()) {
                                    Text("See all \(store.records.count) transactions →")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(hex: "14B8A6"))
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.top, 4)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(14)

                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            } // end else
        }
        .sheet(isPresented: $showLogger) {
            ManualSavingsLogger()
        }
        .sheet(isPresented: $showShare) {
            let text = SavingsSummaryShareSheet.summary(from: store)
            ActivityView(activityItems: [text])
        }
        .sheet(isPresented: $showGoalSheet) {
            goalSheet
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color(hex: "0D1B2A"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - Goal Sheet

    private var goalSheet: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()

            VStack(spacing: 28) {
                Text("Monthly Savings Goal")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 40)

                Text("Set a target for how much you want to save each month using the right cards.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)

                HStack(spacing: 4) {
                    Text("$")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(Color(hex: "14B8A6"))
                    TextField("0", text: $goalInput)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(width: 180)
                }
                .padding(.vertical, 20)

                HStack(spacing: 12) {
                    ForEach([5, 10, 20, 50], id: \.self) { amount in
                        Button {
                            goalInput = "\(amount)"
                        } label: {
                            Text("$\(amount)")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(hex: "14B8A6"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color(hex: "14B8A6").opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(hex: "14B8A6").opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(10)
                        }
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        if let val = Double(goalInput), val > 0 {
                            monthlyGoal = val
                            UserDefaultsStore.monthlyGoal = val
                        }
                        showGoalSheet = false
                    } label: {
                        Text("Set Goal")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(hex: "14B8A6"))
                            .cornerRadius(14)
                    }

                    if monthlyGoal > 0 {
                        Button {
                            monthlyGoal = 0
                            UserDefaultsStore.monthlyGoal = 0
                            showGoalSheet = false
                        } label: {
                            Text("Remove Goal")
                                .font(.system(size: 15))
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

                    Button { showGoalSheet = false } label: {
                        Text("Cancel")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            goalInput = monthlyGoal > 0 ? String(format: "%.0f", monthlyGoal) : ""
        }
    }

    // MARK: - Helpers

    private func yearRangeLabel() -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        let now = Date()
        let jan = Calendar.current.date(
            from: DateComponents(
                year: Calendar.current.component(.year, from: now),
                month: 1)
        ) ?? now
        return "\(f.string(from: jan)) – \(f.string(from: now))"
    }

    private func projectedYearlySavings() -> Double {
        let month = Double(Calendar.current.component(.month, from: Date()))
        return month > 0 ? (store.totalSaved / month) * 12 : 0
    }

    private struct CategoryRow: Identifiable {
        let id      = UUID()
        let name:     String
        let amount:   Double
        let colorHex: String
    }

    private func categoryRows(byCat: [String: Double]) -> [CategoryRow] {
        [
            CategoryRow(name: "Grocery",     amount: byCat["Grocery"]     ?? 0, colorHex: "22C55E"),
            CategoryRow(name: "Dining",      amount: byCat["Dining"]      ?? 0, colorHex: "14B8A6"),
            CategoryRow(name: "Gas",         amount: byCat["Gas"]         ?? 0, colorHex: "D97706"),
            CategoryRow(name: "Shopping",    amount: byCat["Shopping"]    ?? 0, colorHex: "C084FC"),
            CategoryRow(name: "Pharmacy",    amount: byCat["Pharmacy"]    ?? 0, colorHex: "94A3B8"),
            CategoryRow(name: "Electronics", amount: byCat["Electronics"] ?? 0, colorHex: "60A5FA"),
            CategoryRow(name: "Hardware",    amount: byCat["Hardware"]    ?? 0, colorHex: "F97316"),
        ].filter { $0.amount > 0 }
    }

    private struct ChartPoint {
        let month:  Int
        let label:  String
        let amount: Double
    }

    private func chartData() -> [ChartPoint] {
        let trend        = store.monthlyTrend
        let names        = ["Jan","Feb","Mar","Apr","May","Jun",
                            "Jul","Aug","Sep","Oct","Nov","Dec"]
        let currentMonth = Calendar.current.component(.month, from: Date())
        return (1...currentMonth).map { m in
            ChartPoint(month: m, label: names[m - 1], amount: trend[m] ?? 0)
        }
    }

    private func categoryIcon(_ cat: String) -> String {
        switch cat {
        case "Grocery":     return "cart.fill"
        case "Dining":      return "fork.knife"
        case "Gas":         return "fuelpump.fill"
        case "Shopping":    return "bag.fill"
        case "Pharmacy":    return "cross.fill"
        case "Electronics": return "desktopcomputer"
        case "Hardware":    return "hammer.fill"
        default:            return "dollarsign.circle.fill"
        }
    }
}

#Preview {
    NavigationStack {
        SavingsView()
    }
}
