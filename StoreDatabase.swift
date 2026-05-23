import Foundation
import CoreLocation

class StoreDatabase {
    static let shared = StoreDatabase()

    struct Template {
        let name: String
        let mcc: String
        let category: String
        let radius: Double
    }

    // ── First 7 are shown in the simulate buttons (prefix(7)) ──
    // Deliberately one per category so every cashback rate is demonstrated.
    // Costco is included so users can see a debit card (Discover Cashback Debit)
    // earning 1% alongside credit cards earning up to 6% at the same store.
    let templates: [Template] = [
        Template(name: "Trader Joe's",   mcc: "5411", category: "Grocery",     radius: 100),
        Template(name: "Starbucks",      mcc: "5812", category: "Dining",      radius: 80),
        Template(name: "Shell",          mcc: "5541", category: "Gas",         radius: 80),
        Template(name: "Target",         mcc: "5999", category: "Shopping",    radius: 150),
        Template(name: "CVS",            mcc: "5912", category: "Pharmacy",    radius: 80),
        Template(name: "Best Buy",       mcc: "5734", category: "Electronics", radius: 150),
        Template(name: "Costco",         mcc: "5411", category: "Grocery",     radius: 200),

        // ── Remaining stores (geofenced but not in simulate buttons) ──
        Template(name: "Whole Foods",    mcc: "5411", category: "Grocery",     radius: 100),
        Template(name: "Kroger",         mcc: "5411", category: "Grocery",     radius: 120),
        Template(name: "Safeway",        mcc: "5411", category: "Grocery",     radius: 100),
        Template(name: "Amazon Fresh",   mcc: "5411", category: "Grocery",     radius: 100),
        Template(name: "Chipotle",       mcc: "5812", category: "Dining",      radius: 80),
        Template(name: "McDonald's",     mcc: "5812", category: "Dining",      radius: 80),
        Template(name: "Chick-fil-A",    mcc: "5812", category: "Dining",      radius: 80),
        Template(name: "Panera Bread",   mcc: "5812", category: "Dining",      radius: 80),
        Template(name: "Chevron",        mcc: "5541", category: "Gas",         radius: 80),
        Template(name: "Arco",           mcc: "5541", category: "Gas",         radius: 80),
        Template(name: "76 Station",     mcc: "5541", category: "Gas",         radius: 80),
        Template(name: "Walmart",        mcc: "5999", category: "Shopping",    radius: 200),
        Template(name: "Walgreens",      mcc: "5912", category: "Pharmacy",    radius: 80),
        Template(name: "Home Depot",     mcc: "5251", category: "Hardware",    radius: 200),
    ]

    /// Builds Store values for geofencing only — no reward data baked in.
    /// Best-card recommendations are computed live in each view using
    /// RewardDataService so they always reflect the user's current card selection.
    func makeStores(near coordinate: CLLocationCoordinate2D) -> [Store] {
        // Spread fake demo coordinates around the given location.
        // In production, replace with a Places API lookup.
        return templates.enumerated().map { idx, t in
            let angle = Double(idx) / Double(templates.count) * 2 * .pi
            let dist  = 0.003 + Double(idx % 4) * 0.001
            let lat   = coordinate.latitude  + dist * cos(angle)
            let lon   = coordinate.longitude + dist * sin(angle)

            return Store(
                name:       t.name,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                category:   t.category,
                mcc:        t.mcc,
                radius:     t.radius
            )
        }
    }
}
