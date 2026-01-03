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
    
    // MARK: - Guest Migration State
    
    /// Tracks whether to show the data migration sheet
    @State private var showMigrationSheet = false
    
    /// Tracks if user was in guest mode before starting sign-in flow
    /// This is needed because: guest → signedOut → signedIn (not direct)
    @State private var wasGuestBeforeSignIn = false
    
    /// Reference to app settings for theme
    @ObservedObject private var appSettings = AppSettings.shared

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
        .fullScreenCover(isPresented: $recovery.isPresentingPasswordReset) {
            SetNewPasswordView {
                recovery.clearPasswordReset()
            }
        }
        .fullScreenCover(isPresented: $recovery.isPresentingEmailVerified) {
            EmailVerifiedView {
                recovery.clearEmailVerified()
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
        // MARK: - Guest → SignedIn Migration Detection
        .onChange(of: authManager.state) { oldState, newState in
            #if DEBUG
            print("[ContentView] Auth state changed: \(oldState) → \(newState)")
            #endif
            
            // Track when user leaves guest mode (guest → signedOut happens before sign-in)
            // IMPORTANT: Persist guest data BEFORE namespace changes
            if case .guest = oldState {
                wasGuestBeforeSignIn = true
                #if DEBUG
                print("[ContentView] User leaving guest mode - persisting guest data NOW")
                #endif
                // Force persist all guest data DIRECTLY to guest keys
                // (Don't use store.persist() as namespace may have already changed)
                persistGuestDataDirectly()
            }
            
            // Detect when user becomes signedIn (could be from guest → signedOut → signedIn)
            if case .signedIn = newState, wasGuestBeforeSignIn {
                #if DEBUG
                print("[ContentView] Detected guest → signedIn transition (via signedOut)")
                #endif
                
                // Reset the flag
                wasGuestBeforeSignIn = false
                
                // Check if there's guest data to migrate
                if GuestMigrationManager.shared.hasGuestData() {
                    #if DEBUG
                    print("[ContentView] Guest data found, showing migration sheet")
                    #endif
                    // Small delay to let auth state and sync settle
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showMigrationSheet = true
                    }
                } else {
                    #if DEBUG
                    print("[ContentView] No guest data to migrate")
                    #endif
                }
            }
            
            // Reset flag if user signs out completely (not part of sign-in flow)
            if case .signedOut = newState, case .signedIn = oldState {
                wasGuestBeforeSignIn = false
            }
        }
        // MARK: - Migration Sheet
        .sheet(isPresented: $showMigrationSheet) {
            DataMigrationSheet(theme: appSettings.profileTheme)
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
    
    // MARK: - Guest Data Persistence
    
    /// Persist guest data directly to guest keys (bypasses namespace switching race condition)
    private func persistGuestDataDirectly() {
        let defaults = UserDefaults.standard
        let guestSessionsKey = "ff_local_progress.sessions.v1_guest"
        let guestTasksKey = "focusflow_tasks_state_guest"
        let guestPresetsKey = "ff_focus_presets_guest"
        
        #if DEBUG
        print("[ContentView] === Starting guest data persistence ===")
        print("[ContentView] In-memory sessions: \(ProgressStore.shared.sessions.count)")
        print("[ContentView] In-memory tasks: \(TasksStore.shared.tasks.count)")
        print("[ContentView] In-memory presets: \(FocusPresetStore.shared.presets.count)")
        #endif
        
        // 1. Persist sessions - try in-memory first, then check existing UserDefaults
        var sessions = ProgressStore.shared.sessions
        if sessions.isEmpty {
            // Check if there's existing data in UserDefaults we should preserve
            if let existingData = defaults.data(forKey: guestSessionsKey) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if let existingSessions = try? decoder.decode([ProgressSession].self, from: existingData) {
                    sessions = existingSessions
                    #if DEBUG
                    print("[ContentView] Using \(sessions.count) sessions from existing UserDefaults")
                    #endif
                }
            }
        }
        if !sessions.isEmpty {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(sessions) {
                defaults.set(data, forKey: guestSessionsKey)
                #if DEBUG
                print("[ContentView] ✅ Persisted \(sessions.count) sessions to guest key")
                #endif
            }
        } else {
            #if DEBUG
            print("[ContentView] ⚠️ No sessions to persist")
            #endif
        }
        
        // 2. Persist daily goal
        let goal = ProgressStore.shared.dailyGoalMinutes
        defaults.set(goal, forKey: "ff_local_progress.goalMinutes.v1_guest")
        #if DEBUG
        print("[ContentView] ✅ Persisted daily goal: \(goal)")
        #endif
        
        // 3. Persist tasks - try in-memory first, then check existing UserDefaults
        var tasks = TasksStore.shared.tasks
        var completedKeys = TasksStore.shared.completedOccurrenceKeys
        if tasks.isEmpty {
            if let existingData = defaults.data(forKey: guestTasksKey) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if let existingState = try? decoder.decode(TasksStore.LocalState.self, from: existingData) {
                    tasks = existingState.tasks
                    completedKeys = Set(existingState.completedKeys)
                    #if DEBUG
                    print("[ContentView] Using \(tasks.count) tasks from existing UserDefaults")
                    #endif
                }
            }
        }
        if !tasks.isEmpty {
            let state = TasksStore.LocalState(tasks: tasks, completedKeys: Array(completedKeys))
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(state) {
                defaults.set(data, forKey: guestTasksKey)
                #if DEBUG
                print("[ContentView] ✅ Persisted \(tasks.count) tasks to guest key")
                #endif
            }
        }
        
        // 4. Persist ALL presets (including system defaults, so settings are preserved)
        var presets = FocusPresetStore.shared.presets
        if presets.isEmpty {
            if let existingData = defaults.data(forKey: guestPresetsKey),
               let existingPresets = try? JSONDecoder().decode([FocusPreset].self, from: existingData) {
                presets = existingPresets
                #if DEBUG
                print("[ContentView] Using \(presets.count) presets from existing UserDefaults")
                #endif
            }
        }
        if !presets.isEmpty {
            if let data = try? JSONEncoder().encode(presets) {
                defaults.set(data, forKey: guestPresetsKey)
                let customCount = presets.filter { !$0.isSystemDefault }.count
                #if DEBUG
                print("[ContentView] ✅ Persisted \(presets.count) presets (\(customCount) custom) to guest key")
                #endif
            }
        }
        
        // 5. Persist settings directly to guest keys
        let settings = AppSettings.shared
        defaults.set(settings.selectedTheme.rawValue, forKey: "ff_selectedTheme_guest")
        defaults.set(settings.profileTheme.rawValue, forKey: "ff_profileTheme_guest")
        defaults.set(settings.soundEnabled, forKey: "ff_soundEnabled_guest")
        defaults.set(settings.hapticsEnabled, forKey: "ff_hapticsEnabled_guest")
        if let sound = settings.selectedFocusSound {
            defaults.set(sound.rawValue, forKey: "ff_selectedFocusSound_guest")
        }
        if let musicApp = settings.selectedExternalMusicApp {
            defaults.set(musicApp.rawValue, forKey: "ff_externalMusicApp_guest")
        }
        // Persist profile info (always persist - migration will decide if it should be applied)
        if !settings.displayName.isEmpty {
            defaults.set(settings.displayName, forKey: "ff_displayName_guest")
            #if DEBUG
            print("[ContentView] Persisted display name: \(settings.displayName)")
            #endif
        }
        if !settings.tagline.isEmpty {
            defaults.set(settings.tagline, forKey: "ff_tagline_guest")
            #if DEBUG
            print("[ContentView] Persisted tagline: \(settings.tagline)")
            #endif
        }
        if !settings.avatarID.isEmpty {
            defaults.set(settings.avatarID, forKey: "ff_avatarID_guest")
            #if DEBUG
            print("[ContentView] Persisted avatar ID: \(settings.avatarID)")
            #endif
        }
        if let profileImageData = settings.profileImageData {
            defaults.set(profileImageData, forKey: "ff_profileImageData_guest")
            #if DEBUG
            print("[ContentView] Persisted profile image")
            #endif
        }
        
        #if DEBUG
        print("[ContentView] === Guest data persistence complete ===")
        #endif
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings.shared)
        .environmentObject(ProEntitlementManager.shared)
}
