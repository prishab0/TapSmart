import Foundation
import SwiftUI

class PremiumManager: ObservableObject {
    static let shared = PremiumManager()

    @AppStorage("demoUsageCount") var demoUsageCount: Int = 0
    @AppStorage("isPremiumUser") var isPremiumUser: Bool = false

    let freeDemoLimit = 5

    func canUseFeature() -> Bool {
        return isPremiumUser || demoUsageCount < freeDemoLimit
    }

    func registerUse() {
        guard !isPremiumUser else { return }
        demoUsageCount += 1
    }

    func remainingUses() -> Int {
        return max(0, freeDemoLimit - demoUsageCount)
    }
}
