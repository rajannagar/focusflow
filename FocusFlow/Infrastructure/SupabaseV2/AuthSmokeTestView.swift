import SwiftUI
import Supabase
import Auth

/// Simple view to verify Supabase Auth is wired correctly.
/// You can keep this around behind a debug flag if you want.
struct AuthSmokeTestView: View {
    @State private var log: String = ""
    @State private var isWorking: Bool = false

    // ✅ Use the new provider shape
    private var client: SupabaseClient { SupabaseClientProvider.shared.client }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Text("Supabase Auth Smoke Test")
                    .font(.headline)

                Button {
                    Task { await checkSession() }
                } label: {
                    Text("Check session")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isWorking)

                Button {
                    Task { await signOut() }
                } label: {
                    Text("Sign out")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .disabled(isWorking)

                ScrollView {
                    Text(log.isEmpty ? "No output yet." : log)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.black.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding()
            .navigationTitle("Auth Test")
        }
    }

    private func append(_ line: String) {
        let stamp = ISO8601DateFormatter().string(from: Date())
        log += "[\(stamp)] \(line)\n"
        print(line)
    }

    private func checkSession() async {
        isWorking = true
        defer { isWorking = false }

        do {
            let session = try await client.auth.session
            append("✅ Session exists")
            append("User id: \(session.user.id)")
            append("Email: \(session.user.email ?? "nil")")
        } catch {
            append("ℹ️ No session (or error): \(error.localizedDescription)")
        }
    }

    private func signOut() async {
        isWorking = true
        defer { isWorking = false }

        do {
            try await client.auth.signOut()
            append("✅ Signed out")
        } catch {
            append("❌ Sign out failed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AuthSmokeTestView()
}
