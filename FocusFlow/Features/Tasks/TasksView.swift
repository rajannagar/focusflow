import SwiftUI
import UIKit

// =========================================================
// MARK: - TasksView (Habits-consistent theme + glass)
// =========================================================

struct TasksView: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @State private var iconPulse = false

    // Date state
    @State private var selectedDate: Date = Calendar.autoupdatingCurrent.startOfDay(for: Date())
    @State private var centeredDateID: Int? = nil
    @State private var scrollRequestID: Int? = nil

    // In-memory tasks (persistence later)
    @State private var tasks: [FFTaskItem] = []
    @State private var completedOccurrenceKeys: Set<String> = []
    @State private var createdPresetTaskIDs: Set<UUID> = []   // ensures convert-to-preset only happens once per task

    // Animation State
    @State private var confettiTaskID: UUID? = nil

    // Sheets
    @State private var showingEditorSheet = false
    @State private var showingJumpToDate = false
    @State private var taskToEdit: FFTaskItem? = nil

    init() {
        UITableViewCell.appearance().selectionStyle = .none
        UITableView.appearance().backgroundColor = .clear
        UITableView.appearance().tintColor = UIColor(white: 0.08, alpha: 1.0)
    }

    private var theme: AppTheme { appSettings.selectedTheme }
    private var cal: Calendar { .autoupdatingCurrent }
    private var day: Date { cal.startOfDay(for: selectedDate) }

    // MARK: - Derived UI

    private var monthYearLabel: String {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.setLocalizedDateFormatFromTemplate("MMMM, yyyy") // "December, 2025"
        return f.string(from: selectedDate)
    }

    private var visibleTasks: [FFTaskItem] {
        let d = day
        let filtered = tasks.filter { $0.occurs(on: d, calendar: cal) }

        return filtered.sorted { a, b in
            let aDone = isCompleted(a, on: d)
            let bDone = isCompleted(b, on: d)
            if aDone != bDone { return !aDone && bDone } // incomplete first

            if let ta = a.reminderDate, let tb = b.reminderDate { return ta < tb }
            if a.reminderDate != nil && b.reminderDate == nil { return true }
            if a.reminderDate == nil && b.reminderDate != nil { return false }

            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
    }

    private var hasTasksForSelectedDay: Bool { !visibleTasks.isEmpty }

    private var completedCount: Int {
        visibleTasks.filter { isCompleted($0, on: day) }.count
    }

    private var progress: Double {
        guard !visibleTasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(visibleTasks.count)
    }

    private var totalPlannedMinutes: Int {
        visibleTasks.reduce(0) { $0 + max(0, $1.durationMinutes) }
    }

    private var bannerSubtitle: String {
        if visibleTasks.isEmpty {
            return "No tasks yet • Tap Add to start"
        }
        let planned = totalPlannedMinutes > 0 ? " • \(formatMinutes(totalPlannedMinutes)) planned" : ""
        if progress >= 1.0 {
            return "\(completedCount)/\(visibleTasks.count) completed • All done"
        } else {
            return "\(completedCount)/\(visibleTasks.count) completed\(planned)"
        }
    }

    // =========================================================
    // MARK: - Body
    // =========================================================

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let accentPrimary = theme.accentPrimary
            let accentSecondary = theme.accentSecondary

            ZStack {
                // ✅ Match HabitsView background exactly
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

                VStack(spacing: 14) {
                    header
                        .padding(.horizontal, 22)
                        .padding(.top, 18)

                    // ✅ Ultra-thin banner hero (with ring)
                    summaryCard
                        .padding(.horizontal, 22)

                    // Month+Year left, Today + Calendar right
                    dateControls
                        .padding(.horizontal, 22)

                    // Date strip
                    GlassCard(cornerRadius: 22) {
                        InfiniteDateStrip(
                            selectedDate: $selectedDate,
                            centeredDateID: $centeredDateID,
                            scrollRequestID: $scrollRequestID,
                            accentPrimary: accentPrimary,
                            accentSecondary: accentSecondary,
                            hasIndicator: { date in
                                let d = cal.startOfDay(for: date)
                                return tasks.contains(where: { $0.showsIndicator(on: d, calendar: cal) })
                            }
                        )
                        .frame(height: 54)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    }
                    .padding(.horizontal, 22)

                    sectionHeader
                        .padding(.horizontal, 22)
                        .padding(.top, 2)

                    if visibleTasks.isEmpty {
                        emptyState
                            .padding(.horizontal, 22)
                            .padding(.top, 4)
                        Spacer(minLength: 0)
                    } else {
                        tasksList
                            .padding(.horizontal, 22)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .sheet(isPresented: $showingEditorSheet) { editorSheet }
        .sheet(isPresented: $showingJumpToDate) { jumpToDateSheet }
        .onAppear {
            let today = cal.startOfDay(for: Date())
            selectedDate = today
            let id = FFDateID(today).value
            centeredDateID = id
            scrollRequestID = id
            iconPulse = true
        }
    }

    // =========================================================
    // MARK: - Header (Reset like Habits)
    // =========================================================

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

                    Text("Tasks")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)

                    if hasTasksForSelectedDay {
                        statusChip
                    }
                }

                Text("Make today feel light.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()

            Button {
                simpleTap()
                withAnimation(.easeInOut(duration: 0.2)) {
                    resetCompletionsForSelectedDay()
                }
            } label: {
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

    private var statusChip: some View {
        let done = progress >= 1.0 && !visibleTasks.isEmpty
        return HStack(spacing: 5) {
            Circle()
                .fill(done ? theme.accentPrimary : Color.white.opacity(0.35))
                .frame(width: 8, height: 8)
            Text(done ? "All done" : "In progress")
                .font(.system(size: 10, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.white.opacity(0.15))
        .clipShape(Capsule())
        .foregroundColor(.white.opacity(0.9))
    }

    // =========================================================
    // MARK: - Banner hero (thin) + ring
    // =========================================================

    private var summaryCard: some View {
        GlassCard(cornerRadius: 22) {
            HStack(spacing: 12) {
                tasksMiniRing

                VStack(alignment: .leading, spacing: 2) {
                    Text("Tasks today")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))

                    Text(bannerSubtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.70))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Button {
                    prepareSheetForCreation()
                    simpleTap()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                        Text("Add").font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [theme.accentPrimary, theme.accentSecondary]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(radius: 10)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }

    private var tasksMiniRing: some View {
        let percentage = Int((progress * 100).rounded())
        let done = (progress >= 1.0 && !visibleTasks.isEmpty)

        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 6)

            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [theme.accentPrimary, theme.accentSecondary, theme.accentPrimary]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: progress)

            if visibleTasks.isEmpty {
                Text("--")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            } else if done {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Text("\(percentage)%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.95))
            }
        }
        .frame(width: 42, height: 42)
    }

    // =========================================================
    // MARK: - Date controls row
    // =========================================================

    private var dateControls: some View {
        HStack(spacing: 10) {
            Text(monthYearLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))

            Spacer()

            Button {
                Haptics.impact(.light)
                jumpToToday()
            } label: {
                Text("Today")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
                Haptics.impact(.light)
                showingJumpToDate = true
            } label: {
                Image(systemName: "calendar")
                    .imageScale(.medium)
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    // =========================================================
    // MARK: - Section header + List
    // =========================================================

    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tasks")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))
                Text("Tap to complete. Swipe to edit or delete.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            if !visibleTasks.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle").imageScale(.small)
                    Text("\(completedCount)/\(visibleTasks.count)")
                }
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.18))
                .clipShape(Capsule())
                .foregroundColor(.white.opacity(0.9))
            }
        }
    }

    private var tasksList: some View {
        List {
            ForEach(visibleTasks) { task in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                        toggleCompletion(task, on: day)
                    }
                } label: {
                    taskRow(task)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                .contentShape(Rectangle())
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) { delete(task: task) } label: { Image(systemName: "trash") }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button { prepareSheetForEditing(task) } label: { Image(systemName: "pencil") }
                        .tint(theme.accentPrimary)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }

    // ✅ Habits-style brighter glass rows
    private func taskRow(_ task: FFTaskItem) -> some View {
        let done = isCompleted(task, on: day)

        return HStack(spacing: 12) {
            ZStack {
                if done && confettiTaskID == task.id {
                    ConfettiBurst(color: theme.accentPrimary)
                }

                if done {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [theme.accentPrimary, theme.accentSecondary]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 30, height: 30)
                        .shadow(color: Color.white.opacity(0.25), radius: 5)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.45), lineWidth: 2)
                        .frame(width: 28, height: 28)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .foregroundColor(.white.opacity(done ? 0.65 : 1.0))
                    .font(.system(size: 16, weight: .regular))
                    .strikethrough(done, color: .white.opacity(0.35))
                    .lineLimit(2)

                let meta = taskMeta(task)
                if !meta.isEmpty {
                    Text(meta)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(done ? 0.20 : 0.14),
                            Color.white.opacity(done ? 0.10 : 0.07)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
        .scaleEffect(done ? 0.99 : 1.0)
    }

    private func taskMeta(_ task: FFTaskItem) -> String {
        var parts: [String] = []

        if let date = task.reminderDate {
            let f = DateFormatter()
            f.timeStyle = .short
            parts.append(f.string(from: date))
        }

        if task.durationMinutes > 0 {
            parts.append(formatMinutes(task.durationMinutes))
        }

        if task.repeatRule != .none {
            parts.append(task.repeatRule.displayName)
        }

        return parts.joined(separator: " • ")
    }

    // =========================================================
    // MARK: - Empty state
    // =========================================================

    private var emptyState: some View {
        GlassCard(cornerRadius: 22) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [theme.accentPrimary, theme.accentSecondary]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)

                    Image(systemName: "checklist")
                        .foregroundColor(.white)
                        .imageScale(.medium)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("No tasks here")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Tap Add to create one for this day.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
            }
            .padding(14)
        }
    }

    // =========================================================
    // MARK: - Sheets
    // =========================================================

    private var editorSheet: some View {
        TaskEditorSheet(
            theme: theme,
            selectedDay: day,
            taskToEdit: taskToEdit,
            onCancel: {
                showingEditorSheet = false
                taskToEdit = nil
            },
            onSave: { draft in
                upsertAndMaybeConvertToPreset(draft)
                showingEditorSheet = false
                taskToEdit = nil
            }
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var jumpToDateSheet: some View {
        JumpToDateSheet(
            theme: theme,
            initialDate: selectedDate,
            onDone: { picked in
                let d = cal.startOfDay(for: picked)
                selectedDate = d
                let id = FFDateID(d).value
                centeredDateID = id
                scrollRequestID = id
                showingJumpToDate = false
            },
            onCancel: { showingJumpToDate = false }
        )
        .presentationDetents([.fraction(0.62)])
        .presentationDragIndicator(.visible)
    }

    // =========================================================
    // MARK: - Actions / Logic
    // =========================================================

    private func simpleTap() {
        Haptics.impact(.light)
    }

    private func resetCompletionsForSelectedDay() {
        let comps = cal.dateComponents([.year, .month, .day], from: day)
        let suffix = "|\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
        completedOccurrenceKeys = Set(completedOccurrenceKeys.filter { !$0.hasSuffix(suffix) })
    }

    private func prepareSheetForCreation() {
        taskToEdit = nil
        showingEditorSheet = true
    }

    private func prepareSheetForEditing(_ task: FFTaskItem) {
        taskToEdit = task
        showingEditorSheet = true
        Haptics.impact(.light)
    }

    private func delete(task: FFTaskItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            tasks.removeAll { $0.id == task.id }
        }
        Haptics.impact(.light)
    }

    private func toggleCompletion(_ task: FFTaskItem, on day: Date) {
        let key = occurrenceKey(taskID: task.id, day: day)
        let wasDone = completedOccurrenceKeys.contains(key)

        if wasDone {
            Haptics.impact(.light)
            completedOccurrenceKeys.remove(key)
        } else {
            confettiTaskID = task.id
            Haptics.impact(.medium)

            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                completedOccurrenceKeys.insert(key)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.confettiTaskID == task.id {
                    self.confettiTaskID = nil
                }
            }
        }
    }

    private func isCompleted(_ task: FFTaskItem, on day: Date) -> Bool {
        completedOccurrenceKeys.contains(occurrenceKey(taskID: task.id, day: day))
    }

    private func occurrenceKey(taskID: UUID, day: Date) -> String {
        let comps = cal.dateComponents([.year, .month, .day], from: day)
        return "\(taskID.uuidString)|\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }

    private func jumpToToday() {
        let today = cal.startOfDay(for: Date())
        selectedDate = today
        let id = FFDateID(today).value
        centeredDateID = id
        scrollRequestID = id
    }

    private func upsertAndMaybeConvertToPreset(_ draft: FFTaskItem) {
        if let idx = tasks.firstIndex(where: { $0.id == draft.id }) {
            tasks[idx] = draft
        } else {
            tasks.insert(draft, at: 0)
        }

        guard draft.convertToPreset else { return }
        guard !createdPresetTaskIDs.contains(draft.id) else { return }
        createdPresetTaskIDs.insert(draft.id)

        let minutes = max(1, draft.durationMinutes)
        let soundID = appSettings.selectedFocusSound?.rawValue ?? FocusSound.lightRainAmbient.rawValue

        let preset = FocusPreset(
            name: draft.title,
            durationSeconds: FocusPreset.minutes(minutes),
            soundID: soundID,
            emoji: nil,
            isSystemDefault: false,
            themeRaw: nil,
            externalMusicAppRaw: nil
        )
        FocusPresetStore.shared.save(preset)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let m = max(0, minutes)
        let h = m / 60
        let r = m % 60
        if h > 0 && r > 0 { return "\(h)h \(r)m" }
        if h > 0 { return "\(h)h" }
        return "\(r)m"
    }
}

// =========================================================
// MARK: - GlassCard (static container)
// =========================================================

private struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 26
    let content: () -> Content

    var body: some View {
        content()
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

// =========================================================
// MARK: - InfiniteDateStrip
// =========================================================

private struct InfiniteDateStrip: View {
    @Binding var selectedDate: Date
    @Binding var centeredDateID: Int?
    @Binding var scrollRequestID: Int?

    let accentPrimary: Color
    let accentSecondary: Color
    let hasIndicator: (Date) -> Bool

    private let cal = Calendar.autoupdatingCurrent
    private let windowRadius: Int = 80
    private let preloadThreshold: Int = 18
    private let hardLimitDays: Int = 370

    @State private var dates: [Date] = []
    @State private var ignoreCenterChange = false
    @State private var debounceWork: DispatchWorkItem?

    var body: some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(dates, id: \.self) { date in
                        let id = FFDateID(date).value
                        CompactDatePill(
                            date: date,
                            isSelected: cal.isDate(date, inSameDayAs: selectedDate),
                            accentPrimary: accentPrimary,
                            accentSecondary: accentSecondary,
                            showsDot: hasIndicator(date)
                        ) {
                            Haptics.impact(.light)
                            let d = cal.startOfDay(for: date)
                            programmaticSelectAndCenter(d, reader: reader)
                        }
                        .id(id)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 6)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $centeredDateID, anchor: .center)
            .sensoryFeedback(.selection, trigger: centeredDateID)
            .onAppear {
                let today = cal.startOfDay(for: selectedDate)
                dates = makeWindow(around: today)
                let id = FFDateID(today).value
                centeredDateID = id
                DispatchQueue.main.async {
                    reader.scrollTo(id, anchor: .center)
                }
            }
            .onChange(of: scrollRequestID) { _, newID in
                guard let newID else { return }
                ignoreCenterChange = true
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    centeredDateID = newID
                    reader.scrollTo(newID, anchor: .center)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    ignoreCenterChange = false
                    scrollRequestID = nil
                }
            }
            .onChange(of: centeredDateID) { _, newID in
                guard !ignoreCenterChange else { return }
                guard let newID else { return }
                guard let newDate = dates.first(where: { FFDateID($0).value == newID }) else { return }

                debounceWork?.cancel()
                let work = DispatchWorkItem {
                    let normalized = cal.startOfDay(for: newDate)
                    paginateIfNeeded(around: normalized, reader: reader)
                }
                debounceWork = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.04, execute: work)
            }
            .onChange(of: selectedDate) { _, newValue in
                let d = cal.startOfDay(for: newValue)
                let id = FFDateID(d).value
                if !dates.contains(where: { cal.isDate($0, inSameDayAs: d) }) {
                    dates = makeWindow(around: d)
                }
                centeredDateID = id
                DispatchQueue.main.async {
                    ignoreCenterChange = true
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        reader.scrollTo(id, anchor: .center)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { ignoreCenterChange = false }
                }
            }
        }
    }

    private func programmaticSelectAndCenter(_ date: Date, reader: ScrollViewProxy) {
        let d = cal.startOfDay(for: date)
        let id = FFDateID(d).value

        if !dates.contains(where: { cal.isDate($0, inSameDayAs: d) }) {
            dates = makeWindow(around: d)
        }

        ignoreCenterChange = true
        selectedDate = d
        centeredDateID = id
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            reader.scrollTo(id, anchor: .center)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            ignoreCenterChange = false
        }
    }

    private func paginateIfNeeded(around center: Date, reader: ScrollViewProxy) {
        guard let idx = dates.firstIndex(where: { cal.isDate($0, inSameDayAs: center) }) else { return }
        if idx <= preloadThreshold || idx >= (dates.count - 1 - preloadThreshold) {
            let newDates = makeWindow(around: center)
            dates = newDates
            let id = FFDateID(center).value
            ignoreCenterChange = true
            centeredDateID = id
            DispatchQueue.main.async {
                reader.scrollTo(id, anchor: .center)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { ignoreCenterChange = false }
            }
        }
    }

    private func makeWindow(around center: Date) -> [Date] {
        let clampedRadius = min(windowRadius, hardLimitDays)
        return (-(clampedRadius)...clampedRadius).compactMap { offset in
            cal.date(byAdding: .day, value: offset, to: center).map { cal.startOfDay(for: $0) }
        }
    }
}

private struct CompactDatePill: View {
    let date: Date
    let isSelected: Bool
    let accentPrimary: Color
    let accentSecondary: Color
    let showsDot: Bool
    let action: () -> Void

    private var weekday: String {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.setLocalizedDateFormatFromTemplate("EEE")
        return f.string(from: date).uppercased()
    }

    private var dayNumber: String {
        "\(Calendar.autoupdatingCurrent.component(.day, from: date))"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(weekday)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .black.opacity(0.85) : .white.opacity(0.78))

                Text(dayNumber)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .black.opacity(0.92) : .white)

                if showsDot {
                    Circle()
                        .fill(isSelected ? Color.black.opacity(0.45) : Color.white.opacity(0.70))
                        .frame(width: 4, height: 4)
                        .padding(.top, 1)
                } else {
                    Spacer().frame(height: 5)
                }
            }
            .frame(width: 46, height: 54)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        isSelected
                        ? LinearGradient(gradient: Gradient(colors: [accentPrimary, accentSecondary]),
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.16), Color.white.opacity(0.07)]),
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(isSelected ? 0.0 : 0.14), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// =========================================================
// MARK: - Jump to Date Sheet (no Today button)
// =========================================================

private struct JumpToDateSheet: View {
    let theme: AppTheme
    let initialDate: Date

    @State private var tempDate: Date = Date()

    let onDone: (Date) -> Void
    let onCancel: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                LinearGradient(gradient: Gradient(colors: theme.backgroundColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                Circle().fill(theme.accentPrimary.opacity(0.45)).blur(radius: 100)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: -size.width * 0.45, y: -size.height * 0.55)

                Circle().fill(theme.accentSecondary.opacity(0.30)).blur(radius: 110)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: size.width * 0.45, y: size.height * 0.55)

                VStack(spacing: 16) {
                    HStack {
                        Button("Cancel") { onCancel() }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .buttonStyle(.plain)

                        Spacer()

                        Text("Select date")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        Button("Select") {
                            Haptics.impact(.light)
                            onDone(tempDate)
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [theme.accentPrimary, theme.accentSecondary]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(radius: 10)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)

                    DatePicker("", selection: $tempDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .tint(.white)
                        .colorScheme(.dark)
                        .padding(.horizontal, 18)

                    Spacer(minLength: 0)
                }
            }
        }
        .onAppear { tempDate = initialDate }
    }
}

// =========================================================
// MARK: - Task Editor Sheet
// =========================================================

private struct TaskEditorSheet: View {
    let theme: AppTheme
    let selectedDay: Date
    let taskToEdit: FFTaskItem?
    let onCancel: () -> Void
    let onSave: (FFTaskItem) -> Void

    @State private var title: String = ""
    @State private var notes: String = ""

    @State private var reminderDate: Date? = nil
    @State private var reminderTime: Date = Date()

    @State private var durationHours: Int = 0
    @State private var durationMinutesComponent: Int = 25

    @State private var repeatRule: FFTaskRepeatRule = .none
    @State private var customWeekdays: Set<Int> = []
    @State private var convertToPreset: Bool = false

    @State private var showingDatePickerSheet = false
    @State private var showingTimePickerSheet = false
    @State private var showingDurationPickerSheet = false
    @State private var showingRepeatPickerSheet = false
    @State private var showingCustomDaysSheet = false

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var sheetTitle: String { taskToEdit == nil ? "Add task" : "Edit task" }
    private var totalMinutes: Int { durationHours * 60 + durationMinutesComponent }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                LinearGradient(gradient: Gradient(colors: theme.backgroundColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                Circle().fill(theme.accentPrimary.opacity(0.5)).blur(radius: 90)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: -size.width * 0.45, y: -size.height * 0.55)

                Circle().fill(theme.accentSecondary.opacity(0.35)).blur(radius: 100)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: size.width * 0.45, y: size.height * 0.5)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerBar

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reminder style, just like Habits.")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Choose date, time, duration, repeat, and optional preset creation.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        GlassCard(cornerRadius: 28) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Task title")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))

                                TextField("e.g. Plan tomorrow", text: $title)
                                    .foregroundColor(.white)
                                    .tint(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.10))
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                                Text("Notes (optional)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.top, 4)

                                TextField("Add details…", text: $notes, axis: .vertical)
                                    .lineLimit(3, reservesSpace: true)
                                    .foregroundColor(.white)
                                    .tint(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.10))
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .padding(18)
                        }

                        GlassCard(cornerRadius: 28) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Reminders")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.85))
                                    .padding(.horizontal, 18)
                                    .padding(.top, 18)
                                    .padding(.bottom, 10)

                                Group {
                                    settingRow(title: "Date", value: formattedDate(reminderDate)) { showingDatePickerSheet = true }
                                    Divider().background(Color.white.opacity(0.18)).padding(.leading, 18)

                                    settingRow(title: "Time of day", value: formattedTime(reminderDate == nil ? nil : reminderTime)) { showingTimePickerSheet = true }
                                        .opacity(reminderDate == nil ? 0.45 : 1.0)
                                        .disabled(reminderDate == nil)

                                    Divider().background(Color.white.opacity(0.18)).padding(.leading, 18)
                                    settingRow(title: "Duration", value: formattedDuration()) { showingDurationPickerSheet = true }

                                    Divider().background(Color.white.opacity(0.18)).padding(.leading, 18)
                                    settingRow(title: "Repeat", value: repeatRule.displayName) { showingRepeatPickerSheet = true }

                                    if repeatRule == .customDays {
                                        Divider().background(Color.white.opacity(0.18)).padding(.leading, 18)
                                        settingRow(title: "Custom days", value: customDaysSummary()) { showingCustomDaysSheet = true }
                                    }
                                }

                                Text("Leave date/time blank if you want a flexible task that shows every day.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(18)
                            }
                        }

                        GlassCard(cornerRadius: 28) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Convert to Focus preset")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Creates ONE preset using title + duration.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                Spacer()
                                Toggle("", isOn: $convertToPreset).labelsHidden()
                            }
                            .padding(18)
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 18)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear { hydrate() }
        .sheet(isPresented: $showingDatePickerSheet) { datePickerSheet }
        .sheet(isPresented: $showingTimePickerSheet) { timePickerSheet }
        .sheet(isPresented: $showingDurationPickerSheet) { durationPickerSheet }
        .sheet(isPresented: $showingRepeatPickerSheet) { repeatPickerSheet }
        .sheet(isPresented: $showingCustomDaysSheet) { customDaysSheet }
    }

    private var headerBar: some View {
        HStack {
            Button { onCancel() } label: {
                Text("Cancel")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(sheetTitle)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Button {
                guard canSave else { return }
                onSave(buildDraft())
            } label: {
                Text("Save")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [theme.accentPrimary, theme.accentSecondary]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(radius: 12)
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
            .opacity(canSave ? 1.0 : 0.5)
        }
    }

    private func settingRow(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).font(.system(size: 15, weight: .medium)).foregroundColor(.white)
                Spacer()
                Text(value).font(.system(size: 15, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                Image(systemName: "chevron.right").imageScale(.small).foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var datePickerSheet: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: theme.backgroundColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer().frame(height: 30)
                Text("Pick a date").font(.title3.bold()).foregroundColor(.white)

                DatePicker(
                    "",
                    selection: Binding(
                        get: { reminderDate ?? selectedDay },
                        set: { reminderDate = Calendar.autoupdatingCurrent.startOfDay(for: $0) }
                    ),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(.white)
                .colorScheme(.dark)
                .padding(.horizontal, 22)

                HStack {
                    Button("Clear") {
                        reminderDate = nil
                        showingDatePickerSheet = false
                    }
                    .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Button("Done") { showingDatePickerSheet = false }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 30)

                Spacer(minLength: 24)
            }
        }
        .presentationDetents([.fraction(0.62)])
        .presentationDragIndicator(.visible)
    }

    private var timePickerSheet: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: theme.backgroundColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer().frame(height: 30)
                Text("Time of day").font(.title3.bold()).foregroundColor(.white)

                DatePicker("", selection: $reminderTime, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .tint(.white)
                    .colorScheme(.dark)
                    .padding(.horizontal, 22)

                HStack {
                    Button("Cancel") { showingTimePickerSheet = false }.foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Button("Done") { showingTimePickerSheet = false }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 30)

                Spacer(minLength: 24)
            }
        }
        .presentationDetents([.fraction(0.42)])
        .presentationDragIndicator(.visible)
    }

    private var durationPickerSheet: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: theme.backgroundColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer().frame(height: 30)
                Text("Duration").font(.title3.bold()).foregroundColor(.white)
                Text("Rough estimate is enough.").font(.system(size: 13)).foregroundColor(.white.opacity(0.7))

                HStack(spacing: 0) {
                    VStack {
                        Text("Hours").font(.headline).foregroundColor(.white.opacity(0.85))
                        Picker("Hours", selection: $durationHours) { ForEach(0..<13) { Text("\($0)").tag($0) } }
                            .pickerStyle(.wheel)
                    }
                    .frame(maxWidth: .infinity)
                    .clipped()

                    VStack {
                        Text("Minutes").font(.headline).foregroundColor(.white.opacity(0.85))
                        Picker("Minutes", selection: $durationMinutesComponent) {
                            ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) { m in
                                Text("\(m)").tag(m)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
                .colorScheme(.dark)
                .padding(.horizontal, 22)
                .frame(height: 160)

                HStack {
                    Button("Cancel") { showingDurationPickerSheet = false }.foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Button("Set length") { showingDurationPickerSheet = false }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 30)

                Spacer(minLength: 24)
            }
        }
        .presentationDetents([.fraction(0.48)])
        .presentationDragIndicator(.visible)
    }

    private var repeatPickerSheet: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: theme.backgroundColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer().frame(height: 30)
                Text("Repeat").font(.title3.bold()).foregroundColor(.white)

                Picker("Repeat", selection: $repeatRule) {
                    ForEach(FFTaskRepeatRule.allCases) { rule in
                        Text(rule.displayName).tag(rule)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .padding(.horizontal, 22)

                HStack {
                    Button("Cancel") { showingRepeatPickerSheet = false }.foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Button("Done") {
                        showingRepeatPickerSheet = false
                        if repeatRule != .customDays { customWeekdays = [] }
                        if repeatRule == .customDays && customWeekdays.isEmpty {
                            let w = Calendar.autoupdatingCurrent.component(.weekday, from: selectedDay)
                            customWeekdays.insert(w)
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                }
                .padding(.horizontal, 30)

                Spacer(minLength: 24)
            }
        }
        .presentationDetents([.fraction(0.42)])
        .presentationDragIndicator(.visible)
    }

    private var customDaysSheet: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: theme.backgroundColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Spacer().frame(height: 30)
                Text("Custom days").font(.title3.bold()).foregroundColor(.white)

                WeekdayChips(
                    selection: $customWeekdays,
                    accentPrimary: theme.accentPrimary,
                    accentSecondary: theme.accentSecondary
                )
                .padding(.horizontal, 18)

                HStack {
                    Button("Clear") { customWeekdays.removeAll() }.foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Button("Done") {
                        if customWeekdays.isEmpty {
                            let w = Calendar.autoupdatingCurrent.component(.weekday, from: selectedDay)
                            customWeekdays.insert(w)
                        }
                        showingCustomDaysSheet = false
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                }
                .padding(.horizontal, 30)

                Spacer(minLength: 24)
            }
        }
        .presentationDetents([.fraction(0.35)])
        .presentationDragIndicator(.visible)
    }

    private func hydrate() {
        if let t = taskToEdit {
            title = t.title
            notes = t.notes ?? ""
            reminderDate = t.reminderDate.map { Calendar.autoupdatingCurrent.startOfDay(for: $0) }
            reminderTime = t.reminderDate ?? Date()
            repeatRule = t.repeatRule
            customWeekdays = t.customWeekdays
            durationHours = max(0, t.durationMinutes) / 60
            durationMinutesComponent = max(0, t.durationMinutes) % 60
            convertToPreset = t.convertToPreset
            return
        }

        title = ""
        notes = ""
        reminderDate = selectedDay
        reminderTime = Date()
        durationHours = 0
        durationMinutesComponent = 25
        repeatRule = .none
        customWeekdays = []
        convertToPreset = false
    }

    private func buildDraft() -> FFTaskItem {
        let cal = Calendar.autoupdatingCurrent

        var mergedReminder: Date? = nil
        if let d = reminderDate {
            let dateParts = cal.dateComponents([.year, .month, .day], from: d)
            let timeParts = cal.dateComponents([.hour, .minute], from: reminderTime)
            var merged = DateComponents()
            merged.year = dateParts.year
            merged.month = dateParts.month
            merged.day = dateParts.day
            merged.hour = timeParts.hour
            merged.minute = timeParts.minute
            mergedReminder = cal.date(from: merged)
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNotes = trimmedNotes.isEmpty ? nil : trimmedNotes

        return FFTaskItem(
            id: taskToEdit?.id ?? UUID(),
            title: trimmedTitle,
            notes: finalNotes,
            reminderDate: mergedReminder,
            repeatRule: repeatRule,
            customWeekdays: customWeekdays,
            durationMinutes: max(0, totalMinutes),
            convertToPreset: convertToPreset,
            createdAt: taskToEdit?.createdAt ?? selectedDay
        )
    }

    private func formattedDate(_ d: Date?) -> String {
        guard let d else { return "None" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: d)
    }

    private func formattedTime(_ d: Date?) -> String {
        guard let d else { return "None" }
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: d)
    }

    private func formattedDuration() -> String {
        if totalMinutes == 0 { return "None" }
        let h = durationHours
        let m = durationMinutesComponent
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    private func customDaysSummary() -> String {
        if customWeekdays.isEmpty { return "Select" }
        if customWeekdays.count == 7 { return "Every day" }
        return "\(customWeekdays.count) days"
    }
}

private struct WeekdayChips: View {
    @Binding var selection: Set<Int>
    let accentPrimary: Color
    let accentSecondary: Color

    private let cal = Calendar.autoupdatingCurrent

    var body: some View {
        let symbols = cal.shortWeekdaySymbols

        HStack(spacing: 10) {
            ForEach(0..<7, id: \.self) { idx in
                let weekday = idx + 1
                let selected = selection.contains(weekday)

                Text(String(symbols[idx].prefix(1)).uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 36, height: 36)
                    .foregroundColor(selected ? .black : .white)
                    .background {
                        if selected {
                            LinearGradient(
                                gradient: Gradient(colors: [accentPrimary, accentSecondary]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color.white.opacity(0.12)
                        }
                    }
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(selected ? 0.0 : 0.14), lineWidth: 1))
                    .onTapGesture {
                        Haptics.impact(.light)
                        if selected { selection.remove(weekday) } else { selection.insert(weekday) }
                    }
            }
        }
        .padding(.vertical, 8)
    }
}

// =========================================================
// MARK: - Particle / Confetti Effects
// =========================================================

struct ParticleEffect: GeometryEffect {
    var time: Double
    var speed: Double = Double.random(in: 20...100)
    var direction: Double = Double.random(in: -Double.pi...Double.pi)

    var animatableData: Double {
        get { time }
        set { time = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let xTranslation = speed * cos(direction) * time
        let yTranslation = speed * sin(direction) * time
        let affineTranslation = CGAffineTransform(translationX: xTranslation, y: yTranslation)
        let transform = CGAffineTransform(rotationAngle: CGFloat(time * speed * 0.1))
        return ProjectionTransform(transform.concatenating(affineTranslation))
    }
}

struct ConfettiBurst: View {
    @State private var time: Double = 0.0
    let color: Color

    var body: some View {
        ZStack {
            ForEach(0..<12) { _ in
                Circle()
                    .fill(color)
                    .frame(width: 4, height: 4)
                    .modifier(ParticleEffect(time: time))
                    .opacity(1 - time)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                time = 1.5
            }
        }
    }
}

// =========================================================
// MARK: - Models
// =========================================================

fileprivate struct FFTaskItem: Identifiable, Equatable {
    let id: UUID
    var title: String
    var notes: String?
    var reminderDate: Date?
    var repeatRule: FFTaskRepeatRule
    var customWeekdays: Set<Int>
    var durationMinutes: Int
    var convertToPreset: Bool
    var createdAt: Date

    func occurs(on day: Date, calendar: Calendar) -> Bool {
        let target = calendar.startOfDay(for: day)
        let anchor = calendar.startOfDay(for: reminderDate ?? createdAt)

        if repeatRule != .none, target < anchor { return false }

        switch repeatRule {
        case .none:
            guard reminderDate != nil else { return true }
            return calendar.isDate(target, inSameDayAs: anchor)

        case .daily:
            return target >= anchor

        case .weekly:
            return calendar.component(.weekday, from: target) == calendar.component(.weekday, from: anchor) && target >= anchor

        case .monthly:
            return calendar.component(.day, from: target) == calendar.component(.day, from: anchor) && target >= anchor

        case .yearly:
            return calendar.component(.month, from: target) == calendar.component(.month, from: anchor)
                && calendar.component(.day, from: target) == calendar.component(.day, from: anchor)
                && target >= anchor

        case .customDays:
            return customWeekdays.contains(calendar.component(.weekday, from: target)) && target >= anchor
        }
    }

    func showsIndicator(on day: Date, calendar: Calendar) -> Bool {
        if reminderDate == nil && repeatRule == .none { return false }
        return occurs(on: day, calendar: calendar)
    }
}

fileprivate enum FFTaskRepeatRule: String, CaseIterable, Identifiable {
    case none, daily, weekly, monthly, yearly, customDays
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "No repeat"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .customDays: return "Custom"
        }
    }
}

fileprivate struct FFDateID: Hashable {
    let value: Int
    init(_ date: Date) {
        let c = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day], from: date)
        self.value = (c.year! * 10000) + (c.month! * 100) + c.day!
    }
}

#Preview {
    TasksView()
}
