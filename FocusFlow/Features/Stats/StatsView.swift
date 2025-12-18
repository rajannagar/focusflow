import SwiftUI
import UIKit

// MARK: - Glass card container

private struct GlassCard<Content: View>: View {
    let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
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
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Main Stats View (iOS 18+)

struct StatsView: View {
    @ObservedObject private var stats = StatsManager.shared
    @ObservedObject private var appSettings = AppSettings.shared

    // UI State
    @State private var showingGoalSheet = false

    // Month navigation (arrows)
    @State private var monthOffset: Int = 0

    // Selected day (nil = default)
    @State private var selectedDay: Date? = nil

    // Trigger to force the chart to scroll back to "Today"
    @State private var resetChartTrigger = UUID()

    // Header icon animation
    @State private var iconPulse = false

    private let calendar = Calendar.current

    // ✅ Force Sunday → Saturday everywhere (stable regardless of locale)
    private var sundayCalendar: Calendar {
        var c = calendar
        c.firstWeekday = 1 // Sunday
        return c
    }

    private var theme: AppTheme { appSettings.selectedTheme }

    // MARK: - Formatters

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }

    // MARK: - Date helpers

    private func startOfDay(_ d: Date) -> Date { sundayCalendar.startOfDay(for: d) }

    private func dayInterval(for day: Date) -> DateInterval {
        let start = startOfDay(day)
        let end = sundayCalendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86400)
        return DateInterval(start: start, end: end)
    }

    // Returns the full Month interval (e.g., Dec 1 - Jan 1)
    private func monthInterval(offset: Int) -> DateInterval? {
        let base = sundayCalendar.date(byAdding: .month, value: -offset, to: Date()) ?? Date()
        let comps = sundayCalendar.dateComponents([.year, .month], from: base)
        guard let start = sundayCalendar.date(from: comps) else { return nil }
        let end = sundayCalendar.date(byAdding: .month, value: 1, to: start) ?? start.addingTimeInterval(30 * 86400)
        return DateInterval(start: start, end: end)
    }

    // The currently visible Month
    private var activeMonthInterval: DateInterval {
        return monthInterval(offset: monthOffset) ?? DateInterval(start: Date(), duration: 30 * 86400)
    }

    private var isCurrentMonth: Bool {
        return sundayCalendar.isDate(Date(), equalTo: activeMonthInterval.start, toGranularity: .month)
    }

    // MARK: - Sessions (source of truth)

    private var allSessions: [FocusSession] {
        stats.sessions.sorted { $0.date > $1.date }
    }

    private func sessions(in interval: DateInterval) -> [FocusSession] {
        allSessions.filter { $0.date >= interval.start && $0.date < interval.end }
    }

    private func total(in interval: DateInterval) -> TimeInterval {
        sessions(in: interval).reduce(0) { $0 + $1.duration }
    }

    // MARK: - Selected day (default behavior)

    private var selectedDayResolved: Date {
        // ✅ If user explicitly selected a day, always respect it
        if let sd = selectedDay { return startOfDay(sd) }

        // ✅ Default: If Today is in the visible month, select Today.
        // Otherwise, select the first day of that month.
        let today = startOfDay(Date())
        if today >= activeMonthInterval.start && today < activeMonthInterval.end {
            return today
        }
        return startOfDay(activeMonthInterval.start)
    }

    // ✅ Newest → Oldest
    private var selectedDaySessionsAll: [FocusSession] {
        let di = dayInterval(for: selectedDayResolved)
        return allSessions
            .filter { $0.date >= di.start && $0.date < di.end }
            .sorted { $0.date > $1.date }
    }

    private var selectedDayTotalAll: TimeInterval {
        selectedDaySessionsAll.reduce(0) { $0 + $1.duration }
    }

    private var selectedDayAvgMinutes: Int {
        guard !selectedDaySessionsAll.isEmpty else { return 0 }
        return Int(round((selectedDayTotalAll / Double(selectedDaySessionsAll.count)) / 60.0))
    }

    private var goalSeconds: TimeInterval { TimeInterval(stats.dailyGoalMinutes * 60) }

    // ✅ Top summary follows selected day
    private var topSummaryTitle: String {
        if sundayCalendar.isDateInToday(selectedDayResolved) { return "Today" }
        if sundayCalendar.isDateInYesterday(selectedDayResolved) { return "Yesterday" }
        return selectedDayResolved.formatted(date: .abbreviated, time: .omitted)
    }

    private var topSummaryPercent: Int {
        let denom = max(1.0, Double(stats.dailyGoalMinutes) * 60.0)
        return Int((selectedDayTotalAll / denom) * 100.0)
    }

    private var currentStreak: Int {
        let daysWithFocus = Set(allSessions.filter({ $0.duration > 0 }).map({ startOfDay($0.date) }))
        guard !daysWithFocus.isEmpty else { return 0 }
        var current = 0
        var cursor = startOfDay(Date())
        while daysWithFocus.contains(cursor) {
            current += 1
            guard let prev = sundayCalendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return current
    }

    // MARK: - Point Generation (For the Chart)

    struct TrendPoint: Identifiable {
        let id = UUID()
        let date: Date
        let total: TimeInterval
        let prevTotal: TimeInterval
    }

    private func generateTrendPoints(for interval: DateInterval) -> [TrendPoint] {
        let prevIntervalStart = sundayCalendar.date(byAdding: .weekOfYear, value: -1, to: interval.start) ?? interval.start

        return (0..<7).compactMap { i in
            guard let d = sundayCalendar.date(byAdding: .day, value: i, to: interval.start),
                  let p = sundayCalendar.date(byAdding: .day, value: i, to: prevIntervalStart) else { return nil }

            let t = total(in: dayInterval(for: d))
            let pr = total(in: dayInterval(for: p))
            return TrendPoint(date: startOfDay(d), total: t, prevTotal: pr)
        }
    }

    // MARK: - Distribution (✅ now based on TIME, not count)

    enum Bucket: String, CaseIterable, Identifiable {
        case morning, afternoon, evening
        var id: String { rawValue }
        var label: String {
            switch self {
            case .morning: return "Morning"
            case .afternoon: return "Afternoon"
            case .evening: return "Evening"
            }
        }
    }

    private func bucket(for hour: Int) -> Bucket {
        if hour < 12 { return .morning }
        if hour < 17 { return .afternoon }
        return .evening
    }

    private var distribution: [(Bucket, TimeInterval)] {
        let intervalSessions = sessions(in: activeMonthInterval)
        var dict: [Bucket: TimeInterval] = [.morning: 0, .afternoon: 0, .evening: 0]

        for s in intervalSessions {
            let hour = sundayCalendar.component(.hour, from: s.date)
            let b = bucket(for: hour)
            dict[b, default: 0] += s.duration
        }

        return Bucket.allCases.map { ($0, dict[$0, default: 0]) }
    }

    // MARK: - Header labels

    private var subtitleText: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        let label = f.string(from: activeMonthInterval.start)
        return monthOffset == 0 ? "This Month • \(label)" : label
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let accentPrimary = theme.accentPrimary
            let accentSecondary = theme.accentSecondary

            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: theme.backgroundColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Circle()
                    .fill(accentPrimary.opacity(0.5))
                    .blur(radius: 90)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: -size.width * 0.45, y: -size.height * 0.55)

                Circle()
                    .fill(accentSecondary.opacity(0.35))
                    .blur(radius: 100)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: size.width * 0.45, y: size.height * 0.5)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        header
                            .padding(.horizontal, 22)
                            .padding(.top, 18)

                        summaryRow
                            .padding(.horizontal, 22)

                        thisWeekCard
                            .padding(.horizontal, 22)

                        timeDistributionCard
                            .padding(.horizontal, 22)

                        selectedDayCard
                            .padding(.horizontal, 22)
                            .padding(.bottom, 120)
                    }
                }
            }
        }
        .onAppear {
            iconPulse = true
            selectedDay = nil
        }
        .onChange(of: monthOffset) { _, _ in
            selectedDay = nil
        }
        .sheet(isPresented: $showingGoalSheet) {
            GoalSheet(goalMinutes: $stats.dailyGoalMinutes)
        }
    }

    // MARK: - Header (✅ removed delete/trash)

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image("Focusflow_Logo")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                        .scaleEffect(iconPulse ? 1.06 : 0.94)
                        .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: iconPulse)

                    Text("Stats")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text(subtitleText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()

            // Keep goal only
            Button {
                Haptics.impact(.light)
                showingGoalSheet = true
            } label: {
                Image(systemName: "target")
                    .imageScale(.medium)
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.20))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Summary

    private var summaryRow: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(topSummaryTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    Text(selectedDayTotalAll > 0 ? selectedDayTotalAll.asReadableDuration : "No focus logged")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        StatPill(icon: "checkmark.circle.fill", text: "\(selectedDaySessionsAll.count) sessions", tint: .white.opacity(0.8))
                        StatPill(icon: "flame.fill", text: "\(currentStreak) streak", tint: .white.opacity(0.8))
                    }
                    .padding(.top, 4)
                }

                Spacer()

                StatsDonutRing(
                    progress: stats.dailyGoalMinutes > 0 ? min(selectedDayTotalAll / max(1, goalSeconds), 1.0) : 0,
                    accentA: theme.accentPrimary,
                    accentB: theme.accentSecondary,
                    centerTop: stats.dailyGoalMinutes > 0 ? "\(max(0, topSummaryPercent))%" : "--",
                    centerBottom: "Goal"
                )
            }
        }
    }

    // MARK: - This Week Card

    private var thisWeekCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("This Week")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.95))

                        Text("Swipe to view weeks. Tap a day.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        Button {
                            Haptics.impact(.light)
                            withAnimation {
                                monthOffset = 0
                                selectedDay = nil
                                resetChartTrigger = UUID()
                            }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.white.opacity(0.16))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)

                        HStack(spacing: 6) {
                            Button {
                                Haptics.impact(.light)
                                monthOffset += 1
                                selectedDay = nil
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(8)
                                    .background(Color.white.opacity(0.16))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)

                            Button {
                                Haptics.impact(.light)
                                monthOffset = max(monthOffset - 1, 0)
                                selectedDay = nil
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(8)
                                    .background(Color.white.opacity(monthOffset == 0 ? 0.08 : 0.16))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .disabled(monthOffset == 0)
                        }
                    }
                }

                Text(selectedDayResolved.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.14))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .leading)

                MonthlyPagedWeekChart(
                    accentA: theme.accentPrimary,
                    accentB: theme.accentSecondary,
                    monthStart: activeMonthInterval.start,
                    monthEnd: activeMonthInterval.end,
                    selectedDay: selectedDayResolved,
                    isCurrentMonth: isCurrentMonth,
                    goalMinutes: stats.dailyGoalMinutes,
                    resetTrigger: resetChartTrigger,
                    calendar: sundayCalendar,
                    generatePoints: generateTrendPoints(for:),
                    onSelectDay: { d in
                        Haptics.impact(.light)
                        selectedDay = d
                    }
                )
                .frame(height: 200)
            }
        }
    }

    // MARK: - Time distribution

    private var timeDistributionCard: some View {
        TimeDistributionCard(
            accentA: theme.accentPrimary,
            accentB: theme.accentSecondary,
            distribution: distribution,
            monthLabel: subtitleText
        )
    }

    // MARK: - Selected day detail

    private var selectedDayCard: some View {
        GlassCard {
            SelectedDayDetail(
                accentA: theme.accentPrimary,
                accentB: theme.accentSecondary,
                day: selectedDayResolved,
                total: selectedDayTotalAll,
                sessionCount: selectedDaySessionsAll.count,
                avgMinutes: selectedDayAvgMinutes,
                sessions: selectedDaySessionsAll,
                timeFormatter: timeFormatter
            )
        }
    }
}

// MARK: - Unified Stats Pill

private struct StatsGraphPill: View {
    let width: CGFloat
    let height: CGFloat

    let fillFraction: CGFloat
    let prevFraction: CGFloat

    let fillGradient: LinearGradient
    let isSelected: Bool
    let isFuture: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(isFuture ? 0.03 : 0.06))
                .frame(width: width, height: height)

            if !isFuture {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: width, height: max(0, height * min(1.0, prevFraction)))
            }

            if !isFuture {
                Capsule(style: .continuous)
                    .fill(fillGradient)
                    .frame(width: width, height: max(0, height * min(1.0, fillFraction)))
                    .opacity(fillFraction > 0.02 ? 1.0 : 0.35)
            }
        }
        .frame(width: width, height: height, alignment: .bottom)
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(isSelected ? 0.9 : 0.0), lineWidth: 1.5)
        )
        .shadow(color: (fillFraction >= 1.0 && !isFuture) ? Color.white.opacity(0.25) : .clear, radius: 6, x: 0, y: 0)
    }
}

// MARK: - Weekly Fixed Chart (Used inside Monthly Pager)

private struct WeeklyFixedPillChart: View {
    let accentA: Color
    let accentB: Color
    let points: [StatsView.TrendPoint]
    let selectedDay: Date
    let goalMinutes: Int
    let calendar: Calendar
    let onSelectDay: (Date) -> Void

    private let barHeight: CGFloat = 140
    private let fixedPillWidth: CGFloat = 32

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(points) { point in
                let isSel = calendar.isDate(point.date, inSameDayAs: selectedDay)
                let isFuture = calendar.startOfDay(for: point.date) > calendar.startOfDay(for: Date())

                let minutes = Int(point.total / 60)
                let prevMinutes = Int(point.prevTotal / 60)

                let safeGoal = max(1, CGFloat(goalMinutes))
                let fill = CGFloat(minutes) / safeGoal
                let prevFill = CGFloat(prevMinutes) / safeGoal

                Button {
                    onSelectDay(point.date)
                } label: {
                    VStack(spacing: 12) {
                        StatsGraphPill(
                            width: fixedPillWidth,
                            height: barHeight,
                            fillFraction: fill,
                            prevFraction: prevFill,
                            fillGradient: LinearGradient(colors: [accentA, accentB], startPoint: .bottom, endPoint: .top),
                            isSelected: isSel,
                            isFuture: isFuture
                        )

                        Text(dateLabel(for: point.date))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(isSel ? .white : .white.opacity(isFuture ? 0.2 : 0.6))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(isSel ? Color.white.opacity(0.15) : Color.clear)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func dateLabel(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "E"
        return String(f.string(from: date).prefix(1)).uppercased()
    }
}

// MARK: - Monthly Paged Week Chart (Paging)

private struct MonthlyPagedWeekChart: View {
    let accentA: Color
    let accentB: Color

    let monthStart: Date
    let monthEnd: Date

    let selectedDay: Date
    let isCurrentMonth: Bool
    let goalMinutes: Int
    let resetTrigger: UUID
    let calendar: Calendar
    let generatePoints: (DateInterval) -> [StatsView.TrendPoint]
    let onSelectDay: (Date) -> Void

    @State private var selectedPageIndex: Int = 0

    private var monthWeeks: [DateInterval] {
        var weeks: [DateInterval] = []

        let mStart = calendar.startOfDay(for: monthStart)
        let mEnd = calendar.startOfDay(for: monthEnd)

        guard let firstWeekStart = calendar.dateInterval(of: .weekOfYear, for: mStart)?.start else {
            return [DateInterval(start: mStart, end: calendar.date(byAdding: .day, value: 7, to: mStart) ?? mStart)]
        }

        var currentStart = firstWeekStart
        while currentStart < mEnd {
            let end = calendar.date(byAdding: .day, value: 7, to: currentStart) ?? currentStart.addingTimeInterval(7 * 86400)
            weeks.append(DateInterval(start: currentStart, end: end))
            currentStart = end
        }

        return weeks
    }

    var body: some View {
        TabView(selection: $selectedPageIndex) {
            ForEach(Array(monthWeeks.enumerated()), id: \.offset) { index, weekInterval in
                WeeklyFixedPillChart(
                    accentA: accentA,
                    accentB: accentB,
                    points: generatePoints(weekInterval),
                    selectedDay: selectedDay,
                    goalMinutes: goalMinutes,
                    calendar: calendar,
                    onSelectDay: onSelectDay
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onAppear { goToInitialWeek() }
        .onChange(of: monthStart) { _, _ in goToInitialWeek() }
        .onChange(of: resetTrigger) { _, _ in goToInitialWeek() }
    }

    private func goToInitialWeek() {
        if isCurrentMonth {
            let today = calendar.startOfDay(for: Date())
            if let index = monthWeeks.firstIndex(where: { $0.start <= today && today < $0.end }) {
                selectedPageIndex = index
            } else {
                selectedPageIndex = 0
            }
        } else {
            selectedPageIndex = 0
        }
    }
}

// MARK: - Time Distribution (✅ duration-based)

private struct TimeDistributionCard: View {
    let accentA: Color
    let accentB: Color
    let distribution: [(StatsView.Bucket, TimeInterval)]
    let monthLabel: String

    private struct Item: Identifiable {
        let id = UUID()
        let bucket: StatsView.Bucket
        let percent: Int
        let duration: TimeInterval
    }

    private var items: [Item] {
        let total = max(1.0, distribution.reduce(0.0) { $0 + $1.1 })
        return distribution.map { pair in
            let pct = Int((pair.1 / total) * 100.0)
            return Item(bucket: pair.0, percent: pct, duration: pair.1)
        }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("When you focus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))
                    Text("Based on focused time • \(monthLabel)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }

                HStack(spacing: 10) {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.bucket.label)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white.opacity(0.75))

                            Text("\(item.percent)%")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)

                            Text(item.duration > 0 ? item.duration.asReadableDuration : "—")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.55))

                            RoundedRectangle(cornerRadius: 999, style: .continuous)
                                .fill(segmentGradient(for: item.bucket))
                                .frame(height: 4)
                                .opacity(0.85)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private func segmentGradient(for bucket: StatsView.Bucket) -> LinearGradient {
        switch bucket {
        case .morning:
            return LinearGradient(colors: [.orange.opacity(0.95), .orange.opacity(0.45)], startPoint: .leading, endPoint: .trailing)
        case .afternoon:
            return LinearGradient(colors: [accentA, accentB], startPoint: .leading, endPoint: .trailing)
        case .evening:
            return LinearGradient(colors: [Color.white.opacity(0.55), Color.white.opacity(0.18)], startPoint: .leading, endPoint: .trailing)
        }
    }
}

// MARK: - Selected Day Detail

private struct SelectedDayDetail: View {
    let accentA: Color
    let accentB: Color

    let day: Date
    let total: TimeInterval
    let sessionCount: Int
    let avgMinutes: Int
    let sessions: [FocusSession]
    let timeFormatter: DateFormatter

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dayTitle(day))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(total > 0 ? total.asReadableDuration : "No focus logged")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            HStack(spacing: 10) {
                miniPill(icon: "clock", text: "\(sessionCount) session\(sessionCount == 1 ? "" : "s")")
                miniPill(icon: "gauge", text: avgMinutes == 0 ? "— min avg" : "\(avgMinutes) min avg")
                Spacer()
            }

            if sessions.isEmpty {
                Text("Start a session to light up this day.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.top, 2)
            } else {
                VStack(spacing: 10) {
                    ForEach(sessions.sorted(by: { $0.date > $1.date })) { s in
                        HStack(spacing: 10) {
                            Text(timeFormatter.string(from: s.date))
                                .font(.caption2.monospaced().weight(.semibold))
                                .foregroundColor(.white.opacity(0.65))
                                .frame(width: 62, alignment: .leading)

                            Text(s.sessionName ?? "Focus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))
                                .lineLimit(1)

                            Spacer()

                            Text(s.duration.asReadableDuration)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [accentA, accentB]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    private func dayTitle(_ date: Date) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    private func miniPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).imageScale(.small)
            Text(text)
        }
        .font(.system(size: 11, weight: .medium))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.18))
        .clipShape(Capsule())
        .foregroundColor(.white.opacity(0.9))
    }
}

// MARK: - Donut ring

private struct StatsDonutRing: View {
    let progress: Double
    let accentA: Color
    let accentB: Color
    let centerTop: String
    let centerBottom: String

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.18), lineWidth: 8)

            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [accentA, accentB, accentA]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: progress)

            VStack(spacing: 2) {
                Text(centerTop)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(centerBottom)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(width: 70, height: 70)
        .padding(.leading, 4)
    }
}

private struct StatPill: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).imageScale(.small)
            Text(text)
        }
        .font(.system(size: 11, weight: .medium))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.18))
        .clipShape(Capsule())
        .foregroundColor(tint)
    }
}

// MARK: - Goal sheet (Polished)

private struct GoalSheet: View {
    @Binding var goalMinutes: Int
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var appSettings = AppSettings.shared

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: appSettings.selectedTheme.backgroundColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Text("Daily Goal")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.top, 16)

                VStack(spacing: 4) {
                    Text("\(goalMinutes)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())

                    Text("minutes per day")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.vertical, 10)

                HStack(spacing: 16) {
                    Button {
                        Haptics.impact(.light)
                        if goalMinutes > 5 { goalMinutes -= 5 }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }

                    Slider(
                        value: Binding(get: { Double(goalMinutes) }, set: { goalMinutes = Int($0) }),
                        in: 5...240,
                        step: 5
                    )
                    .tint(.white)

                    Button {
                        Haptics.impact(.light)
                        if goalMinutes < 240 { goalMinutes += 5 }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }

                Text("Approx. \(max(1, goalMinutes / 25)) focus session\(goalMinutes/25 > 1 ? "s" : "")")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, -8)

                Spacer()

                Button {
                    Haptics.impact(.medium)
                    dismiss()
                } label: {
                    Text("Update Goal")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
            .padding(24)
        }
        .presentationDetents([.fraction(0.55)])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    StatsView()
}
