import Foundation

extension AuthManager {

    @MainActor
    func applySupabaseSignedIn(userId: UUID, email: String?, accessToken: String?) {
        setSupabaseAuthenticated(userId: userId, email: email, accessToken: accessToken)
    }

    @MainActor
    func applySupabaseSignedOut() {
        setSupabaseUnauthenticated()
    }

    @MainActor
    func applySupabaseUnknown() {
        setSupabaseUnknown()
    }
}
