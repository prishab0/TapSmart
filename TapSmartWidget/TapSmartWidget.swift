import WidgetKit
import SwiftUI

// MARK: - Shared data model
// Must stay in sync with SavingsStore.SavingRecord.
// spendAmount added in v2 — decoder uses default 50.0 for old records.
// NOTE: Not private — TapSmartLargeWidget.swift also uses this type.

struct WidgetSavingRecord: Codable {
    let id: UUID
    let storeName: String
    let category: String
    let cardName: String
    let amount: Double
    let spendAmount: Double     // matches SavingsStore migration
    let date: Date
    let usedBestCard: Bool

    // Coding keys let us supply a default for spendAmount when it's absent
    // (old records written before the migration).
    enum CodingKeys: String, CodingKey {
        case id, storeName, category, cardName, amount, spendAmount, date, usedBestCard
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(UUID.self,   forKey: .id)
        storeName    = try c.decode(String.self, forKey: .storeName)
        category     = try c.decode(String.self, forKey: .category)
        cardName     = try c.decode(String.self, forKey: .cardName)
        amount       = try c.decode(Double.self, forKey: .amount)
        spendAmount  = (try? c.decode(Double.self, forKey: .spendAmount)) ?? 50.0
        date         = try c.decode(Date.self,   forKey: .date)
        usedBestCard = (try? c.decode(Bool.self, forKey: .usedBestCard)) ?? true
    }
}

// MARK: - Timeline Entry

struct TapSmartEntry: TimelineEntry {
    let date: Date
    let totalSaved: Double
    let recentCard: String
    let recentStore: String
    let projectedYearly: Double
}

// MARK: - Timeline Provider

struct TapSmartProvider: TimelineProvider {

    private let key      = "ts_saving_records"
    private let suiteName = "group.com.tapsmart.shared"

    func placeholder(in context: Context) -> TapSmartEntry {
        TapSmartEntry(date: .now,
                      totalSaved: 42.50,
                      recentCard: "Amex Blue Cash Preferred",
                      recentStore: "Trader Joe's",
                      projectedYearly: 510)
    }

    func getSnapshot(in context: Context,
                     completion: @escaping (TapSmartEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<TapSmartEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry()], policy: .after(next)))
    }

    // MARK: - Private

    private func entry() -> TapSmartEntry {
        let records   = loadRecords()
        let total     = records.reduce(0) { $0 + $1.amount }
        let recent    = records.sorted { $0.date > $1.date }.first

        let month     = Double(Calendar.current.component(.month, from: .now))
        let projected = month > 0 ? (total / month) * 12 : 0

        return TapSmartEntry(
            date:            .now,
            totalSaved:      total,
            recentCard:      recent?.cardName  ?? "—",
            recentStore:     recent?.storeName ?? "—",
            projectedYearly: projected
        )
    }

    func loadRecords() -> [WidgetSavingRecord] {
        guard
            let defaults = UserDefaults(suiteName: suiteName),
            let data     = defaults.data(forKey: key),
            let records  = try? JSONDecoder().decode([WidgetSavingRecord].self, from: data)
        else { return [] }
        return records
    }
}

// MARK: - Widget Views

struct TapSmartWidgetEntryView: View {
    var entry: TapSmartEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:  smallView
        case .systemMedium: mediumView
        default:            smallView
        }
    }

    private var smallView: some View {
        ZStack {
            Color(hex: "0D1B2A")
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "14B8A6"))
                    Text("TAPSMART")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "14B8A6"))
                }
                Spacer()
                Text("$\(entry.totalSaved, specifier: "%.2f")")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "4ADE80"))
                    .minimumScaleFactor(0.7)
                Text("saved this year")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                Text("~$\(entry.projectedYearly, specifier: "%.0f") projected")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "14B8A6"))
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private var mediumView: some View {
        ZStack {
            Color(hex: "0D1B2A")
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "14B8A6"))
                        Text("TAPSMART")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "14B8A6"))
                    }
                    Spacer()
                    Text("$\(entry.totalSaved, specifier: "%.2f")")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "4ADE80"))
                        .minimumScaleFactor(0.7)
                    Text("saved this year")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    Text("~$\(entry.projectedYearly, specifier: "%.0f") projected")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "14B8A6"))
                }
                .padding(14)
                .frame(maxHeight: .infinity, alignment: .leading)

                Divider()
                    .background(Color.white.opacity(0.12))

                VStack(alignment: .leading, spacing: 6) {
                    Text("LAST SAVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                    Text(entry.recentStore)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(entry.recentCard)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(2)
                    Link(destination: URL(string: "tapsmart://savings")!) {
                        Text("View Savings →")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "14B8A6"))
                    }
                }
                .padding(14)
                .frame(maxHeight: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Widget Declaration

struct TapSmartWidget: Widget {
    let kind = "TapSmartWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TapSmartProvider()) { entry in
            TapSmartWidgetEntryView(entry: entry)
                .containerBackground(Color(hex: "0D1B2A"), for: .widget)
        }
        .configurationDisplayName("TapSmart Savings")
        .description("Track your cashback savings at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Color+Hex
// Internal (not private) so TapSmartLargeWidget.swift in the same target can use it.

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    TapSmartWidget()
} timeline: {
    TapSmartEntry(date: .now, totalSaved: 42.50,
                  recentCard: "Amex BCP", recentStore: "Trader Joe's",
                  projectedYearly: 510)
}
