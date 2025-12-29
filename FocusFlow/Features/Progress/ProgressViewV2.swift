import SwiftUI
import UIKit

// =========================================================
// MARK: - ProgressViewV2 (Dark Premium Theme)
// =========================================================

struct ProgressViewV2: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var tasksStore = TasksStore.shared

    @State private var selectedDate: Date = Date()
    @State private var showGoalSheet = false
    @State private var showDatePicker = false
    @State private var goalVersion: Int = 0

    @State private var weekPageIndex: Int = 0
    @State private var weekStarts: [Date] = []
    @State private var preferredWeekdayOffset: Int = 0
    @State private var isSyncingFromPager = false
    @State private var isSyncingFromDate = false
    private let weekWindowRadius = 10
    
    // Info sheet states
    @State private var showStreakInfo = false
    @State private var showScoreInfo = false
    @State private var showComparisonInfo = false
    @State private var showInsightsInfo = false

    private var theme: AppTheme { appSettings.profileTheme }
    private var cal: Calendar { .autoupdatingCurrent }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Premium animated background
                PremiumAppBackground(theme: theme)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        headerSection
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        // Date Navigator
                        dateNavigator
                            .padding(.horizontal, 20)

                        // Today Hero Card
                        todayHeroCard
                            .padding(.horizontal, 20)

                        // Current Streak & Focus Score
                        streakAndScoreSection
                            .padding(.horizontal, 20)

                        // Quick Stats Strip
                        quickStatsStrip
                            .padding(.horizontal, 20)

                        // Comparison with Last Week
                        weekComparisonCard
                            .padding(.horizontal, 20)

                        // Weekly Activity Chart
                        weeklyActivityCard
                            .padding(.horizontal, 20)

                        // Week Summary
                        weekSummaryCard
                            .padding(.horizontal, 20)

                        // Insights Grid
                        insightsGrid
                            .padding(.horizontal, 20)

                        // Session Timeline
                        sessionTimeline
                            .padding(.horizontal, 20)

                        Spacer(minLength: 120)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showGoalSheet) {
            GoalSheet(
                theme: theme,
                goalMinutes: Binding(
                    get: { goalMinutes(for: selectedDate) },
                    set: { newValue in
                        PV2GoalHistory.set(goalMinutes: max(0, newValue), for: selectedDate, calendar: cal)
                        progressStore.dailyGoalMinutes = max(0, newValue)
                        goalVersion &+= 1
                    }
                )
            )
            .presentationDetents([.fraction(0.65), .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(red: 0.08, green: 0.08, blue: 0.10))
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(theme: theme, date: $selectedDate)
                .presentationDetents([.fraction(0.65), .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(red: 0.08, green: 0.08, blue: 0.10))
        }
        .sheet(isPresented: $showStreakInfo) {
            InfoSheet(
                theme: theme,
                icon: "flame.fill",
                iconColor: .orange,
                title: "Focus Streak",
                description: "Your streak counts consecutive days where you've focused for at least 1 minute.",
                details: [
                    ("How it works", "Each day you complete any focus session, your streak increases by 1. The counter resets at midnight."),
                    ("Maintaining it", "Focus at least once every day to keep your streak alive. Even a 5-minute session counts!"),
                    ("If you miss a day", "Your streak resets to 0, but don't worry – start fresh and build it back up. Consistency beats perfection."),
                    ("Why it matters", "Streaks build habits. Research shows it takes about 66 days to form a habit. Your streak helps you get there."),
                    ("Pro tip", "Set a daily reminder to protect your streak. Morning sessions are great for consistency.")
                ]
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showScoreInfo) {
            InfoSheet(
                theme: theme,
                icon: "star.fill",
                iconColor: .yellow,
                title: "Focus Score",
                description: "A 0-100 score measuring your overall focus performance over the last 7 days.",
                details: [
                    ("Consistency (40%)", "How many of the last 7 days you focused. Daily practice matters most for building habits and achieving long-term goals."),
                    ("Goals Hit (40%)", "How many daily goals you completed. Setting realistic, achievable goals helps maintain motivation."),
                    ("Time Quality (20%)", "How close you got to your target focus time on average. This rewards both effort and goal-setting accuracy."),
                    ("Grade Scale", "S (90-100) Exceptional • A (80-89) Excellent • B (70-79) Good • C (60-69) Average • D (50-59) Needs Work • F (<50) Getting Started"),
                    ("How to improve", "Focus on consistency first – it's the biggest factor. Then work on hitting your daily goals. The score updates in real-time as you focus.")
                ]
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showComparisonInfo) {
            InfoSheet(
                theme: theme,
                icon: "chart.bar.fill",
                iconColor: .blue,
                title: "Week Comparison",
                description: "See how your current week stacks up against last week's performance.",
                details: [
                    ("This Week", "Total focus time accumulated from the start of the current week (Sunday) until now."),
                    ("Last Week", "Total focus time for the entire previous week. This is your benchmark to beat."),
                    ("Percentage Change", "Shows improvement (+) or decline (-) compared to last week. Green arrow = doing better!"),
                    ("Why compare?", "Weekly comparisons help you spot trends and stay accountable. It's not about perfection – it's about progress."),
                    ("Pro tip", "Aim for small, consistent improvements. Even 10% more focus each week compounds into huge gains over time.")
                ]
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showInsightsInfo) {
            InfoSheet(
                theme: theme,
                icon: "lightbulb.fill",
                iconColor: .purple,
                title: "Insights",
                description: "Key metrics that reveal your focus patterns and help you optimize your productivity.",
                details: [
                    ("Active Days", "Days in the last 7 where you completed at least one focus session. Aim for 7/7 for maximum consistency."),
                    ("Goals Hit", "Number of days you reached your daily focus goal. If this is low, consider adjusting your goal to be more achievable."),
                    ("Best Time", "The hour of day when you've accumulated the most focus time over the last 2 weeks. Schedule important work during this window!"),
                    ("Peak Day", "Your highest single-day focus time in the last 30 days. This shows what you're capable of on your best days."),
                    ("Using insights", "Use these patterns to optimize your schedule. Block your best time for deep work and protect your streak daily.")
                ]
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            preferredWeekdayOffset = weekdayIndexWithinWeek(for: selectedDate)
            rebuildWeekWindow(around: selectedDate)
        }
        .onChange(of: selectedDate) { _, newValue in
            guard !isSyncingFromPager else { return }
            preferredWeekdayOffset = weekdayIndexWithinWeek(for: newValue)
            ensureWeekWindowContains(newValue)
        }
        .onChange(of: weekPageIndex) { _, newValue in
            guard !isSyncingFromDate else { return }
            guard weekStarts.indices.contains(newValue) else { return }
            let ws = weekStarts[newValue]
            let newDate = cal.date(byAdding: .day, value: preferredWeekdayOffset, to: ws) ?? ws
            isSyncingFromPager = true
            DispatchQueue.main.async {
                withAnimation(.none) { selectedDate = newDate }
                isSyncingFromPager = false
            }
        }
    }

    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    Image("Focusflow_Logo")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

                    Text("Progress")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }

                Text(monthTitle(selectedDate))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Button {
                Haptics.impact(.medium)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    selectedDate = Date()
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Date Navigator
    
    private var dateNavigator: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.impact(.light)
                stepDay(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button {
                Haptics.impact(.light)
                showDatePicker = true
            } label: {
                HStack(spacing: 8) {
                    Text(dayTitle(selectedDate))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if cal.isDateInToday(selectedDate) {
                        Text("TODAY")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(theme.accentPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.accentPrimary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }

            Button {
                Haptics.impact(.light)
                stepDay(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    // MARK: - Today Hero Card
    
    private var todayHeroCard: some View {
        let dayInt = dayInterval(selectedDate)
        let focusSec = focusSeconds(in: dayInt)
        let goal = goalMinutes(for: selectedDate)
        let progress = goal > 0 ? min(1.0, focusSec / (Double(goal) * 60)) : 0
        let sessionsToday = sessions(in: dayInt)

        return VStack(spacing: 0) {
            // Top section with ring and focus time
            HStack(spacing: 20) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 12)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

                    VStack(spacing: 2) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("of goal")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(dayLabel(selectedDate))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))

                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(formatDuration(focusSec))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("/ \(goal)m")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                    }

                    Button {
                        Haptics.impact(.light)
                        showGoalSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "scope")
                                .font(.system(size: 11))
                            Text("Set Goal")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(theme.accentPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.accentPrimary.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }

                Spacer()
            }
            .padding(20)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
                .padding(.horizontal, 16)

            // Bottom metrics
            HStack(spacing: 0) {
                metricItem(icon: "bolt.fill", value: "\(sessionsToday.count)", label: "Sessions", color: theme.accentPrimary)
                
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 1, height: 40)

                let avg = avgSessionMinutes(sessionsToday)
                metricItem(icon: "clock.fill", value: avg > 0 ? "\(avg)m" : "—", label: "Average", color: .blue)
                
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 1, height: 40)

                let longest = longestSessionMinutes(sessionsToday)
                metricItem(icon: "flame.fill", value: longest > 0 ? "\(longest)m" : "—", label: "Longest", color: .orange)
            }
            .padding(.vertical, 16)
        }
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func metricItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quick Stats Strip
    
    private var quickStatsStrip: some View {
        let dayInt = dayInterval(selectedDate)
        let tasksAggData = tasksAgg(in: dayInt)
        let remaining = max(0, goalMinutes(for: selectedDate) - Int(focusSeconds(in: dayInt) / 60))

        return HStack(spacing: 12) {
            // Tasks Progress
            quickStatCard(
                icon: "checklist",
                title: "Tasks",
                value: "\(tasksAggData.completed)/\(tasksAggData.scheduled)",
                color: .green
            )

            // Time Remaining
            quickStatCard(
                icon: "hourglass",
                title: "Remaining",
                value: remaining > 0 ? "\(remaining)m" : "Done!",
                color: remaining > 0 ? .orange : .green
            )
        }
    }

    private func quickStatCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Streak & Focus Score Section
    
    private var streakAndScoreSection: some View {
        HStack(spacing: 12) {
            // Current Streak
            streakCard
            
            // Focus Score
            focusScoreCard
        }
    }
    
    private var streakCard: some View {
        let streak = currentStreak
        let isOnFire = streak >= 7
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: isOnFire ? "flame.fill" : "flame")
                    .font(.system(size: 18))
                    .foregroundColor(.orange)
                
                Text("Streak")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Button {
                    Haptics.impact(.light)
                    showStreakInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(streak)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("days")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Text(streakMessage(streak))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            streak >= 7
                ? LinearGradient(colors: [Color.orange.opacity(0.15), Color.red.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [Color.white.opacity(0.04), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(streak >= 7 ? Color.orange.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    private var focusScoreCard: some View {
        let score = calculateFocusScore()
        let grade = focusGrade(score)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.yellow)
                
                Text("Focus Score")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Button {
                    Haptics.impact(.light)
                    showScoreInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(score)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(grade)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(gradeColor(score))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(gradeColor(score).opacity(0.2))
                    .clipShape(Capsule())
            }
            
            Text("Based on last 7 days")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    // MARK: - Week Comparison Card
    
    private var weekComparisonCard: some View {
        let thisWeekFocus = focusSeconds(in: weekInterval(selectedDate))
        let lastWeekStart = cal.date(byAdding: .weekOfYear, value: -1, to: startOfWeek(for: selectedDate)) ?? selectedDate
        let lastWeekInterval = DateInterval(start: lastWeekStart, end: cal.date(byAdding: .day, value: 7, to: lastWeekStart) ?? lastWeekStart)
        let lastWeekFocus = focusSeconds(in: lastWeekInterval)
        
        let diff = thisWeekFocus - lastWeekFocus
        let percentChange = lastWeekFocus > 0 ? (diff / lastWeekFocus) * 100 : (thisWeekFocus > 0 ? 100 : 0)
        let isUp = diff >= 0
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("VS LAST WEEK")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
                
                Button {
                    Haptics.impact(.light)
                    showComparisonInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 11, weight: .bold))
                    Text("\(abs(Int(percentChange)))%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundColor(isUp ? .green : .red)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background((isUp ? Color.green : Color.red).opacity(0.15))
                .clipShape(Capsule())
            }
            
            HStack(spacing: 16) {
                comparisonBar(
                    label: "This Week",
                    value: thisWeekFocus,
                    maxValue: max(thisWeekFocus, lastWeekFocus),
                    color: theme.accentPrimary,
                    isCurrent: true
                )
                
                comparisonBar(
                    label: "Last Week",
                    value: lastWeekFocus,
                    maxValue: max(thisWeekFocus, lastWeekFocus),
                    color: .gray,
                    isCurrent: false
                )
            }
            
            Text(comparisonMessage(diff: diff, isUp: isUp))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private func comparisonBar(label: String, value: TimeInterval, maxValue: TimeInterval, color: Color, isCurrent: Bool) -> some View {
        let progress = maxValue > 0 ? value / maxValue : 0
        
        return VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            
            Text(formatDuration(value))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(isCurrent ? .white : .white.opacity(0.6))
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            isCurrent
                                ? LinearGradient(colors: [theme.accentPrimary, theme.accentSecondary], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [color.opacity(0.5), color.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func comparisonMessage(diff: TimeInterval, isUp: Bool) -> String {
        let diffMins = abs(Int(diff / 60))
        if diffMins < 5 {
            return "About the same as last week. Consistency is key!"
        } else if isUp {
            return "You're \(formatDuration(abs(diff))) ahead of last week. Great progress!"
        } else {
            return "You're \(formatDuration(abs(diff))) behind last week. Still time to catch up!"
        }
    }

    // MARK: - Weekly Activity Card
    
    private var weeklyActivityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("WEEKLY ACTIVITY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)

                Spacer()

                Text(weekRangeTitle(for: displayWeekStart()))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }

            TabView(selection: $weekPageIndex) {
                ForEach(Array(weekStarts.enumerated()), id: \.offset) { idx, start in
                    weekBarsView(for: start)
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 160)
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func weekBarsView(for weekStart: Date) -> some View {
        let bars = weekBars(for: weekStart)
        let maxGoal = bars.map { goalMinutes(for: $0.2) }.max() ?? 60

        return HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(bars.enumerated()), id: \.offset) { _, bar in
                let d = bar.2
                let isSelected = cal.isDate(d, inSameDayAs: selectedDate)
                let isFuture = cal.startOfDay(for: d) > cal.startOfDay(for: Date())
                let goal = goalMinutes(for: d)
                let progress = goal > 0 ? min(1.0, Double(bar.1) / Double(goal)) : 0

                Button {
                    Haptics.impact(.light)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        selectedDate = d
                    }
                } label: {
                    VStack(spacing: 8) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 36, height: 100)

                            if !isFuture && bar.1 > 0 {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: progress >= 1.0
                                                ? [theme.accentPrimary, theme.accentSecondary]
                                                : [theme.accentPrimary.opacity(0.7), theme.accentSecondary.opacity(0.5)],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(width: 36, height: max(8, 100 * progress))
                            }

                            if isSelected {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 36, height: 100)
                            }
                        }

                        Text(String(bar.0.prefix(1)))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isSelected ? .white : (isFuture ? .white.opacity(0.2) : .white.opacity(0.5)))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Week Summary Card
    
    private var weekSummaryCard: some View {
        let weekInt = weekInterval(selectedDate)
        let weekFocus = focusSeconds(in: weekInt)
        let weekGoal = weeklyGoalMinutes(forWeekContaining: selectedDate)
        let weekProgress = weekGoal > 0 ? min(1.0, (weekFocus / 60) / Double(weekGoal)) : 0
        let weekTasksData = tasksAgg(in: weekInt)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("WEEK SUMMARY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)

                Spacer()

                Text("\(Int(weekProgress * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(theme.accentPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(theme.accentPrimary.opacity(0.15))
                    .clipShape(Capsule())
            }

            HStack(spacing: 12) {
                weekSummaryTile(
                    title: "Focus Time",
                    value: formatDuration(weekFocus),
                    subtitle: "Avg \(Int(weekFocus / 60 / 7))m/day",
                    icon: "clock.fill",
                    color: theme.accentPrimary
                )

                weekSummaryTile(
                    title: "Tasks Done",
                    value: "\(weekTasksData.completed)",
                    subtitle: "\(weekTasksData.scheduled) scheduled",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func weekSummaryTile(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Insights Grid
    
    private var insightsGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("INSIGHTS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
                
                Button {
                    Haptics.impact(.light)
                    showInsightsInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                }
                
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                insightCard(
                    icon: "calendar",
                    title: "Active Days",
                    value: "\(activeFocusDays(lastNDays: 7))/7",
                    color: .blue
                )

                insightCard(
                    icon: "target",
                    title: "Goals Hit",
                    value: "\(goalHits(lastNDays: 7))/7",
                    color: .green
                )

                insightCard(
                    icon: "clock.badge.checkmark",
                    title: "Best Time",
                    value: bestTimeWindowLabel(lastDays: 14),
                    color: .purple
                )

                if let peak = peakDayLast30() {
                    insightCard(
                        icon: "flame.fill",
                        title: "Peak Day",
                        value: "\(peak.minutes)m",
                        color: .orange
                    )
                } else {
                    insightCard(
                        icon: "flame.fill",
                        title: "Peak Day",
                        value: "—",
                        color: .orange
                    )
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func insightCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Session Timeline
    
    private var sessionTimeline: some View {
        let sessionsToday = sessions(in: dayInterval(selectedDate))

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("SESSIONS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)

                Spacer()

                Text("\(sessionsToday.count) session\(sessionsToday.count == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }

            if sessionsToday.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.15))
                    Text("No sessions yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    Text("Start a focus session to see it here")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sessionsToday.enumerated()), id: \.offset) { index, session in
                        sessionRow(session: session, isLast: index == sessionsToday.count - 1)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func sessionRow(session: ProgressSession, isLast: Bool) -> some View {
        HStack(spacing: 14) {
            // Time
            Text(session.date.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
                .frame(width: 55, alignment: .trailing)

            // Dot and line
            VStack(spacing: 0) {
                Circle()
                    .fill(theme.accentPrimary)
                    .frame(width: 10, height: 10)

                if !isLast {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 2)
                        .frame(height: 40)
                }
            }

            // Session info
            VStack(alignment: .leading, spacing: 4) {
                Text(sessionTitle(session))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(formatDuration(session.duration))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(.vertical, isLast ? 0 : 8)
    }

    private func sessionTitle(_ s: ProgressSession) -> String {
        let raw = (s.sessionName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? "Focus Session" : raw
    }

    // =========================================================
    // MARK: - Weekly Pager Logic
    // =========================================================

    private func rebuildWeekWindow(around date: Date) {
        let ws = startOfWeek(for: date)
        let start = cal.date(byAdding: .weekOfYear, value: -weekWindowRadius, to: ws) ?? ws
        weekStarts = (0...(weekWindowRadius * 2)).compactMap { i in
            cal.date(byAdding: .weekOfYear, value: i, to: start)
        }
        weekPageIndex = weekWindowRadius
    }

    private func indexForWeek(containing date: Date) -> Int? {
        let ws = startOfWeek(for: date)
        return weekStarts.firstIndex(where: { cal.isDate($0, inSameDayAs: ws) })
    }

    private func ensureWeekWindowContains(_ date: Date) {
        if weekStarts.isEmpty {
            rebuildWeekWindow(around: date)
            return
        }
        if let idx = indexForWeek(containing: date) {
            if weekPageIndex != idx {
                isSyncingFromDate = true
                withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                    weekPageIndex = idx
                }
                DispatchQueue.main.async { isSyncingFromDate = false }
            }
            return
        }
        rebuildWeekWindow(around: date)
    }

    private func displayWeekStart() -> Date {
        if weekStarts.indices.contains(weekPageIndex) { return weekStarts[weekPageIndex] }
        return startOfWeek(for: selectedDate)
    }

    // =========================================================
    // MARK: - Date Helpers
    // =========================================================

    private func startOfWeek(for date: Date) -> Date {
        cal.dateInterval(of: .weekOfYear, for: date)?.start ?? cal.startOfDay(for: date)
    }

    private func weekdayIndexWithinWeek(for date: Date) -> Int {
        let ws = startOfWeek(for: date)
        let sd = cal.startOfDay(for: date)
        let diff = cal.dateComponents([.day], from: ws, to: sd).day ?? 0
        return max(0, min(6, diff))
    }

    private func dayInterval(_ d: Date) -> DateInterval {
        let s = cal.startOfDay(for: d)
        let e = cal.date(byAdding: .day, value: 1, to: s) ?? s.addingTimeInterval(86400)
        return DateInterval(start: s, end: e)
    }

    private func weekInterval(_ d: Date) -> DateInterval {
        cal.dateInterval(of: .weekOfYear, for: d) ??
        DateInterval(start: cal.startOfDay(for: d), duration: 7 * 86400)
    }

    // =========================================================
    // MARK: - Focus Data
    // =========================================================

    private func sessions(in interval: DateInterval) -> [ProgressSession] {
        progressStore.sessions
            .filter { $0.date >= interval.start && $0.date < interval.end }
            .sorted(by: { $0.date > $1.date })
    }

    private func focusSeconds(in interval: DateInterval) -> TimeInterval {
        sessions(in: interval).reduce(0) { $0 + $1.duration }
    }

    private func avgSessionMinutes(_ list: [ProgressSession]) -> Int {
        guard !list.isEmpty else { return 0 }
        let avg = list.reduce(0.0) { $0 + $1.duration } / Double(list.count)
        return max(0, Int(round(avg / 60.0)))
    }

    private func longestSessionMinutes(_ list: [ProgressSession]) -> Int {
        let maxSec = list.map { $0.duration }.max() ?? 0
        return Int(round(maxSec / 60.0))
    }

    // =========================================================
    // MARK: - Tasks
    // =========================================================

    private func tasksAgg(in interval: DateInterval) -> (scheduled: Int, completed: Int, plannedMinutes: Int, completionRate: Double) {
        var scheduled = 0
        var completed = 0
        var plannedMinutes = 0

        var cursor = cal.startOfDay(for: interval.start)
        let endDay = cal.startOfDay(for: interval.end)

        while cursor < endDay {
            let visible = tasksStore.tasksVisible(on: cursor, calendar: cal)
            scheduled += visible.count
            for t in visible {
                plannedMinutes += max(0, t.durationMinutes)
                if tasksStore.isCompleted(taskId: t.id, on: cursor, calendar: cal) {
                    completed += 1
                }
            }
            cursor = cal.date(byAdding: .day, value: 1, to: cursor) ?? cursor.addingTimeInterval(86400)
        }

        let rate = scheduled > 0 ? Double(completed) / Double(scheduled) : 0
        return (scheduled, completed, plannedMinutes, rate)
    }

    // =========================================================
    // MARK: - Goals
    // =========================================================

    private func goalMinutes(for date: Date) -> Int {
        _ = goalVersion
        return PV2GoalHistory.goalMinutes(
            for: date,
            fallback: max(0, progressStore.dailyGoalMinutes),
            calendar: cal
        )
    }

    private func weeklyGoalMinutes(forWeekContaining date: Date) -> Int {
        let ws = startOfWeek(for: date)
        return (0..<7).reduce(0) { acc, i in
            let d = cal.date(byAdding: .day, value: i, to: ws) ?? ws
            return acc + max(0, goalMinutes(for: d))
        }
    }

    private func goalHits(lastNDays n: Int) -> Int {
        guard n > 0 else { return 0 }
        let today = cal.startOfDay(for: Date())
        var hits = 0
        for i in 0..<n {
            guard let d = cal.date(byAdding: .day, value: -i, to: today) else { continue }
            let goal = goalMinutes(for: d)
            guard goal > 0 else { continue }
            let focused = focusSeconds(in: dayInterval(d))
            if focused >= Double(goal) * 60.0 { hits += 1 }
        }
        return hits
    }

    // MARK: - Streak Calculation
    
    private var currentStreak: Int {
        let today = cal.startOfDay(for: Date())
        let focusDays = Set(progressStore.sessions.filter { $0.duration >= 60 }.map { cal.startOfDay(for: $0.date) })
        
        guard !focusDays.isEmpty else { return 0 }
        
        var streak = 0
        var cursor = today
        
        // Check if today has focus, if not start from yesterday
        if !focusDays.contains(cursor) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        
        while focusDays.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        
        return streak
    }
    
    private func streakMessage(_ streak: Int) -> String {
        switch streak {
        case 0: return "Start focusing to begin your streak!"
        case 1: return "Day 1! Keep going tomorrow."
        case 2...6: return "Building momentum! \(7 - streak) more days to a week."
        case 7...13: return "One week strong! 🔥"
        case 14...29: return "Two weeks! You're unstoppable."
        case 30...99: return "A whole month! Legendary."
        default: return "Incredible dedication! 💪"
        }
    }
    
    // MARK: - Focus Score Calculation
    
    private func calculateFocusScore() -> Int {
        // Score based on last 7 days (0-100)
        // Components: consistency (40%), goal completion (40%), total time (20%)
        
        let today = cal.startOfDay(for: Date())
        var activeDays = 0
        var goalsHit = 0
        var totalMinutes = 0.0
        var totalGoalMinutes = 0
        
        for i in 0..<7 {
            guard let d = cal.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayFocus = focusSeconds(in: dayInterval(d))
            let dayGoal = goalMinutes(for: d)
            
            if dayFocus >= 60 { activeDays += 1 }
            if dayGoal > 0 && dayFocus >= Double(dayGoal) * 60 { goalsHit += 1 }
            totalMinutes += dayFocus / 60
            totalGoalMinutes += dayGoal
        }
        
        // Consistency score (0-40): % of days with any focus
        let consistencyScore = Double(activeDays) / 7.0 * 40.0
        
        // Goal completion score (0-40): % of goals hit
        let goalScore = Double(goalsHit) / 7.0 * 40.0
        
        // Time score (0-20): Based on meeting average goal
        let avgDailyGoal = Double(totalGoalMinutes) / 7.0
        let avgDailyFocus = totalMinutes / 7.0
        let timeScore = avgDailyGoal > 0 ? min(20.0, (avgDailyFocus / avgDailyGoal) * 20.0) : 10.0
        
        return min(100, Int(round(consistencyScore + goalScore + timeScore)))
    }
    
    private func focusGrade(_ score: Int) -> String {
        switch score {
        case 90...100: return "S"
        case 80..<90: return "A"
        case 70..<80: return "B"
        case 60..<70: return "C"
        case 50..<60: return "D"
        default: return "F"
        }
    }
    
    private func gradeColor(_ score: Int) -> Color {
        switch score {
        case 90...100: return .yellow
        case 80..<90: return .green
        case 70..<80: return .blue
        case 60..<70: return .orange
        default: return .red
        }
    }

    // =========================================================
    // MARK: - Insights
    // =========================================================

    private func activeFocusDays(lastNDays n: Int) -> Int {
        guard n > 0 else { return 0 }
        let today = cal.startOfDay(for: Date())
        let set = Set(progressStore.sessions.filter { $0.duration > 0 }.map { cal.startOfDay(for: $0.date) })
        var count = 0
        for i in 0..<n {
            if let d = cal.date(byAdding: .day, value: -i, to: today), set.contains(d) {
                count += 1
            }
        }
        return count
    }

    private func bestTimeWindowLabel(lastDays: Int = 14) -> String {
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -(lastDays - 1), to: today) ?? today
        let interval = DateInterval(start: start, end: cal.date(byAdding: .day, value: 1, to: today) ?? today)

        var buckets = Array(repeating: TimeInterval(0), count: 24)
        for s in sessions(in: interval) {
            let h = cal.component(.hour, from: s.date)
            if (0..<24).contains(h) { buckets[h] += s.duration }
        }

        guard let best = buckets.enumerated().max(by: { $0.element < $1.element }),
              best.element > 0 else { return "—" }

        return hourRangeLabel(best.offset)
    }

    private func peakDayLast30() -> (date: Date, minutes: Int)? {
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -29, to: today) ?? today
        var best: (Date, TimeInterval) = (start, 0)

        for i in 0..<30 {
            guard let d = cal.date(byAdding: .day, value: i, to: start) else { continue }
            let total = focusSeconds(in: dayInterval(d))
            if total > best.1 { best = (d, total) }
        }

        guard best.1 > 0 else { return nil }
        return (best.0, Int(round(best.1 / 60.0)))
    }

    // =========================================================
    // MARK: - Weekly Chart Data
    // =========================================================

    private func weekRangeTitle(for weekStart: Date) -> String {
        let end = cal.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.setLocalizedDateFormatFromTemplate("MMM d")
        return "\(f.string(from: weekStart)) – \(f.string(from: end))"
    }

    private func weekBars(for weekStart: Date) -> [(String, Int, Date)] {
        let df = DateFormatter()
        df.locale = .autoupdatingCurrent
        df.setLocalizedDateFormatFromTemplate("E")

        return (0..<7).map { i in
            let d = cal.date(byAdding: .day, value: i, to: weekStart) ?? weekStart
            let mins = Int(round(focusSeconds(in: dayInterval(d)) / 60.0))
            return (df.string(from: d).uppercased(), mins, d)
        }
    }

    // =========================================================
    // MARK: - Formatting
    // =========================================================

    private func dayLabel(_ d: Date) -> String {
        if cal.isDateInToday(d) { return "Today" }
        if cal.isDateInYesterday(d) { return "Yesterday" }
        return d.formatted(date: .abbreviated, time: .omitted)
    }

    private func dayTitle(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.setLocalizedDateFormatFromTemplate("EEE, MMM d")
        return f.string(from: d)
    }

    private func monthTitle(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return f.string(from: d)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "0m" }
        let totalMinutes = Int(seconds / 60)
        if totalMinutes >= 60 {
            let h = totalMinutes / 60
            let m = totalMinutes % 60
            return m == 0 ? "\(h)h" : "\(h)h \(m)m"
        }
        return "\(totalMinutes)m"
    }

    private func hourRangeLabel(_ startHour: Int) -> String {
        let df = DateFormatter()
        df.locale = .autoupdatingCurrent
        df.dateFormat = "ha"
        let base = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .hour, value: startHour, to: base) ?? base
        return df.string(from: start).lowercased()
    }

    // =========================================================
    // MARK: - Actions
    // =========================================================

    private func stepDay(_ val: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            selectedDate = cal.date(byAdding: .day, value: val, to: selectedDate) ?? selectedDate
        }
    }
}

// =========================================================
// MARK: - Goal History (Per-day)
// =========================================================

private enum PV2GoalHistory {
    private static let storeKey = "focusflow.pv2.dailyGoalHistory.v1"

    static func goalMinutes(for date: Date, fallback: Int, calendar: Calendar) -> Int {
        let dict = load()
        let k = key(for: date, calendar: calendar)
        return max(0, dict[k] ?? fallback)
    }

    static func set(goalMinutes: Int, for date: Date, calendar: Calendar) {
        var dict = load()
        dict[key(for: date, calendar: calendar)] = max(0, goalMinutes)
        save(dict)
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

// =========================================================
// MARK: - Goal Sheet
// =========================================================

private struct GoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    let theme: AppTheme
    @Binding var goalMinutes: Int

    @State private var hours: Int
    @State private var minutes: Int

    init(theme: AppTheme, goalMinutes: Binding<Int>) {
        self.theme = theme
        self._goalMinutes = goalMinutes
        let safe = max(0, goalMinutes.wrappedValue)
        _hours = State(initialValue: safe / 60)
        let m = safe % 60
        let snapped = Int(round(Double(m) / 5.0) * 5.0)
        _minutes = State(initialValue: min(55, max(0, snapped)))
    }

    private var totalMinutes: Int { max(0, hours * 60 + minutes) }
    
    private var formattedGoal: String {
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(theme.accentPrimary.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "scope")
                        .font(.system(size: 22))
                        .foregroundColor(theme.accentPrimary)
                }
                .padding(.top, 32)

                Text("Daily Focus Goal")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text("Set a target you can hit consistently")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Preview of selected time
            Text(formattedGoal)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 24)
                .padding(.bottom, 16)
            
            // Pickers
            HStack(spacing: 20) {
                // Hours
                VStack(spacing: 8) {
                    Text("HOURS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)
                    
                    Picker("Hours", selection: $hours) {
                        ForEach(0..<9, id: \.self) { h in
                            Text("\(h)").tag(h)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100, height: 120)
                    .clipped()
                }
                
                // Minutes
                VStack(spacing: 8) {
                    Text("MINUTES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)
                    
                    Picker("Minutes", selection: $minutes) {
                        ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { m in
                            Text("\(m)").tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100, height: 120)
                    .clipped()
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()

            // Buttons
            HStack(spacing: 12) {
                Button {
                    Haptics.impact(.light)
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button {
                    Haptics.impact(.medium)
                    goalMinutes = totalMinutes
                    dismiss()
                } label: {
                    Text("Set Goal")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.10))
        .colorScheme(.dark)
    }
}

// =========================================================
// MARK: - Date Picker Sheet
// =========================================================

private struct DatePickerSheet: View {
    let theme: AppTheme
    @Binding var date: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Select Date")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("Jump to any day")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Button {
                    Haptics.impact(.light)
                    date = Date()
                } label: {
                    Text("Today")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.accentPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.accentPrimary.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 8)

            // Calendar
            DatePicker("", selection: $date, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .tint(theme.accentPrimary)
                .padding(.horizontal, 8)

            Spacer()
            
            // Done button
            Button {
                Haptics.impact(.light)
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.10))
        .colorScheme(.dark)
    }
}

// =========================================================
// MARK: - Info Sheet (Full Screen)
// =========================================================

private struct InfoSheet: View {
    let theme: AppTheme
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let details: [(String, String)]
    
    @Environment(\.dismiss) private var dismiss
    @State private var appearAnimation = false
    
    var body: some View {
        ZStack {
            // Premium background
            PremiumAppBackground(theme: theme, particleCount: 20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with close button
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Hero Section
                    VStack(spacing: 20) {
                        // Animated icon
                        ZStack {
                            // Outer glow
                            Circle()
                                .fill(iconColor.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .blur(radius: 30)
                                .scaleEffect(appearAnimation ? 1.2 : 0.8)
                            
                            // Icon background
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [iconColor.opacity(0.3), iconColor.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                            
                            // Icon
                            Image(systemName: icon)
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(iconColor)
                                .scaleEffect(appearAnimation ? 1 : 0.5)
                        }
                        .padding(.top, 20)
                        
                        // Title
                        Text(title)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                        
                        // Description
                        Text(description)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                    }
                    .padding(.bottom, 32)
                    
                    // Detail Cards
                    VStack(spacing: 12) {
                        ForEach(Array(details.enumerated()), id: \.offset) { index, detail in
                            DetailCard(
                                title: detail.0,
                                text: detail.1,
                                iconColor: iconColor,
                                index: index
                            )
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 30)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1 + 0.3),
                                value: appearAnimation
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Done button
                    Button {
                        Haptics.impact(.light)
                        dismiss()
                    } label: {
                        Text("Got it")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: theme.accentPrimary.opacity(0.4), radius: 16, y: 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                    .opacity(appearAnimation ? 1 : 0)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appearAnimation = true
            }
        }
    }
}

private struct DetailCard: View {
    let title: String
    let text: String
    let iconColor: Color
    let index: Int
    
    private var cardIcon: String {
        let icons = ["1.circle.fill", "2.circle.fill", "3.circle.fill", "4.circle.fill", "5.circle.fill", "6.circle.fill"]
        return icons[index % icons.count]
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Number indicator
            Image(systemName: cardIcon)
                .font(.system(size: 24))
                .foregroundColor(iconColor.opacity(0.8))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    ProgressViewV2()
}
