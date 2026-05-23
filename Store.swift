import Foundation
import CoreLocation

struct Store: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let category: String
    let mcc: String
    let radius: Double
}

struct CardOption: Identifiable {
    let id = UUID()
    let bank: String
    let bankColor: String
    let name: String
    let category: String
    let cashback: String
    let isBest: Bool
    let isDebit: Bool           // NEW — true for debit cards
}
