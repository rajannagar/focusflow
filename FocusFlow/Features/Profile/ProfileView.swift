// =========================================================
// ProfileView.swift
// =========================================================

import SwiftUI
import UIKit
import PhotosUI
import UserNotifications
import Supabase

// MARK: - Level System

private struct LevelSystem {
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

    static func progressToNextLevel(_ xp: Int) -> Double {
        let currentLevel = levelFromXP(xp)
        if currentLevel >= 50 { return 1.0 }
        let currentLevelXP = xpForLevel(currentLevel)
        let nextLevelXP = xpForLevel(currentLevel + 1)
        return min(1.0, max(0, Double(xp - currentLevelXP) / Double(nextLevelXP - currentLevelXP)))
    }

    static func xpToNextLevel(_ xp: Int) -> Int {
        let currentLevel = levelFromXP(xp)
        if currentLevel >= 50 { return 0 }
        return xpForLevel(currentLevel + 1) - xp
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

// =========================================================
// MARK: - Goal History (Shared with ProgressViewV2)
// This makes Profile's goal/XP math match per-day goals.
// =========================================================

private enum GoalHistory {
    private static let storeKey = "focusflow.pv2.dailyGoalHistory.v1"

    static func goalMinutes(for date: Date, fallback: Int, calendar: Calendar = .autoupdatingCurrent) -> Int {
        let dict = load()
        let k = key(for: date, calendar: calendar)
        return max(0, dict[k] ?? fallback)
    }

    static func set(goalMinutes: Int, for date: Date, calendar: Calendar = .autoupdatingCurrent) {
        var dict = load()
        dict[key(for: date, calendar: calendar)] = max(0, goalMinutes)
        save(dict)
    }

    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: storeKey)
    }

    private static func key(for date: Date, calendar: Calendar) -> String {
        let d = calendar.startOfDay(for: date)
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }

    private static func load() -> [String: Int] {
        guard let data = UserDefaults.standard.data(forKey: storeKey) else { return [:] }
        return (try? JSONDecoder().decode([String: Int].self, from: data)) ?? [:]
    }

    private static func save(_ dict: [String: Int]) {
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
    }
}

// MARK: - Badge

private struct Badge: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: Color
    let requirement: String
    let howToAchieve: String
    var isUnlocked: Bool = false
    var progress: Double = 0
    var currentValue: Int = 0
    var targetValue: Int = 1
}

private struct BadgeSystem {
    static func allBadges(
        totalMinutes: Int,
        totalSessions: Int,
        bestStreak: Int,
        tasksCompleted: Int,
        goalsHit: Int,
        longestSession: Int,
        morningCount: Int,
        nightCount: Int
    ) -> [Badge] {
        [
            Badge(id: "first_hour", name: "First Hour", description: "Focus for 1 total hour", icon: "clock.fill", color: .blue, requirement: "1 hour", howToAchieve: "Complete 60 minutes of focus time.", isUnlocked: totalMinutes >= 60, progress: min(1, Double(totalMinutes) / 60), currentValue: min(totalMinutes, 60), targetValue: 60),
            Badge(id: "ten_hours", name: "Dedicated", description: "Focus for 10 hours", icon: "flame.fill", color: .orange, requirement: "10 hours", howToAchieve: "Complete 600 minutes of focus time.", isUnlocked: totalMinutes >= 600, progress: min(1, Double(totalMinutes) / 600), currentValue: min(totalMinutes, 600), targetValue: 600),
            Badge(id: "fifty_hours", name: "Committed", description: "Focus for 50 hours", icon: "star.fill", color: .yellow, requirement: "50 hours", howToAchieve: "Complete 3,000 minutes of focus time.", isUnlocked: totalMinutes >= 3000, progress: min(1, Double(totalMinutes) / 3000), currentValue: min(totalMinutes, 3000), targetValue: 3000),
            Badge(id: "centurion", name: "Centurion", description: "Focus for 100 hours", icon: "trophy.fill", color: .purple, requirement: "100 hours", howToAchieve: "Complete 6,000 minutes of focus time.", isUnlocked: totalMinutes >= 6000, progress: min(1, Double(totalMinutes) / 6000), currentValue: min(totalMinutes, 6000), targetValue: 6000),

            Badge(id: "streak_3", name: "Warming Up", description: "3 day streak", icon: "bolt.fill", color: .cyan, requirement: "3 days", howToAchieve: "Focus for 3 consecutive days.", isUnlocked: bestStreak >= 3, progress: min(1, Double(bestStreak) / 3), currentValue: min(bestStreak, 3), targetValue: 3),
            Badge(id: "streak_7", name: "On Fire", description: "7 day streak", icon: "flame.circle.fill", color: .orange, requirement: "7 days", howToAchieve: "Focus for 7 consecutive days.", isUnlocked: bestStreak >= 7, progress: min(1, Double(bestStreak) / 7), currentValue: min(bestStreak, 7), targetValue: 7),
            Badge(id: "streak_30", name: "Unstoppable", description: "30 day streak", icon: "crown.fill", color: .yellow, requirement: "30 days", howToAchieve: "Focus for 30 consecutive days.", isUnlocked: bestStreak >= 30, progress: min(1, Double(bestStreak) / 30), currentValue: min(bestStreak, 30), targetValue: 30),

            Badge(id: "marathon", name: "Marathon", description: "2+ hour session", icon: "figure.run", color: .green, requirement: "2hr session", howToAchieve: "Complete a 120+ minute session.", isUnlocked: longestSession >= 120, progress: min(1, Double(longestSession) / 120), currentValue: min(longestSession, 120), targetValue: 120),

            Badge(id: "early_bird", name: "Early Bird", description: "10 morning sessions", icon: "sunrise.fill", color: .orange, requirement: "10 mornings", howToAchieve: "Start 10 sessions before 8 AM.", isUnlocked: morningCount >= 10, progress: min(1, Double(morningCount) / 10), currentValue: min(morningCount, 10), targetValue: 10),
            Badge(id: "night_owl", name: "Night Owl", description: "10 night sessions", icon: "moon.stars.fill", color: .indigo, requirement: "10 nights", howToAchieve: "Start 10 sessions after 10 PM.", isUnlocked: nightCount >= 10, progress: min(1, Double(nightCount) / 10), currentValue: min(nightCount, 10), targetValue: 10),

            Badge(id: "task_starter", name: "Task Starter", description: "Complete 10 tasks", icon: "checkmark.circle.fill", color: .green, requirement: "10 tasks", howToAchieve: "Check off 10 tasks.", isUnlocked: tasksCompleted >= 10, progress: min(1, Double(tasksCompleted) / 10), currentValue: min(tasksCompleted, 10), targetValue: 10),
            Badge(id: "task_master", name: "Task Master", description: "Complete 50 tasks", icon: "checkmark.seal.fill", color: .blue, requirement: "50 tasks", howToAchieve: "Check off 50 tasks.", isUnlocked: tasksCompleted >= 50, progress: min(1, Double(tasksCompleted) / 50), currentValue: min(tasksCompleted, 50), targetValue: 50),
            Badge(id: "task_legend", name: "Task Legend", description: "Complete 200 tasks", icon: "star.circle.fill", color: .purple, requirement: "200 tasks", howToAchieve: "Check off 200 tasks.", isUnlocked: tasksCompleted >= 200, progress: min(1, Double(tasksCompleted) / 200), currentValue: min(tasksCompleted, 200), targetValue: 200),

            Badge(id: "goal_crusher", name: "Goal Crusher", description: "Hit goal 10 times", icon: "target", color: .red, requirement: "10 goals", howToAchieve: "Hit your daily goal 10 times.", isUnlocked: goalsHit >= 10, progress: min(1, Double(goalsHit) / 10), currentValue: min(goalsHit, 10), targetValue: 10),

            Badge(id: "sessions_25", name: "Getting Started", description: "25 sessions", icon: "play.circle.fill", color: .blue, requirement: "25 sessions", howToAchieve: "Complete 25 focus sessions.", isUnlocked: totalSessions >= 25, progress: min(1, Double(totalSessions) / 25), currentValue: min(totalSessions, 25), targetValue: 25),
            Badge(id: "sessions_100", name: "Veteran", description: "100 sessions", icon: "medal.fill", color: .purple, requirement: "100 sessions", howToAchieve: "Complete 100 focus sessions.", isUnlocked: totalSessions >= 100, progress: min(1, Double(totalSessions) / 100), currentValue: min(totalSessions, 100), targetValue: 100),
        ]
    }
}

// MARK: - Components

private struct XPProgressBar: View {
    let progress: Double
    let color: Color
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1))
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 8)
    }
}

private struct LevelBadge: View {
    let level: Int, color: Color, size: CGFloat
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [color, color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: size, height: size)
            Text("\(level)")
                .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .shadow(color: color.opacity(0.5), radius: 6)
    }
}

private struct ProBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill").font(.system(size: 10))
            Text("PRO").font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(.yellow)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.yellow.opacity(0.2))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.yellow.opacity(0.3), lineWidth: 1))
    }
}

private struct BadgeCard: View {
    let badge: Badge, size: CGFloat, onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(badge.isUnlocked ? badge.color.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: size, height: size)

                    if !badge.isUnlocked {
                        Circle()
                            .trim(from: 0, to: badge.progress)
                            .stroke(badge.color.opacity(0.4), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: size - 4, height: size - 4)
                            .rotationEffect(.degrees(-90))
                    }

                    Image(systemName: badge.icon)
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundColor(badge.isUnlocked ? badge.color : .white.opacity(0.25))

                    if badge.isUnlocked {
                        Circle()
                            .fill(badge.color.opacity(0.3))
                            .frame(width: size + 10, height: size + 10)
                            .blur(radius: 10)
                    }
                }

                Text(badge.name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(badge.isUnlocked ? .white : .white.opacity(0.4))
                    .lineLimit(1)
            }
            .frame(width: size + 10)
        }
        .buttonStyle(.plain)
    }
}

private struct WeekDayDot: View {
    let day: String, isActive: Bool, isToday: Bool, color: Color
    var body: some View {
        VStack(spacing: 6) {
            Text(day)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
            Circle()
                .fill(isActive ? color : Color.white.opacity(0.1))
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(isToday ? Color.white.opacity(0.6) : Color.clear, lineWidth: 2))
        }
    }
}

private struct RingProgress: View {
    let progress: Double, lineWidth: CGFloat, color: Color
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(1.0, progress))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

// =========================================================
// MARK: - MAIN PROFILE VIEW
// =========================================================

struct ProfileView: View {
    // External navigation trigger from ContentView
    @Binding var navigateToJourney: Bool

    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var tasksStore = TasksStore.shared
    @ObservedObject private var auth = AuthManagerV2.shared
    @EnvironmentObject private var pro: ProEntitlementManager

    @State private var showingSettings = false
    @State private var showingEditProfile = false
    @State private var showingAllBadges = false
    @State private var showingLevelInfo = false
    @State private var showingPaywall = false
    @State private var selectedBadge: Badge? = nil
    @State private var dataVersion = 0

    // ✅ Prevent double-taps
    @State private var isSigningOut = false

    private let cal = Calendar.autoupdatingCurrent

    private var theme: AppTheme { settings.profileTheme }
    private var today: Date { cal.startOfDay(for: Date()) }
    private var displayName: String {
        let n = settings.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return n.isEmpty ? "Focus Master" : n
    }

    private var goalsHitCount: Int {
        let _ = dataVersion

        let sessionsByDay = Dictionary(grouping: progressStore.sessions) { cal.startOfDay(for: $0.date) }

        var hits = 0
        for (day, sessions) in sessionsByDay {
            let goalMin = GoalHistory.goalMinutes(
                for: day,
                fallback: max(0, progressStore.dailyGoalMinutes),
                calendar: cal
            )
            guard goalMin > 0 else { continue }

            let total = sessions.reduce(0.0) { $0 + $1.duration }
            if total >= Double(goalMin) * 60.0 { hits += 1 }
        }
        return hits
    }

    private var totalXP: Int {
        let _ = dataVersion
        return Int(progressStore.lifetimeFocusSeconds / 60)
        + progressStore.lifetimeBestStreak * 10
        + progressStore.lifetimeSessionCount * 5
        + goalsHitCount * 20
        + tasksStore.completedOccurrenceKeys.count * 3
    }

    private var currentLevel: Int { LevelSystem.levelFromXP(totalXP) }
    private var levelProgress: Double { LevelSystem.progressToNextLevel(totalXP) }
    private var xpToNext: Int { LevelSystem.xpToNextLevel(totalXP) }
    private var currentTitle: String { LevelSystem.title(for: currentLevel) }

    private var todayMinutes: Int { Int(progressStore.totalToday / 60) }
    private var todayGoal: Int {
        max(
            1,
            GoalHistory.goalMinutes(for: today, fallback: max(1, progressStore.dailyGoalMinutes), calendar: cal)
        )
    }
    private var todayProgress: Double { min(1.0, Double(todayMinutes) / Double(todayGoal)) }

    private var tasksCompletedToday: Int {
        let visible = tasksStore.tasksVisible(on: today, calendar: cal)
        return visible.filter { tasksStore.isCompleted(taskId: $0.id, on: today, calendar: cal) }.count
    }
    private var tasksTotalToday: Int { tasksStore.tasksVisible(on: today, calendar: cal).count }
    private var totalTasksCompleted: Int { tasksStore.completedOccurrenceKeys.count }

    private var weekInterval: DateInterval? { cal.dateInterval(of: .weekOfYear, for: Date()) }
    private var activeDaysThisWeek: Set<Date> {
        guard let interval = weekInterval else { return [] }
        return Set(
            progressStore.sessions
                .filter { $0.date >= interval.start && $0.date < interval.end && $0.duration >= 60 }
                .map { cal.startOfDay(for: $0.date) }
        )
    }
    private var thisWeekMinutes: Int {
        guard let interval = weekInterval else { return 0 }
        return Int(
            progressStore.sessions
                .filter { $0.date >= interval.start && $0.date < interval.end }
                .reduce(0) { $0 + $1.duration } / 60
        )
    }

    private var currentStreak: Int {
        let days = Set(progressStore.sessions.filter { $0.duration > 0 }.map { cal.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }
        var streak = 0
        var cursor = today
        while days.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    private var allBadges: [Badge] {
        let totalMinutes = Int(progressStore.lifetimeFocusSeconds / 60)
        let longestSession = Int((progressStore.sessions.map { $0.duration }.max() ?? 0) / 60)
        let morningCount = progressStore.sessions.filter { cal.component(.hour, from: $0.date) < 8 && $0.duration >= 300 }.count
        let nightCount = progressStore.sessions.filter { cal.component(.hour, from: $0.date) >= 22 && $0.duration >= 300 }.count

        return BadgeSystem.allBadges(
            totalMinutes: totalMinutes,
            totalSessions: progressStore.lifetimeSessionCount,
            bestStreak: progressStore.lifetimeBestStreak,
            tasksCompleted: totalTasksCompleted,
            goalsHit: goalsHitCount,
            longestSession: longestSession,
            morningCount: morningCount,
            nightCount: nightCount
        )
    }
    private var unlockedBadges: [Badge] { allBadges.filter { $0.isUnlocked } }
    private var inProgressBadges: [Badge] { allBadges.filter { !$0.isUnlocked && $0.progress > 0 }.sorted { $0.progress > $1.progress } }

    private var weekDays: [(day: String, date: Date, isActive: Bool, isToday: Bool)] {
        guard let interval = weekInterval else { return [] }
        let dayLetters = ["S", "M", "T", "W", "T", "F", "S"]

        var result: [(String, Date, Bool, Bool)] = []
        var cursor = interval.start
        var dayIndex = cal.component(.weekday, from: cursor) - 1

        for _ in 0..<7 {
            result.append((
                dayLetters[dayIndex % 7],
                cursor,
                activeDaysThisWeek.contains(cursor),
                cal.isDateInToday(cursor)
            ))
            dayIndex += 1
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    var body: some View {
        NavigationStack {
            GeometryReader { _ in
                ZStack {
                    PremiumAppBackground(theme: theme)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            identityCard.padding(.top, 16)
                            journeyButton
                            badgesSection
                            allTimeSection
                            weekCard
                            accountSection
                            if !pro.isPro { upgradeCard }
                            Text("FocusFlow v1.0")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.2))
                                .padding(.top, 8)
                                .padding(.bottom, 100)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $navigateToJourney) {
                JourneyView()
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsSheet(theme: theme).environmentObject(pro) }
        .sheet(isPresented: $showingEditProfile) { EditProfileSheet(theme: theme) }
        .sheet(isPresented: $showingAllBadges) { AllBadgesSheet(badges: allBadges, theme: theme) }
        .sheet(isPresented: $showingLevelInfo) { LevelInfoSheet(currentLevel: currentLevel, totalXP: totalXP, theme: theme) }
        .sheet(item: $selectedBadge) { badge in BadgeDetailSheet(badge: badge, theme: theme) }
        .sheet(isPresented: $showingPaywall) { PaywallView().environmentObject(pro) }
        .onReceive(NotificationCenter.default.publisher(for: AppSyncManager.sessionCompleted)) { _ in dataVersion += 1 }
        .onReceive(NotificationCenter.default.publisher(for: AppSyncManager.taskCompleted)) { _ in dataVersion += 1 }
    }

    // MARK: - Identity Card

    private var identityCard: some View {
        VStack(spacing: 0) {
            HStack {
                if pro.isPro { ProBadge() }
                Spacer()
                Button {
                    Haptics.impact(.light)
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Button {
                Haptics.impact(.light)
                showingEditProfile = true
            } label: {
                ZStack {
                    RingProgress(progress: levelProgress, lineWidth: 4, color: theme.accentPrimary)
                        .frame(width: 96, height: 96)

                    profileAvatar(size: 80)

                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            LevelBadge(level: currentLevel, color: theme.accentPrimary, size: 32)
                                .offset(x: 6, y: 6)
                        }
                    }
                    .frame(width: 96, height: 96)
                }
            }
            .buttonStyle(.plain)

            Text(displayName)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 12)

            HStack(spacing: 6) {
                Text(currentTitle)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(theme.accentPrimary)
                Button {
                    Haptics.impact(.light)
                    showingLevelInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(theme.accentPrimary.opacity(0.15))
            .clipShape(Capsule())
            .padding(.top, 6)

            VStack(spacing: 6) {
                XPProgressBar(progress: levelProgress, color: theme.accentPrimary)

                HStack {
                    Text("\(totalXP) XP")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Text(currentLevel < 50 ? "\(xpToNext) XP to Level \(currentLevel + 1)" : "MAX LEVEL")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(currentLevel < 50 ? .white.opacity(0.4) : theme.accentPrimary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    @ViewBuilder private func profileAvatar(size: CGFloat) -> some View {
        if let data = settings.profileImageData, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            let option = AvatarLibrary.option(for: settings.avatarID)
            Circle()
                .fill(LinearGradient(colors: [option.gradientA, option.gradientB], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: option.symbol)
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                )
        }
    }

    // MARK: - Journey Button

    private var journeyButton: some View {
        Button {
            Haptics.impact(.light)
            navigateToJourney = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.accentPrimary.opacity(0.3), theme.accentSecondary.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.accentPrimary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("My Journey")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Text("Your focus story & daily summaries")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [theme.accentPrimary.opacity(0.3), theme.accentSecondary.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Badges Section

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("BADGES")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
                Spacer()
                Button {
                    Haptics.impact(.light)
                    showingAllBadges = true
                } label: {
                    HStack(spacing: 4) {
                        Text("\(unlockedBadges.count)/\(allBadges.count)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.accentPrimary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(theme.accentPrimary.opacity(0.6))
                    }
                }
            }
            .padding(.bottom, 4)

            if unlockedBadges.isEmpty && inProgressBadges.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "trophy")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.2))
                    Text("Start focusing to earn badges!")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(unlockedBadges.prefix(4)) { badge in
                            BadgeCard(badge: badge, size: 52) {
                                Haptics.impact(.light)
                                selectedBadge = badge
                            }
                        }
                        if !inProgressBadges.isEmpty {
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 1, height: 50)
                            ForEach(inProgressBadges.prefix(2)) { badge in
                                BadgeCard(badge: badge, size: 52) {
                                    Haptics.impact(.light)
                                    selectedBadge = badge
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                }
                .padding(.top, -6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - All Time Section

    private var allTimeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ALL TIME")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCell(icon: "clock.fill", value: formatTime(progressStore.lifetimeFocusSeconds), label: "Focused", color: theme.accentPrimary)
                statCell(icon: "flame.fill", value: "\(progressStore.lifetimeBestStreak)", label: "Best Streak", color: .orange)
                statCell(icon: "play.circle.fill", value: "\(progressStore.lifetimeSessionCount)", label: "Sessions", color: .blue)
                statCell(icon: "checkmark.circle.fill", value: "\(totalTasksCompleted)", label: "Tasks Done", color: .green)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))

                    HStack(spacing: 12) {
                        Label("\(todayMinutes)m", systemImage: "clock")
                        if tasksTotalToday > 0 {
                            Label("\(tasksCompletedToday)/\(tasksTotalToday)", systemImage: "checklist")
                        }
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        Haptics.impact(.light)
                        let current = todayGoal
                        let newVal = max(1, current - 5)
                        GoalHistory.set(goalMinutes: newVal, for: today, calendar: cal)
                        progressStore.dailyGoalMinutes = newVal
                        AppSyncManager.shared.goalDidUpdate(minutes: newVal)
                        AppSyncManager.shared.forceRefresh()
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Text("\(todayGoal)m")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))

                    Button {
                        Haptics.impact(.light)
                        let current = todayGoal
                        let newVal = min(240, current + 5)
                        GoalHistory.set(goalMinutes: newVal, for: today, calendar: cal)
                        progressStore.dailyGoalMinutes = newVal
                        AppSyncManager.shared.goalDidUpdate(minutes: newVal)
                        AppSyncManager.shared.forceRefresh()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func statCell(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = seconds / 3600
        if hours >= 100 { return "\(Int(hours))h" }
        if hours >= 1 { return String(format: "%.1fh", hours) }
        return "\(Int(seconds / 60))m"
    }

    // MARK: - Week Card

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("THIS WEEK")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
                Spacer()
                Text("\(thisWeekMinutes)m • \(activeDaysThisWeek.count)/7 days")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }

            HStack(spacing: 0) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { _, day in
                    WeekDayDot(day: day.day, isActive: day.isActive, isToday: day.isToday, color: theme.accentPrimary)
                        .frame(maxWidth: .infinity)
                }
            }

            if currentStreak > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill").foregroundColor(.orange)
                    Text("\(currentStreak) day streak")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(spacing: 0) {
            switch auth.state {
            case .signedIn:
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(settings.accountEmail ?? "Signed in")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                            Text("Synced")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    Spacer()
                    Button {
                        Haptics.impact(.medium)
                        signOutTapped()
                    } label: {
                        if isSigningOut {
                            ProgressView()
                                .tint(.white.opacity(0.7))
                                .scaleEffect(0.9)
                                .frame(width: 70, height: 28)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                        } else {
                            Text("Sign Out")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                    .disabled(isSigningOut)
                }
                .padding(14)
            
            case .guest:
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Guest")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        HStack(spacing: 4) {
                            Circle().fill(Color.orange).frame(width: 6, height: 6)
                            Text("Local data")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    Spacer()
                    Button {
                        Haptics.impact(.medium)
                        auth.exitGuest()
                    } label: {
                        Text("Sign In")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
                .padding(14)
            
            default:
                EmptyView()
            }
        }
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func signOutTapped() {
        guard !isSigningOut else { return }
        isSigningOut = true
        Task {
            await auth.signOut()
            await MainActor.run {
                isSigningOut = false
            }
        }
    }

    // MARK: - Upgrade Card

    private var upgradeCard: some View {
        Button {
            Haptics.impact(.medium)
            showingPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upgrade to Pro")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("Unlock all features & 2X XP")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.yellow.opacity(0.6))
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.yellow.opacity(0.15), Color.orange.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// =========================================================
// MARK: - Level Info Sheet
// =========================================================

private struct LevelInfoSheet: View {
    let currentLevel: Int, totalXP: Int, theme: AppTheme
    @Environment(\.dismiss) private var dismiss

    private let levelTiers: [(range: String, title: String, color: Color)] = [
        ("1-4", "Beginner", .gray), ("5-9", "Apprentice", .green), ("10-14", "Focused", .blue), ("15-19", "Dedicated", .purple),
        ("20-24", "Committed", .orange), ("25-29", "Expert", .pink), ("30-34", "Master", .red), ("35-39", "Grandmaster", .yellow),
        ("40-44", "Legend", .cyan), ("45-49", "Mythic", .indigo), ("50", "Transcendent", .white)
    ]

    var body: some View {
        ZStack {
            PremiumAppBackground(theme: theme, showParticles: false)

            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Levels & XP")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            Text("How to level up")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }

                    VStack(spacing: 8) {
                        LevelBadge(level: currentLevel, color: theme.accentPrimary, size: 60)
                        Text("Level \(currentLevel)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(totalXP) XP total")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.vertical, 16)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("EARN XP BY")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1.5)
                        xpRow(icon: "clock.fill", text: "Focusing", value: "1 XP / minute", color: theme.accentPrimary)
                        xpRow(icon: "play.circle.fill", text: "Completing sessions", value: "5 XP each", color: .blue)
                        xpRow(icon: "flame.fill", text: "Building streaks", value: "10 XP / day", color: .orange)
                        xpRow(icon: "target", text: "Hitting daily goals", value: "20 XP each", color: .red)
                        xpRow(icon: "checkmark.circle.fill", text: "Completing tasks", value: "3 XP each", color: .green)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("LEVEL TITLES")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1.5)

                        ForEach(levelTiers, id: \.title) { tier in
                            HStack {
                                Text("Lv \(tier.range)")
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(width: 60, alignment: .leading)
                                Text(tier.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(tier.color)
                                Spacer()
                                if isCurrentTier(tier.range) {
                                    Text("CURRENT")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(theme.accentPrimary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(theme.accentPrimary.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(20)
            }
        }
    }

    private func isCurrentTier(_ range: String) -> Bool {
        let parts = range.components(separatedBy: "-")
        let low = Int(parts.first ?? "0") ?? 0
        let high = Int(parts.last ?? "50") ?? 50
        return currentLevel >= low && currentLevel <= high
    }

    private func xpRow(icon: String, text: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(color).frame(width: 24)
            Text(text).font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.white.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
}

// =========================================================
// MARK: - All Badges Sheet
// =========================================================

private struct AllBadgesSheet: View {
    let badges: [Badge], theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @State private var selectedBadge: Badge? = nil

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    private var unlockedBadges: [Badge] { badges.filter { $0.isUnlocked } }
    private var lockedBadges: [Badge] { badges.filter { !$0.isUnlocked }.sorted { $0.progress > $1.progress } }

    var body: some View {
        ZStack {
            PremiumAppBackground(theme: theme, showParticles: false)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("All Badges").font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                            Text("\(unlockedBadges.count) of \(badges.count) unlocked")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    if !unlockedBadges.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("UNLOCKED")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1.5)
                                .padding(.horizontal, 20)

                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(unlockedBadges) { badge in
                                    BadgeCard(badge: badge, size: 56) { selectedBadge = badge }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    if !lockedBadges.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("IN PROGRESS")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1.5)
                                .padding(.horizontal, 20)

                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(lockedBadges) { badge in
                                    BadgeCard(badge: badge, size: 56) { selectedBadge = badge }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailSheet(badge: badge, theme: theme)
        }
    }
}

// =========================================================
// MARK: - Badge Detail Sheet
// =========================================================

private struct BadgeDetailSheet: View {
    let badge: Badge, theme: AppTheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            PremiumAppBackground(theme: theme, showParticles: false)

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                ZStack {
                    if badge.isUnlocked {
                        Circle()
                            .fill(badge.color.opacity(0.2))
                            .frame(width: 140, height: 140)
                            .blur(radius: 30)
                    }

                    Circle()
                        .fill(badge.isUnlocked ? badge.color.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 100, height: 100)

                    if !badge.isUnlocked {
                        Circle()
                            .trim(from: 0, to: badge.progress)
                            .stroke(badge.color.opacity(0.5), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 96, height: 96)
                            .rotationEffect(.degrees(-90))
                    }

                    Image(systemName: badge.icon)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(badge.isUnlocked ? badge.color : .white.opacity(0.25))
                }

                VStack(spacing: 8) {
                    Text(badge.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Text(badge.description)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    if badge.isUnlocked {
                        Text("UNLOCKED")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(badge.color)
                            .padding(.top, 8)
                    } else {
                        Text("\(badge.currentValue)/\(badge.targetValue)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 8)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1))
                                RoundedRectangle(cornerRadius: 4).fill(badge.color).frame(width: geo.size.width * badge.progress)
                            }
                        }
                        .frame(height: 6)
                        .frame(maxWidth: 200)
                        .padding(.top, 4)
                    }
                }

                VStack(spacing: 8) {
                    Text("HOW TO ACHIEVE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1.5)

                    Text(badge.howToAchieve)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 16)

                Spacer()
                Spacer()
            }
        }
        .presentationDetents([.medium])
    }
}

// =========================================================
// MARK: - Settings Sheet (Updated with new notification system)
// =========================================================

private struct SettingsSheet: View {
    let theme: AppTheme
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var tasksStore = TasksStore.shared
    @EnvironmentObject private var pro: ProEntitlementManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingReset = false
    @State private var resetText = ""
    @State private var showingPaywall = false
    @State private var showingNotificationSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumAppBackground(theme: theme, showParticles: false)
                settingsContent
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .alert("Reset All Data", isPresented: $showingReset) {
            TextField("Type RESET to confirm", text: $resetText)
            Button("Cancel", role: .cancel) { resetText = "" }
            Button("Delete Everything", role: .destructive) {
                if resetText.uppercased() == "RESET" {
                    progressStore.clearAll()
                    tasksStore.clearAll()
                    GoalHistory.clearAll()
                    AppSyncManager.shared.forceRefresh()
                    resetText = ""
                }
            }
        } message: {
            Text("This will permanently delete all your focus sessions, tasks, goals, and progress. Type RESET to confirm.")
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView().environmentObject(pro)
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
    }

    private var settingsContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                themeSection
                feedbackSection
                notificationsSection
                subscriptionSection
                dataSection
                aboutSection
            }
            .padding(20)
        }
    }

    private var themeSection: some View {
        SettingsSectionView(title: "THEME") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(AppTheme.allCases) { t in
                        themeButton(for: t)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
        }
    }

    private func themeButton(for t: AppTheme) -> some View {
        Button {
            Haptics.impact(.light)
            settings.setThemeWithSync(t)
        } label: {
            VStack(spacing: 8) {
                Circle()
                    .fill(LinearGradient(colors: [t.accentPrimary, t.accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: settings.profileTheme == t ? 3 : 0)
                            .frame(width: 48, height: 48)
                    )
                    .scaleEffect(settings.profileTheme == t ? 1.0 : 0.92)
                    .animation(.easeInOut(duration: 0.15), value: settings.profileTheme == t)

                Text(t.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(settings.profileTheme == t ? .white : .white.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }

    private var feedbackSection: some View {
        SettingsSectionView(title: "FEEDBACK") {
            Toggle("Sounds", isOn: $settings.soundEnabled).tint(theme.accentPrimary)
            Toggle("Haptics", isOn: $settings.hapticsEnabled).tint(theme.accentPrimary)
        }
    }

    private var notificationsSection: some View {
        SettingsSectionView(title: "NOTIFICATIONS") {
            Button {
                Haptics.impact(.light)
                showingNotificationSettings = true
            } label: {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 14))
                            .foregroundColor(theme.accentPrimary)

                        Text("Manage Notifications")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
    }

    private var subscriptionSection: some View {
        SettingsSectionView(title: "SUBSCRIPTION") {
            Button { showingPaywall = true } label: {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill").foregroundColor(.yellow)
                        Text("FocusFlow Pro")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text(pro.isPro ? "Active" : "Subscribe")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(pro.isPro ? .green : theme.accentPrimary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
    }

    private var dataSection: some View {
        SettingsSectionView(title: "DATA") {
            Button { showingReset = true } label: {
                HStack {
                    Text("Reset All Data").foregroundColor(.red)
                    Spacer()
                    Image(systemName: "exclamationmark.triangle").foregroundColor(.red.opacity(0.6))
                }
            }
        }
    }

    private var aboutSection: some View {
        SettingsSectionView(title: "ABOUT") {
            Link(destination: URL(string: "https://rajannagar.github.io/FocusFlow/privacy.html")!) {
                HStack {
                    Text("Privacy Policy").foregroundColor(.white)
                    Spacer()
                    Image(systemName: "arrow.up.right").foregroundColor(.white.opacity(0.3))
                }
            }
            Link(destination: URL(string: "https://rajannagar.github.io/FocusFlow/terms.html")!) {
                HStack {
                    Text("Terms of Service").foregroundColor(.white)
                    Spacer()
                    Image(systemName: "arrow.up.right").foregroundColor(.white.opacity(0.3))
                }
            }
        }
    }
}

// MARK: - Settings Section View

private struct SettingsSectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)

            VStack(spacing: 12) {
                content()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(12)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Edit Profile Sheet

private struct EditProfileSheet: View {
    let theme: AppTheme
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingAvatars = false

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumAppBackground(theme: theme, showParticles: false)

                VStack(spacing: 24) {
                    ZStack {
                        if let data = settings.profileImageData, let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            let opt = AvatarLibrary.option(for: settings.avatarID)
                            Circle()
                                .fill(LinearGradient(colors: [opt.gradientA, opt.gradientB], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: opt.symbol)
                                        .font(.system(size: 32, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.9))
                                )
                        }
                    }

                    HStack(spacing: 12) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Photo", systemImage: "photo")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Capsule())
                        }

                        Button { showingAvatars = true } label: {
                            Label("Avatar", systemImage: "face.smiling")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Capsule())
                        }

                        if settings.profileImageData != nil {
                            Button { settings.profileImageData = nil } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(width: 28, height: 28)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Display Name")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))

                        TextField("Your name", text: $name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .tint(.white)
                    }
                    .padding(.horizontal, 20)

                    Button {
                        settings.displayName = name
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(theme.accentPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onAppear { name = settings.displayName }
        .sheet(isPresented: $showingAvatars) {
            AvatarPickerSheet(avatarID: $settings.avatarID, theme: theme)
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        settings.profileImageData = data
                    }
                }
            }
        }
    }
}

// MARK: - Avatar Library

private struct AvatarOption: Identifiable, Equatable {
    let id: String, symbol: String, gradientA: Color, gradientB: Color
}

private enum AvatarLibrary {
    static let options: [AvatarOption] = [
        .init(id: "sparkles", symbol: "sparkles", gradientA: .purple, gradientB: .pink),
        .init(id: "flame", symbol: "flame.fill", gradientA: .orange, gradientB: .red),
        .init(id: "bolt", symbol: "bolt.fill", gradientA: .blue, gradientB: .cyan),
        .init(id: "star", symbol: "star.fill", gradientA: .yellow, gradientB: .orange),
        .init(id: "heart", symbol: "heart.fill", gradientA: .pink, gradientB: .red),
        .init(id: "moon", symbol: "moon.stars.fill", gradientA: .indigo, gradientB: .purple),
        .init(id: "leaf", symbol: "leaf.fill", gradientA: .green, gradientB: .mint),
        .init(id: "crown", symbol: "crown.fill", gradientA: .yellow, gradientB: .orange),
        .init(id: "trophy", symbol: "trophy.fill", gradientA: .yellow, gradientB: .orange),
        .init(id: "rocket", symbol: "rocket.fill", gradientA: .blue, gradientB: .purple),
        .init(id: "brain", symbol: "brain.head.profile", gradientA: .cyan, gradientB: .blue),
        .init(id: "target", symbol: "target", gradientA: .red, gradientB: .orange),
    ]

    static func option(for id: String) -> AvatarOption { options.first { $0.id == id } ?? options[0] }
}

private struct AvatarPickerSheet: View {
    @Binding var avatarID: String
    let theme: AppTheme
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            PremiumAppBackground(theme: theme, showParticles: false)

            VStack(spacing: 16) {
                HStack {
                    Text("Choose Avatar")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(AvatarLibrary.options) { opt in
                        Button {
                            avatarID = opt.id
                            dismiss()
                        } label: {
                            Circle()
                                .fill(LinearGradient(colors: [opt.gradientA, opt.gradientB], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: opt.symbol)
                                        .font(.system(size: 26, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.9))
                                )
                                .overlay(Circle().stroke(avatarID == opt.id ? Color.white : Color.clear, lineWidth: 3))
                        }
                    }
                }
                .padding(20)

                Spacer()
            }
        }
    }
}

#Preview {
    ProfileView(navigateToJourney: .constant(false))
        .environmentObject(ProEntitlementManager())
}
