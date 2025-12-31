//
//  FocusFlowApp.swift
//  FocusFlow
//
//  Updated for Supabase V2 architecture + Onboarding
//

import SwiftUI
import UserNotifications
import Supabase

@main
struct FocusFlowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var pro = ProEntitlementManager()
    @StateObject private var onboardingManager = OnboardingManager.shared

    init() {
        // ═══════════════════════════════════════════════════════════════════
        // MARK: - V2 Cloud Infrastructure (NEW)
        // ═══════════════════════════════════════════════════════════════════

        // ✅ Initialize Supabase client (single source of truth)
        _ = SupabaseManager.shared

        // ✅ Initialize auth manager (observes Supabase auth state)
        _ = AuthManagerV2.shared

        // ✅ Initialize sync coordinator (starts/stops engines based on auth)
        _ = SyncCoordinator.shared
        
        // ✅ Initialize sync queue (ensures no changes are lost)
        _ = SyncQueue.shared

        // ═══════════════════════════════════════════════════════════════════
        // MARK: - Local Managers (unchanged)
        // ═══════════════════════════════════════════════════════════════════

        // ✅ Keep these alive early so they observe and broadcast app-wide updates
        _ = AppSyncManager.shared
        _ = JourneyManager.shared

        // ✅ Ensure task reminders are scheduled even if Tasks tab is never opened
        _ = TaskReminderScheduler.shared

        // ✅ Initialize notification preferences store (namespace-aware)
        _ = NotificationPreferencesStore.shared

        // ✅ Initialize in-app notifications bridge (listens to AppSyncManager events)
        _ = InAppNotificationsBridge.shared

        // Ensure UNUserNotificationCenter delegate is set (foreground behavior)
        UNUserNotificationCenter.current().delegate = appDelegate

        // ✅ Reconcile notifications on launch (no prompting, respects preferences)
        Task { @MainActor in
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
            center.removeAllDeliveredNotifications()

            await NotificationsCoordinator.shared.reconcileAll(reason: "launch")
            InAppNotificationsBridge.shared.generateDailyRecapIfNeeded()
        }
        
        // ✅ Ensure stores are initialized (widget sync will happen after remote sync in SyncCoordinator)
        _ = ProgressStore.shared
        _ = TasksStore.shared
        _ = FocusPresetStore.shared
        
        // Note: Widget sync is now triggered by SyncCoordinator after initial remote sync completes
        // This ensures widgets have the latest data from the cloud
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(AppSettings.shared)
                .environmentObject(pro)
                .environmentObject(onboardingManager)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }

    // MARK: - Deep Link Handling

    private func handleIncomingURL(_ url: URL) {
        #if DEBUG
        print("[FocusFlowApp] Received URL: \(url)")
        print("[FocusFlowApp] URL scheme: \(url.scheme ?? "nil")")
        #endif
        
        let scheme = url.scheme?.lowercased() ?? ""
        
        // ✅ Handle widget deep links (old scheme for backwards compatibility)
        if scheme == "focusflow" {
            handleWidgetDeepLink(url)
            return
        }
        
        // ✅ Handle auth deep links (scheme: ca.softcomputers.FocusFlow - case insensitive)
        if scheme == "ca.softcomputers.focusflow" {
            Task { @MainActor in
                #if DEBUG
                print("[FocusFlowApp] Processing auth deep link...")
                #endif
                
                let handled = await SupabaseManager.shared.handleDeepLink(url)
                
                #if DEBUG
                print("[FocusFlowApp] Deep link handled: \(handled)")
                #endif
                
                if handled {
                    let pendingFlow = PasswordRecoveryManager.shared.pendingFlow
                    
                    #if DEBUG
                    print("[FocusFlowApp] Deep link handled, pendingFlow: \(pendingFlow)")
                    #endif
                    
                    // Clear the pending flow
                    PasswordRecoveryManager.shared.clearPendingFlow()
                    
                    // Handle based on what flow was pending
                    switch pendingFlow {
                    case .signup:
                        // Email verification - sign out and show success
                        #if DEBUG
                        print("[FocusFlowApp] Email verification flow - signing out first")
                        #endif
                        await AuthManagerV2.shared.signOut()
                        
                        // Wait for state to settle, then show verified screen
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        PasswordRecoveryManager.shared.isPresentingEmailVerified = true
                        
                    case .passwordReset:
                        // Password reset - show the set new password screen
                        // Don't sign out - user needs the session to update password
                        #if DEBUG
                        print("[FocusFlowApp] Password reset flow - showing password screen")
                        #endif
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        PasswordRecoveryManager.shared.isPresentingPasswordReset = true
                        
                    case .none:
                        // No pending flow - just sign in normally
                        #if DEBUG
                        print("[FocusFlowApp] No pending flow - normal sign in")
                        #endif
                        break
                    }
                }
            }
            return
        }
        
        // ✅ Fallback for any other auth-related deep links
        Task { @MainActor in
            let handled = await SupabaseManager.shared.handleDeepLink(url)
            if handled {
                NotificationCenter.default.post(name: Notification.Name("FocusFlow.authCompleted"), object: nil)
                PasswordRecoveryManager.shared.handleAuthDeepLink(url: url)
            }
        }
    }
    
    private func handleWidgetDeepLink(_ url: URL) {
        guard url.scheme == "focusflow" else { return }
        
        switch url.host {
        case "start":
            // Navigate to Focus tab
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(
                    name: NotificationCenterManager.navigateToDestination,
                    object: nil,
                    userInfo: ["destination": NotificationDestination.focus]
                )
            }
            
        case "startfocus":
            // Start focus with widget-selected preset
            let defaults = UserDefaults(suiteName: "group.ca.softcomputers.FocusFlow")
            let selectedPresetID = defaults?.string(forKey: "widget.selectedPresetID")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Navigate to focus tab
                NotificationCenter.default.post(
                    name: NotificationCenterManager.navigateToDestination,
                    object: nil,
                    userInfo: ["destination": NotificationDestination.focus]
                )
                
                // Start with preset if selected
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let presetIDString = selectedPresetID,
                       let presetID = UUID(uuidString: presetIDString) {
                        NotificationCenter.default.post(
                            name: Notification.Name("FocusFlow.applyPresetFromWidget"),
                            object: nil,
                            userInfo: ["presetID": presetID, "autoStart": true]
                        )
                    } else {
                        // No preset selected - just start with current settings
                        NotificationCenter.default.post(
                            name: Notification.Name("FocusFlow.widgetStartAction"),
                            object: nil
                        )
                    }
                    
                    // Clear the selected preset after starting
                    defaults?.removeObject(forKey: "widget.selectedPresetID")
                    defaults?.removeObject(forKey: "widget.selectedPresetDuration")
                }
            }
            
        case "preset":
            // Handle preset deep link: focusflow://preset/{presetID}
            // Selects preset AND starts session
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if let presetIDString = pathComponents.first,
               let presetID = UUID(uuidString: presetIDString) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(
                        name: NotificationCenterManager.navigateToDestination,
                        object: nil,
                        userInfo: [
                            "destination": NotificationDestination.focus,
                            "presetID": presetID,
                            "autoStart": true
                        ]
                    )
                }
            }
            
        case "selectpreset":
            // Handle select preset deep link: focusflow://selectpreset/{presetID}
            // Only selects preset, doesn't start session
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if let presetIDString = pathComponents.first,
               let presetID = UUID(uuidString: presetIDString) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    NotificationCenter.default.post(
                        name: NotificationCenterManager.navigateToDestination,
                        object: nil,
                        userInfo: [
                            "destination": NotificationDestination.focus,
                            "presetID": presetID,
                            "autoStart": false
                        ]
                    )
                }
            }
            
        case "switchpreset":
            // Handle switch preset with confirmation: focusflow://switchpreset/{presetID}
            // Shows confirmation dialog if session is running
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if let presetIDString = pathComponents.first,
               let presetID = UUID(uuidString: presetIDString) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    NotificationCenter.default.post(
                        name: NotificationCenterManager.navigateToDestination,
                        object: nil,
                        userInfo: ["destination": NotificationDestination.focus]
                    )
                    
                    // Post switch preset notification
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationCenter.default.post(
                            name: Notification.Name("FocusFlow.widgetSwitchPreset"),
                            object: nil,
                            userInfo: ["presetID": presetID]
                        )
                    }
                }
            }
            
        case "resetconfirm":
            // Handle reset with confirmation: focusflow://resetconfirm
            // Shows confirmation dialog if session is running
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NotificationCenter.default.post(
                    name: NotificationCenterManager.navigateToDestination,
                    object: nil,
                    userInfo: ["destination": NotificationDestination.focus]
                )
                
                // Post reset confirmation notification
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(
                        name: Notification.Name("FocusFlow.widgetResetConfirm"),
                        object: nil
                    )
                }
            }
            
        case "pause":
            // Pause the current focus session
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(
                    name: NotificationCenterManager.navigateToDestination,
                    object: nil,
                    userInfo: ["destination": NotificationDestination.focus]
                )
                // Post pause action notification
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    NotificationCenter.default.post(
                        name: Notification.Name("FocusFlow.widgetPauseAction"),
                        object: nil
                    )
                }
            }
            
        case "resume":
            // Resume the current focus session
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(
                    name: NotificationCenterManager.navigateToDestination,
                    object: nil,
                    userInfo: ["destination": NotificationDestination.focus]
                )
                // Post resume action notification
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    NotificationCenter.default.post(
                        name: Notification.Name("FocusFlow.widgetResumeAction"),
                        object: nil
                    )
                }
            }
            
        case "open":
            // Generic open - navigate to Focus tab
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(
                    name: NotificationCenterManager.navigateToDestination,
                    object: nil,
                    userInfo: ["destination": NotificationDestination.focus]
                )
            }
            
        case "tasks":
            // Navigate to Tasks tab
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(
                    name: NotificationCenterManager.navigateToDestination,
                    object: nil,
                    userInfo: ["destination": NotificationDestination.tasks]
                )
            }
            
        case "progress":
            // Navigate to Progress/Journey tab
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(
                    name: NotificationCenterManager.navigateToDestination,
                    object: nil,
                    userInfo: ["destination": NotificationDestination.journey]
                )
            }
            
        default:
            break
        }
    }
}

// MARK: - Root View

/// Root view that decides whether to show onboarding or main content
struct RootView: View {
    @EnvironmentObject private var onboardingManager: OnboardingManager
    
    var body: some View {
        ZStack {
            if onboardingManager.hasCompletedOnboarding {
                ContentView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: onboardingManager.hasCompletedOnboarding)
    }
}
