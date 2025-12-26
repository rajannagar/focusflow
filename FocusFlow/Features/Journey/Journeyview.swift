import SwiftUI

// MARK: - Swipe Back Gesture Enabler

struct SwipeBackGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            if let nav = uiViewController.navigationController {
                nav.interactivePopGestureRecognizer?.isEnabled = true
                nav.interactivePopGestureRecognizer?.delegate = nil
            }
        }
    }
}

// MARK: - Journey View

struct JourneyView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var journeyManager = JourneyManager.shared
    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var stats = StatsManager.shared
    
    @State private var appearedCards: Set<UUID> = []
    @State private var filterMode: FilterMode = .all
    
    private var theme: AppTheme { appSettings.profileTheme }
    
    enum FilterMode: String, CaseIterable {
        case all = "All Days"
        case active = "Active Only"
    }
    
    private var filteredSummaries: [DailySummary] {
        switch filterMode {
        case .all:
            return journeyManager.summaries
        case .active:
            return journeyManager.summaries.filter { $0.hasActivity }
        }
    }
    
    var body: some View {
        ZStack {
            PremiumAppBackground(theme: theme, particleCount: 8)
            
            SwipeBackGestureEnabler()
                .frame(width: 0, height: 0)
            
            VStack(spacing: 0) {
                header
                
                if journeyManager.summaries.isEmpty {
                    emptyState
                } else {
                    timelineContent
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            journeyManager.refresh()
            Haptics.impact(.light)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Button {
                Haptics.impact(.light)
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text("Journey")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Menu {
                ForEach(FilterMode.allCases, id: \.self) { mode in
                    Button {
                        Haptics.impact(.light)
                        withAnimation(.spring(response: 0.3)) {
                            filterMode = mode
                        }
                    } label: {
                        HStack {
                            Text(mode.rawValue)
                            if filterMode == mode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(theme.accentPrimary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "book.pages")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(theme.accentPrimary.opacity(0.6))
            }
            
            Text("Your Journey Begins")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Text("Complete focus sessions and tasks\nto start building your story.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Timeline Content
    
    private var timelineContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Insights Section
                insightsSection
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                
                // Title
                VStack(spacing: 8) {
                    Text("Your Focus Story")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("A timeline of your productivity journey")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.bottom, 24)
                
                // Timeline
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredSummaries.enumerated()), id: \.element.id) { index, summary in
                        VStack(spacing: 0) {
                            if shouldShowWeeklySummary(at: index) {
                                WeeklySummaryCard(
                                    weekSummaries: getWeekSummaries(endingAt: index),
                                    theme: theme
                                )
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                            }
                            
                            DailySummaryCard(
                                summary: summary,
                                theme: theme,
                                isFirst: index == 0,
                                isLast: index == filteredSummaries.count - 1,
                                hasAppeared: appearedCards.contains(summary.id)
                            )
                            .padding(.horizontal, 20)
                            .onAppear {
                                if !appearedCards.contains(summary.id) {
                                    Haptics.impact(.soft)
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        appearedCards.insert(summary.id)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
        }
        .refreshable {
            Haptics.impact(.medium)
            await refreshData()
        }
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                insightCard(
                    icon: "flame.fill",
                    value: "\(currentStreak)",
                    label: "Day Streak",
                    color: .orange,
                    trend: streakTrend
                )
                
                insightCard(
                    icon: "clock.fill",
                    value: formatTime(thisWeekFocusSeconds),
                    label: "This Week",
                    color: theme.accentPrimary,
                    trend: weekComparison
                )
            }
            
            if let comparison = weekComparisonText {
                HStack(spacing: 8) {
                    Image(systemName: weekComparisonPositive ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(weekComparisonPositive ? .green : .orange)
                    
                    Text(comparison)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill((weekComparisonPositive ? Color.green : Color.orange).opacity(0.12))
                )
            }
        }
    }
    
    private func insightCard(icon: String, value: String, label: String, color: Color, trend: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
                
                if let trend = trend {
                    Text(trend)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(trend.hasPrefix("+") ? .green : (trend.hasPrefix("-") ? .red : .white.opacity(0.5)))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((trend.hasPrefix("+") ? Color.green : (trend.hasPrefix("-") ? Color.red : Color.white)).opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Computed Properties
    
    private var currentStreak: Int {
        let cal = Calendar.autoupdatingCurrent
        let today = cal.startOfDay(for: Date())
        let days = Set(stats.sessions.filter { $0.duration > 0 }.map { cal.startOfDay(for: $0.date) })
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
    
    private var streakTrend: String? {
        let streak = currentStreak
        if streak >= 7 { return "🔥" }
        if streak >= 3 { return "+\(streak)" }
        return nil
    }
    
    private var thisWeekFocusSeconds: TimeInterval {
        let cal = Calendar.autoupdatingCurrent
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        return stats.sessions.filter { $0.date >= weekStart }.reduce(0) { $0 + $1.duration }
    }
    
    private var lastWeekFocusSeconds: TimeInterval {
        let cal = Calendar.autoupdatingCurrent
        guard let thisWeekStart = cal.dateInterval(of: .weekOfYear, for: Date())?.start,
              let lastWeekStart = cal.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart),
              let lastWeekEnd = cal.date(byAdding: .day, value: 7, to: lastWeekStart) else { return 0 }
        return stats.sessions.filter { $0.date >= lastWeekStart && $0.date < lastWeekEnd }.reduce(0) { $0 + $1.duration }
    }
    
    private var weekComparison: String? {
        let thisWeek = thisWeekFocusSeconds
        let lastWeek = lastWeekFocusSeconds
        guard lastWeek > 0 else { return nil }
        let diff = Int(((thisWeek - lastWeek) / lastWeek) * 100)
        if diff > 0 { return "+\(diff)%" }
        if diff < 0 { return "\(diff)%" }
        return nil
    }
    
    private var weekComparisonPositive: Bool {
        thisWeekFocusSeconds >= lastWeekFocusSeconds
    }
    
    private var weekComparisonText: String? {
        let thisWeek = thisWeekFocusSeconds
        let lastWeek = lastWeekFocusSeconds
        guard lastWeek > 0 else {
            if thisWeek > 0 { return "Great start this week! Keep it up." }
            return nil
        }
        let percentage = Int(((thisWeek - lastWeek) / lastWeek) * 100)
        if percentage > 20 { return "You're \(percentage)% more focused than last week!" }
        else if percentage > 0 { return "Slightly ahead of last week. Keep going!" }
        else if percentage == 0 { return "Matching last week's focus. Stay consistent!" }
        else if percentage > -20 { return "A bit behind last week. You've got this!" }
        else { return "Down \(abs(percentage))% from last week. Time to focus!" }
    }
    
    // MARK: - Weekly Summary Helpers
    
    private func shouldShowWeeklySummary(at index: Int) -> Bool {
        guard index > 0 else { return false }
        let cal = Calendar.autoupdatingCurrent
        let currentWeek = cal.component(.weekOfYear, from: filteredSummaries[index].date)
        let previousWeek = cal.component(.weekOfYear, from: filteredSummaries[index - 1].date)
        return currentWeek != previousWeek
    }
    
    private func getWeekSummaries(endingAt index: Int) -> [DailySummary] {
        guard index > 0 else { return [] }
        let cal = Calendar.autoupdatingCurrent
        let weekOfPrevious = cal.component(.weekOfYear, from: filteredSummaries[index - 1].date)
        return filteredSummaries.filter { cal.component(.weekOfYear, from: $0.date) == weekOfPrevious }
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
    
    private func refreshData() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        journeyManager.refresh()
    }
}

// MARK: - Weekly Summary Card

struct WeeklySummaryCard: View {
    let weekSummaries: [DailySummary]
    let theme: AppTheme
    
    private var totalFocusTime: TimeInterval { weekSummaries.reduce(0) { $0 + $1.totalFocusSeconds } }
    private var totalSessions: Int { weekSummaries.reduce(0) { $0 + $1.sessionCount } }
    private var totalTasksCompleted: Int { weekSummaries.reduce(0) { $0 + $1.tasksCompleted } }
    private var activeDays: Int { weekSummaries.filter { $0.hasActivity }.count }
    
    private var weekLabel: String {
        guard let first = weekSummaries.last, let last = weekSummaries.first else { return "Week" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: first.date)) - \(formatter.string(from: last.date))"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.accentPrimary)
                
                Text("WEEK IN REVIEW")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(theme.accentPrimary)
                    .tracking(1)
                
                Spacer()
                
                Text(weekLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            HStack(spacing: 16) {
                weekStatItem(value: formatTime(totalFocusTime), label: "Focused")
                weekStatItem(value: "\(totalSessions)", label: "Sessions")
                weekStatItem(value: "\(totalTasksCompleted)", label: "Tasks")
                weekStatItem(value: "\(activeDays)/7", label: "Active")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [theme.accentPrimary.opacity(0.15), theme.accentSecondary.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(theme.accentPrimary.opacity(0.3), lineWidth: 1))
        )
    }
    
    private func weekStatItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

// MARK: - Daily Summary Card

struct DailySummaryCard: View {
    let summary: DailySummary
    let theme: AppTheme
    let isFirst: Bool
    let isLast: Bool
    var hasAppeared: Bool = true
    
    private var isMilestone: Bool {
        summary.goalHit || summary.xpEarnedToday >= 50 || isLevelUp || summary.streakCount == 7 || summary.streakCount == 30
    }
    
    private var isLevelUp: Bool {
        let prevXP = summary.totalXP - summary.xpEarnedToday
        let prevLevel = min(max(1, prevXP / 100 + 1), 50)
        return summary.level > prevLevel
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            timelineConnector
            cardContent
                .opacity(hasAppeared ? 1 : 0)
                .offset(x: hasAppeared ? 0 : 20)
        }
    }
    
    private var timelineConnector: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(isFirst ? Color.clear : theme.accentPrimary.opacity(0.3))
                .frame(width: 2, height: 20)
            
            ZStack {
                if isMilestone {
                    Circle()
                        .fill(theme.accentPrimary)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().fill(theme.accentPrimary).blur(radius: 6))
                    Image(systemName: "star.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Circle()
                        .fill(summary.hasActivity ? theme.accentPrimary : Color.white.opacity(0.2))
                        .frame(width: 12, height: 12)
                    if summary.hasActivity {
                        Circle().fill(theme.accentPrimary).frame(width: 12, height: 12).blur(radius: 4)
                    }
                }
            }
            
            Rectangle()
                .fill(isLast ? Color.clear : theme.accentPrimary.opacity(0.3))
                .frame(width: 2)
                .frame(maxHeight: .infinity)
        }
        .frame(width: 20)
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(summary.relativeDateString)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                if isMilestone {
                    Text("★").font(.system(size: 12, weight: .bold)).foregroundColor(theme.accentPrimary)
                }
                Spacer()
                Text(summary.shortDateString)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            // Milestone banners
            if isLevelUp {
                milestoneBanner(icon: "arrow.up.circle.fill", text: "Leveled up to \(summary.level)!", color: .yellow)
            }
            if summary.streakCount == 7 {
                milestoneBanner(icon: "flame.fill", text: "7 Day Streak! 🔥", color: .orange)
            } else if summary.streakCount == 30 {
                milestoneBanner(icon: "crown.fill", text: "30 Day Streak! 👑", color: .yellow)
            }
            
            // Stats
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    statItem(icon: "timer", value: summary.formattedFocusTime, label: "\(summary.sessionCount) session\(summary.sessionCount == 1 ? "" : "s")", color: theme.accentPrimary)
                    statItem(icon: "checkmark.circle", value: summary.taskProgressText, label: "tasks", color: .green)
                }
                HStack(spacing: 12) {
                    statItem(icon: "star.fill", value: "Level \(summary.level)", label: "\(summary.totalXP) XP", color: .yellow)
                    statItem(icon: "flame.fill", value: "\(summary.streakCount) day\(summary.streakCount == 1 ? "" : "s")", label: "streak", color: .orange)
                }
                if summary.longestSessionMinutes >= 15 {
                    HStack(spacing: 12) {
                        statItem(icon: "trophy.fill", value: "\(summary.longestSessionMinutes)m", label: "longest session", color: .purple)
                        Spacer()
                    }
                }
            }
            
            // Badges
            if summary.xpEarnedToday > 0 {
                badgePill(icon: "plus.circle.fill", text: "\(summary.xpEarnedToday) XP earned", color: theme.accentPrimary)
            }
            if summary.goalHit {
                badgePill(icon: "target", text: "Daily goal achieved!", color: .green)
            }
            
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1).padding(.vertical, 4)
            
            // Message
            HStack(alignment: .top, spacing: 10) {
                Text(summary.messageEmoji).font(.system(size: 20))
                Text(summary.message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isMilestone ? theme.accentPrimary.opacity(0.06) : Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(isMilestone ? theme.accentPrimary.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1))
        )
        .padding(.bottom, 16)
    }
    
    private func milestoneBanner(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold))
            Text(text).font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(color.opacity(0.15)))
    }
    
    private func badgePill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold))
            Text(text).font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
    
    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                Text(label).font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.4))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    JourneyView()
}
