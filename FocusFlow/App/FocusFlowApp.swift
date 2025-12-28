//
//  FocusFlowApp.swift
//  FocusFlow
//
//  Updated for Supabase V2 architecture
//

import SwiftUI
import UserNotifications
import Supabase

@main
struct FocusFlowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var pro = ProEntitlementManager()

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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AppSettings.shared)
                .environmentObject(pro)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }

    // MARK: - Deep Link Handling

    private func handleIncomingURL(_ url: URL) {
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
}
