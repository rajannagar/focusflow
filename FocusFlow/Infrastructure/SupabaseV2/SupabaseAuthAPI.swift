import Foundation
import Supabase
import Auth

enum SupabaseAuthAPIError: Error {
    case missingSession
}

@MainActor
final class SupabaseAuthAPI {
    static let shared = SupabaseAuthAPI()
    private init() {}

    private var client: SupabaseClient { SupabaseClientProvider.shared.client }
    private var redirectURL: URL { SupabaseClientProvider.shared.redirectURL }

    // MARK: - Email Auth

    /// Returns an AuthResponse (may or may not include session depending on email confirmations).
    func signUp(email: String, password: String) async throws -> AuthResponse {
        try await client.auth.signUp(
            email: email,
            password: password,
            redirectTo: redirectURL
        )
    }

    /// Returns a Session on successful login.
    func signIn(email: String, password: String) async throws -> Session {
        try await client.auth.signIn(
            email: email,
            password: password
        )
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Password Reset

    func sendPasswordReset(email: String) async throws {
        // ✅ Passing redirectTo here too (in addition to global config) avoids edge cases.
        try await client.auth.resetPasswordForEmail(
            email,
            redirectTo: redirectURL
        )
    }

    /// Updates password for the CURRENT authenticated session (recovery flow sets session first).
    func updatePassword(newPassword: String) async throws {
        _ = try await client.auth.update(
            user: UserAttributes(password: newPassword)
        )
    }

    // MARK: - Recovery Deep Link (PKCE or implicit)
    /// For PKCE: link has ?code=...
    /// For implicit: link may have #access_token=...&refresh_token=...&type=recovery
    func handleRecovery(url: URL) async throws {
        // PKCE flow: code in query
        if let code = url.queryItem(named: "code"), !code.isEmpty {
            _ = try await client.auth.exchangeCodeForSession(authCode: code)
            return
        }

        // Implicit flow: tokens in fragment
        guard let fragment = url.fragment, !fragment.isEmpty else {
            return
        }

        let params = Self.parseFragment(fragment)
        let type = params["type"]
        let accessToken = params["access_token"]
        let refreshToken = params["refresh_token"]

        guard type == "recovery",
              let accessToken, !accessToken.isEmpty,
              let refreshToken, !refreshToken.isEmpty
        else {
            return
        }

        _ = try await client.auth.setSession(accessToken: accessToken, refreshToken: refreshToken)
    }

    private static func parseFragment(_ fragment: String) -> [String: String] {
        var dict: [String: String] = [:]
        let pairs = fragment.split(separator: "&").map(String.init)
        for pair in pairs {
            let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            dict[parts[0]] = parts[1].removingPercentEncoding ?? parts[1]
        }
        return dict
    }
}

// MARK: - URL helper
private extension URL {
    func queryItem(named name: String) -> String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == name })?
            .value
    }
}
