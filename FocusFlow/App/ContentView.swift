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
    @Environment(\.scenePhase) private var scenePhase

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
            
            let presetID = notification.userInfo?["presetID"] as? UUID
            let autoStart = notification.userInfo?["autoStart"] as? Bool ?? false
            
            handleNotificationNavigation(to: destination, presetID: presetID, autoStart: autoStart)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // ✅ Push pending changes when app goes to background
            if newPhase == .background || newPhase == .inactive {
                Task { @MainActor in
                    await SyncCoordinator.shared.forcePushAllPending()
                }
            }
            
            // ✅ Pull latest changes when app becomes active (detects changes from other devices)
            if newPhase == .active && oldPhase != .active {
                Task { @MainActor in
                    await SyncCoordinator.shared.pullFromRemote()
                }
            }
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

    private func handleNotificationNavigation(to destination: NotificationDestination, presetID: UUID? = nil, autoStart: Bool = false) {
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
            
            // Handle preset selection from widget
            if let presetID = presetID {
                handlePresetSelection(presetID: presetID, autoStart: autoStart)
            }
        case .tasks:
            selectedTab = .tasks
        }
    }
    
    private func handlePresetSelection(presetID: UUID, autoStart: Bool) {
        // Set the preset as active
        guard let preset = FocusPresetStore.shared.presets.first(where: { $0.id == presetID }) else {
            return
        }
        
        // Only select, don't auto-start
        FocusPresetStore.shared.activePresetID = presetID
        
        // Notify FocusView to apply the preset settings
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NotificationCenter.default.post(
                name: Notification.Name("FocusFlow.applyPresetFromWidget"),
                object: nil,
                userInfo: ["presetID": presetID, "autoStart": autoStart]
            )
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings.shared)
        .environmentObject(ProEntitlementManager())
}
