import Foundation

struct AuthAPIUser: Decodable {
    let id: UUID
    let email: String?
}

struct AuthAPISessionResult: Decodable {
    let user: AuthAPIUser
    let accessToken: String?
    let refreshToken: String?   // ✅ NEW

    enum CodingKeys: String, CodingKey {
        case user
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

enum AuthAPIError: Error, LocalizedError {
    case invalidURL
    case serverError(String)
    case decodingError
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid server URL."
        case .serverError(let message): return message
        case .decodingError: return "Failed to read server response."
        case .unknown: return "Something went wrong. Please try again."
        }
    }
}

final class AuthAPI {

    static let shared = AuthAPI()

    // Uses the same project URL + anon key as the rest of the app
    private let config = SupabaseConfig.shared

    // Supabase Edge Functions base path
    private var baseURLString: String {
        config.projectURL.absoluteString + "/functions/v1"
    }

    private init() {}

    // MARK: - Convenience methods (unchanged signatures)

    func signUpWithEmail(email: String, password: String) async throws -> AuthAPIUser {
        let session = try await signUpWithEmailSession(email: email, password: password)
        return session.user
    }

    func loginWithEmail(email: String, password: String) async throws -> AuthAPIUser {
        let session = try await loginWithEmailSession(email: email, password: password)
        return session.user
    }

    func loginWithApple(userIdentifier: String, idToken: String?, email: String?) async throws -> AuthAPIUser {
        let session = try await loginWithAppleSession(userIdentifier: userIdentifier, idToken: idToken, email: email)
        return session.user
    }

    // MARK: - Session methods (return access_token + refresh_token)

    func signUpWithEmailSession(email: String, password: String) async throws -> AuthAPISessionResult {
        try await sendAuthRequestSession(
            path: "/auth-email-signup",
            body: ["email": email, "password": password]
        )
    }

    func loginWithEmailSession(email: String, password: String) async throws -> AuthAPISessionResult {
        try await sendAuthRequestSession(
            path: "/auth-email-login",
            body: ["email": email, "password": password]
        )
    }

    func loginWithAppleSession(userIdentifier: String, idToken: String?, email: String?) async throws -> AuthAPISessionResult {
        try await sendAuthRequestSession(
            path: "/auth-apple",
            body: [
                "apple_user_id": userIdentifier,
                "apple_id_token": idToken ?? "",
                "email": email ?? ""
            ]
        )
    }

    // MARK: - Core request helper

    private func sendAuthRequestSession(path: String, body: [String: Any]) async throws -> AuthAPISessionResult {
        guard let url = URL(string: baseURLString + path) else {
            throw AuthAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Supabase standard headers (Edge Functions accept these)
        request.setValue("Bearer \(config.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AuthAPIError.unknown
        }

        guard (200..<300).contains(http.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8) ?? ""
            throw AuthAPIError.serverError(serverMessage.isEmpty ? "Server returned status \(http.statusCode)" : serverMessage)
        }

        // Decode:
        // Preferred: { user: {id,email}, access_token: "...", refresh_token: "..." }
        // Fallback:  { user: {id,email}, access_token: "..." }
        // Fallback2: { id, email }
        do {
            return try JSONDecoder().decode(AuthAPISessionResult.self, from: data)
        } catch {
            do {
                let user = try JSONDecoder().decode(AuthAPIUser.self, from: data)
                return AuthAPISessionResult(user: user, accessToken: nil, refreshToken: nil)
            } catch {
                print("AuthAPI decode failed. Raw:", String(data: data, encoding: .utf8) ?? "<non-utf8>")
                throw AuthAPIError.decodingError
            }
        }
    }
}
