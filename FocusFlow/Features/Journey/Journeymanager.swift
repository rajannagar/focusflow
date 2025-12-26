import SwiftUI
import Combine

// MARK: - Daily Summary Model

struct DailySummary: Identifiable {
    let id: UUID = UUID()
    let date: Date
    
    // Focus Stats
    let totalFocusSeconds: TimeInterval
    let sessionCount: Int
    let longestSessionSeconds: TimeInterval
    
    // Tasks
    let tasksCompleted: Int
    let tasksTotal: Int
    
    // Gamification (cumulative up to this day)
    let streakCount: Int
    let level: Int
    let totalXP: Int
    let xpEarnedToday: Int
    
    // Achievements
    let badgesUnlockedToday: [String]
    let goalHit: Bool
    
    // Personalized message
    let message: String
    let messageEmoji: String
    
    // Computed
    var totalFocusMinutes: Int { Int(totalFocusSeconds / 60) }
    var longestSessionMinutes: Int { Int(longestSessionSeconds / 60) }
    var hasActivity: Bool { sessionCount > 0 || tasksCompleted > 0 }
    
    var formattedFocusTime: String {
        let hours = Int(totalFocusSeconds) / 3600
        let minutes = (Int(totalFocusSeconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "0m"
        }
    }
    
    var taskProgressText: String {
        if tasksTotal == 0 && tasksCompleted == 0 {
            return "No tasks"
        }
        return "\(tasksCompleted)/\(tasksTotal)"
    }
}

// MARK: - Journey Manager

final class JourneyManager: ObservableObject {
    static let shared = JourneyManager()
    
    @Published private(set) var summaries: [DailySummary] = []
    
    private let calendar = Calendar.autoupdatingCurrent
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Observe changes to refresh summaries
        NotificationCenter.default.publisher(for: AppSyncManager.sessionCompleted)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.generateSummaries() }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: AppSyncManager.taskCompleted)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.generateSummaries() }
            .store(in: &cancellables)
        
        // Initial generation
        generateSummaries()
    }
    
    // MARK: - Public
    
    func refresh() {
        generateSummaries()
    }
    
    // MARK: - Summary Generation
    
    func generateSummaries() {
        let stats = StatsManager.shared
        let tasksStore = TasksStore.shared
        
        // Get all unique days with activity
        var allDays = Set<Date>()
        
        // Add days from sessions
        for session in stats.sessions {
            let day = calendar.startOfDay(for: session.date)
            allDays.insert(day)
        }
        
        // Add days from task completions
        for key in tasksStore.completedOccurrenceKeys {
            // Key format: "taskId_yyyy-MM-dd"
            if let dateString = key.split(separator: "_").last,
               let date = parseDate(String(dateString)) {
                allDays.insert(date)
            }
        }
        
        // Always include today
        let today = calendar.startOfDay(for: Date())
        allDays.insert(today)
        
        // Sort days descending (newest first)
        let sortedDays = allDays.sorted { $0 > $1 }
        
        // Get all days with focus sessions for streak calculation
        let daysWithSessions = Set(stats.sessions.filter { $0.duration > 0 }.map {
            calendar.startOfDay(for: $0.date)
        })
        
        // Generate summary for each day
        var newSummaries: [DailySummary] = []
        var previousTotalXP = 0
        
        // Process oldest first for cumulative XP
        let oldestFirst = sortedDays.reversed()
        var summariesDict: [Date: DailySummary] = [:]
        
        for day in oldestFirst {
            let summary = generateSummary(
                for: day,
                stats: stats,
                tasksStore: tasksStore,
                daysWithSessions: daysWithSessions,
                previousTotalXP: previousTotalXP
            )
            summariesDict[day] = summary
            previousTotalXP = summary.totalXP
        }
        
        // Build array in descending order (newest first)
        for day in sortedDays {
            if let summary = summariesDict[day] {
                newSummaries.append(summary)
            }
        }
        
        DispatchQueue.main.async {
            self.summaries = newSummaries
        }
    }
    
    private func generateSummary(
        for date: Date,
        stats: StatsManager,
        tasksStore: TasksStore,
        daysWithSessions: Set<Date>,
        previousTotalXP: Int
    ) -> DailySummary {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        // Focus stats for this day
        let daySessions = stats.sessions.filter {
            $0.date >= dayStart && $0.date < dayEnd
        }
        let totalFocusSeconds = daySessions.reduce(0) { $0 + $1.duration }
        let sessionCount = daySessions.count
        let longestSession = daySessions.map { $0.duration }.max() ?? 0
        
        // Task stats for this day
        let (completed, total) = getTaskStats(for: date, tasksStore: tasksStore)
        
        // Streak calculation - count backwards from this date
        let streak = calculateStreakAt(date: date, daysWithSessions: daysWithSessions)
        
        // Calculate cumulative XP up to this day
        let totalXP = calculateTotalXP(upTo: date, stats: stats, tasksStore: tasksStore)
        let xpEarnedToday = max(0, totalXP - previousTotalXP)
        
        // Level from XP
        let level = levelFromXP(totalXP)
        
        // Goal hit
        let goalSeconds = Double(stats.dailyGoalMinutes * 60)
        let goalHit = goalSeconds > 0 && totalFocusSeconds >= goalSeconds
        
        // Badges (simplified)
        let badgesToday: [String] = []
        
        // Generate message
        let (message, emoji) = generateMessage(
            focusMinutes: Int(totalFocusSeconds / 60),
            sessionCount: sessionCount,
            tasksCompleted: completed,
            tasksTotal: total,
            streak: streak,
            goalHit: goalHit,
            level: level,
            xpEarned: xpEarnedToday,
            isToday: calendar.isDateInToday(date)
        )
        
        return DailySummary(
            date: date,
            totalFocusSeconds: totalFocusSeconds,
            sessionCount: sessionCount,
            longestSessionSeconds: longestSession,
            tasksCompleted: completed,
            tasksTotal: total,
            streakCount: streak,
            level: level,
            totalXP: totalXP,
            xpEarnedToday: xpEarnedToday,
            badgesUnlockedToday: badgesToday,
            goalHit: goalHit,
            message: message,
            messageEmoji: emoji
        )
    }
    
    // MARK: - Streak Calculation (matches ProfileView logic)
    
    private func calculateStreakAt(date: Date, daysWithSessions: Set<Date>) -> Int {
        let dayStart = calendar.startOfDay(for: date)
        
        guard daysWithSessions.contains(dayStart) else { return 0 }
        
        var streak = 0
        var cursor = dayStart
        
        while daysWithSessions.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        
        return streak
    }
    
    // MARK: - Task Stats
    
    private func getTaskStats(for date: Date, tasksStore: TasksStore) -> (completed: Int, total: Int) {
        let dayStart = calendar.startOfDay(for: date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: dayStart)
        
        // Count completed tasks for this day
        let completed = tasksStore.completedOccurrenceKeys.filter { key in
            key.hasSuffix(dateString)
        }.count
        
        // Count total tasks scheduled for this day using occurs(on:calendar:)
        let total = tasksStore.tasks.filter { task in
            task.occurs(on: dayStart, calendar: calendar)
        }.count
        
        return (completed, max(total, completed))
    }
    
    // MARK: - XP Calculation (matches ProfileView logic exactly)
    // ProfileView formula: Int(stats.lifetimeFocusSeconds / 60) + stats.lifetimeBestStreak * 10 + stats.lifetimeSessionCount * 5 + goalsHitCount * 20 + tasksStore.completedOccurrenceKeys.count * 3
    
    private func calculateTotalXP(upTo date: Date, stats: StatsManager, tasksStore: TasksStore) -> Int {
        let cal = calendar
        let today = cal.startOfDay(for: Date())
        let targetDay = cal.startOfDay(for: date)
        
        // For today, use exact same values as ProfileView (lifetime stats)
        if targetDay == today {
            let focusMinutes = Int(stats.lifetimeFocusSeconds / 60)
            let bestStreak = stats.lifetimeBestStreak
            let sessionCount = stats.lifetimeSessionCount
            let goalsHit = calculateGoalsHitTotal(stats: stats)
            let tasksCompleted = tasksStore.completedOccurrenceKeys.count
            
            return focusMinutes + (bestStreak * 10) + (sessionCount * 5) + (goalsHit * 20) + (tasksCompleted * 3)
        }
        
        // For past days, calculate cumulative up to that day
        let dayEnd = cal.date(byAdding: .day, value: 1, to: targetDay)!
        
        let focusSeconds = stats.sessions
            .filter { $0.date < dayEnd }
            .reduce(0) { $0 + $1.duration }
        let focusMinutes = Int(focusSeconds / 60)
        
        let sessionCount = stats.sessions.filter { $0.date < dayEnd }.count
        
        // Calculate best streak up to that date
        let bestStreak = calculateBestStreak(upTo: date, stats: stats)
        
        // Goals hit up to that date
        let goalsHit = calculateGoalsHit(upTo: date, stats: stats)
        
        // Tasks completed up to that date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let tasksCompleted = tasksStore.completedOccurrenceKeys.filter { key in
            if let keyDateStr = key.split(separator: "_").last {
                return String(keyDateStr) <= dateString
            }
            return false
        }.count
        
        return focusMinutes + (bestStreak * 10) + (sessionCount * 5) + (goalsHit * 20) + (tasksCompleted * 3)
    }
    
    // Match ProfileView's goalsHitCount calculation exactly
    private func calculateGoalsHitTotal(stats: StatsManager) -> Int {
        let goal = Double(stats.dailyGoalMinutes * 60)
        guard goal > 0 else { return 0 }
        let sessionsByDay = Dictionary(grouping: stats.sessions) { calendar.startOfDay(for: $0.date) }
        return sessionsByDay.values.filter { $0.reduce(0) { $0 + $1.duration } >= goal }.count
    }
    
    private func levelFromXP(_ xp: Int) -> Int {
        let xpPerLevel = 100
        let maxLevel = 50
        return min(max(1, xp / xpPerLevel + 1), maxLevel)
    }
    
    private func calculateBestStreak(upTo date: Date, stats: StatsManager) -> Int {
        let days = stats.sessions
            .filter { $0.duration > 0 && $0.date <= date }
            .map { calendar.startOfDay(for: $0.date) }
        
        let uniqueDays = Set(days).sorted()
        guard !uniqueDays.isEmpty else { return 0 }
        
        var bestStreak = 1
        var currentStreak = 1
        
        for i in 1..<uniqueDays.count {
            let prev = uniqueDays[i - 1]
            let curr = uniqueDays[i]
            
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: prev), nextDay == curr {
                currentStreak += 1
                bestStreak = max(bestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        return bestStreak
    }
    
    private func calculateGoalsHit(upTo date: Date, stats: StatsManager) -> Int {
        let goal = Double(stats.dailyGoalMinutes * 60)
        guard goal > 0 else { return 0 }
        
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
        
        let sessionsByDay = Dictionary(grouping: stats.sessions.filter { $0.date < dayEnd }) {
            calendar.startOfDay(for: $0.date)
        }
        
        return sessionsByDay.values.filter {
            $0.reduce(0) { $0 + $1.duration } >= goal
        }.count
    }
    
    // MARK: - Message Generation
    
    private func generateMessage(
        focusMinutes: Int,
        sessionCount: Int,
        tasksCompleted: Int,
        tasksTotal: Int,
        streak: Int,
        goalHit: Bool,
        level: Int,
        xpEarned: Int,
        isToday: Bool
    ) -> (message: String, emoji: String) {
        
        // No activity
        if sessionCount == 0 && tasksCompleted == 0 {
            if isToday {
                return ("Your focus journey continues. Ready to start a session?", "🌅")
            } else {
                return ("A quiet day. Rest is part of the journey too.", "🌙")
            }
        }
        
        // Amazing day - goal hit + most tasks done
        if goalHit && tasksTotal > 0 && tasksCompleted >= tasksTotal {
            return ("Incredible day! You crushed your goal and completed all tasks.", "🏆")
        }
        
        // Goal hit
        if goalHit {
            return ("You hit your daily goal! Consistency builds success.", "🎯")
        }
        
        // Long streak
        if streak >= 7 {
            return ("\(streak) day streak! You're unstoppable.", "🔥")
        }
        
        if streak >= 3 {
            return ("\(streak) days in a row! Keep the momentum going.", "💪")
        }
        
        // Good focus time
        if focusMinutes >= 120 {
            return ("Over 2 hours of deep focus. That's serious dedication!", "🧠")
        }
        
        if focusMinutes >= 60 {
            return ("Solid hour of focus time. You're making progress.", "✨")
        }
        
        // Tasks focused
        if tasksTotal > 0 && tasksCompleted == tasksTotal {
            return ("All tasks done! Clean slate feels good.", "✅")
        }
        
        if tasksCompleted > 0 {
            return ("Making progress on your tasks. Keep it up!", "📝")
        }
        
        // Some focus
        if sessionCount >= 3 {
            return ("Multiple focus sessions show real commitment.", "🎖️")
        }
        
        if sessionCount > 0 {
            return ("Every session counts. You showed up today.", "🌟")
        }
        
        // Fallback
        return ("Keep going, you're doing great!", "💫")
    }
    
    // MARK: - Helpers
    
    private func parseDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}

// MARK: - Date Formatting Extension

extension DailySummary {
    var relativeDateString: String {
        let calendar = Calendar.autoupdatingCurrent
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
    
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
