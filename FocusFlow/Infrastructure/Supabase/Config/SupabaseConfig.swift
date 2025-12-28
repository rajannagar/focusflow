import Foundation

struct SupabaseConfig {
    static let shared = SupabaseConfig()

    /// FocusFlow project URL
    let projectURL: URL

    /// Anon key (safe to ship)
    let anonKey: String

    private init() {
        // ✅ NEW project URL (your FocusFlow project)
        self.projectURL = URL(string: "https://grcelvuzlayxrrokojpg.supabase.co")!

        // ✅ NEW anon public key (the one you pasted)
        self.anonKey =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyY2VsdnV6bGF5eHJyb2tvanBnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY3OTI4NzAsImV4cCI6MjA4MjM2ODg3MH0.Ibjy2icZOIEZFq9mIe7y8C7twbq4fSXpMTh1JPqMHdw"
    }
}
