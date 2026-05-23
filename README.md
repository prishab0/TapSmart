# TapSmart

**The right credit card, the moment you walk in.**

TapSmart uses geofencing to detect when you're near a store and instantly surfaces the card in your wallet that earns the most rewards there — delivered as a lock-screen notification before you even reach the register.

---

## How It Works

1. **You walk toward a store.** TapSmart's geofence fires.
2. **You get a notification.** "You're at Trader Joe's — Amex Blue Cash Preferred earns 6% here."
3. **You tap to pay.** One-tap Apple Pay with the recommended card pre-selected.

No manual lookup. No switching apps. Just tap and go.

---

## Features

| | Free | Premium |
|---|---|---|
| Card recommendations | 5 / month | Unlimited |
| Lock-screen & banner notifications | ✅ | ✅ |
| Full card name in notifications | ✅ | ✅ |
| One-tap Apple Pay with best card | — | ✅ |
| Spending insights & savings tracker | — | ✅ |
| Proactive alerts & card-of-the-month | — | ✅ |
| Home screen widget | — | ✅ |

---

## Tech Stack

- **SwiftUI** — 100% declarative UI
- **CoreLocation** — geofencing via `CLLocationManager` region monitoring
- **UserNotifications** — local push notifications with deep-link routing
- **StoreKit 2** — in-app subscription (`com.tapsmart.premium.monthly`)
- **Plaid LinkKit** — card linking and transaction sync
- **WidgetKit** — home screen and lock screen widgets
- **Swift Charts** — savings and spending visualizations

---

## Project Structure

```
TapSmart/
├── LocationManager.swift        # Geofence setup & notification trigger
├── RewardDataService.swift      # Card → MCC reward rate lookup engine
├── CardRecommendationEngine.swift
├── SubscriptionManager.swift    # StoreKit 2 freemium logic (5 free uses/month)
├── ProactiveAlertsEngine.swift  # Proactive reward alerts
├── ApplePayHandler.swift        # One-tap Apple Pay integration
├── PlaidService.swift           # Plaid card linking
├── CardsView.swift              # Main recommendation UI
├── LockScreenView.swift         # Geofence demo + in-app banner
├── SavingsView.swift            # Cumulative rewards tracker
├── SpendingInsightsView.swift   # Spending breakdown by category
├── AlertsView.swift             # Proactive alerts feed
├── PaywallView.swift            # Premium upgrade flow
└── TapSmartWidget/              # WidgetKit extension
```

---

## Getting Started

### Requirements
- Xcode 15+
- iOS 17+ deployment target
- A physical device for geofencing (simulator doesn't fire region events)

### Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/YOUR_USERNAME/TapSmart.git
   ```

2. Open `TapSmart.xcodeproj` in Xcode.

3. Set your development team under **Signing & Capabilities**.

4. Add your Plaid `client_id` and environment config in `PlaidService.swift`.

5. To test geofencing without walking to a store, use the **Live** tab in the app — it lets you simulate entering any store in your list.

---

## Freemium Model

Free users get **5 card lookups per month**. On the 6th attempt, the notification still fires (so they know they're at a store) but the card name is hidden behind an upgrade prompt. The counter resets on the 1st of each month.

Premium is a monthly auto-renewing subscription managed entirely through StoreKit 2 — no backend required.

---

## Status

Active development. Core geofencing, notification, and recommendation flows are complete. Currently working on: expanding the MCC → reward rate database, Plaid transaction auto-categorization, and App Store submission.

---

*Built in Pittsburgh. Applying to YC S26.*
