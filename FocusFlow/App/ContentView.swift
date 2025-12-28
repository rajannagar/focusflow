import SwiftUI

enum AppTab: Int, Hashable {
    case focus = 0
    case tasks = 1
    case progress = 2
    case profile = 3
}

struct ContentView: View {
    @State private var showLaunch = true
    @State private var selectedTab: AppTab = .focus
    @State private var navigateToJourney = false

    @EnvironmentObject private var pro: ProEntitlementManager
    
    // ✅ Updated to use AuthManagerV2
    @ObservedObject private var authManager = AuthManagerV2.shared

    // ✅ Use ObservedObject for a singleton
    @ObservedObject private var recovery = PasswordRecoveryManager.shared

    var body: some View {
        ZStack {
            Group {
                // ✅ Updated to use CloudAuthState cases
                switch authManager.state {
                case .unknown:
                    // Still loading auth state
                    Color.black.ignoresSafeArea()

                case .signedOut:
                    // User signed out - show auth landing
                    AuthLandingView()

                case .guest, .signedIn:
                    // Guest mode OR signed in - show main app
                    mainTabs
                }
            }
            .opacity(showLaunch ? 0 : 1)

            if showLaunch {
                FocusFlowLaunchView()
                    .transition(.opacity)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.6), value: showLaunch)
        .onAppear {
            // ✅ AuthManagerV2 auto-restores session on init, no need to call manually
            // authManager.restoreSessionIfNeeded() - removed

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                showLaunch = false
            }
        }
        .sheet(isPresented: $recovery.isPresenting) {
            SetNewPasswordView {
                recovery.clear()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationCenterManager.navigateToDestination)) { notification in
            guard let destination = notification.userInfo?["destination"] as? NotificationDestination else { return }
            handleNotificationNavigation(to: destination)
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            FocusView()
                .tabItem { Label("Focus", systemImage: "timer") }
                .tag(AppTab.focus)

            TasksView()
                .tabItem { Label("Tasks", systemImage: "checklist") }
                .tag(AppTab.tasks)

            ProgressViewV2()
                .tabItem { Label("Progress", systemImage: "chart.bar") }
                .tag(AppTab.progress)

            ProfileView(navigateToJourney: $navigateToJourney)
                .tabItem { Label("Profile", systemImage: "person.circle") }
                .tag(AppTab.profile)
        }
        .syncWithAppState()
    }

    private func handleNotificationNavigation(to destination: NotificationDestination) {
        switch destination {
        case .journey:
            selectedTab = .profile
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navigateToJourney = true
            }
        case .profile:
            selectedTab = .profile
        case .progress:
            selectedTab = .progress
        case .focus:
            selectedTab = .focus
        case .tasks:
            selectedTab = .tasks
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings.shared)
        .environmentObject(ProEntitlementManager())
}
