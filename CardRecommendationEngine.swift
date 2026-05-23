import Foundation

// MARK: - Models

struct CardRecommendation: Identifiable {
    let id = UUID()
    let card: RewardRate
    let projectedAnnualGain: Double   // extra dollars vs what user earns now
    let topCategory: String           // category where this card wins most
    let topCategoryGain: Double       // extra % in that category
    let breakdown: [CategoryGain]     // per-category detail
}

struct CategoryGain: Identifiable {
    let id = UUID()
    let category: String
    let mcc: String
    let currentBestRate: Double       // best rate from cards user already owns
    let newCardRate: Double           // rate the candidate card offers
    let annualSpend: Double           // estimated from history
    let extraEarned: Double           // (newCardRate - currentBestRate) / 100 * annualSpend
}

// MARK: - Engine

/// Maps SavingRecord categories → MCC codes (mirrors StoreDatabase templates)
private let categoryToMCC: [String: String] = [
    "Grocery":     "5411",
    "Dining":      "5812",
    "Gas":         "5541",
    "Shopping":    "5999",
    "Pharmacy":    "5912",
    "Electronics": "5734",
    "Hardware":    "5251",
]

/// Assumed average spend per transaction used to estimate category volume.
/// SavingRecord stores the *savings amount*, not the purchase amount, so we
/// back-calculate: amount = (rate - 1) / 100 * 50  →  purchase ≈ $50 per trip.
private let assumedSpendPerVisit: Double = 50.0

final class CardRecommendationEngine {
    static let shared = CardRecommendationEngine()

    /// Returns unowned cards ranked by how much extra cashback they'd have
    /// earned the user based on their actual spending history.
    func recommendations(
        records: [SavingRecord],
        ownedCardIds: [String]
    ) -> [CardRecommendation] {

        let svc = RewardDataService.shared

        // 1. Build annualised spend per MCC from history
        let annualSpend = annualisedSpend(from: records)
        guard !annualSpend.isEmpty else { return [] }

        // 2. For each MCC, find the best rate the user currently gets
        var currentBestRate: [String: Double] = [:]
        for mcc in annualSpend.keys {
            let best = svc.allCards
                .filter { ownedCardIds.contains($0.cardId) }
                .map { svc.rate(for: $0, mcc: mcc) }
                .max() ?? 1.0
            currentBestRate[mcc] = best
        }

        // 3. Score every unowned card
        let candidates = svc.allCards.filter { !ownedCardIds.contains($0.cardId) }

        let scored: [CardRecommendation] = candidates.compactMap { card in
            var breakdown: [CategoryGain] = []

            for (mcc, spend) in annualSpend {
                let newRate     = svc.rate(for: card, mcc: mcc)
                let existingRate = currentBestRate[mcc] ?? 1.0
                guard newRate > existingRate else { continue }

                let extra = (newRate - existingRate) / 100.0 * spend
                let catName = categoryForMCC(mcc)
                breakdown.append(CategoryGain(
                    category:        catName,
                    mcc:             mcc,
                    currentBestRate: existingRate,
                    newCardRate:     newRate,
                    annualSpend:     spend,
                    extraEarned:     extra
                ))
            }

            let totalGain = breakdown.reduce(0) { $0 + $1.extraEarned }
            guard totalGain > 0 else { return nil }

            let topBreakdown = breakdown.max(by: { $0.extraEarned < $1.extraEarned })!

            return CardRecommendation(
                card:                card,
                projectedAnnualGain: totalGain,
                topCategory:         topBreakdown.category,
                topCategoryGain:     topBreakdown.newCardRate - topBreakdown.currentBestRate,
                breakdown:           breakdown.sorted { $0.extraEarned > $1.extraEarned }
            )
        }

        return scored.sorted { $0.projectedAnnualGain > $1.projectedAnnualGain }
    }

    // MARK: - Private helpers

    /// Converts SavingRecord history into annualised spend per MCC.
    /// Each record represents roughly a $50 purchase; we scale to 12 months.
    private func annualisedSpend(from records: [SavingRecord]) -> [String: Double] {
        // Count visits per category
        var visitCount: [String: Int] = [:]
        for rec in records {
            visitCount[rec.category, default: 0] += 1
        }

        // Scale to annual: find how many months of data we have
        let months = monthsOfData(from: records)
        let scale  = months > 0 ? 12.0 / months : 1.0

        var result: [String: Double] = [:]
        for (cat, count) in visitCount {
            guard let mcc = categoryToMCC[cat] else { continue }
            result[mcc] = Double(count) * assumedSpendPerVisit * scale
        }
        return result
    }

    private func monthsOfData(from records: [SavingRecord]) -> Double {
        guard let oldest = records.map(\.date).min(),
              let newest = records.map(\.date).max() else { return 1 }
        let diff = Calendar.current.dateComponents([.month], from: oldest, to: newest)
        return max(1, Double((diff.month ?? 0) + 1))
    }

    private func categoryForMCC(_ mcc: String) -> String {
        categoryToMCC.first(where: { $0.value == mcc })?.key ?? "Other"
    }
}
