import Foundation
import Combine
import Supabase

/// Minimal realtime subscriber wrapper.
/// We’ll wire real-time DB syncing later; for now this just compiles cleanly.
@MainActor
final class SupabaseRealtimeSubscriber: ObservableObject {
    private let client: SupabaseClient

    @Published private(set) var isConnected: Bool = false
    private var cancellables = Set<AnyCancellable>()

    // ✅ Default uses provider.client
    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }

    /// Placeholder connect method (no-op for now).
    /// We'll implement actual channel subscriptions after DB schema + RLS are ready.
    func connect() {
        isConnected = true
    }

    func disconnect() {
        isConnected = false
    }
}
