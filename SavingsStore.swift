import Foundation
import Combine
import WidgetKit

struct SavingRecord: Codable, Identifiable {
    let id: UUID
    let storeName: String
    let category: String
    let cardName: String
    let amount: Double           // cashback earned above 1% baseline
    let spendAmount: Double      // actual purchase total (new field)
    let date: Date
    let usedBestCard: Bool
}

class SavingsStore: ObservableObject {
    static let shared = SavingsStore()

    @Published private(set) var records: [SavingRecord] = []

    private let key = "ts_saving_records"

    init() { load() }

    // MARK: - Computed

    var totalSaved: Double {
        records.reduce(0) { $0 + $1.amount }
    }

    var savingsByCategory: [String: Double] {
        Dictionary(grouping: records, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }

    var monthlyTrend: [Int: Double] {
        let cal  = Calendar.current
        let year = cal.component(.year, from: Date())
        return Dictionary(
            grouping: records.filter {
                cal.component(.year, from: $0.date) == year
            },
            by: { cal.component(.month, from: $0.date) }
        ).mapValues { $0.reduce(0) { $0 + $1.amount } }
    }

    var recentRecords: [SavingRecord] {
        records.sorted { $0.date > $1.date }.prefix(10).map { $0 }
    }

    // MARK: - Streak

    var currentStreak: Int {
        let sorted = records.sorted { $0.date > $1.date }
        var streak = 0
        for record in sorted {
            if record.usedBestCard { streak += 1 } else { break }
        }
        return streak
    }

    var bestStreak: Int {
        let sorted = records.sorted { $0.date < $1.date }
        var best = 0
        var current = 0
        for record in sorted {
            if record.usedBestCard {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }

    // MARK: - Mutations

    func recordSaving(storeName: String, category: String,
                      cardName: String, bestCashbackPct: Double,
                      spendAmount: Double = 50.0,
                      usedBestCard: Bool = true) {
        let saving = max(0, (bestCashbackPct - 1.0) / 100.0 * spendAmount)
        let record = SavingRecord(
            id:           UUID(),
            storeName:    storeName,
            category:     category,
            cardName:     cardName,
            amount:       saving,
            spendAmount:  spendAmount,
            date:         Date(),
            usedBestCard: usedBestCard
        )
        records.append(record)
        save()
    }

    /// Direct injection for demo seeding — bypasses date/amount calculation.
    /// Do not call from production code paths.
    func injectRecord(_ record: SavingRecord) {
        records.append(record)
        save()
    }

    func reset() {
        records = []
        save()
    }

    func deleteRecord(id: UUID) {
        records.removeAll { $0.id == id }
        save()
    }

    // MARK: - Persistence

    private func save() {
        guard let encoded = try? JSONEncoder().encode(records) else { return }

        UserDefaults.standard.set(encoded, forKey: key)

        if let shared = UserDefaults(suiteName: "group.com.tapsmart.shared") {
            shared.set(encoded, forKey: key)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }

        // 1. Try current format (has spendAmount + usedBestCard)
        if let saved = try? JSONDecoder().decode([SavingRecord].self, from: data) {
            records = saved
            return
        }

        // 2. Migrate v2 records (have usedBestCard but no spendAmount)
        struct V2Record: Codable {
            let id: UUID
            let storeName: String
            let category: String
            let cardName: String
            let amount: Double
            let date: Date
            let usedBestCard: Bool
        }
        if let v2 = try? JSONDecoder().decode([V2Record].self, from: data) {
            records = v2.map {
                SavingRecord(id: $0.id, storeName: $0.storeName,
                             category: $0.category, cardName: $0.cardName,
                             amount: $0.amount, spendAmount: 50.0,
                             date: $0.date, usedBestCard: $0.usedBestCard)
            }
            save()
            return
        }

        // 3. Migrate v1 records (no usedBestCard, no spendAmount)
        struct V1Record: Codable {
            let id: UUID
            let storeName: String
            let category: String
            let cardName: String
            let amount: Double
            let date: Date
        }
        if let v1 = try? JSONDecoder().decode([V1Record].self, from: data) {
            records = v1.map {
                SavingRecord(id: $0.id, storeName: $0.storeName,
                             category: $0.category, cardName: $0.cardName,
                             amount: $0.amount, spendAmount: 50.0,
                             date: $0.date, usedBestCard: true)
            }
            save()
        }
    }
}
