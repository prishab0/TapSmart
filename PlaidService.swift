import Foundation
import Security

// MARK: - Models

/// Returned by your backend's /create_link_token endpoint
struct LinkTokenResponse: Codable {
    let linkToken: String
    enum CodingKeys: String, CodingKey {
        case linkToken = "link_token"
    }
}

/// Returned by your backend's /exchange_public_token endpoint
struct ExchangeTokenResponse: Codable {
    let accessToken: String
    let itemId: String
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case itemId      = "item_id"
    }
}

/// A single credit/charge card returned by Plaid's /accounts/get
struct PlaidCard: Codable, Identifiable {
    let accountId:   String
    let name:        String          // e.g. "Amex Blue Cash Preferred"
    let officialName: String?        // more verbose name Plaid sometimes returns
    let mask:        String?         // last 4 digits
    let subtype:     String?         // "credit card" | "paypal" | etc.
    let isoCurrencyCode: String?

    var id: String { accountId }

    enum CodingKeys: String, CodingKey {
        case accountId      = "account_id"
        case name
        case officialName   = "official_name"
        case mask
        case subtype
        case isoCurrencyCode = "iso_currency_code"
    }
}

struct PlaidAccountsResponse: Codable {
    let accounts: [PlaidCard]
}

// MARK: - Errors

enum PlaidError: LocalizedError {
    case missingBackendURL
    case networkError(String)
    case decodingError(String)
    case keychainError(String)
    case noAccessToken

    var errorDescription: String? {
        switch self {
        case .missingBackendURL:    return "Backend URL not configured."
        case .networkError(let m):  return "Network error: \(m)"
        case .decodingError(let m): return "Decoding error: \(m)"
        case .keychainError(let m): return "Keychain error: \(m)"
        case .noAccessToken:        return "No Plaid access token found. Please re-link your card."
        }
    }
}

// MARK: - PlaidService

/// Handles all communication with your backend Plaid proxy.
/// The client_id and client_secret NEVER live on device — only your backend holds them.
///
/// TODO: Replace backendBaseURL with your actual backend URL before shipping.
///       During development you can run the companion Node/Vercel backend locally
///       and point this at http://localhost:3000
final class PlaidService {

    static let shared = PlaidService()

    // ── TODO: swap this for your real backend URL ──────────────────────────────
    // Sandbox:    point at your local dev server or Vercel preview URL
    // Production: point at your production API
    private let backendBaseURL = "https://YOUR_BACKEND_URL_HERE"
    // ───────────────────────────────────────────────────────────────────────────

    private let keychainAccessTokenKey = "ts_plaid_access_token"
    private let keychainItemIdKey      = "ts_plaid_item_id"

    // MARK: - Link Token (Step 1)

    /// Ask your backend to create a Plaid link_token for this user.
    /// The link_token is short-lived (30 min) and used only to open Plaid Link.
    func createLinkToken(userId: String) async throws -> String {
        guard let url = URL(string: "\(backendBaseURL)/create_link_token") else {
            throw PlaidError.missingBackendURL
        }

        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody   = try JSONEncoder().encode(["user_id": userId])

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTP(response)

        do {
            let decoded = try JSONDecoder().decode(LinkTokenResponse.self, from: data)
            return decoded.linkToken
        } catch {
            throw PlaidError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Public Token Exchange (Step 2)

    /// Called after Plaid Link succeeds with a public_token.
    /// Exchanges it for a permanent access_token via your backend, then stores it in Keychain.
    func exchangePublicToken(_ publicToken: String) async throws {
        guard let url = URL(string: "\(backendBaseURL)/exchange_public_token") else {
            throw PlaidError.missingBackendURL
        }

        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody   = try JSONEncoder().encode(["public_token": publicToken])

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTP(response)

        do {
            let decoded = try JSONDecoder().decode(ExchangeTokenResponse.self, from: data)
            try saveToKeychain(key: keychainAccessTokenKey, value: decoded.accessToken)
            try saveToKeychain(key: keychainItemIdKey,      value: decoded.itemId)
        } catch let e as PlaidError {
            throw e
        } catch {
            throw PlaidError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Fetch Cards (Step 3)

    /// Fetches the user's credit cards from Plaid using the stored access_token.
    /// Filters to credit-card subtypes only.
    func fetchLinkedCards() async throws -> [PlaidCard] {
        guard let accessToken = readFromKeychain(key: keychainAccessTokenKey) else {
            throw PlaidError.noAccessToken
        }

        guard let url = URL(string: "\(backendBaseURL)/accounts") else {
            throw PlaidError.missingBackendURL
        }

        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody   = try JSONEncoder().encode(["access_token": accessToken])

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTP(response)

        do {
            let decoded = try JSONDecoder().decode(PlaidAccountsResponse.self, from: data)
            // Keep only credit cards (subtype == "credit card")
            return decoded.accounts.filter {
                $0.subtype?.lowercased() == "credit card"
            }
        } catch {
            throw PlaidError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - State helpers

    var hasLinkedAccount: Bool {
        readFromKeychain(key: keychainAccessTokenKey) != nil
    }

    /// Call this when the user explicitly unlinks (e.g. "Remove all linked cards")
    func removeLinkedAccount() {
        deleteFromKeychain(key: keychainAccessTokenKey)
        deleteFromKeychain(key: keychainItemIdKey)
    }

    // MARK: - HTTP validation

    private func validateHTTP(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw PlaidError.networkError("HTTP \(code)")
        }
    }

    // MARK: - Keychain helpers

    private func saveToKeychain(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else { return }
        deleteFromKeychain(key: key) // remove old value first

        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData:   data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw PlaidError.keychainError("SecItemAdd failed: \(status)")
        }
    }

    private func readFromKeychain(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let str  = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    private func deleteFromKeychain(key: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
