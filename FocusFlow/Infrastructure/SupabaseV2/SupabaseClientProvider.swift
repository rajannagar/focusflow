import Foundation
import Supabase
import Auth

@MainActor
final class SupabaseClientProvider {
    static let shared = SupabaseClientProvider()

    let client: SupabaseClient
    let redirectURL: URL

    private init() {
        // 1) Read Info.plist values
        let plist = Bundle.main.infoDictionary ?? [:]

        guard let urlString = plist["SUPABASE_URL"] as? String,
              !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            fatalError("Missing SUPABASE_URL in Info.plist. Add SUPABASE_URL as a String.")
        }

        guard let anonKey = plist["SUPABASE_ANON_KEY"] as? String,
              !anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            fatalError("Missing SUPABASE_ANON_KEY in Info.plist. Add SUPABASE_ANON_KEY as a String.")
        }

        guard let supabaseURL = URL(string: urlString) else {
            fatalError("SUPABASE_URL is not a valid URL.")
        }

        // 2) Build redirect URL from bundle identifier:
        // ca.softcomputers.FocusFlow://login-callback
        let scheme = Bundle.main.bundleIdentifier ?? "ca.softcomputers.FocusFlow"
        guard let redirect = URL(string: "\(scheme)://login-callback") else {
            fatalError("Unable to build redirect URL from bundle identifier.")
        }
        self.redirectURL = redirect

        // 3) Configure Supabase client with global redirectToURL (prevents localhost fallback)
        let options = SupabaseClientOptions(
            auth: .init(
                redirectToURL: redirectURL,
                flowType: .pkce
            )
        )

        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: anonKey,
            options: options
        )

        print("✅ Supabase configured")
        print("   URL:", supabaseURL.absoluteString)
        print("   Redirect:", redirectURL.absoluteString)
    }
}
