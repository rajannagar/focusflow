import Foundation
import SwiftUI
import Combine
import UIKit

@MainActor
final class PasswordRecoveryManager: ObservableObject {
    static let shared = PasswordRecoveryManager()

    @Published var isPresenting: Bool = false
    @Published var lastError: String? = nil

    private init() {}

    /// Call this after `SupabaseManager.shared.handleDeepLink(url)` succeeds.
    /// Presents the in-app "Set New Password" flow **only** for recovery links.
    func handleIfRecovery(url: URL) {
        lastError = nil

        guard Self.isRecoveryLink(url) else { return }

        // Best effort: clear any presented modal before showing reset UI
        Self.dismissAnyPresentedModals()

        // Present after a tiny delay so SwiftUI/UIViewController state is clean
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.isPresenting = true
        }
    }

    func clear() {
        isPresenting = false
        lastError = nil
    }

    // MARK: - Recovery link detection

    private static func isRecoveryLink(_ url: URL) -> Bool {
        // Supabase recovery links typically include: type=recovery
        if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if comps.queryItems?.contains(where: {
                $0.name.lowercased() == "type" && ($0.value ?? "").lowercased() == "recovery"
            }) == true {
                return true
            }

            // Many Supabase links put tokens in the fragment: #access_token=...&type=recovery
            if let fragment = comps.fragment, fragment.lowercased().contains("type=recovery") {
                return true
            }
        }

        // Fallback: string check
        return url.absoluteString.lowercased().contains("type=recovery")
    }

    // MARK: - UIKit helpers

    private static func dismissAnyPresentedModals() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        guard let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        if root.presentedViewController != nil {
            root.dismiss(animated: true)
        }
    }
}
