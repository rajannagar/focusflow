import Foundation
import WidgetKit

// MARK: - App Group Shared Data Provider
// Enables the main app to share data with Home Screen widgets

struct WidgetDataProvider {
    
    static let appGroupID = "group.ca.softcomputers.FocusFlow"
    
    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    // MARK: - Keys
    
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
        
        // Presets
        static let presetsJSON = "widget.presetsJSON"
        
        // Active session
        static let isSessionActive = "widget.isSessionActive"
        static let activeSessionName = "widget.activeSessionName"
        static let activeSessionEndDate = "widget.activeSessionEndDate"
        static let activeSessionIsPaused = "widget.activeSessionIsPaused"
        static let activeSessionTotalSeconds = "widget.activeSessionTotalSeconds"
        static let activeSessionRemainingSeconds = "widget.activeSessionRemainingSeconds"
        
        // Selected preset (from widget interaction)
        static let selectedPresetID = "widget.selectedPresetID"
        static let selectedPresetDuration = "widget.selectedPresetDuration"
        
        // Pro status
        static let isPro = "widget.isPro"
    }
    
    // MARK: - Widget Entry Data
    
    struct WidgetData {
        let todayFocusSeconds: TimeInterval
        let dailyGoalMinutes: Int
        let currentStreak: Int
        let lifetimeSessionCount: Int
        let lifetimeFocusHours: Double
        let lastUpdated: Date
        let selectedTheme: String
        let displayName: String
        let presets: [WidgetPreset]
        let isSessionActive: Bool
        let activeSessionName: String?
        let activeSessionEndDate: Date?
        let activeSessionIsPaused: Bool
        let activeSessionTotalSeconds: Int
        let activeSessionRemainingSeconds: Int
        let selectedPresetID: String?
        let selectedPresetDuration: Int
        let isPro: Bool
        
        var sessionProgress: Double {
            guard activeSessionTotalSeconds > 0 else { return 0 }
            
            // When running (not paused), calculate progress based on current time
            if let endDate = activeSessionEndDate, !activeSessionIsPaused {
                let remaining = max(0, endDate.timeIntervalSince(Date()))
                let elapsed = Double(activeSessionTotalSeconds) - remaining
                return min(1.0, elapsed / Double(activeSessionTotalSeconds))
            }
            
            // When paused, use stored remaining seconds
            let elapsed = activeSessionTotalSeconds - activeSessionRemainingSeconds
            return Double(elapsed) / Double(activeSessionTotalSeconds)
        }
        
        var todayProgress: Double {
            guard dailyGoalMinutes > 0 else { return 0 }
            return min(1.0, todayFocusSeconds / Double(dailyGoalMinutes * 60))
        }
        
        var todayFocusFormatted: String {
            let totalMinutes = Int(todayFocusSeconds / 60)
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }
        
        var goalFormatted: String {
            let hours = dailyGoalMinutes / 60
            let minutes = dailyGoalMinutes % 60
            
            if hours > 0 && minutes > 0 {
                return "\(hours)h \(minutes)m goal"
            } else if hours > 0 {
                return "\(hours)h goal"
            } else {
                return "\(minutes)m goal"
            }
        }
        
        static let placeholder = WidgetData(
            todayFocusSeconds: 45 * 60,
            dailyGoalMinutes: 60,
            currentStreak: 5,
            lifetimeSessionCount: 42,
            lifetimeFocusHours: 28.5,
            lastUpdated: Date(),
            selectedTheme: "forest",
            displayName: "You",
            presets: [
                WidgetPreset(id: "1", name: "Deep Work", emoji: "🧠", durationMinutes: 50),
                WidgetPreset(id: "2", name: "Study", emoji: "📚", durationMinutes: 40),
                WidgetPreset(id: "3", name: "Writing", emoji: "✍️", durationMinutes: 30),
                WidgetPreset(id: "4", name: "Reading", emoji: "📖", durationMinutes: 25)
            ],
            isSessionActive: false,
            activeSessionName: nil,
            activeSessionEndDate: nil,
            activeSessionIsPaused: false,
            activeSessionTotalSeconds: 0,
            activeSessionRemainingSeconds: 0,
            selectedPresetID: nil,
            selectedPresetDuration: 0,
            isPro: true // Placeholder shows Pro features
        )
    }
    
    struct WidgetPreset: Codable, Identifiable {
        let id: String
        let name: String
        let emoji: String?
        let durationMinutes: Int
        
        var durationFormatted: String {
            let hours = durationMinutes / 60
            let mins = durationMinutes % 60
            
            if hours > 0 && mins > 0 {
                return "\(hours)h \(mins)m"
            } else if hours > 0 {
                return "\(hours)h"
            } else {
                return "\(mins)m"
            }
        }
    }
    
    // MARK: - Read Data (Widget Extension)
    
    static func readData() -> WidgetData {
        guard let defaults = sharedDefaults else {
            // App Group not accessible - return placeholder
            // This usually means entitlements issue or widget not installed properly
            print("[WidgetDataProvider] ❌ Cannot access App Group - using placeholder")
            return .placeholder
        }
        
        // Check if data has been synced (lastUpdated exists)
        guard defaults.object(forKey: Keys.lastUpdated) != nil else {
            // No data synced yet - return placeholder
            print("[WidgetDataProvider] ⚠️ No synced data found - using placeholder")
            return .placeholder
        }
        
        let todayFocusSeconds = defaults.double(forKey: Keys.todayFocusSeconds)
        let dailyGoalMinutes = defaults.integer(forKey: Keys.dailyGoalMinutes)
        let currentStreak = defaults.integer(forKey: Keys.currentStreak)
        let lifetimeSessionCount = defaults.integer(forKey: Keys.lifetimeSessionCount)
        let lifetimeFocusHours = defaults.double(forKey: Keys.lifetimeFocusHours)
        let lastUpdated = defaults.object(forKey: Keys.lastUpdated) as? Date ?? Date()
        let selectedTheme = defaults.string(forKey: Keys.selectedTheme) ?? "forest"
        let displayName = defaults.string(forKey: Keys.displayName) ?? "You"
        
        // Parse presets
        var presets: [WidgetPreset] = []
        if let presetsData = defaults.data(forKey: Keys.presetsJSON) {
            presets = (try? JSONDecoder().decode([WidgetPreset].self, from: presetsData)) ?? []
        }
        
        // Active session
        let isSessionActive = defaults.bool(forKey: Keys.isSessionActive)
        let activeSessionName = defaults.string(forKey: Keys.activeSessionName)
        let activeSessionEndDate = defaults.object(forKey: Keys.activeSessionEndDate) as? Date
        let activeSessionIsPaused = defaults.bool(forKey: Keys.activeSessionIsPaused)
        let activeSessionTotalSeconds = defaults.integer(forKey: Keys.activeSessionTotalSeconds)
        let activeSessionRemainingSeconds = defaults.integer(forKey: Keys.activeSessionRemainingSeconds)
        
        // Selected preset (from widget tap)
        let selectedPresetID = defaults.string(forKey: Keys.selectedPresetID)
        let selectedPresetDuration = defaults.integer(forKey: Keys.selectedPresetDuration)
        
        // Pro status (defaults to false for free users)
        let isPro = defaults.object(forKey: Keys.isPro) as? Bool ?? false
        
        return WidgetData(
            todayFocusSeconds: todayFocusSeconds,
            dailyGoalMinutes: max(1, dailyGoalMinutes),
            currentStreak: currentStreak,
            lifetimeSessionCount: lifetimeSessionCount,
            lifetimeFocusHours: lifetimeFocusHours,
            lastUpdated: lastUpdated,
            selectedTheme: selectedTheme,
            displayName: displayName,
            presets: presets,
            isSessionActive: isSessionActive,
            activeSessionName: activeSessionName,
            activeSessionEndDate: activeSessionEndDate,
            activeSessionIsPaused: activeSessionIsPaused,
            activeSessionTotalSeconds: activeSessionTotalSeconds,
            activeSessionRemainingSeconds: activeSessionRemainingSeconds,
            selectedPresetID: selectedPresetID,
            selectedPresetDuration: selectedPresetDuration,
            isPro: isPro
        )
    }
    
    // MARK: - Write Data (Main App)
    
    static func updateWidgetData(
        todayFocusSeconds: TimeInterval,
        dailyGoalMinutes: Int,
        currentStreak: Int,
        lifetimeSessionCount: Int,
        lifetimeFocusHours: Double,
        selectedTheme: String,
        displayName: String,
        presets: [WidgetPreset],
        isSessionActive: Bool = false,
        activeSessionName: String? = nil,
        activeSessionEndDate: Date? = nil,
        activeSessionIsPaused: Bool = false
    ) {
        guard let defaults = sharedDefaults else { return }
        
        defaults.set(todayFocusSeconds, forKey: Keys.todayFocusSeconds)
        defaults.set(dailyGoalMinutes, forKey: Keys.dailyGoalMinutes)
        defaults.set(currentStreak, forKey: Keys.currentStreak)
        defaults.set(lifetimeSessionCount, forKey: Keys.lifetimeSessionCount)
        defaults.set(lifetimeFocusHours, forKey: Keys.lifetimeFocusHours)
        defaults.set(Date(), forKey: Keys.lastUpdated)
        defaults.set(selectedTheme, forKey: Keys.selectedTheme)
        defaults.set(displayName, forKey: Keys.displayName)
        
        // Encode presets
        if let presetsData = try? JSONEncoder().encode(presets) {
            defaults.set(presetsData, forKey: Keys.presetsJSON)
        }
        
        // Active session
        defaults.set(isSessionActive, forKey: Keys.isSessionActive)
        defaults.set(activeSessionName, forKey: Keys.activeSessionName)
        defaults.set(activeSessionEndDate, forKey: Keys.activeSessionEndDate)
        defaults.set(activeSessionIsPaused, forKey: Keys.activeSessionIsPaused)
        
        // Request widget refresh
        WidgetCenter.shared.reloadTimelines(ofKind: "FocusFlowWidget")
    }
    
    // MARK: - Convenience for active session updates
    
    static func updateActiveSession(
        isActive: Bool,
        sessionName: String? = nil,
        endDate: Date? = nil,
        isPaused: Bool = false
    ) {
        guard let defaults = sharedDefaults else { return }
        
        defaults.set(isActive, forKey: Keys.isSessionActive)
        defaults.set(sessionName, forKey: Keys.activeSessionName)
        defaults.set(endDate, forKey: Keys.activeSessionEndDate)
        defaults.set(isPaused, forKey: Keys.activeSessionIsPaused)
        
        WidgetCenter.shared.reloadTimelines(ofKind: "FocusFlowWidget")
    }
}

