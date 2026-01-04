import Foundation
import WidgetKit

// MARK: - Widget Data Manager
// Syncs app data to Home Screen widgets via App Group
// Ensures data is tied to the current logged-in user

@MainActor
final class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private static let appGroupID = "group.ca.softcomputers.FocusFlow"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupID)
    }
    
    // MARK: - Keys (must match WidgetDataProvider in extension)
    
    private enum Keys {
        static let userID = "widget.userID"
        static let todayFocusSeconds = "widget.todayFocusSeconds"
        static let dailyGoalMinutes = "widget.dailyGoalMinutes"
        static let currentStreak = "widget.currentStreak"
        static let lifetimeSessionCount = "widget.lifetimeSessionCount"
        static let lifetimeFocusHours = "widget.lifetimeFocusHours"
        static let lastUpdated = "widget.lastUpdated"
        static let selectedTheme = "widget.selectedTheme"
        static let displayName = "widget.displayName"
        static let presetsJSON = "widget.presetsJSON"
        static let isSessionActive = "widget.isSessionActive"
        static let activeSessionName = "widget.activeSessionName"
        static let activeSessionEndDate = "widget.activeSessionEndDate"
        static let activeSessionIsPaused = "widget.activeSessionIsPaused"
        static let activeSessionTotalSeconds = "widget.activeSessionTotalSeconds"
        static let activeSessionRemainingSeconds = "widget.activeSessionRemainingSeconds"
        static let selectedPresetID = "widget.selectedPresetID"
        static let selectedPresetDuration = "widget.selectedPresetDuration"
        static let isPro = "widget.isPro" // ✅ Pro status for widget gating
    }
    
    private init() {}
    
    // MARK: - Full Sync
    
    /// Syncs all relevant data to widgets. Call when:
    /// - App becomes active
    /// - Session completes
    /// - Presets change
    /// - Settings change
    func syncAll() {
        guard let defaults = sharedDefaults else {
            print("[WidgetDataManager] ❌ Failed to access App Group defaults - check entitlements!")
            return
        }
        
        // Get current user ID from AuthManager
        let currentUserID = AuthManagerV2.shared.state.userId?.uuidString ?? "anonymous"
        let storedUserID = defaults.string(forKey: Keys.userID)
        
        // If user changed, clear all widget data first
        if storedUserID != nil && storedUserID != currentUserID {
            print("[WidgetDataManager] ⚠️ User changed, clearing old widget data")
            clearAllData()
        }
        
        // Store current user ID
        defaults.set(currentUserID, forKey: Keys.userID)
        
        #if DEBUG
        print("[WidgetDataManager] ✅ Syncing for user: \(currentUserID)")
        #endif
        
        // Progress data
        let progressStore = ProgressStore.shared
        let todaySeconds = progressStore.totalToday
        let dailyGoal = progressStore.dailyGoalMinutes
        let streak = calculateCurrentStreak()
        let sessionCount = progressStore.lifetimeSessionCount
        let lifetimeHours = progressStore.lifetimeFocusSeconds / 3600.0
        
        defaults.set(todaySeconds, forKey: Keys.todayFocusSeconds)
        defaults.set(dailyGoal, forKey: Keys.dailyGoalMinutes)
        defaults.set(streak, forKey: Keys.currentStreak)
        defaults.set(sessionCount, forKey: Keys.lifetimeSessionCount)
        defaults.set(lifetimeHours, forKey: Keys.lifetimeFocusHours)
        defaults.set(Date(), forKey: Keys.lastUpdated)
        
        // Theme
        let settings = AppSettings.shared
        defaults.set(settings.selectedTheme.rawValue, forKey: Keys.selectedTheme)
        defaults.set(settings.displayName, forKey: Keys.displayName)
        
        // ✅ Sync Pro status (needed for widget gating)
        let isPro = ProGatingHelper.shared.isPro
        defaults.set(isPro, forKey: Keys.isPro)
        
        // Presets (only sync for Pro users)
        if isPro {
        syncPresets(to: defaults)
        } else {
            // Clear presets for free users
            defaults.removeObject(forKey: Keys.presetsJSON)
            #if DEBUG
            print("[WidgetDataManager] 🔒 Presets not synced - requires Pro")
            #endif
        }
        
        // ✅ Force synchronize to ensure data is written before widget reads it
        defaults.synchronize()
        
        // Request widget refresh
        reloadWidgets()
        
        #if DEBUG
        print("[WidgetDataManager] Synced: \(Int(todaySeconds/60))m today, \(streak) streak, \(sessionCount) sessions, theme: \(settings.selectedTheme.rawValue)")
        #endif
    }
    
    /// Clears all widget data - call on logout
    func clearAllData() {
        guard let defaults = sharedDefaults else { return }
        
        // Remove all widget keys
        defaults.removeObject(forKey: Keys.userID)
        defaults.removeObject(forKey: Keys.todayFocusSeconds)
        defaults.removeObject(forKey: Keys.dailyGoalMinutes)
        defaults.removeObject(forKey: Keys.currentStreak)
        defaults.removeObject(forKey: Keys.lifetimeSessionCount)
        defaults.removeObject(forKey: Keys.lifetimeFocusHours)
        defaults.removeObject(forKey: Keys.lastUpdated)
        defaults.removeObject(forKey: Keys.selectedTheme)
        defaults.removeObject(forKey: Keys.displayName)
        defaults.removeObject(forKey: Keys.presetsJSON)
        defaults.removeObject(forKey: Keys.isSessionActive)
        defaults.removeObject(forKey: Keys.activeSessionName)
        defaults.removeObject(forKey: Keys.activeSessionEndDate)
        defaults.removeObject(forKey: Keys.activeSessionIsPaused)
        defaults.removeObject(forKey: Keys.activeSessionTotalSeconds)
        defaults.removeObject(forKey: Keys.activeSessionRemainingSeconds)
        defaults.removeObject(forKey: Keys.selectedPresetID)
        defaults.removeObject(forKey: Keys.selectedPresetDuration)
        defaults.removeObject(forKey: Keys.isPro)
        
        // Also clear any widget pause/resume requests
        defaults.removeObject(forKey: "widget.pauseRequestedAt")
        defaults.removeObject(forKey: "widget.resumeRequestedAt")
        
        defaults.synchronize()
        reloadWidgets()
        
        print("[WidgetDataManager] 🗑️ Cleared all widget data")
    }
    
    // MARK: - Preset Sync
    
    private func syncPresets(to defaults: UserDefaults) {
        let presetStore = FocusPresetStore.shared
        
        // Convert to widget-compatible format
        struct WidgetPreset: Codable {
            let id: String
            let name: String
            let emoji: String?
            let durationMinutes: Int
        }
        
        // Take first 4 presets for widget display
        let widgetPresets: [WidgetPreset] = presetStore.presets.prefix(4).map { preset in
            WidgetPreset(
                id: preset.id.uuidString,
                name: preset.name,
                emoji: preset.emoji,
                durationMinutes: preset.durationSeconds / 60
            )
        }
        
        #if DEBUG
        print("[WidgetDataManager] Syncing \(widgetPresets.count) presets: \(widgetPresets.map { $0.name })")
        #endif
        
        if let data = try? JSONEncoder().encode(widgetPresets) {
            defaults.set(data, forKey: Keys.presetsJSON)
        }
    }
    
    // MARK: - Active Session Updates
    
    func updateActiveSession(
        isActive: Bool,
        sessionName: String? = nil,
        endDate: Date? = nil,
        isPaused: Bool = false,
        totalSeconds: Int = 0,
        remainingSeconds: Int = 0
    ) {
        guard let defaults = sharedDefaults else { return }
        
        // ✅ Only sync control state for Pro users
        let isPro = ProGatingHelper.shared.isPro
        if isPro {
        defaults.set(isActive, forKey: Keys.isSessionActive)
        defaults.set(sessionName, forKey: Keys.activeSessionName)
        defaults.set(endDate, forKey: Keys.activeSessionEndDate)
        defaults.set(isPaused, forKey: Keys.activeSessionIsPaused)
        defaults.set(totalSeconds, forKey: Keys.activeSessionTotalSeconds)
        defaults.set(remainingSeconds, forKey: Keys.activeSessionRemainingSeconds)
        } else {
            // Clear control state for free users
            defaults.set(false, forKey: Keys.isSessionActive)
            defaults.removeObject(forKey: Keys.activeSessionName)
            defaults.removeObject(forKey: Keys.activeSessionEndDate)
            defaults.set(false, forKey: Keys.activeSessionIsPaused)
            defaults.set(0, forKey: Keys.activeSessionTotalSeconds)
            defaults.set(0, forKey: Keys.activeSessionRemainingSeconds)
            #if DEBUG
            print("[WidgetDataManager] 🔒 Control state not synced - requires Pro")
            #endif
        }
        
        // ✅ Force synchronize to ensure data is written before widget reads it
        defaults.synchronize()
        
        reloadWidgets()
    }
    
    // MARK: - Streak Calculation
    
    private func calculateCurrentStreak() -> Int {
        let progressStore = ProgressStore.shared
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: Date())
        
        // Get all unique days with sessions
        let sessionDays = Set(progressStore.sessions
            .filter { $0.duration > 0 }
            .map { calendar.startOfDay(for: $0.date) }
        )
        
        guard !sessionDays.isEmpty else { return 0 }
        
        var streak = 0
        var checkDate = today
        
        // Check if today or yesterday has a session (streak can continue from yesterday)
        let hasToday = sessionDays.contains(today)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let hasYesterday = sessionDays.contains(yesterday)
        
        if !hasToday && !hasYesterday {
            return 0  // Streak is broken
        }
        
        // Start from today if there's a session, otherwise from yesterday
        if hasToday {
            checkDate = today
        } else {
            checkDate = yesterday
        }
        
        // Count consecutive days going backwards
        while sessionDays.contains(checkDate) {
            streak += 1
            guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prevDay
        }
        
        return streak
    }
    
    // MARK: - Widget Reload
    
    private func reloadWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "FocusFlowWidget")
    }
    
    /// Call to reload all widgets (e.g., after theme change)
    func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

