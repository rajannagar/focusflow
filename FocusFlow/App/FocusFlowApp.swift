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
        // ✅ Handle widget deep links first
        if url.scheme == "focusflow" {
            handleWidgetDeepLink(url)
            return
        }
        
        // ✅ Single entry point for all auth-related deep links:
        // - Google OAuth callback
        // - Magic links
        // - Password recovery links
        Task { @MainActor in
            let handled = await SupabaseManager.shared.handleDeepLink(url)
            if handled {
                // Only present "Set New Password" UI for recovery links (type=recovery)
                PasswordRecoveryManager.shared.handleIfRecovery(url: url)
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
