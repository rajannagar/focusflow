import Foundation
import Combine
import Supabase

/// Bridges SupabaseAuthManagerV2 -> AuthManager (legacy UI state)
/// so you can keep existing screens while we clean up old auth later.
@MainActor
final class AppAuthBridgeV2 {

    static let shared = AppAuthBridgeV2()

    private let supabase = SupabaseClientProvider.shared.client
    private let supabaseAuth = SupabaseAuthManagerV2()

    private var cancellables = Set<AnyCancellable>()
    private var started = false

    private init() {}

    func start() {
        guard !started else { return }
        started = true

        supabaseAuth.start()

        supabaseAuth.$state
            .removeDuplicates()
            .sink { state in
                Task { @MainActor in
                    await self.apply(state)
                }
            }
            .store(in: &cancellables)
    }

    private func apply(_ state: SupabaseAuthManagerV2.State) async {
        // Never override guest mode
        if let s = AuthManager.shared.currentUserSession, s.isGuest {
            return
        }

        switch state {
        case .unknown:
            AuthManager.shared.applySupabaseUnknown()

        case .signedOut:
            AuthManager.shared.applySupabaseSignedOut()

        case .signedIn:
            do {
                let session = try await supabase.auth.session
                AuthManager.shared.applySupabaseSignedIn(
                    userId: session.user.id,
                    email: session.user.email,
                    accessToken: session.accessToken
                )
            } catch {
                AuthManager.shared.applySupabaseSignedOut()
            }
        }
    }
}
