import SwiftUI
import UIKit

// =========================================================
// MARK: - ProgressViewV2 (Ultra Premium • Story of the day • Smooth Weekly Pager)
// =========================================================

struct ProgressViewV2: View {
    // MARK: - Dependencies
    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var stats = StatsManager.shared
    @ObservedObject private var tasksStore = TasksStore.shared

    // MARK: - State
    @State private var selectedDate: Date = Date()
    @State private var showGoalSheet = false
    @State private var showDatePicker = false

    // ✅ Forces UI refresh when we write per-day goal to UserDefaults
    @State private var goalVersion: Int = 0

    // Weekly pager (smooth: no “reset to center”)
    @State private var weekPageIndex: Int = 0
    @State private var weekStarts: [Date] = []                 // week start dates (window)
    @State private var preferredWeekdayOffset: Int = 0          // 0...6 (keeps weekday while swiping)
    @State private var isSyncingFromPager = false
    @State private var isSyncingFromDate = false
    private let weekWindowRadius = 10                           // 21 pages total

    // MARK: - Computed
    private var theme: AppTheme { appSettings.selectedTheme }
    private var cal: Calendar { .autoupdatingCurrent }

    // MARK: - Body
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: theme.backgroundColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Ambient blobs
                PV2AmbientBlob(color: theme.accentPrimary, x: -size.width * 0.42, y: -size.height * 0.40)
                PV2AmbientBlob(color: theme.accentSecondary, x:  size.width * 0.42, y:  size.height * 0.22)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {

                        // ✅ Header aligned like StatsView (logo + title in same row)
                        // ✅ No status pill
                        // ✅ Jump-to-today icon sized like other pages (34x34)
                        PV2TopHeader(
                            monthTitle: monthTitle(selectedDate),
                            onJumpToday: { jumpToday() }
                        )
                        .padding(.horizontal, 22)
                        .padding(.top, 18)

                        // Date capsule (tap title opens calendar)
                        PV2DateCapsule(
                            title: dayTitle(selectedDate),
                            onPrev: { stepDay(-1) },
                            onNext: { stepDay(1) },
                            onTapTitle: {
                                Haptics.impact(.light)
                                showDatePicker = true
                            }
                        )
                        .padding(.horizontal, 22)

                        // HERO: Today story
                        let dayAgg = tasksAgg(in: dayInterval(selectedDate))
                        PV2TodayHeroCard(
                            theme: theme,
                            day: selectedDate,
                            focusSeconds: focusSeconds(in: dayInterval(selectedDate)),
                            goalMinutes: goalMinutes(for: selectedDate),
                            sessions: sessions(in: dayInterval(selectedDate)),
                            tasksAgg: dayAgg,
                            onTapGoal: {
                                Haptics.impact(.light)
                                showGoalSheet = true
                            }
                        )
                        .padding(.horizontal, 22)

                        // Week summary
                        let wkAgg = tasksAgg(in: weekInterval(selectedDate))
                        PV2WeekSummaryCard(
                            theme: theme,
                            weekStart: startOfWeek(for: selectedDate),
                            weekFocusSeconds: focusSeconds(in: weekInterval(selectedDate)),
                            weekTasksAgg: wkAgg,
                            weeklyGoalMinutes: weeklyGoalMinutes(forWeekContaining: selectedDate),
                            plannedWeekMinutes: wkAgg.plannedMinutes,
                            weekDayIndex: weekdayIndexWithinWeek(for: selectedDate)
                        )
                        .padding(.horizontal, 22)

                        // Weekly Activity (goal-based per-day goal)
                        PV2WeeklyPagerChart(
                            theme: theme,
                            pages: weekStarts,
                            displayWeekStart: displayWeekStart(),
                            weekTitle: { weekStart in weekRangeTitle(for: weekStart) },
                            barsForWeekStart: { weekStart in weekBars(for: weekStart) },
                            selectedDate: selectedDate,
                            goalForDate: { d in goalMinutes(for: d) }, // ✅ per-day goal
                            weekPageIndex: $weekPageIndex,
                            onSelectDate: { d in
                                Haptics.impact(.light)
                                withAnimation(.spring(response: 0.30, dampingFraction: 0.90)) {
                                    selectedDate = d
                                }
                            }
                        )
                        .padding(.horizontal, 22)

                        // Insights (2x2; Peak fits)
                        PV2InsightsStrip(
                            theme: theme,
                            activeDays7: activeFocusDays(lastNDays: 7),
                            goalHits7: goalHits(lastNDays: 7),
                            bestWindow: bestTimeWindowLabel(lastDays: 14),
                            peakDay: peakDayLast30()
                        )
                        .padding(.horizontal, 22)

                        // Replay
                        PV2TimelineView(
                            sessions: sessions(in: dayInterval(selectedDate)),
                            theme: theme
                        )
                        .padding(.horizontal, 22)

                        Spacer(minLength: 120)
                    }
                    .padding(.bottom, 10)
                }
            }
        }
        .sheet(isPresented: $showGoalSheet) {
            // ✅ Goal is associated with the selected day (per-day)
            PV2GoalSheet(
                theme: theme,
                goalMinutes: Binding(
                    get: { goalMinutes(for: selectedDate) },
                    set: { newValue in
                        let v = max(0, newValue)

                        // Persist per-day goal
                        PV2GoalHistory.set(goalMinutes: v, for: selectedDate, calendar: cal)

                        // Optional: keep global fallback “reasonable”
                        // (so new days without a custom goal inherit last-set target)
                        stats.dailyGoalMinutes = v

                        // ✅ Force a view refresh (UserDefaults writes aren't observed)
                        goalVersion &+= 1
                    }
                )
            )
            .presentationDetents([.fraction(0.45)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showDatePicker) {
            PV2DatePickerSheet(theme: theme, date: $selectedDate)
                .presentationDetents([.fraction(0.62)])
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

    // =========================================================
    // MARK: - Weekly Pager (Smooth)
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
                withAnimation(.spring(response: 0.30, dampingFraction: 0.92)) {
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
    // MARK: - Focus
    // =========================================================

    private func sessions(in interval: DateInterval) -> [FocusSession] {
        stats.sessions
            .filter { $0.date >= interval.start && $0.date < interval.end }
            .sorted(by: { $0.date > $1.date })
    }

    private func focusSeconds(in interval: DateInterval) -> TimeInterval {
        sessions(in: interval).reduce(0) { $0 + $1.duration }
    }

    // =========================================================
    // MARK: - Tasks (from TasksStore)
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
    // MARK: - Goal (Per-day) ✅ refreshes via goalVersion
    // =========================================================

    private func goalMinutes(for date: Date) -> Int {
        _ = goalVersion // ✅ establishes dependency so UI updates when goalVersion changes
        return PV2GoalHistory.goalMinutes(
            for: date,
            fallback: max(0, stats.dailyGoalMinutes),
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

    // =========================================================
    // MARK: - Insights
    // =========================================================

    private func activeFocusDays(lastNDays n: Int) -> Int {
        guard n > 0 else { return 0 }
        let today = cal.startOfDay(for: Date())
        let set = Set(stats.sessions.filter { $0.duration > 0 }.map { cal.startOfDay(for: $0.date) })

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

    private func hourRangeLabel(_ startHour: Int) -> String {
        let df = DateFormatter()
        df.locale = .autoupdatingCurrent
        df.dateFormat = "h a"

        let base = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .hour, value: startHour, to: base) ?? base
        let end = cal.date(byAdding: .hour, value: 1, to: start) ?? start.addingTimeInterval(3600)

        let s = df.string(from: start)
        let e = df.string(from: end)

        let sParts = s.split(separator: " ")
        let eParts = e.split(separator: " ")
        if sParts.count == 2, eParts.count == 2, sParts[1] == eParts[1] {
            return "\(sParts[0])–\(eParts[0]) \(sParts[1])"
        }
        return "\(s)–\(e)"
    }

    // =========================================================
    // MARK: - Actions
    // =========================================================

    private func stepDay(_ val: Int) {
        Haptics.impact(.light)
        withAnimation(.spring(response: 0.34, dampingFraction: 0.90)) {
            selectedDate = cal.date(byAdding: .day, value: val, to: selectedDate) ?? selectedDate
        }
    }

    private func jumpToday() {
        Haptics.impact(.medium)
        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
            selectedDate = Date()
        }
    }
}

// =========================================================
// MARK: - Goal History (Per-day goal memory)
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
// MARK: - Premium UI Components
// =========================================================

private struct PV2GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 26
    let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
    }
}

private struct PV2AmbientBlob: View {
    let color: Color
    let x: CGFloat
    let y: CGFloat

    @State private var appear = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 320, height: 320)
            .blur(radius: 110)
            .opacity(appear ? 0.40 : 0)
            .offset(x: x, y: y)
            .onAppear { withAnimation(.easeIn(duration: 1.6)) { appear = true } }
    }
}

// =========================================================
// MARK: - Header + Date
// =========================================================

private struct PV2TopHeader: View {
    let monthTitle: String
    let onJumpToday: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image("Focusflow_Logo")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)

                    Text("Progress")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text(monthTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
            }

            Spacer()

            // ✅ Same sizing as StatsView header button
            Button(action: onJumpToday) {
                Image(systemName: "arrow.counterclockwise")
                    .imageScale(.medium)
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.20))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

private struct PV2DateCapsule: View {
    let title: String
    let onPrev: () -> Void
    let onNext: () -> Void
    let onTapTitle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPrev) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .frame(width: 44, height: 42)
                    .background(Color.white.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: onTapTitle) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
                    .frame(width: 44, height: 42)
                    .background(Color.white.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

// =========================================================
// MARK: - Today Hero Card
// =========================================================

private struct PV2TodayHeroCard: View {
    let theme: AppTheme
    let day: Date
    let focusSeconds: TimeInterval
    let goalMinutes: Int
    let sessions: [FocusSession]
    let tasksAgg: (scheduled: Int, completed: Int, plannedMinutes: Int, completionRate: Double)
    let onTapGoal: () -> Void

    private var goalSeconds: Double { Double(max(1, goalMinutes)) * 60.0 }
    private var progress: Double { goalMinutes > 0 ? min(1.0, focusSeconds / goalSeconds) : 0 }

    var body: some View {
        PV2GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    Text(dayLabel(day))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))

                    Spacer()

                    Button(action: onTapGoal) {
                        HStack(spacing: 6) {
                            Image(systemName: "scope").imageScale(.small)
                            Text("Goal").lineLimit(1)
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.14))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.10), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .frame(width: 78, height: 78)

                        Circle()
                            .trim(from: 0, to: CGFloat(min(1, max(0, progress))))
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [theme.accentPrimary, theme.accentSecondary, theme.accentPrimary]),
                                    center: .center,
                                    startAngle: .degrees(-90),
                                    endAngle: .degrees(270)
                                ),
                                style: StrokeStyle(lineWidth: 16, lineCap: .round)
                            )
                            .frame(width: 78, height: 78)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: theme.accentPrimary.opacity(0.35), radius: 10, x: 0, y: 0)
                            .animation(.spring(response: 0.55, dampingFraction: 0.78), value: progress)

                        VStack(spacing: 1) {
                            Text("\(Int(round(progress * 100)))%")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Goal")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.55))
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Focus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.65))

                        HStack(alignment: .lastTextBaseline, spacing: 8) {
                            Text(durationText(focusSeconds))
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)

                            Text("/ \(goalMinutes)m")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.40))
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)
                }

                let avg = avgSessionMinutes(sessions)
                let longest = longestSessionMinutes(sessions)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    PV2MiniMetric(title: "Sessions", value: "\(sessions.count)", icon: "bolt.fill")
                    PV2MiniMetric(title: "Avg", value: avg > 0 ? "\(avg)m" : "—", icon: "clock.fill")
                    PV2MiniMetric(title: "Longest", value: longest > 0 ? "\(longest)m" : "—", icon: "stopwatch.fill")
                    PV2MiniMetric(title: "Tasks", value: "\(tasksAgg.completed)/\(tasksAgg.scheduled)", icon: "checkmark.circle.fill")
                }

                Text(coachLine(tasksAgg: tasksAgg, progress: progress))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.70))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
    }

    private func dayLabel(_ d: Date) -> String {
        let c = Calendar.autoupdatingCurrent
        if c.isDateInToday(d) { return "Today" }
        if c.isDateInYesterday(d) { return "Yesterday" }
        return d.formatted(date: .abbreviated, time: .omitted)
    }

    private func coachLine(tasksAgg: (scheduled: Int, completed: Int, plannedMinutes: Int, completionRate: Double), progress: Double) -> String {
        if tasksAgg.scheduled > 0 && tasksAgg.completed < tasksAgg.scheduled {
            return "Today has \(tasksAgg.scheduled) planned. Start with the smallest for a quick win."
        }
        if progress >= 1.0 { return "Goal hit. Keep it light and steady." }
        let remaining = max(0, Int(round((1.0 - progress) * Double(goalMinutes))))
        return remaining > 0 ? "\(remaining)m to hit your goal." : "Start a quick session to begin the day."
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "0m" }
        let f = DateComponentsFormatter()
        f.allowedUnits = seconds >= 3600 ? [.hour, .minute] : [.minute]
        f.unitsStyle = .abbreviated
        return f.string(from: seconds) ?? "0m"
    }

    private func avgSessionMinutes(_ list: [FocusSession]) -> Int {
        guard !list.isEmpty else { return 0 }
        let avg = list.reduce(0.0) { $0 + $1.duration } / Double(list.count)
        return max(0, Int(round(avg / 60.0)))
    }

    private func longestSessionMinutes(_ list: [FocusSession]) -> Int {
        let maxSec = list.map { $0.duration }.max() ?? 0
        return Int(round(maxSec / 60.0))
    }
}

private struct PV2MiniMetric: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.70))
                    .lineLimit(1)

                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

// =========================================================
// MARK: - Week Summary
// =========================================================

private struct PV2WeekSummaryCard: View {
    let theme: AppTheme
    let weekStart: Date
    let weekFocusSeconds: TimeInterval
    let weekTasksAgg: (scheduled: Int, completed: Int, plannedMinutes: Int, completionRate: Double)
    let weeklyGoalMinutes: Int
    let plannedWeekMinutes: Int
    let weekDayIndex: Int

    var body: some View {
        PV2GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Week")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.95))

                        Text(weekRangeTitle(weekStart))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.65))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    Spacer()

                    PV2PercentPill(percentText: weekPercentText())
                }

                HStack(spacing: 10) {
                    PV2WeekTile(
                        title: "Focus",
                        value: durationText(weekFocusSeconds),
                        foot: focusFoot()
                    )

                    PV2WeekTile(
                        title: "Tasks",
                        value: "\(weekTasksAgg.completed)/\(weekTasksAgg.scheduled)",
                        foot: tasksFoot()
                    )
                }

                Text(planLine())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
    }

    private func weekRangeTitle(_ ws: Date) -> String {
        let cal = Calendar.autoupdatingCurrent
        let end = cal.date(byAdding: .day, value: 6, to: ws) ?? ws
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.setLocalizedDateFormatFromTemplate("MMM d")
        return "\(f.string(from: ws)) – \(f.string(from: end))"
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "0m" }
        let f = DateComponentsFormatter()
        f.allowedUnits = seconds >= 3600 ? [.hour, .minute] : [.minute]
        f.unitsStyle = .abbreviated
        return f.string(from: seconds) ?? "0m"
    }

    private func weekPercentText() -> String {
        let denom = max(1, weeklyGoalMinutes)
        let pct = Int(round((weekFocusSeconds / 60.0) / Double(denom) * 100.0))
        return "\(max(0, pct))%"
    }

    private func focusFoot() -> String {
        let minutes = Int(round(weekFocusSeconds / 60.0))
        let avgPerDay = Int(round(Double(minutes) / 7.0))
        return "Avg/day \(avgPerDay)m"
    }

    private func tasksFoot() -> String {
        if weekTasksAgg.scheduled == 0 { return "No tasks" }
        let pct = Int(round(weekTasksAgg.completionRate * 100))
        return "\(pct)% completion"
    }

    private func planLine() -> String {
        let focusedM = Int(round(weekFocusSeconds / 60.0))
        let plannedM = max(0, plannedWeekMinutes)
        if plannedM == 0 { return "Set task durations to track plan vs done." }

        let remaining = max(0, plannedM - focusedM)
        if remaining == 0 { return "You’re on track with your plan." }

        let daysLeft = max(1, 7 - weekDayIndex)
        let perDay = Int(ceil(Double(remaining) / Double(daysLeft)))
        return "\(remaining)m remaining • ~\(perDay)m/day to finish your plan."
    }
}

private struct PV2WeekTile: View {
    let title: String
    let value: String
    let foot: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(1)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(foot)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.60))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct PV2PercentPill: View {
    let percentText: String
    var body: some View {
        Text(percentText)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white.opacity(0.92))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.14))
            .clipShape(Capsule())
            .lineLimit(1)
    }
}

// =========================================================
// MARK: - Weekly Activity
// =========================================================

private struct PV2WeeklyPagerChart: View {
    let theme: AppTheme
    let pages: [Date]
    let displayWeekStart: Date

    let weekTitle: (Date) -> String
    let barsForWeekStart: (Date) -> [(String, Int, Date)]
    let selectedDate: Date
    let goalForDate: (Date) -> Int

    @Binding var weekPageIndex: Int
    let onSelectDate: (Date) -> Void

    var body: some View {
        PV2GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Weekly Activity")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))

                    Spacer()

                    Text("Swipe")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.70))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Capsule())
                }

                Text(weekTitle(displayWeekStart))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
                    .padding(.top, 2)

                TabView(selection: $weekPageIndex) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, start in
                        PV2WeekBars(
                            bars: barsForWeekStart(start),
                            selectedDate: selectedDate,
                            theme: theme,
                            goalForDate: goalForDate,
                            onTap: onSelectDate
                        )
                        .padding(.horizontal, 2)
                        .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 140)

                Text("Goal-based fill • Tap a day to jump.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
        }
    }
}

private struct PV2WeekBars: View {
    let bars: [(String, Int, Date)]
    let selectedDate: Date
    let theme: AppTheme
    let goalForDate: (Date) -> Int
    let onTap: (Date) -> Void

    private var cal: Calendar { .autoupdatingCurrent }
    private let barHeight: CGFloat = 96
    private let pillWidth: CGFloat = 32

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(Array(bars.enumerated()), id: \.offset) { _, b in
                let d = b.2
                let isSelected = cal.isDate(d, inSameDayAs: selectedDate)
                let isFuture = cal.startOfDay(for: d) > cal.startOfDay(for: Date())

                let goal = max(1, goalForDate(d))
                let frac = min(1.0, Double(max(0, b.1)) / Double(goal))
                let fillH = CGFloat(frac) * barHeight

                Button { onTap(d) } label: {
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottom) {
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: pillWidth, height: barHeight)
                                .overlay(
                                    Group {
                                        if isSelected {
                                            Capsule(style: .continuous)
                                                .strokeBorder(Color.white.opacity(0.85), lineWidth: 2)
                                        }
                                    }
                                )

                            if !isFuture, b.1 > 0 {
                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [theme.accentPrimary, theme.accentSecondary]),
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(width: pillWidth, height: max(8, fillH))
                            }
                        }

                        Text(String(b.0.prefix(1)))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(isSelected ? 0.95 : (isFuture ? 0.25 : 0.65)))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(isSelected ? Color.white.opacity(0.12) : Color.clear)
                            .clipShape(Capsule())
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 132)
    }
}

// =========================================================
// MARK: - Insights (2x2 Grid • Peak fits)
// =========================================================

private struct PV2InsightsStrip: View {
    let theme: AppTheme
    let activeDays7: Int
    let goalHits7: Int
    let bestWindow: String
    let peakDay: (date: Date, minutes: Int)?

    var body: some View {
        PV2GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Insights")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))

                let peakTitle: String = {
                    guard let peakDay else { return "Peak day" }
                    let f = DateFormatter()
                    f.locale = .autoupdatingCurrent
                    f.setLocalizedDateFormatFromTemplate("MMM d")
                    return "Peak • \(f.string(from: peakDay.date))"
                }()

                let peakValue: String = {
                    guard let peakDay else { return "—" }
                    return minutesText(peakDay.minutes)
                }()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    PV2InsightPill(icon: "calendar", title: "Active", value: "\(activeDays7)/7")
                    PV2InsightPill(icon: "scope", title: "Goal hits", value: "\(goalHits7)/7")
                    PV2InsightPill(icon: "clock.fill", title: "Best time", value: bestWindow)
                    PV2InsightPill(icon: "sparkles", title: peakTitle, value: peakValue)
                }
            }
        }
    }

    private func minutesText(_ mins: Int) -> String {
        let m = max(0, mins)
        if m >= 60 {
            let h = m / 60
            let rm = m % 60
            return rm == 0 ? "\(h)h" : "\(h)h \(rm)m"
        }
        return "\(m)m"
    }
}

private struct PV2InsightPill: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.70))
                    .lineLimit(1)
                    .minimumScaleFactor(0.80)

                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.60)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

// =========================================================
// MARK: - Replay Timeline
// =========================================================

private struct PV2TimelineView: View {
    let sessions: [FocusSession]
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Replay")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))
                Spacer()
                Text("\(sessions.count) session\(sessions.count == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.70))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 4)

            if sessions.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white.opacity(0.18))
                    Text("No sessions recorded")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.45))
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 190)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sessions.enumerated()), id: \.offset) { index, session in
                        PV2TimelineRow(
                            session: session,
                            isLast: index == sessions.count - 1,
                            theme: theme
                        )
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                )
            }
        }
    }
}

private struct PV2TimelineRow: View {
    let session: FocusSession
    let isLast: Bool
    let theme: AppTheme

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(session.date.formatted(date: .omitted, time: .shortened))
                .font(.caption2.monospaced().weight(.semibold))
                .foregroundColor(.white.opacity(0.55))
                .frame(width: 60, alignment: .trailing)
                .padding(.top, 2)

            VStack(spacing: 0) {
                Circle()
                    .fill(theme.accentSecondary.opacity(0.95))
                    .frame(width: 10, height: 10)
                    .padding(.top, 4)

                if !isLast {
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.top, 6)
                }
            }
            .frame(width: 12)

            VStack(alignment: .leading, spacing: 6) {
                Text(sessionTitle(session))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.93))
                    .lineLimit(1)

                Text(formatDuration(session.duration))
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Capsule())
            }
            .padding(.bottom, isLast ? 14 : 22)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, isLast ? 14 : 0)
    }

    private func sessionTitle(_ s: FocusSession) -> String {
        let raw = (s.sessionName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? "Focus Session" : raw
    }

    private func formatDuration(_ sec: TimeInterval) -> String {
        let m = max(0, Int(sec) / 60)
        if m >= 60 {
            let h = m / 60
            let rm = m % 60
            return rm == 0 ? "\(h)h" : "\(h)h \(rm)m"
        }
        return "\(m)m"
    }
}

// =========================================================
// MARK: - Sheets
// =========================================================

private struct PV2GoalSheet: View {
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

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: theme.backgroundColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                PV2AmbientBlob(color: theme.accentPrimary, x: -size.width * 0.40, y: -size.height * 0.45)
                PV2AmbientBlob(color: theme.accentSecondary, x:  size.width * 0.40, y:  size.height * 0.40)

                VStack(spacing: 18) {
                    Spacer().frame(height: 18)

                    Text("Daily goal")
                        .font(.title3.bold())
                        .foregroundColor(.white)

                    Text("Set a target that feels sustainable.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    HStack(spacing: 0) {
                        VStack(spacing: 8) {
                            Text("Hours")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.75))

                            Picker("Hours", selection: $hours) {
                                ForEach(0..<9, id: \.self) { h in Text("\(h)").tag(h) }
                            }
                            .pickerStyle(.wheel)
                        }
                        .frame(maxWidth: .infinity)
                        .clipped()

                        VStack(spacing: 8) {
                            Text("Minutes")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.75))

                            Picker("Minutes", selection: $minutes) {
                                ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { m in
                                    Text("\(m)").tag(m)
                                }
                            }
                            .pickerStyle(.wheel)
                        }
                        .frame(maxWidth: .infinity)
                        .clipped()
                    }
                    .frame(height: 170)
                    .colorScheme(.dark)
                    .padding(.horizontal, 18)

                    HStack {
                        Button("Cancel") { dismiss() }
                            .foregroundColor(.white.opacity(0.7))

                        Spacer()

                        Button("Set goal") {
                            Haptics.impact(.light)
                            goalMinutes = totalMinutes
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    }
                    .padding(.horizontal, 26)

                    Spacer(minLength: 10)
                }
            }
        }
    }
}

private struct PV2DatePickerSheet: View {
    let theme: AppTheme
    @Binding var date: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: theme.backgroundColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer().frame(height: 18)

                Text("Pick a date")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                DatePicker("", selection: $date, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .tint(.white)
                    .padding(.horizontal, 18)

                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 26)

                Spacer(minLength: 10)
            }
        }
    }
}

#Preview {
    ProgressViewV2()
}
