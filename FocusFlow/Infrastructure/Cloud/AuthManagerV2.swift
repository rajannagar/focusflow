//
//  AuthManagerV2.swift
//  FocusFlow
//
//  Simplified authentication state manager.
//  Replaces: AuthManager.swift, AuthManager+SupabaseV2.swift, SupabaseAuthManagerV2.swift
//
//  States:
//  - .unknown: App just launched, checking for existing session
//  - .guest: User chose to skip sign in (local data only)
//  - .signedIn(userId): Authenticated with Supabase
//  - .signedOut: Was signed in, now signed out
//

import Foundation
import Combine
import Supabase

// MARK: - Cloud Auth State

/// Authentication state for cloud sync.
/// Named CloudAuthState to avoid conflict with legacy AuthState in AuthManager.
enum CloudAuthState: Equatable {
    case unknown
    case guest
    case signedIn(userId: UUID)
    case signedOut
    
    var isSignedIn: Bool {
        if case .signedIn = self { return true }
        return false
    }
    
    var userId: UUID? {
        if case .signedIn(let id) = self { return id }
        return nil
    }
    
    var isGuest: Bool {
        self == .guest
    }
}

// MARK: - Auth Manager V2

@MainActor
final class AuthManagerV2: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AuthManagerV2()
    
    // MARK: - Published State
    
    @Published private(set) var state: CloudAuthState = .unknown
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    // MARK: - Private
    
    private var authStateTask: Task<Void, Never>?
    private let supabase = SupabaseManager.shared
    
    /// Key for storing guest mode preference
    private let guestModeKey = "AuthManagerV2.isGuestMode"
    
    // MARK: - Init
    
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        authStateTask?.cancel()
    }
    
    // MARK: - Auth State Listener
    
    private func setupAuthStateListener() {
        authStateTask = Task { [weak self] in
            guard let self = self else { return }
            
            // First, check for existing session
            await self.checkInitialSession()
            
            // Then listen for auth state changes
            for await (event, session) in self.supabase.auth.authStateChanges {
                guard !Task.isCancelled else { break }
                
                await MainActor.run {
                    self.handleAuthEvent(event, session: session)
                }
            }
        }
    }
    
    private func checkInitialSession() async {
        // Check if user previously chose guest mode
        if UserDefaults.standard.bool(forKey: guestModeKey) {
            await MainActor.run {
                self.state = .guest
            }
            return
        }
        
        // Check for existing Supabase session
        do {
            let session = try await supabase.auth.session
            await MainActor.run {
                self.state = .signedIn(userId: session.user.id)
                // Set email from session if available and not already set
                if let email = session.user.email, !email.isEmpty {
                    if AppSettings.shared.accountEmail == nil || AppSettings.shared.accountEmail?.isEmpty == true {
                        AppSettings.shared.accountEmail = email
                    }
                }
                // Set display name from session metadata if available and not already set
                setDisplayNameFromSession(session)
                #if DEBUG
                print("[AuthManagerV2] Restored session for user: \(session.user.id), email: \(session.user.email ?? "no email")")
                #endif
            }
        } catch {
            // No existing session
            await MainActor.run {
                self.state = .signedOut
                #if DEBUG
                print("[AuthManagerV2] No existing session")
                #endif
            }
        }
    }
    
    private func handleAuthEvent(_ event: AuthChangeEvent, session: Session?) {
        #if DEBUG
        print("[AuthManagerV2] Auth event: \(event)")
        #endif
        
        switch event {
        case .initialSession:
            if let session = session {
                state = .signedIn(userId: session.user.id)
                // Set email from session if available and not already set
                if let email = session.user.email, !email.isEmpty {
                    if AppSettings.shared.accountEmail == nil || AppSettings.shared.accountEmail?.isEmpty == true {
                        AppSettings.shared.accountEmail = email
                    }
                }
                // Set display name from session metadata if available and not already set
                setDisplayNameFromSession(session)
            } else if UserDefaults.standard.bool(forKey: guestModeKey) {
                state = .guest
            } else {
                state = .signedOut
            }
            
        case .signedIn:
            if let session = session {
                // Clear guest mode when signing in
                UserDefaults.standard.set(false, forKey: guestModeKey)
                state = .signedIn(userId: session.user.id)
                // Set email from session if available and not already set
                if let email = session.user.email, !email.isEmpty {
                    if AppSettings.shared.accountEmail == nil || AppSettings.shared.accountEmail?.isEmpty == true {
                        AppSettings.shared.accountEmail = email
                    }
                }
                // Set display name from session metadata if available and not already set
                setDisplayNameFromSession(session)
            }
            
        case .signedOut:
            state = .signedOut
            
        case .tokenRefreshed:
            // Token refreshed, keep current state
            break
            
        case .userUpdated:
            // User profile updated, keep current state
            break
            
        case .passwordRecovery:
            // Password recovery initiated
            break
            
        case .mfaChallengeVerified:
            // MFA verified
            break
            
        default:
            // Handle any other cases (including future cases from Supabase SDK)
            #if DEBUG
            print("[AuthManagerV2] Unhandled auth event: \(event)")
            #endif
            break
        }
        
        error = nil
    }
    
    // MARK: - Public Actions
    
    /// Enter guest mode (skip sign in)
    func continueAsGuest() {
        UserDefaults.standard.set(true, forKey: guestModeKey)
        state = .guest
        
        #if DEBUG
        print("[AuthManagerV2] Continuing as guest")
        #endif
    }

    /// Exit guest mode and return to signed-out state (shows Auth UI in ContentView).
    /// This does **not** call Supabase signOut because guest mode has no remote session.
    func exitGuest() {
        UserDefaults.standard.set(false, forKey: guestModeKey)
        error = nil
        state = .signedOut

        #if DEBUG
        print("[AuthManagerV2] Exited guest mode")
        #endif
    }
    
    /// Sign in with Apple
    func signInWithApple() async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            try await supabase.auth.signInWithOAuth(
                provider: .apple,
                redirectTo: SupabaseManager.redirectURL
            )
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Sign in with Google
    func signInWithGoogle() async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            try await supabase.auth.signInWithOAuth(
                provider: .google,
                redirectTo: SupabaseManager.redirectURL
            )
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            try await supabase.auth.signIn(email: email, password: password)
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Sign up with email and password
    func signUp(email: String, password: String) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            try await supabase.auth.signUp(email: email, password: password)
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Send password reset email
    func resetPassword(email: String) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Sign out
    func signOut() async {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            try await supabase.auth.signOut()
            UserDefaults.standard.set(false, forKey: guestModeKey)
            state = .signedOut
            
            // ✅ Clear widget data on logout to prevent data leaking between accounts
            await MainActor.run {
                WidgetDataManager.shared.clearAllData()
            }
        } catch {
            self.error = error
            #if DEBUG
            print("[AuthManagerV2] Sign out error: \(error)")
            #endif
        }
    }
    
    /// Upgrade from guest to signed-in user
    /// Call this after successful OAuth or email sign in from guest mode
    func upgradeFromGuest() {
        UserDefaults.standard.set(false, forKey: guestModeKey)
        // State will be updated by auth listener when sign in completes
    }
    
    /// Extracts and sets display name from session user metadata if available
    private func setDisplayNameFromSession(_ session: Session) {
        let userMetadata = session.user.userMetadata
        let appMetadata = session.user.appMetadata
        
        // Helper to extract string from AnyJSON
        func extractString(from json: AnyJSON?) -> String? {
            guard let json = json else { return nil }
            // AnyJSON can be decoded/encoded to extract underlying values
            // Try to get string representation
            if case .string(let value) = json {
                return value
            }
            // Fallback: try to decode as string via JSON
            if let data = try? JSONEncoder().encode(json),
               let decoded = try? JSONDecoder().decode(String.self, from: data) {
                return decoded
            }
            return nil
        }
        
        // Common metadata keys for name: full_name, name, display_name
        var nameFromMetadata: String? = nil
        if let fullName = extractString(from: userMetadata["full_name"]), !fullName.isEmpty {
            nameFromMetadata = fullName
        } else if let name = extractString(from: userMetadata["name"]), !name.isEmpty {
            nameFromMetadata = name
        } else if let displayName = extractString(from: userMetadata["display_name"]), !displayName.isEmpty {
            nameFromMetadata = displayName
        } else if let fullName = extractString(from: appMetadata["full_name"]), !fullName.isEmpty {
            nameFromMetadata = fullName
        } else if let name = extractString(from: appMetadata["name"]), !name.isEmpty {
            nameFromMetadata = name
        }
        
        // Set display name if found and not already set (or only default "You")
        if let name = nameFromMetadata, !name.isEmpty {
            if AppSettings.shared.displayName.isEmpty || AppSettings.shared.displayName == "You" {
                AppSettings.shared.displayName = name
                #if DEBUG
                print("[AuthManagerV2] Set display name from session: \(name)")
                #endif
            }
        }
    }
}

// MARK: - Namespace Helper

extension AuthManagerV2 {
    
    /// Returns the storage namespace key for the current auth state.
    /// - Guest mode: "guest"
    /// - Signed in: user's UUID string
    /// - Otherwise: "guest" (fallback)
    var storageNamespace: String {
        switch state {
        case .signedIn(let userId):
            return userId.uuidString
        case .guest, .unknown, .signedOut:
            return "guest"
        }
    }
}
