import Foundation
import Combine
import Supabase

/// Single source of truth for authenticated Supabase users (V2).
/// Guest mode stays outside of this (local-only).
@MainActor
final class SupabaseAuthManagerV2: ObservableObject {

    enum State: Equatable {
        case unknown
        case signedOut
        case signedIn(userId: UUID)
    }

    @Published private(set) var state: State = .unknown

    private let supabase: SupabaseClient
    private var sessionTask: Task<Void, Never>?

    init(supabase: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.supabase = supabase
    }

    func start() {
        // Avoid double-start
        sessionTask?.cancel()

        sessionTask = Task { [weak self] in
            guard let self else { return }

            // Initial state
            await self.refresh()

            // Listen for auth changes (Supabase broadcasts auth events)
            for await _ in self.supabase.auth.authStateChanges {
                await self.refresh()
            }
        }
    }

    func stop() {
        sessionTask?.cancel()
        sessionTask = nil
    }

    func refresh() async {
        do {
            let session = try await supabase.auth.session
            state = .signedIn(userId: session.user.id)
        } catch {
            state = .signedOut
        }
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        await refresh()
    }
}
