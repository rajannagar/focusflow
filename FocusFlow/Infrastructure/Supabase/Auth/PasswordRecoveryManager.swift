import Foundation
import SwiftUI
import Combine
import UIKit

@MainActor
final class PasswordRecoveryManager: ObservableObject {
    static let shared = PasswordRecoveryManager()

    @Published var isPresenting: Bool = false
    private(set) var recoveryAccessToken: String?

    private init() {}

    func handle(url: URL) {
        // Supabase puts tokens in the fragment: #access_token=...&type=recovery...
        guard let fragment = url.fragment, !fragment.isEmpty else { return }

        let params = Self.parseFragment(fragment)
        let type = params["type"]
        let accessToken = params["access_token"]

        guard type == "recovery", let accessToken, !accessToken.isEmpty else {
            return
        }

        // ✅ Critical: dismiss any currently presented sheet first
        Self.dismissAnyPresentedModals()

        // Keep in-memory only (do NOT persist)
        self.recoveryAccessToken = accessToken

        // Present after a tiny delay so SwiftUI/UIKIt finishes dismissing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.isPresenting = true
        }
    }

    func clear() {
        recoveryAccessToken = nil
        isPresenting = false
    }

    private static func parseFragment(_ fragment: String) -> [String: String] {
        var dict: [String: String] = [:]
        let pairs = fragment.split(separator: "&").map(String.init)

        for pair in pairs {
            let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            let key = parts[0]
            let value = parts[1].removingPercentEncoding ?? parts[1]
            dict[key] = value
        }

        return dict
    }

    private static func dismissAnyPresentedModals() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        guard let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }

        // Dismiss anything presented on top of root (EmailAuth sheet, etc.)
        if root.presentedViewController != nil {
            root.dismiss(animated: true)
        }
    }
}
