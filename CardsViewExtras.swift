import SwiftUI

// MARK: - CardsView+Compare
//
// This file provides:
//   1. ComparePickerView  — lets the user pick two cards to compare, then
//                          launches CardCompareView.
//   2. AllTransactionsView — full searchable/filterable list of all savings
//                           records. Used by SavingsView "See all" link.

struct ComparePickerView: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss

    private var ownedCards: [RewardRate] {
        RewardDataService.shared.allCards
            .filter { UserDefaultsStore.userCards.contains($0.cardId) && !$0.isDebit }
    }

    @State private var leftId:  String = ""
    @State private var rightId: String = ""
    @State private var showCompare = false

    private var canCompare: Bool {
        !leftId.isEmpty && !rightId.isEmpty && leftId != rightId
    }

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    Spacer()
                    Text("Compare Cards")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)

                // vs. display
                HStack(spacing: 16) {
                    cardSlot(id: $leftId, label: "Card A")
                    Text("vs")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.white.opacity(0.3))
                    cardSlot(id: $rightId, label: "Card B")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

                // Card picker list
                ScrollView {
                    VStack(spacing: 0) {
                        Text("PICK TWO CARDS FROM YOUR WALLET")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.35))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)

                        ForEach(ownedCards) { card in
                            let isLeft     = leftId  == card.cardId
                            let isRight    = rightId == card.cardId
                            let isSelected = isLeft || isRight

                            HStack(spacing: 14) {
                                Text(card.bank)
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.white)
                                    .minimumScaleFactor(0.7)
                                    .frame(width: 54, height: 32)
                                    .background(Color(hex: card.bankColor))
                                    .cornerRadius(6)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(card.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Text(card.note)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.45))
                                        .lineLimit(1)
                                }

                                Spacer()

                                if isLeft {
                                    slotBadge("A", color: "14B8A6")
                                } else if isRight {
                                    slotBadge("B", color: "F59E0B")
                                } else {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white.opacity(0.2))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 13)
                            .background(
                                isSelected
                                    ? Color(hex: isLeft ? "14B8A6" : "F59E0B").opacity(0.08)
                                    : Color.clear
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.25)) {
                                    if isLeft               { leftId  = "" }
                                    else if isRight         { rightId = "" }
                                    else if leftId.isEmpty  { leftId  = card.cardId }
                                    else if rightId.isEmpty { rightId = card.cardId }
                                    else                    { leftId  = card.cardId }
                                }
                            }

                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 1)
                                .padding(.leading, 20)
                        }
                    }
                }

                // Compare CTA
                if canCompare {
                    Button { showCompare = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 16))
                            Text("Compare These Cards")
                                .font(.system(size: 17, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(hex: "14B8A6"))
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.3), value: canCompare)
        .sheet(isPresented: $showCompare) {
            CardCompareView(leftId: leftId, rightId: rightId)
        }
    }

    private func cardSlot(id: Binding<String>, label: String) -> some View {
        let card = RewardDataService.shared.allCards.first { $0.cardId == id.wrappedValue }
        return VStack(spacing: 6) {
            if let card {
                Text(card.bank)
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: card.bankColor))
                    .cornerRadius(8)
                Text(card.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.15),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                    .frame(height: 38)
                    .overlay(
                        Text(label)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.3))
                    )
                Text("Tap a card below")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func slotBadge(_ letter: String, color: String) -> some View {
        Text(letter)
            .font(.system(size: 13, weight: .black))
            .foregroundColor(.white)
            .frame(width: 28, height: 28)
            .background(Color(hex: color))
            .clipShape(Circle())
    }
}

// MARK: - AllTransactionsView

struct AllTransactionsView: View {
    // FIX: Use @ObservedObject (not @StateObject) when referencing a shared singleton.
    // @StateObject would create a new instance, breaking the Binding and causing
    // "Cannot call value of non-function type 'Binding<Subject>'" errors.
    @ObservedObject private var store = SavingsStore.shared
    @State private var searchText = ""
    @State private var filterCat  = "All"

    private let categories = [
        "All", "Grocery", "Dining", "Gas", "Shopping",
        "Pharmacy", "Electronics", "Hardware", "Travel", "Hotels"
    ]

    private var filtered: [SavingRecord] {
        let q = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        return store.records
            .sorted { $0.date > $1.date }
            .filter { rec in
                let matchesCat   = filterCat == "All" || rec.category == filterCat
                let matchesQuery = q.isEmpty
                    || rec.storeName.lowercased().contains(q)
                    || rec.cardName.lowercased().contains(q)
                    || rec.category.lowercased().contains(q)
                return matchesCat && matchesQuery
            }
    }

    var body: some View {
        ZStack {
            Color(hex: "0D1B2A").ignoresSafeArea()
            VStack(spacing: 0) {
                searchBar
                categoryPills
                resultsHeader
                transactionList
            }
        }
        .navigationTitle("All Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color(hex: "0D1B2A"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - Sub-views (extracted to keep type-checker happy)

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.4))
                .font(.system(size: 15))

            TextField("", text: $searchText)
                .placeholder(when: searchText.isEmpty) {
                    Text("Search stores, cards, categories…")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.system(size: 15))
                }
                .foregroundColor(.white)
                .font(.system(size: 15))
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.white.opacity(0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    searchText.isEmpty
                        ? Color.white.opacity(0.1)
                        : Color(hex: "14B8A6").opacity(0.5),
                    lineWidth: 1.5
                )
        )
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    Button {
                        withAnimation(.spring(response: 0.25)) { filterCat = cat }
                    } label: {
                        Text(cat)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(filterCat == cat ? .white : .white.opacity(0.55))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                filterCat == cat
                                    ? Color(hex: "14B8A6")
                                    : Color.white.opacity(0.07)
                            )
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }

    private var resultsHeader: some View {
        let total = filtered.reduce(0.0) { $0 + $1.amount }
        return HStack {
            Text("\(filtered.count) transaction\(filtered.count == 1 ? "" : "s")")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.35))
            Spacer()
            Text("Total: $\(total, specifier: "%.2f")")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "14B8A6"))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var transactionList: some View {
        if filtered.isEmpty {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.2))
                Text("No matching transactions")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.35))
            }
            Spacer()
        } else {
            List {
                ForEach(filtered) { rec in
                    NavigationLink(destination: TransactionDetailView(record: rec)) {
                        TransactionRow(record: rec)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
                .onDelete { indexSet in
                    // FIX: deleteRecord(id:) added to SavingsStore — see SavingsStore.swift
                    for i in indexSet {
                        store.deleteRecord(id: filtered[i].id)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

// MARK: - TransactionRow

struct TransactionRow: View {
    let record: SavingRecord

    private var categoryColor: String {
        switch record.category {
        case "Grocery":     return "22C55E"
        case "Dining":      return "F97316"
        case "Gas":         return "D97706"
        case "Shopping":    return "C084FC"
        case "Pharmacy":    return "94A3B8"
        case "Electronics": return "60A5FA"
        case "Hardware":    return "F97316"
        case "Travel":      return "14B8A6"
        case "Hotels":      return "F59E0B"
        default:            return "14B8A6"
        }
    }

    private var categoryIcon: String {
        switch record.category {
        case "Grocery":     return "cart.fill"
        case "Dining":      return "fork.knife"
        case "Gas":         return "fuelpump.fill"
        case "Shopping":    return "bag.fill"
        case "Pharmacy":    return "cross.fill"
        case "Electronics": return "desktopcomputer"
        case "Hardware":    return "hammer.fill"
        case "Travel":      return "airplane"
        case "Hotels":      return "building.2.fill"
        default:            return "dollarsign.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: categoryIcon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: categoryColor))
                .frame(width: 36, height: 36)
                .background(Color(hex: categoryColor).opacity(0.12))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.storeName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    Text(record.cardName)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(1)
                    if !record.usedBestCard {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "F97316"))
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("+$\(record.amount, specifier: "%.2f")")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "22C55E"))
                Text(record.date, style: .date)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }
}

// MARK: - Previews

#Preview("Compare Picker") {
    ComparePickerView()
}

#Preview("All Transactions") {
    NavigationStack {
        AllTransactionsView()
    }
}
