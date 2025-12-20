import SwiftUI

@main
struct FocusFlowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var pro = ProEntitlementManager()

    init() {
        AuthManager.shared.restoreSessionIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AppSettings.shared)
                .environmentObject(pro)
                // ✅ Catch password recovery deep links here (works anywhere in app)
                .onOpenURL { url in
                    PasswordRecoveryManager.shared.handle(url: url)
                }
        }
    }
}
