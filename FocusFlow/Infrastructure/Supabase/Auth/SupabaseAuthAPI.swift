import Foundation

enum SupabaseAuthAPIError: Error {
    case badURL
    case badResponse(status: Int, body: String)
    case missingTokens
}

final class SupabaseAuthAPI {
    static let shared = SupabaseAuthAPI()
    private init() {}

    private let config: SupabaseConfig = .shared

    struct RefreshResponse: Decodable {
        let access_token: String?
        let refresh_token: String?
        let expires_in: Int?
        let token_type: String?
    }

    // ---------------------------------------------------------
    // MARK: - Refresh Token
    // ---------------------------------------------------------
    /// Refresh Supabase access token using refresh_token.
    /// POST /auth/v1/token?grant_type=refresh_token  (form-encoded)
    func refresh(refreshToken: String) async throws -> (accessToken: String, refreshToken: String) {
        guard let url = URL(string: "\(config.projectURL.absoluteString)/auth/v1/token?grant_type=refresh_token") else {
            throw SupabaseAuthAPIError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let encoded = refreshToken.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? refreshToken
        request.httpBody = "refresh_token=\(encoded)".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1

        guard (200...299).contains(status) else {
            let raw = String(data: data, encoding: .utf8) ?? ""
            throw SupabaseAuthAPIError.badResponse(status: status, body: raw)
        }

        let decoded = try JSONDecoder().decode(RefreshResponse.self, from: data)

        guard
            let newAccess = decoded.access_token, !newAccess.isEmpty,
            let newRefresh = decoded.refresh_token, !newRefresh.isEmpty
        else {
            throw SupabaseAuthAPIError.missingTokens
        }

        return (newAccess, newRefresh)
    }

    // ---------------------------------------------------------
    // MARK: - Password Reset Email
    // ---------------------------------------------------------
    /// Sends a password reset email using Supabase Auth:
    /// POST /auth/v1/recover  (JSON)
    ///
    /// `redirect_to` ensures the email link opens the app via deep link.
    func sendPasswordReset(email: String) async throws {
        guard let url = URL(string: "\(config.projectURL.absoluteString)/auth/v1/recover") else {
            throw SupabaseAuthAPIError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "email": email,
            "redirect_to": "focusflow://auth"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1

        guard (200...299).contains(status) else {
            let raw = String(data: data, encoding: .utf8) ?? ""
            throw SupabaseAuthAPIError.badResponse(status: status, body: raw)
        }
    }

    // ---------------------------------------------------------
    // MARK: - Update Password (Recovery Flow)
    // ---------------------------------------------------------
    /// Uses the recovery access token to set a new password:
    /// PUT /auth/v1/user
    ///
    /// - Parameter accessToken: The recovery `access_token` from the deep link fragment.
    func updatePassword(accessToken: String, newPassword: String) async throws {
        guard let url = URL(string: "\(config.projectURL.absoluteString)/auth/v1/user") else {
            throw SupabaseAuthAPIError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT" // ✅ PATCH -> PUT (more reliable across setups)
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let payload: [String: Any] = [
            "password": newPassword
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1

        guard (200...299).contains(status) else {
            let raw = String(data: data, encoding: .utf8) ?? ""
            print("Supabase updatePassword failed status=\(status) body=\(raw)")
            throw SupabaseAuthAPIError.badResponse(status: status, body: raw)
        }
    }
}
