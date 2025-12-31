//
//  SupabaseManager.swift
//  FocusFlow
//
//  Single source of truth for Supabase client configuration.
//  Replaces: SupabaseConfig.swift, SupabaseClientProvider.swift
//

import Foundation
import Supabase

/// Central manager for Supabase client access.
/// Use `SupabaseManager.shared.client` for all database operations.
@MainActor
final class SupabaseManager {
    
    // MARK: - Singleton
    
    static let shared = SupabaseManager()
    
    // MARK: - Public Properties
    
    /// The Supabase client instance. Use this for all operations.
    let client: SupabaseClient
    
    // MARK: - Configuration
    
    /// Deep link scheme for OAuth callbacks (matches Info.plist URL scheme)
    static let redirectScheme = "ca.softcomputers.FocusFlow"
    static let redirectURL = URL(string: "\(redirectScheme)://login-callback")!
    
    // MARK: - Private Init
    
    private init() {
        // Load from Info.plist (set these in your Xcode project)
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              let supabaseURL = URL(string: url) else {
            fatalError("Missing SUPABASE_URL or SUPABASE_ANON_KEY in Info.plist")
        }
        
        // Configure client with PKCE auth flow
        // Parameter order: redirectToURL first, then flowType (Supabase Swift SDK v2)
        // Set emitLocalSessionAsInitialSession to opt-in to new behavior that ensures
        // locally stored session is always emitted, regardless of validity or expiration
        let config = SupabaseClientOptions(
            auth: SupabaseClientOptions.AuthOptions(
                redirectToURL: Self.redirectURL,
                flowType: .pkce,
                emitLocalSessionAsInitialSession: true
            )
        )
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: key,
            options: config
        )
        
        #if DEBUG
        print("[SupabaseManager] Initialized with URL: \(url)")
        #endif
    }
    
    // MARK: - Convenience Accessors
    
    /// Quick access to auth
    var auth: AuthClient {
        client.auth
    }
    
    /// Quick access to database
    /// Note: Direct database access is deprecated in favor of client.from(_:), client.rpc(_:params:), or client.schema(_:)
    /// This property is kept for backward compatibility with existing code
    @available(*, deprecated, message: "Use client.from(_:), client.rpc(_:params:), or client.schema(_:) instead")
    var database: PostgrestClient {
        client.database
    }
    
    /// Current user ID (if signed in)
    var currentUserId: UUID? {
        client.auth.currentUser?.id
    }
    
    /// Check if user is authenticated
    var isAuthenticated: Bool {
        client.auth.currentUser != nil
    }
}

// MARK: - Deep Link Handling

extension SupabaseManager {
    
    /// Handle OAuth callback URLs. Call this from your App's onOpenURL handler.
    /// - Parameter url: The callback URL
    /// - Returns: True if the URL was handled
    @discardableResult
    func handleDeepLink(_ url: URL) async -> Bool {
        // Case-insensitive comparison (iOS may lowercase the scheme)
        guard url.scheme?.lowercased() == Self.redirectScheme.lowercased() else {
            #if DEBUG
            print("[SupabaseManager] Scheme mismatch: \(url.scheme ?? "nil") vs \(Self.redirectScheme)")
            #endif
            return false
        }
        
        do {
            try await client.auth.session(from: url)
            #if DEBUG
            print("[SupabaseManager] Deep link handled successfully")
            #endif
            return true
        } catch {
            #if DEBUG
            print("[SupabaseManager] Deep link error: \(error.localizedDescription)")
            print("[SupabaseManager] Full error: \(error)")
            #endif
            return false
        }
    }
}
