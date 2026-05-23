import SwiftUI

// MARK: - SpendingGoalView
// A goal-progress ring the user can set in Settings (UserDefaultsStore.monthlyGoal).
// Drop into SavingsView between the hero section and the chart.
//
// Usage:
//   SpendingGoalView(store: store)

struct SpendingGoalView: View {

    let store: SavingsStore

    @State private var goal: Double = UserDefaultsStore.monthlyGoal
    @State private var showGoalEditor = false

    private var currentMonthSavings: Double {
        let month = Calendar.current.component(.month, from: Date())
        let year  = Calendar.current.component(.year,  from: Date())
        return store.records
            .filter {
                Calendar.current.component(.month, from: $0.date) == month &&
                Calendar.current.component(.year,  from: $0.date) == year
            }
            .reduce(0) { $0 + $1.amount }
    }

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(currentMonthSavings / goal, 1.0)
    }

    private var progressColor: String {
        switch progress {
        case 0..<0.33:  return "14B8A6"
        case 0.33..<0.66: return "F59E0B"
        default:        return "22C55E"
        }
    }

    var body: some View {
        HStack(spacing: 20) {

            // ── Ring ───────────────────────────────────────────
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color(hex: progressColor),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: progress)

                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.white)
                    Text("of goal")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
            .frame(width: 80, height: 80)

            // ── Details ────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                Text("This month's goal")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$\(currentMonthSavings, specifier: "%.2f")")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(Color(hex: progressColor))
                    Text("/ $\(goal, specifier: "%.0f")")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.4))
                }

                if goal > 0 {
                    let remaining = max(0, goal - currentMonthSavings)
                    Text(remaining > 0
                         ? "$\(remaining, specifier: "%.2f") to go"
                         : "Goal reached! 🎉")
                        .font(.system(size: 13))
                        .foregroundColor(
                            remaining > 0
                                ? .white.opacity(0.5)
                                : Color(hex: "22C55E")
                        )
                } else {
                    Button { showGoalEditor = true } label: {
                        Text("Set a monthly goal →")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "14B8A6"))
                    }
                }
            }

            Spacer()

            // ── Edit button ────────────────────────────────────
            if goal > 0 {
                Button { showGoalEditor = true } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.25))
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.04))
        .cornerRadius(18)
        .sheet(isPresented: $showGoalEditor) {
            GoalEditorSheet(goal: $goal)
        }
    }
}

// MARK: - GoalEditorSheet

private struct GoalEditorSheet: View {
    @Binding var goal: Double
    @State private var draft: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()

            VStack(spacing: 28) {
                Text("Monthly Savings Goal")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 36)

                Text("How much do you want to save in cashback each month?")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                HStack(spacing: 8) {
                    Text("$")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(Color(hex: "14B8A6"))

                    TextField("0", text: $draft)
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(.white)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 160)
                }
                .padding(20)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                // Quick-pick buttons
                HStack(spacing: 12) {
                    ForEach([5, 10, 20, 50], id: \.self) { amount in
                        Button { draft = "\(amount)" } label: {
                            Text("$\(amount)")
                                .font(.system(size: 14, weight: .bold))
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

                Button {
                    let parsed = Double(draft) ?? 0
                    goal = parsed
                    UserDefaultsStore.monthlyGoal = parsed
                    dismiss()
                } label: {
                    Text("Save Goal")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(hex: "14B8A6"))
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)

                if goal > 0 {
                    Button {
                        goal = 0
                        UserDefaultsStore.monthlyGoal = 0
                        dismiss()
                    } label: {
                        Text("Remove goal")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "DC2626"))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .onAppear {
            draft = goal > 0 ? String(format: "%.0f", goal) : ""
        }
    }
}

#Preview {
    VStack {
        SpendingGoalView(store: SavingsStore.shared)
    }
    .padding(20)
    .background(Color(hex: "0D1B2A"))
}
