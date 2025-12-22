import UIKit
import UserNotifications

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

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Premium cleanup:
        // When the user is back inside the app, don't leave "session complete" in Notification Center.
        FocusLocalNotificationManager.shared.clearDeliveredSessionCompletionNotifications()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Keep hook for future.
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let id = notification.request.identifier

        // ✅ Suppress “session complete” banners while the app is open.
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

        if id == FocusLocalNotificationManager.shared.sessionCompletionIdentifier {
            // Premium cleanup if user tapped it
            FocusLocalNotificationManager.shared.clearDeliveredSessionCompletionNotifications()
            completionHandler()
            return
        }

        completionHandler()
    }
}
