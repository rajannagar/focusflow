import Foundation
import SwiftUI
import Combine
import UIKit
import Supabase
import Auth

@MainActor
final class PasswordRecoveryManager: ObservableObject {
    static let shared = PasswordRecoveryManager()

    @Published var isPresenting: Bool = false
    @Published var lastError: String? = nil

    private init() {}

    func handle(url: URL) {
        lastError = nil

        // ✅ Dismiss any currently presented modal first
        Self.dismissAnyPresentedModals()

        Task {
            do {
                // ✅ Supabase v2 deep-link handling (recovery / magic link / oauth)
                _ = try await SupabaseManager.shared.client.auth.session(from: url)

                // Present after a tiny delay so SwiftUI/UIViewController state is clean
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.isPresenting = true
                }
            } catch {
                self.lastError = error.localizedDescription
                print("❌ Recovery handle failed:", error)
            }
        }
    }

    func clear() {
        isPresenting = false
        lastError = nil
    }

    private static func dismissAnyPresentedModals() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        guard let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        if root.presentedViewController != nil {
            root.dismiss(animated: true)
        }
    }
}
