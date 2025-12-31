import Foundation
import SwiftUI
import Combine
import UIKit

/// Tracks what auth flow the user initiated (before the deep link arrives)
enum PendingAuthFlow: String {
    case none
    case signup          // User just created account, waiting for email confirmation
    case passwordReset   // User just requested password reset
}

/// Manages auth flow states for password recovery and email verification
@MainActor
final class PasswordRecoveryManager: ObservableObject {
    static let shared = PasswordRecoveryManager()

    /// Shows the "Set New Password" sheet
    @Published var isPresentingPasswordReset: Bool = false
    
    /// Shows the "Email Verified" success sheet
    @Published var isPresentingEmailVerified: Bool = false
    
    @Published var lastError: String? = nil
    
    /// Tracks what flow the user initiated (so we know what to show when deep link arrives)
    @Published var pendingFlow: PendingAuthFlow = .none
    
    // UserDefaults key for persistence (in case app is killed)
    private let pendingFlowKey = "focusflow.pendingAuthFlow"
    
    // Legacy compatibility
    var isPresenting: Bool {
        get { isPresentingPasswordReset }
        set { isPresentingPasswordReset = newValue }
    }

    private init() {
        // Restore pending flow from UserDefaults
        if let stored = UserDefaults.standard.string(forKey: pendingFlowKey),
           let flow = PendingAuthFlow(rawValue: stored) {
            pendingFlow = flow
        }
    }
    
    /// Call this when user initiates signup
    func setPendingSignup() {
        pendingFlow = .signup
        UserDefaults.standard.set(PendingAuthFlow.signup.rawValue, forKey: pendingFlowKey)
        #if DEBUG
        print("[PasswordRecoveryManager] Set pending flow: signup")
        #endif
    }
    
    /// Call this when user initiates password reset
    func setPendingPasswordReset() {
        pendingFlow = .passwordReset
        UserDefaults.standard.set(PendingAuthFlow.passwordReset.rawValue, forKey: pendingFlowKey)
        #if DEBUG
        print("[PasswordRecoveryManager] Set pending flow: passwordReset")
        #endif
    }
    
    /// Clear pending flow
    func clearPendingFlow() {
        pendingFlow = .none
        UserDefaults.standard.removeObject(forKey: pendingFlowKey)
    }

    /// Handle auth deep link - determines type and shows appropriate UI
    /// NOTE: This is now mostly handled in FocusFlowApp.handleIncomingURL
    /// This method is kept for backwards compatibility
    func handleAuthDeepLink(url: URL) {
        #if DEBUG
        print("[PasswordRecoveryManager] handleAuthDeepLink called (legacy)")
        #endif
        lastError = nil
    }
    
    /// Legacy method for backwards compatibility
    func handleIfRecovery(url: URL) {
        handleAuthDeepLink(url: url)
    }

    func clear() {
        isPresentingPasswordReset = false
        isPresentingEmailVerified = false
        lastError = nil
        clearPendingFlow()
    }
    
    func clearEmailVerified() {
        isPresentingEmailVerified = false
    }
    
    func clearPasswordReset() {
        isPresentingPasswordReset = false
    }

    // MARK: - Link Type Detection
    
    enum AuthLinkType {
        case signup      // Email confirmation
        case recovery    // Password reset
        case magiclink   // Passwordless login
        case emailChange // Email address change
        case unknown
    }

    static func detectLinkType(_ url: URL) -> AuthLinkType {
        let urlString = url.absoluteString.lowercased()
        
        // Check query parameters first
        if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            // Check query items
            if let typeItem = comps.queryItems?.first(where: { $0.name.lowercased() == "type" }) {
                let typeValue = typeItem.value?.lowercased() ?? ""
                switch typeValue {
                case "recovery":
                    return .recovery
                case "signup":
                    return .signup
                case "magiclink":
                    return .magiclink
                case "email_change":
                    return .emailChange
                default:
                    break
                }
            }
            
            // Check fragment (Supabase sometimes puts params there)
            if let fragment = comps.fragment?.lowercased() {
                if fragment.contains("type=recovery") {
                    return .recovery
                } else if fragment.contains("type=signup") {
                    return .signup
                } else if fragment.contains("type=magiclink") {
                    return .magiclink
                } else if fragment.contains("type=email_change") {
                    return .emailChange
                }
            }
        }
        
        // Fallback: string check
        if urlString.contains("type=recovery") {
            return .recovery
        } else if urlString.contains("type=signup") {
            return .signup
        } else if urlString.contains("type=magiclink") {
            return .magiclink
        }
        
        return .unknown
    }

    // MARK: - UIKit helpers

    private static func dismissAnyPresentedModals() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        guard let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        
        // Dismiss all presented modals
        var current = root.presentedViewController
        while current != nil {
            current?.dismiss(animated: false)
            current = root.presentedViewController
        }
    }
}
