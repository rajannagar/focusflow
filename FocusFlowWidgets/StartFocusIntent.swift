import AppIntents
import WidgetKit

// MARK: - Start Focus Intent
// Allows users to start a focus session directly from widget button

struct StartFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Focus Session"
    static var description = IntentDescription("Starts a new focus session in FocusFlow")
    
    /// Opens the main app and signals it to start a session
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        // The app will handle starting the session based on the deep link
        // This intent just opens the app
        return .result()
    }
}

