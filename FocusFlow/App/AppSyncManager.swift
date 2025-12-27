import Foundation
import Combine
import SwiftUI

// MARK: - App Sync Manager
/// Central coordinator that ensures all views stay in sync when state changes occur.
/// This manager listens for ProgressStore, TasksStore, and AppSettings,
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

    /// Call this when a focus session completes (or is recorded)
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

            // ✅ NEW: tasks add XP too, so allow level-up checks from task completion
            self?.checkForLevelUp()

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

    /// Clear celebration states
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
        let progressStore = ProgressStore.shared
        let tasksStore = TasksStore.shared

        let totalXP = calculateTotalXP(progressStore: progressStore, tasksStore: tasksStore)
        let currentLevel = SyncLevelSystem.levelFromXP(totalXP)

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

        UserDefaults.standard.set(currentLevel, forKey: "lastKnownLevel")
    }

    private func checkStreakUpdate() {
        let progressStore = ProgressStore.shared
        let currentStreak = calculateCurrentStreak(progressStore: progressStore)

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

    private func calculateTotalXP(progressStore: ProgressStore, tasksStore: TasksStore) -> Int {
        let focusMinutes = Int(progressStore.lifetimeFocusSeconds / 60)
        let streakBonus = progressStore.lifetimeBestStreak * 10
        let sessionBonus = progressStore.lifetimeSessionCount * 5
        let goalsHitBonus = calculateGoalsHit(progressStore: progressStore) * 20
        let tasksBonus = tasksStore.completedOccurrenceKeys.count * 3

        return focusMinutes + streakBonus + sessionBonus + goalsHitBonus + tasksBonus
    }

    private func calculateGoalsHit(progressStore: ProgressStore) -> Int {
        let goal = Double(progressStore.dailyGoalMinutes * 60)
        guard goal > 0 else { return 0 }

        let sessionsByDay = Dictionary(grouping: progressStore.sessions) {
            calendar.startOfDay(for: $0.date)
        }

        return sessionsByDay.values.filter {
            $0.reduce(0) { $0 + $1.duration } >= goal
        }.count
    }

    private func calculateCurrentStreak(progressStore: ProgressStore) -> Int {
        let days = Set(progressStore.sessions.filter { $0.duration > 0 }.map {
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

// MARK: - Level System (match ProfileView tiers)
private enum SyncLevelSystem {
    static func xpForLevel(_ level: Int) -> Int {
        if level <= 1 { return 0 }
        return Int(pow(Double(level), 2.2) * 50)
    }

    static func levelFromXP(_ xp: Int) -> Int {
        for level in 1...50 {
            if xp < xpForLevel(level) { return level - 1 }
        }
        return 50
    }

    static func title(for level: Int) -> String {
        switch level {
        case 1...4: return "Beginner"
        case 5...9: return "Apprentice"
        case 10...14: return "Focused"
        case 15...19: return "Dedicated"
        case 20...24: return "Committed"
        case 25...29: return "Expert"
        case 30...34: return "Master"
        case 35...39: return "Grandmaster"
        case 40...44: return "Legend"
        case 45...49: return "Mythic"
        case 50: return "Transcendent"
        default: return "Beginner"
        }
    }
}

// MARK: - View Extension for Easy Syncing

extension View {
    func syncWithAppState() -> some View {
        self.modifier(AppSyncModifier())
    }
}

private struct AppSyncModifier: ViewModifier {
    @ObservedObject private var syncManager = AppSyncManager.shared
    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var tasksStore = TasksStore.shared

    func body(content: Content) -> some View {
        content
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
    func setThemeWithSync(_ theme: AppTheme) {
        self.profileTheme = theme
        self.selectedTheme = theme
        AppSyncManager.shared.themeDidChange(to: theme)
    }
}
