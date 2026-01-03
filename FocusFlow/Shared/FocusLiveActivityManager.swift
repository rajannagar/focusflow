import Foundation
import ActivityKit

/// Thin wrapper around ActivityKit for the Focus timer.
@available(iOS 18.0, *)
final class FocusLiveActivityManager {

    static let shared = FocusLiveActivityManager()
    private init() {}

    private var activity: Activity<FocusSessionAttributes>?

    /// Use the explicit reference if we have it, otherwise grab the first active one.
    private var currentActivity: Activity<FocusSessionAttributes>? {
        activity ?? Activity<FocusSessionAttributes>.activities.first
    }

    // MARK: - Helper

    private func formatRemaining(_ totalSeconds: Int) -> String {
        let clamped = max(0, totalSeconds)
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let seconds = clamped % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    // MARK: - Start

    func startActivity(totalSeconds: Int, sessionName: String, endDate: Date) {
        // ✅ Check Pro status - Live Activity is a Pro feature
        guard ProGatingHelper.shared.isPro else {
            #if DEBUG
            print("[LiveActivity] Disabled - requires Pro")
            #endif
            return
        }
        
        let info = ActivityAuthorizationInfo()
        guard info.areActivitiesEnabled else { return }

        let themeID = AppSettings.shared.selectedTheme.rawValue
        
        let attributes = FocusSessionAttributes(
            totalDuration: TimeInterval(totalSeconds)
        )

        let initialContentState = FocusSessionAttributes.ContentState(
            endDate: endDate,
            isPaused: false,
            sessionName: sessionName,
            themeID: themeID,
            pausedDisplayTime: formatRemaining(totalSeconds),
            remainingSeconds: totalSeconds,
            isCompleted: false // Start as not completed
        )

        // Mark content stale at the expected end time so the system can deprioritize/remove it
        // even if the app doesn't get a chance to explicitly end the activity.
        let content = ActivityContent(state: initialContentState, staleDate: endDate)

        do {
            self.activity = try Activity<FocusSessionAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            print("FocusLiveActivityManager: Started activity.")
        } catch {
            print("FocusLiveActivityManager: Failed to start activity: \(error)")
        }
    }

    // MARK: - Update (pause / resume)

    func updatePaused(remainingSeconds: Int, isPaused: Bool, sessionName: String) {
        guard let activity = currentActivity else { return }

        let endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        let themeID = AppSettings.shared.selectedTheme.rawValue
        let pausedString = formatRemaining(remainingSeconds)

        let state = FocusSessionAttributes.ContentState(
            endDate: endDate,
            isPaused: isPaused,
            sessionName: sessionName,
            themeID: themeID,
            pausedDisplayTime: pausedString,
            remainingSeconds: remainingSeconds,
            isCompleted: false // Still running/paused, not done
        )

        Task {
            let content = ActivityContent(state: state, staleDate: isPaused ? nil : endDate)
            await activity.update(content)
            print("FocusLiveActivityManager: Updated (paused=\(isPaused), remaining=\(remainingSeconds))")
        }
    }

    // MARK: - End (completion / reset)

    func endActivity() {
        guard let activity = currentActivity else { return }

        Task {
            // Build a final "completed" state so the widget can show "Session Complete"
            var finalState = activity.content.state
            finalState.isPaused = false
            finalState.isCompleted = true  // <--- Shows checkmark UI
            finalState.remainingSeconds = 0
            finalState.endDate = Date()
            finalState.pausedDisplayTime = "00:00"

            let finalContent = ActivityContent(state: finalState, staleDate: nil)

            // ✅ Use .default so it stays on lock screen until user clears it
            await activity.end(finalContent, dismissalPolicy: .default)
            
            print("FocusLiveActivityManager: Ended activity with completion state.")
        }

        self.activity = nil
    }
}
