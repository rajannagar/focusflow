import SwiftUI
import Combine

// MARK: - App Sync Manager
/// Central coordinator that ensures all views stay in sync when state changes occur.
/// This manager listens for changes in StatsManager, TasksStore, and AppSettings,
/// and broadcasts unified events that all views can respond to.

final class AppSyncManager: ObservableObject {
    static let shared = AppSyncManager()
    
    // MARK: - Published State (for SwiftUI reactivity)
    
    /// Triggers a refresh across all views
    @Published private(set) var refreshTrigger: UUID = UUID()
    
    /// Last completed session info (for showing celebrations)
    @Published private(set) var lastCompletedSession: CompletedSessionInfo?
    
    /// Level up events
    @Published private(set) var didLevelUp: LevelUpInfo?
    
    /// New badge unlocked (badge ID)
    @Published private(set) var recentlyUnlockedBadgeID: String?
    
    // MARK: - Notification Names
    
    static let sessionCompleted = Notification.Name("AppSync.sessionCompleted")
    static let taskCompleted = Notification.Name("AppSync.taskCompleted")
    static let streakUpdated = Notification.Name("AppSync.streakUpdated")
    static let xpUpdated = Notification.Name("AppSync.xpUpdated")
    static let badgeUnlocked = Notification.Name("AppSync.badgeUnlocked")
    static let levelUp = Notification.Name("AppSync.levelUp")
    static let themeChanged = Notification.Name("AppSync.themeChanged")
    static let goalUpdated = Notification.Name("AppSync.goalUpdated")
    static let forceRefresh = Notification.Name("AppSync.forceRefresh")
    
    // MARK: - Private
    
    private var cancellables = Set<AnyCancellable>()
    private let calendar = Calendar.autoupdatingCurrent
    
    private init() {
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Listen for theme changes from AppSettings
        NotificationCenter.default.publisher(for: Self.themeChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.triggerRefresh()
            }
            .store(in: &cancellables)
        
        // Listen for force refresh requests
        NotificationCenter.default.publisher(for: Self.forceRefresh)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.triggerRefresh()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public API
    
    /// Call this when a focus session completes
    func sessionDidComplete(duration: TimeInterval, sessionName: String) {
        let info = CompletedSessionInfo(
            duration: duration,
            sessionName: sessionName,
            completedAt: Date()
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.lastCompletedSession = info
            
            // Post notification for other components
            NotificationCenter.default.post(
                name: Self.sessionCompleted,
                object: nil,
                userInfo: [
                    "duration": duration,
                    "sessionName": sessionName
                ]
            )
            
            // Check for XP/level changes
            self?.checkForLevelUp()
            
            // Update streak
            self?.checkStreakUpdate()
            
            // Trigger global refresh
            self?.triggerRefresh()
        }
    }
    
    /// Call this when a task is completed
    func taskDidComplete(taskId: UUID, taskTitle: String, on date: Date) {
        DispatchQueue.main.async { [weak self] in
            NotificationCenter.default.post(
                name: Self.taskCompleted,
                object: nil,
                userInfo: [
                    "taskId": taskId,
                    "taskTitle": taskTitle,
                    "date": date
                ]
            )
            
            // Trigger refresh
            self?.triggerRefresh()
        }
    }
    
    /// Call this when theme changes
    func themeDidChange(to theme: AppTheme) {
        DispatchQueue.main.async { [weak self] in
            self?.triggerRefresh()
            NotificationCenter.default.post(
                name: Self.themeChanged,
                object: nil,
                userInfo: ["theme": theme]
            )
        }
    }
    
    /// Call this when daily goal is updated
    func goalDidUpdate(minutes: Int) {
        DispatchQueue.main.async { [weak self] in
            NotificationCenter.default.post(
                name: Self.goalUpdated,
                object: nil,
                userInfo: ["minutes": minutes]
            )
            self?.triggerRefresh()
        }
    }
    
    /// Force a refresh across all views
    func forceRefresh() {
        DispatchQueue.main.async { [weak self] in
            self?.triggerRefresh()
            NotificationCenter.default.post(name: Self.forceRefresh, object: nil)
        }
    }
    
    /// Clear celebration states (call after user dismisses celebration UI)
    func clearCelebrations() {
        DispatchQueue.main.async { [weak self] in
            self?.lastCompletedSession = nil
            self?.recentlyUnlockedBadgeID = nil
            self?.didLevelUp = nil
        }
    }
    
    // MARK: - Private Helpers
    
    private func triggerRefresh() {
        refreshTrigger = UUID()
    }
    
    private func checkForLevelUp() {
        let stats = StatsManager.shared
        let tasksStore = TasksStore.shared
        
        let totalXP = calculateTotalXP(stats: stats, tasksStore: tasksStore)
        let currentLevel = SyncLevelSystem.levelFromXP(totalXP)
        
        // Check if we've leveled up (compare with stored level)
        let previousLevel = UserDefaults.standard.integer(forKey: "lastKnownLevel")
        
        if currentLevel > previousLevel && previousLevel > 0 {
            let info = LevelUpInfo(
                previousLevel: previousLevel,
                newLevel: currentLevel,
                newTitle: SyncLevelSystem.title(for: currentLevel)
            )
            
            DispatchQueue.main.async { [weak self] in
                self?.didLevelUp = info
                
                NotificationCenter.default.post(
                    name: Self.levelUp,
                    object: nil,
                    userInfo: ["info": info]
                )
            }
        }
        
        // Store current level
        UserDefaults.standard.set(currentLevel, forKey: "lastKnownLevel")
    }
    
    private func checkStreakUpdate() {
        let stats = StatsManager.shared
        let currentStreak = calculateCurrentStreak(stats: stats)
        
        let previousStreak = UserDefaults.standard.integer(forKey: "lastKnownStreak")
        
        if currentStreak != previousStreak {
            NotificationCenter.default.post(
                name: Self.streakUpdated,
                object: nil,
                userInfo: [
                    "previousStreak": previousStreak,
                    "currentStreak": currentStreak
                ]
            )
        }
        
        UserDefaults.standard.set(currentStreak, forKey: "lastKnownStreak")
    }
    
    // MARK: - Calculation Helpers
    
    private func calculateTotalXP(stats: StatsManager, tasksStore: TasksStore) -> Int {
        let focusMinutes = Int(stats.lifetimeFocusSeconds / 60)
        let streakBonus = stats.lifetimeBestStreak * 10
        let sessionBonus = stats.lifetimeSessionCount * 5
        let goalsHitBonus = calculateGoalsHit(stats: stats) * 20
        let tasksBonus = tasksStore.completedOccurrenceKeys.count * 3
        
        return focusMinutes + streakBonus + sessionBonus + goalsHitBonus + tasksBonus
    }
    
    private func calculateGoalsHit(stats: StatsManager) -> Int {
        let goal = Double(stats.dailyGoalMinutes * 60)
        guard goal > 0 else { return 0 }
        
        let sessionsByDay = Dictionary(grouping: stats.sessions) {
            calendar.startOfDay(for: $0.date)
        }
        
        return sessionsByDay.values.filter {
            $0.reduce(0) { $0 + $1.duration } >= goal
        }.count
    }
    
    private func calculateCurrentStreak(stats: StatsManager) -> Int {
        let days = Set(stats.sessions.filter { $0.duration > 0 }.map {
            calendar.startOfDay(for: $0.date)
        })
        
        guard !days.isEmpty else { return 0 }
        
        var streak = 0
        var cursor = calendar.startOfDay(for: Date())
        
        while days.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        
        return streak
    }
}

// MARK: - Supporting Types

struct CompletedSessionInfo: Equatable {
    let duration: TimeInterval
    let sessionName: String
    let completedAt: Date
    
    var durationMinutes: Int { Int(duration / 60) }
}

struct LevelUpInfo: Equatable {
    let previousLevel: Int
    let newLevel: Int
    let newTitle: String
}

// MARK: - Level System (for sync calculations)
/// Mirrors the LevelSystem in ProfileView for XP/level calculations
private enum SyncLevelSystem {
    static let xpPerLevel = 100
    static let maxLevel = 50
    
    static func levelFromXP(_ xp: Int) -> Int {
        min(max(1, xp / xpPerLevel + 1), maxLevel)
    }
    
    static func xpForLevel(_ level: Int) -> Int {
        (level - 1) * xpPerLevel
    }
    
    static func progressToNextLevel(_ xp: Int) -> Double {
        let level = levelFromXP(xp)
        guard level < maxLevel else { return 1.0 }
        let currentLevelXP = xpForLevel(level)
        let nextLevelXP = xpForLevel(level + 1)
        return Double(xp - currentLevelXP) / Double(nextLevelXP - currentLevelXP)
    }
    
    static func xpToNextLevel(_ xp: Int) -> Int {
        let level = levelFromXP(xp)
        guard level < maxLevel else { return 0 }
        return xpForLevel(level + 1) - xp
    }
    
    static func title(for level: Int) -> String {
        switch level {
        case 1...5: return "Beginner"
        case 6...10: return "Apprentice"
        case 11...15: return "Focused"
        case 16...20: return "Dedicated"
        case 21...25: return "Expert"
        case 26...30: return "Master"
        case 31...35: return "Grandmaster"
        case 36...40: return "Legend"
        case 41...45: return "Mythic"
        case 46...50: return "Transcendent"
        default: return "Beginner"
        }
    }
}

// MARK: - View Extension for Easy Syncing

extension View {
    /// Modifier that triggers updates when app state changes
    /// Note: Uses objectWillChange instead of .id() to avoid breaking navigation
    func syncWithAppState() -> some View {
        self.modifier(AppSyncModifier())
    }
}

private struct AppSyncModifier: ViewModifier {
    @ObservedObject private var syncManager = AppSyncManager.shared
    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var stats = StatsManager.shared
    @ObservedObject private var tasksStore = TasksStore.shared
    
    func body(content: Content) -> some View {
        // Simply observing these objects is enough to trigger re-renders
        // We don't use .id() as it breaks navigation state
        content
            // This invisible view forces a re-render when refreshTrigger changes
            // without destroying the view hierarchy
            .background(
                Color.clear
                    .onChange(of: syncManager.refreshTrigger) { _, _ in
                        // Trigger handled by @ObservedObject
                    }
            )
    }
}

// MARK: - AppSettings Extension for Theme Sync

extension AppSettings {
    /// Sets the theme and broadcasts the change to all views
    func setThemeWithSync(_ theme: AppTheme) {
        self.profileTheme = theme
        self.selectedTheme = theme
        AppSyncManager.shared.themeDidChange(to: theme)
    }
}
