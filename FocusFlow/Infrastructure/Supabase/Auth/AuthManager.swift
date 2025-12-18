import Foundation
import Combine

/// Represents whether the user is logged in or not.
enum AuthState {
    case unknown
    case unauthenticated
    case authenticated(UserSession)
}

/// Minimal info about the logged-in user.
/// `isGuest` lets us distinguish Skip users from real accounts.
/// `accessToken` is required for Supabase RLS / REST calls (habits/stats/preferences sync).
struct UserSession {
    let userId: UUID
    let email: String?
    let isGuest: Bool
    let accessToken: String?
}

/// Central place that knows the current auth state and exposes it to SwiftUI.
/// Handles persisting session + silently refreshing access tokens using refresh_token.
final class AuthManager: ObservableObject {

    static let shared = AuthManager()

    @Published private(set) var state: AuthState = .unknown

    private init() {}

    // MARK: - Keys

    private let kUserId = "currentUserId"
    private let kEmail = "currentUserEmail"
    private let kIsGuest = "currentUserIsGuest"
    private let kAccessToken = "currentUserAccessToken"
    private let kRefreshToken = "currentUserRefreshToken"

    // MARK: - Supabase config

    private let config: SupabaseConfig = .shared

    // MARK: - Refresh control

    private let refreshQueue = DispatchQueue(label: "AuthManager.refresh.queue", qos: .utility)
    private var refreshInFlight = false

    // MARK: - Convenience accessors

    var currentUserSession: UserSession? {
        if case .authenticated(let session) = state { return session }
        return nil
    }

    var currentUserId: UUID? {
        currentUserSession?.userId
    }

    var currentAccessToken: String? {
        currentUserSession?.accessToken
    }

    // MARK: - Session restore

    /// Call this once when the app launches to restore a previous session.
    func restoreSessionIfNeeded() {
        let defaults = UserDefaults.standard

        guard let storedId = defaults.string(forKey: kUserId),
              let uuid = UUID(uuidString: storedId) else {
            state = .unauthenticated
            return
        }

        let storedEmail = defaults.string(forKey: kEmail)
        let isGuest = defaults.bool(forKey: kIsGuest)
        var accessToken = defaults.string(forKey: kAccessToken)
        let refreshToken = defaults.string(forKey: kRefreshToken)

        // If guest, do not attempt token refresh.
        if isGuest {
            let session = UserSession(userId: uuid, email: storedEmail, isGuest: true, accessToken: nil)
            state = .authenticated(session)
            return
        }

        // If access token is expired, clear it from storage/state,
        // then try to refresh silently if we have a refresh token.
        if let t = accessToken, !t.isEmpty, JWTToken.isExpired(t) {
            defaults.removeObject(forKey: kAccessToken)
            accessToken = nil
            print("AuthManager: stored access token expired; cleared. Will refresh if possible.")
        }

        let session = UserSession(
            userId: uuid,
            email: storedEmail,
            isGuest: false,
            accessToken: accessToken
        )
        state = .authenticated(session)

        // If we’re missing a valid access token but have refresh token, refresh silently.
        if (accessToken == nil || accessToken?.isEmpty == true),
           let rt = refreshToken, !rt.isEmpty {
            refreshAccessTokenIfPossible(reason: "restoreSession")
            print("Token Refreshed")
        } else if refreshToken == nil || refreshToken?.isEmpty == true {
            if accessToken == nil || accessToken?.isEmpty == true {
                print("AuthManager: no refresh token. Sync will remain disabled until re-login.")
            }
        }
    }

    // MARK: - Login completion

    /// Call this after a successful login.
    /// `isGuest` = true when user tapped "Skip for now".
    /// Pass BOTH accessToken + refreshToken for future-proof silent refresh.
    func completeLogin(
        userId: UUID,
        email: String?,
        isGuest: Bool = false,
        accessToken: String? = nil,
        refreshToken: String? = nil
    ) {
        let defaults = UserDefaults.standard
        defaults.set(userId.uuidString, forKey: kUserId)

        if let email = email {
            defaults.set(email, forKey: kEmail)
        } else {
            defaults.removeObject(forKey: kEmail)
        }

        defaults.set(isGuest, forKey: kIsGuest)

        if let accessToken = accessToken, !accessToken.isEmpty {
            defaults.set(accessToken, forKey: kAccessToken)
        } else {
            defaults.removeObject(forKey: kAccessToken)
        }

        if let refreshToken = refreshToken, !refreshToken.isEmpty {
            defaults.set(refreshToken, forKey: kRefreshToken)
        } else {
            defaults.removeObject(forKey: kRefreshToken)
        }

        let session = UserSession(
            userId: userId,
            email: email,
            isGuest: isGuest,
            accessToken: accessToken
        )
        state = .authenticated(session)

        // After a real (non-guest) login, ensure a profile row exists in Supabase.
        if !isGuest {
            ensureCloudProfile(for: session)
        }
    }

    // MARK: - Token refresh

    func refreshAccessTokenIfPossible(reason: String) {
        refreshQueue.async { [weak self] in
            guard let self else { return }
            guard self.refreshInFlight == false else { return }
            guard case .authenticated(let s) = self.state, s.isGuest == false else { return }

            let defaults = UserDefaults.standard
            guard let refreshToken = defaults.string(forKey: self.kRefreshToken),
                  !refreshToken.isEmpty else {
                print("AuthManager: no refresh token. Sync will remain disabled until re-login.")
                return
            }

            self.refreshInFlight = true

            Task {
                defer { self.refreshQueue.async { self.refreshInFlight = false } }

                do {
                    let result = try await self.performRefresh(refreshToken: refreshToken)

                    // Persist new tokens
                    defaults.set(result.accessToken, forKey: self.kAccessToken)
                    if let newRT = result.refreshToken, !newRT.isEmpty {
                        defaults.set(newRT, forKey: self.kRefreshToken)
                    }

                    // Update published state on main thread
                    await MainActor.run {
                        if case .authenticated(let current) = self.state {
                            self.state = .authenticated(
                                UserSession(
                                    userId: current.userId,
                                    email: current.email,
                                    isGuest: current.isGuest,
                                    accessToken: result.accessToken
                                )
                            )
                        }
                    }

                    print("AuthManager: refreshed access token. reason=\(reason)")
                } catch {
                    await MainActor.run {
                        self.clearAccessTokenOnly_NoRefresh()
                    }
                    print("AuthManager: refresh failed. Sync will remain disabled until re-login. error=\(error)")
                }
            }
        }
    }

    /// Used by sync engines if they get a 401 / JWT expired.
    func clearAccessTokenButKeepUser() {
        clearAccessTokenOnly_NoRefresh()
        print("AuthManager: access token cleared (user kept signed in). Will refresh if possible.")
        refreshAccessTokenIfPossible(reason: "401FromAPI")
    }

    private func clearAccessTokenOnly_NoRefresh() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: kAccessToken)

        if case .authenticated(let s) = state {
            state = .authenticated(
                UserSession(
                    userId: s.userId,
                    email: s.email,
                    isGuest: s.isGuest,
                    accessToken: nil
                )
            )
        }
    }

    // MARK: - Logout

    func signOut() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: kUserId)
        defaults.removeObject(forKey: kEmail)
        defaults.removeObject(forKey: kIsGuest)
        defaults.removeObject(forKey: kAccessToken)
        defaults.removeObject(forKey: kRefreshToken)

        state = .unauthenticated

        let settings = AppSettings.shared
        settings.displayName = ""
        settings.tagline = ""
        settings.profileImageData = nil
    }

    // MARK: - Private helpers

    private func ensureCloudProfile(for session: UserSession) {
        Task {
            do {
                guard let token = session.accessToken, !token.isEmpty else {
                    print("AuthManager: ensureCloudProfile skipped (missing access token).")
                    return
                }

                // ✅ FIX: your fetchProfile now needs accessToken too
                if let _ = try await UserProfileAPI.shared.fetchProfile(
                    for: session.userId,
                    accessToken: token
                ) {
                    return
                }

                _ = try await UserProfileAPI.shared.upsertProfile(
                    for: session.userId,
                    fullName: nil,
                    displayName: nil,
                    email: session.email,
                    accessToken: token
                )
            } catch {
                print("AuthManager: failed to ensure user profile:", error)
            }
        }
    }

    // MARK: - Supabase refresh request

    private struct RefreshResponse: Decodable {
        let access_token: String
        let refresh_token: String?
    }

    private struct RefreshResult {
        let accessToken: String
        let refreshToken: String?
    }

    /// POST {project}/auth/v1/token?grant_type=refresh_token
    private func performRefresh(refreshToken: String) async throws -> RefreshResult {
        var comps = URLComponents(
            url: config.projectURL.appendingPathComponent("auth/v1/token"),
            resolvingAgainstBaseURL: false
        )
        comps?.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]
        guard let url = comps?.url else { throw URLError(.badURL) }

        let body = try JSONSerialization.data(withJSONObject: ["refresh_token": refreshToken], options: [])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(config.anonKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1

        guard (200...299).contains(status) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "AuthManager.Refresh", code: status, userInfo: ["body": bodyText])
        }

        let decoded = try JSONDecoder().decode(RefreshResponse.self, from: data)
        return RefreshResult(accessToken: decoded.access_token, refreshToken: decoded.refresh_token)
    }
}
