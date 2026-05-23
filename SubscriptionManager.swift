import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {

    static let shared = SubscriptionManager()

    static let premiumProductID = "com.tapsmart.premium.monthly"

    @Published private(set) var isPremium: Bool = false
    @Published private(set) var usesThisMonth: Int = 0
    @Published var showPaywall: Bool = false

    static let freeMonthlyLimit = 5

    var usesRemaining: Int {
        max(0, SubscriptionManager.freeMonthlyLimit - usesThisMonth)
    }

    var isAtLimit: Bool {
        !isPremium && usesThisMonth >= SubscriptionManager.freeMonthlyLimit
    }

    private var product: Product?
    private var transactionListener: Task<Void, Error>?

    private let usesKey      = "ts_free_uses_count"
    private let usesMonthKey = "ts_free_uses_month"

    init() {
        loadUsage()
        transactionListener = listenForTransactions()
        Task { await refreshPremiumStatus() }
    }

    deinit {
        transactionListener?.cancel()
    }

    @discardableResult
    func recordUse() -> Bool {
        if isPremium { return true }
        if usesThisMonth >= SubscriptionManager.freeMonthlyLimit {
            showPaywall = true
            return false
        }
        usesThisMonth += 1
        persistUsage()
        return true
    }

    func canUse() -> Bool {
        isPremium || usesThisMonth < SubscriptionManager.freeMonthlyLimit
    }

    // MARK: - StoreKit

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [SubscriptionManager.premiumProductID])
            product = products.first
        } catch {
            print("TapSmart: failed to load product — \(error)")
        }
    }

    func purchase() async {
        guard let product else {
            await loadProduct()
            guard let product else { return }
            await doPurchase(product)
            return
        }
        await doPurchase(product)
    }

    private func doPurchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshPremiumStatus()
                showPaywall = false
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("TapSmart: purchase error — \(error)")
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshPremiumStatus()
        } catch {
            print("TapSmart: restore error — \(error)")
        }
    }

    func refreshPremiumStatus() async {
        var found = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == SubscriptionManager.premiumProductID,
               transaction.revocationDate == nil {
                found = true
                break
            }
        }
        isPremium = found
        if found { showPaywall = false }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.refreshPremiumStatus()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let value): return value
        }
    }

    // MARK: - Persistence

    private func loadUsage() {
        let currentMonth = monthString()
        let savedMonth   = UserDefaults.standard.string(forKey: usesMonthKey) ?? ""
        if savedMonth == currentMonth {
            usesThisMonth = UserDefaults.standard.integer(forKey: usesKey)
        } else {
            usesThisMonth = 0
            persistUsage()
        }
    }

    private func persistUsage() {
        UserDefaults.standard.set(usesThisMonth, forKey: usesKey)
        UserDefaults.standard.set(monthString(), forKey: usesMonthKey)
    }

    private func monthString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f.string(from: Date())
    }

    // MARK: - Demo / testing

    func resetUsageForTesting() {
        usesThisMonth = 0
        isPremium = false          // ← added: properly resets premium flag
        showPaywall = false
        persistUsage()
    }

    func enableDemoMode() {
        isPremium     = true
        usesThisMonth = 0
        showPaywall   = false
    }
}

enum StoreError: Error {
    case failedVerification
}
