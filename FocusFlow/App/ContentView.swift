import SwiftUI

// ---------------------------------------------------------
// MARK: - Main Content View (Launch → Auth → App)
// ---------------------------------------------------------

struct ContentView: View {
    @State private var showLaunch = true

    // Pro entitlement manager comes from the App root (single instance)
    @EnvironmentObject private var pro: ProEntitlementManager

    // Observe global auth state
    @ObservedObject private var authManager = AuthManager.shared

    // Password recovery manager (sheet presentation)
    @StateObject private var recovery = PasswordRecoveryManager.shared

    var body: some View {
        ZStack {

            // MARK: - Main App Layer
            Group {
                switch authManager.state {
                case .unknown:
                    Color.black.ignoresSafeArea()

                case .unauthenticated:
                    AuthLandingView()

                case .authenticated:
                    mainTabs
                }
            }
            .opacity(showLaunch ? 0 : 1)

            // MARK: - Launch Overlay
            if showLaunch {
                FocusFlowLaunchView()
                    .transition(.opacity)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.6), value: showLaunch)
        .onAppear {
            authManager.restoreSessionIfNeeded()

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                showLaunch = false
            }
        }
        // MARK: - Recovery Sheet
        .sheet(isPresented: $recovery.isPresenting) {
            if let token = recovery.recoveryAccessToken, !token.isEmpty {
                SetNewPasswordView(accessToken: token) {
                    recovery.clear()
                }
            } else {
                // Safety fallback
                VStack(spacing: 12) {
                    Text("Invalid recovery link.")
                        .font(.headline)
                    Button("Close") {
                        recovery.clear()
                    }
                }
                .padding()
            }
        }
    }

    private var mainTabs: some View {
        TabView {
            FocusView()
                .tabItem { Label("Focus", systemImage: "timer") }

            // ✅ New Tasks tab (v1 shell)
            TasksView()
                .tabItem { Label("Tasks", systemImage: "checklist") }

            HabitsView()
                .tabItem { Label("Habits", systemImage: "checkmark.circle") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle") }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings.shared)
        .environmentObject(ProEntitlementManager())
}
