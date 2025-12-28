import Foundation
import Supabase

// MARK: - Row model (what we read back)
struct FFProfileRow: Codable {
    let id: UUID
    let user_id: UUID
    let display_name: String
    let tagline: String
    let created_at: String?
    let updated_at: String?
}

// MARK: - Upsert payload (must be Encodable)
private struct FFProfileUpsertPayload: Encodable {
    let user_id: UUID
    let display_name: String
    let tagline: String
}

enum SupabaseDBSmokeTest {

    static func upsertAndFetchProfile() async throws -> FFProfileRow {
        let supabase = SupabaseClientProvider.shared.client
        let userId = try await supabase.auth.session.user.id

        // 1) Upsert a profile row for this user (by unique user_id)
        let payload = FFProfileUpsertPayload(
            user_id: userId,
            display_name: "Rajan (Test)",
            tagline: "Cloud Sync Test"
        )

        _ = try await supabase
            .from("ff_profiles")
            .upsert(payload, onConflict: "user_id")
            .execute()

        // 2) Fetch it back
        let response = try await supabase
            .from("ff_profiles")
            .select("id,user_id,display_name,tagline,created_at,updated_at")
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()

        let decoder = JSONDecoder()
        return try decoder.decode(FFProfileRow.self, from: response.data)
    }
}
