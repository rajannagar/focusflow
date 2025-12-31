import UIKit
import UserNotifications
import GoogleSignIn
import Supabase
import Auth

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Register categories/actions (safe even if you don't use them yet)
        FocusLocalNotificationManager.shared.registerNotificationCategoriesIfNeeded()
        return true
    }
    
    // MARK: - URL Handling (Google Sign-In + Supabase)
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // Handle Google Sign-In callback
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        
        // Handle Supabase auth callback (magic links, password recovery, etc.)
        Task {
            do {
                try await SupabaseManager.shared.client.auth.session(from: url)
            } catch {
                print("[AppDelegate] Error handling auth URL: \(error)")
            }
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Premium cleanup:
        // When the user is back inside the app, don't leave "session complete" in Notification Center.
        FocusLocalNotificationManager.shared.clearDeliveredSessionCompletionNotifications()
        
        // ✅ Check bridge state and handle sound pause/resume immediately when app becomes active
        if #available(iOS 18.0, *) {
            checkBridgeAndHandleSound()
        }
        
        // ✅ Sync data to Home Screen widgets
        Task { @MainActor in
            WidgetDataManager.shared.syncAll()
        }
    }
    
    // MARK: - Bridge Sound Handling
    
    @available(iOS 18.0, *)
    private func checkBridgeAndHandleSound() {
        guard let bridgeState = FocusSessionBridge.peekState() else { return }
        
        // Post notification to handle sound pause/resume
        NotificationCenter.default.post(
            name: .focusSessionExternalToggle,
            object: nil,
            userInfo: [
                "isPaused": bridgeState.isPaused,
                "remainingSeconds": bridgeState.remainingSeconds
            ]
        )
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Force push any pending changes before app goes to background
        Task { @MainActor in
            await SyncCoordinator.shared.forcePushAllPending()
        }
        
        // ✅ Check bridge and handle sound before going to background
        if #available(iOS 18.0, *) {
            checkBridgeAndHandleSound()
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Force push any pending changes when app enters background
        Task { @MainActor in
            await SyncCoordinator.shared.forcePushAllPending()
        }
        
        // ✅ Check bridge and handle sound when entering background
        if #available(iOS 18.0, *) {
            checkBridgeAndHandleSound()
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Force push any pending changes before app terminates
        // Note: This gives limited time, but better than nothing
        let semaphore = DispatchSemaphore(value: 0)
        Task { @MainActor in
            await SyncCoordinator.shared.forcePushAllPending()
            semaphore.signal()
        }
        // Wait up to 2 seconds for sync to complete
        _ = semaphore.wait(timeout: .now() + 2.0)
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let id = notification.request.identifier

        // ✅ Suppress "session complete" banners while the app is open.
        // We show a premium in-app completion overlay instead.
        if id == FocusLocalNotificationManager.shared.sessionCompletionIdentifier {
            completionHandler([])
            return
        }

        // Everything else: show normally
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.notification.request.identifier

        // ✅ Handle session completion tap
        if id == FocusLocalNotificationManager.shared.sessionCompletionIdentifier {
            FocusLocalNotificationManager.shared.clearDeliveredSessionCompletionNotifications()
            completionHandler()
            return
        }
        
        // ✅ Handle Daily Recap tap → Navigate to Journey
        if id == NotificationIDs.dailyRecap {
            navigateToDestination(.journey)
            completionHandler()
            return
        }
        
        // ✅ Handle Daily Reminder tap → Navigate to Focus
        if id == NotificationIDs.dailyReminder {
            navigateToDestination(.focus)
            completionHandler()
            return
        }
        
        // ✅ Handle Daily Nudges tap → Navigate to Focus
        if NotificationIDs.allNudges.contains(id) {
            navigateToDestination(.focus)
            completionHandler()
            return
        }
        
        // ✅ Handle Task Reminder tap → Navigate to Tasks
        if id.hasPrefix(NotificationIDs.taskPrefix) {
            navigateToDestination(.tasks)
            completionHandler()
            return
        }

        completionHandler()
    }
    
    // MARK: - Navigation Helper
    
    /// Posts navigation event that ContentView listens to
    private func navigateToDestination(_ destination: NotificationDestination) {
        // Small delay to ensure app is fully active
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NotificationCenter.default.post(
                name: NotificationCenterManager.navigateToDestination,
                object: nil,
                userInfo: ["destination": destination]
            )
        }
    }
}
