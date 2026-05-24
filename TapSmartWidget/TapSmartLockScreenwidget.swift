import WidgetKit
import SwiftUI

// MARK: - TapSmartLockScreenWidget
// An accessoryRectangular Lock Screen / StandBy widget showing:
//   • Total saved  •  Best card shortcut
//
// Add this widget to TapSmartWidgetBundle alongside the existing two widgets.
//
// ALSO: replace TapSmartWidgetBundle.swift body with:
//
//   var body: some Widget {
//       TapSmartWidget()
//       TapSmartLargeWidget()
//       TapSmartLockScreenWidget()
//   }
//
// All types below share the existing TapSmartProvider and TapSmartEntry
// defined in TapSmartWidget.swift (same target, internal visibility).

// MARK: - Accessory Rectangular (lock screen, wide)

struct TapSmartAccessoryRectView: View {
    var entry: TapSmartEntry

    var body: some View {
        HStack(spacing: 10) {
            // Left: icon + total
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text("TAPSMART")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(.secondary)

                Text("$\(entry.totalSaved, specifier: "%.2f")")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.7)
            }

            Divider()

            // Right: last save
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.recentStore)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(entry.recentCard)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .widgetURL(URL(string: "tapsmart://savings"))
    }
}

// MARK: - Accessory Circular (lock screen, round)

struct TapSmartAccessoryCircularView: View {
    var entry: TapSmartEntry

    var body: some View {
        ZStack {
            // Background fill — uses .widgetBackground
            AccessoryWidgetBackground()

            VStack(spacing: 1) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 11, weight: .bold))
                Text("$\(entry.totalSaved, specifier: "%.0f")")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .foregroundColor(.primary)
        }
        .widgetURL(URL(string: "tapsmart://savings"))
    }
}

// MARK: - Accessory Inline (lock screen, single line above clock)

struct TapSmartAccessoryInlineView: View {
    var entry: TapSmartEntry

    var body: some View {
        // Inline widgets render as a single attributed string / label
        Label {
            Text("$\(entry.totalSaved, specifier: "%.2f") saved · \(entry.recentStore)")
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        } icon: {
            Image(systemName: "creditcard.fill")
        }
        .widgetURL(URL(string: "tapsmart://savings"))
    }
}

// MARK: - Widget entry view router (handles all accessory families)

struct TapSmartAccessoryEntryView: View {
    var entry: TapSmartEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryRectangular: TapSmartAccessoryRectView(entry: entry)
        case .accessoryCircular:    TapSmartAccessoryCircularView(entry: entry)
        case .accessoryInline:      TapSmartAccessoryInlineView(entry: entry)
        default:                    TapSmartAccessoryRectView(entry: entry)
        }
    }
}

// MARK: - Widget declaration

struct TapSmartLockScreenWidget: Widget {
    let kind = "TapSmartLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TapSmartProvider()) { entry in
            TapSmartAccessoryEntryView(entry: entry)
                // Lock screen widgets don't use containerBackground color —
                // pass .clear so the system renders the standard glass backing.
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("TapSmart Lock Screen")
        .description("Savings total and last store on your Lock Screen.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline
        ])
    }
}

// MARK: - Updated WidgetBundle
// Replace TapSmartWidgetBundle.swift with this entire file, OR just update
// the body of TapSmartWidgetBundle to include TapSmartLockScreenWidget().

// struct TapSmartWidgetBundle: WidgetBundle {
//     var body: some Widget {
//         TapSmartWidget()
//         TapSmartLargeWidget()
//         TapSmartLockScreenWidget()   // ← add this line
//     }
// }

// MARK: - Previews

#Preview("Accessory Rectangular", as: .accessoryRectangular) {
    TapSmartLockScreenWidget()
} timeline: {
    TapSmartEntry(date: .now, totalSaved: 42.50,
                  recentCard: "Amex BCP", recentStore: "Trader Joe's",
                  projectedYearly: 510)
}

#Preview("Accessory Circular", as: .accessoryCircular) {
    TapSmartLockScreenWidget()
} timeline: {
    TapSmartEntry(date: .now, totalSaved: 42.50,
                  recentCard: "Amex BCP", recentStore: "Trader Joe's",
                  projectedYearly: 510)
}

#Preview("Accessory Inline", as: .accessoryInline) {
    TapSmartLockScreenWidget()
} timeline: {
    TapSmartEntry(date: .now, totalSaved: 42.50,
                  recentCard: "Amex BCP", recentStore: "Trader Joe's",
                  projectedYearly: 510)
}
