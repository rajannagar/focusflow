import SwiftUI
import UserNotifications
import Supabase
import Auth

@main
struct FocusFlowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var pro = ProEntitlementManager()

    init() {
        // Keep legacy restore ONLY so Guest mode stays persistent for now.
        // Supabase will override non-guest states via AppAuthBridgeV2.
        AuthManager.shared.restoreSessionIfNeeded()

        // ✅ Start the new Supabase -> AuthManager bridge
        AppAuthBridgeV2.shared.start()

        // ✅ Keep these alive early so they observe and broadcast app-wide updates
        _ = AppSyncManager.shared
        _ = JourneyManager.shared

        // ✅ Ensure task reminders are scheduled even if Tasks tab is never opened.
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
                    // Existing password recovery handler (your in-app reset flow)
                    PasswordRecoveryManager.shared.handle(url: url)

                    // ✅ Supabase: complete OAuth / magic link sessions from the deep link
                    Task {
                        do {
                            _ = try await SupabaseClientProvider.shared.client.auth.session(from: url)
                        } catch {
                            print("Supabase session(from:) failed:", error)
                        }
                    }
                }
        }
    }
}
