import SwiftUI
import UIKit
import UniformTypeIdentifiers

// =========================================================
// MARK: - TasksView (Premium Dark Theme)
// =========================================================

struct TasksView: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var vm = TasksStore.shared
    
    @State private var selectedDate: Date = Calendar.autoupdatingCurrent.startOfDay(for: Date())
    @State private var centeredDateID: Int? = nil
    @State private var scrollRequestID: Int? = nil
    
    @State private var pendingDeleteTask: FFTaskItem? = nil
    @State private var showDeleteAlert: Bool = false
    @State private var confettiTaskID: UUID? = nil
    
    @State private var editorMode: TaskEditorMode? = nil
    @State private var showingJumpToDate = false
    @State private var showingQuickAdd = false
    @State private var showingInfoSheet = false
    
    private var theme: AppTheme { appSettings.profileTheme }
    private var cal: Calendar { .autoupdatingCurrent }
    private var day: Date { cal.startOfDay(for: selectedDate) }
    
    // MARK: - Computed Properties
    
    private var visibleTasks: [FFTaskItem] {
        let base = vm.orderedTasks().filter { $0.occurs(on: day, calendar: cal) }
        let incomplete = base.filter { !isCompleted($0, on: day) }
        let complete = base.filter { isCompleted($0, on: day) }
        return incomplete + complete
    }
    
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
    
    private var remainingMinutes: Int {
        visibleTasks
            .filter { !isCompleted($0, on: day) }
            .reduce(0) { $0 + max(0, $1.durationMinutes) }
    }
    
    private var monthYearLabel: String {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return f.string(from: selectedDate)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            PremiumAppBackground(theme: theme, particleCount: 12)
            
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Date Navigator
                        dateNavigator
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        
                        // Date Strip
                        dateStrip
                            .padding(.horizontal, 20)
                        
                        // Summary Card
                        summaryCard
                            .padding(.horizontal, 20)
                        
                        // Quick Stats
                        if !visibleTasks.isEmpty {
                            quickStats
                                .padding(.horizontal, 20)
                        }
                        
                        // Tasks Section
                        tasksSection
                            .padding(.horizontal, 20)
                        
                        Spacer(minLength: 120)
                    }
                }
            }
            
            // Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    floatingAddButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }
            }
            .ignoresSafeArea(.keyboard)
        }
        .alert("Delete task?", isPresented: $showDeleteAlert, presenting: pendingDeleteTask) { task in
            if task.repeatRule != .none {
                Button("Delete this day", role: .destructive) {
                    vm.deleteOccurrence(taskID: task.id, on: day, calendar: cal)
                    pendingDeleteTask = nil
                }
                Button("Delete series", role: .destructive) {
                    vm.delete(taskID: task.id)
                    pendingDeleteTask = nil
                }
            } else {
                Button("Delete", role: .destructive) {
                    vm.delete(taskID: task.id)
                    pendingDeleteTask = nil
                }
            }
            Button("Cancel", role: .cancel) { pendingDeleteTask = nil }
        } message: { task in
            Text(task.repeatRule != .none
                 ? "Delete only this occurrence or the entire series?"
                 : "This action cannot be undone.")
        }
        .sheet(item: $editorMode) { mode in
            TaskEditorSheet(
                theme: theme,
                selectedDay: day,
                taskToEdit: mode.task,
                onCancel: { editorMode = nil },
                onSave: { draft in
                    upsertTask(draft)
                    editorMode = nil
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(red: 0.08, green: 0.08, blue: 0.10))
        }
        .sheet(isPresented: $showingJumpToDate) {
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
            .presentationDetents([.fraction(0.65), .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(red: 0.08, green: 0.08, blue: 0.10))
        }
        .sheet(isPresented: $showingQuickAdd) {
            QuickAddSheet(theme: theme, selectedDay: day) { title, duration in
                let task = FFTaskItem(
                    id: UUID(),
                    sortIndex: vm.orderedTasks().count,
                    title: title,
                    notes: nil,
                    reminderDate: nil, // ✅ Quick add tasks have no reminder
                    repeatRule: .none, // ✅ Quick add tasks have no repeat
                    customWeekdays: [],
                    durationMinutes: duration,
                    convertToPreset: false,
                    presetCreated: false,
                    createdAt: Date()
                )
                vm.upsert(task)
                showingQuickAdd = false
            }
            .presentationDetents([.fraction(0.4), .medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingInfoSheet) {
            TasksInfoSheet(theme: theme)
        }
        .onAppear {
            let today = cal.startOfDay(for: Date())
            selectedDate = today
            let id = FFDateID(today).value
            centeredDateID = id
            scrollRequestID = id
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image("Focusflow_Logo")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Text("Tasks")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Info button
            Button {
                Haptics.impact(.light)
                showingInfoSheet = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            
            // Reset button
            if completedCount > 0 {
                Button {
                    Haptics.impact(.medium)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        vm.resetCompletions(for: day, calendar: cal)
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
    }
    
    // MARK: - Date Navigator
    
    private var dateNavigator: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.impact(.light)
                showingJumpToDate = true
            } label: {
                HStack(spacing: 6) {
                    Text(monthYearLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            
            Spacer()
            
            // Today button
            if !cal.isDateInToday(selectedDate) {
                Button {
                    Haptics.impact(.medium)
                    jumpToToday()
                } label: {
                    Text("Today")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.accentPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.accentPrimary.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Date Strip
    
    private var dateStrip: some View {
        InfiniteDateStrip(
            selectedDate: $selectedDate,
            centeredDateID: $centeredDateID,
            scrollRequestID: $scrollRequestID,
            theme: theme,
            hasIndicator: { date in
                let d = cal.startOfDay(for: date)
                return vm.orderedTasks().contains { $0.showsIndicator(on: d, calendar: cal) }
            }
        )
        .frame(height: 72)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    // MARK: - Summary Card
    
    private var summaryCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 8)
                        .frame(width: 56, height: 56)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                    
                    if visibleTasks.isEmpty {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                    } else if progress >= 1.0 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if visibleTasks.isEmpty {
                        Text("No tasks for today")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Tap + to add your first task")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    } else {
                        Text("\(completedCount) of \(visibleTasks.count) completed")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if progress >= 1.0 {
                            Text("All done! Great work 🎉")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.green)
                        } else if remainingMinutes > 0 {
                            Text("\(formatMinutes(remainingMinutes)) remaining")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
        }
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    // MARK: - Quick Stats
    
    private var quickStats: some View {
        HStack(spacing: 12) {
            quickStatItem(
                icon: "clock.fill",
                value: formatMinutes(totalPlannedMinutes),
                label: "Planned",
                color: .blue
            )
            
            quickStatItem(
                icon: "checkmark.circle.fill",
                value: "\(completedCount)",
                label: "Done",
                color: .green
            )
            
            quickStatItem(
                icon: "list.bullet",
                value: "\(visibleTasks.count - completedCount)",
                label: "Remaining",
                color: .orange
            )
        }
    }
    
    private func quickStatItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    // MARK: - Tasks Section
    
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text("TASKS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
                
                Spacer()
                
                if !visibleTasks.isEmpty {
                    Button {
                        Haptics.impact(.light)
                        showingQuickAdd = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                            Text("Quick Add")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(theme.accentPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(theme.accentPrimary.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
            }
            
            if visibleTasks.isEmpty {
                emptyState
            } else {
                // Tasks List with native swipe actions
                tasksList
            }
        }
    }
    
    private var tasksList: some View {
        List {
            ForEach(visibleTasks) { task in
                Button {
                    toggleCompletion(task, on: day)
                } label: {
                    taskRow(task)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Haptics.impact(.medium)
                        pendingDeleteTask = task
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        Haptics.impact(.light)
                        editorMode = TaskEditorMode(id: task.id, task: task)
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .tint(theme.accentPrimary)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .frame(minHeight: CGFloat(visibleTasks.count) * 76)
    }
    
    private func taskRow(_ task: FFTaskItem) -> some View {
        let done = isCompleted(task, on: day)
        
        return HStack(spacing: 14) {
            // Checkbox
            ZStack {
                if done && confettiTaskID == task.id {
                    ConfettiBurst(color: theme.accentPrimary)
                }
                
                if done {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 2)
                        .frame(width: 28, height: 28)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(done ? .white.opacity(0.5) : .white)
                    .strikethrough(done, color: .white.opacity(0.3))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                let meta = taskMeta(task)
                if !meta.isEmpty {
                    Text(meta)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            
            Spacer()
            
            // Duration badge
            if task.durationMinutes > 0 {
                Text(formatMinutes(task.durationMinutes))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(done ? 0.03 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.accentPrimary.opacity(0.15))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "checklist")
                    .font(.system(size: 28))
                    .foregroundColor(theme.accentPrimary)
            }
            
            VStack(spacing: 6) {
                Text("No tasks yet")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Add a task to get started with your day")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            
            Button {
                Haptics.impact(.light)
                editorMode = TaskEditorMode(id: UUID(), task: nil)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Add Task")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private func taskMeta(_ task: FFTaskItem) -> String {
        var parts: [String] = []
        
        if let date = task.reminderDate {
            let f = DateFormatter()
            f.timeStyle = .short
            parts.append(f.string(from: date))
        }
        
        if task.repeatRule != .none {
            parts.append(formatRepeatRule(task.repeatRule, customWeekdays: task.customWeekdays))
        }
        
        return parts.joined(separator: " • ")
    }
    
    /// Formats the repeat rule for display, showing actual days for custom
    private func formatRepeatRule(_ rule: FFTaskRepeatRule, customWeekdays: Set<Int>) -> String {
        if rule == .customDays && !customWeekdays.isEmpty {
            let dayAbbreviations = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let sortedDays = customWeekdays.sorted()
            
            // Check for common patterns
            let weekdays = Set([1, 2, 3, 4, 5]) // Mon-Fri
            let weekends = Set([0, 6]) // Sat, Sun
            
            if customWeekdays == weekdays {
                return "Weekdays"
            } else if customWeekdays == weekends {
                return "Weekends"
            } else if customWeekdays.count == 7 {
                return "Every day"
            } else {
                // Show individual days
                let dayNames = sortedDays.map { dayAbbreviations[$0] }
                return dayNames.joined(separator: ", ")
            }
        }
        return rule.displayName
    }
    
    // MARK: - Floating Add Button
    
    private var floatingAddButton: some View {
        Button {
            Haptics.impact(.medium)
            editorMode = TaskEditorMode(id: UUID(), task: nil)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: theme.accentPrimary.opacity(0.4), radius: 12, y: 6)
        }
    }
    
    // MARK: - Actions
    
    private func toggleCompletion(_ task: FFTaskItem, on day: Date) {
        let wasDone = vm.isCompleted(taskId: task.id, on: day, calendar: cal)
        
        if wasDone {
            Haptics.impact(.light)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                vm.toggleCompletion(taskID: task.id, on: day, calendar: cal)
            }
        } else {
            confettiTaskID = task.id
            Haptics.impact(.medium)
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                vm.toggleCompletion(taskID: task.id, on: day, calendar: cal)
            }
            
            // ✅ Sync with entire app - updates Progress, Profile, XP, Badges
            AppSyncManager.shared.taskDidComplete(
                taskId: task.id,
                taskTitle: task.title,
                on: day
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if confettiTaskID == task.id { confettiTaskID = nil }
            }
        }
    }
    
    private func isCompleted(_ task: FFTaskItem, on day: Date) -> Bool {
        vm.isCompleted(taskId: task.id, on: day, calendar: cal)
    }
    
    private func jumpToToday() {
        let today = cal.startOfDay(for: Date())
        selectedDate = today
        let id = FFDateID(today).value
        centeredDateID = id
        scrollRequestID = id
    }
    
    private func upsertTask(_ draft: FFTaskItem) {
        vm.upsert(draft)
        
        guard draft.convertToPreset, !draft.presetCreated else { return }
        
        let minutes = max(1, draft.durationMinutes)
        // ✅ Presets created from tasks should always have no sound by default
        // User can modify the preset later to add sound if desired
        let soundID = "" // Empty string = no sound
        
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
        vm.markPresetCreated(taskID: draft.id)
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

// MARK: - Task Editor Mode

private struct TaskEditorMode: Identifiable {
    let id: UUID
    let task: FFTaskItem?
}

// MARK: - Confetti Burst

private struct ParticleEffect: GeometryEffect {
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

private struct ConfettiBurst: View {
    @State private var time: Double = 0.0
    let color: Color
    
    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { _ in
                Circle()
                    .fill(color)
                    .frame(width: 4, height: 4)
                    .modifier(ParticleEffect(time: time))
                    .opacity(1 - time)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { time = 1.5 }
        }
    }
}

// =========================================================
// MARK: - Infinite Date Strip
// =========================================================

private struct InfiniteDateStrip: View {
    @Binding var selectedDate: Date
    @Binding var centeredDateID: Int?
    @Binding var scrollRequestID: Int?
    
    let theme: AppTheme
    let hasIndicator: (Date) -> Bool
    
    private let cal = Calendar.autoupdatingCurrent
    private let windowRadius: Int = 80
    private let preloadThreshold: Int = 18
    
    @State private var dates: [Date] = []
    @State private var ignoreCenterChange = false
    @State private var debounceWork: DispatchWorkItem?
    
    var body: some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(dates, id: \.self) { date in
                        let id = FFDateID(date).value
                        DatePill(
                            date: date,
                            isSelected: cal.isDate(date, inSameDayAs: selectedDate),
                            isToday: cal.isDateInToday(date),
                            theme: theme,
                            showsDot: hasIndicator(date)
                        ) {
                            Haptics.impact(.light)
                            programmaticSelectAndCenter(cal.startOfDay(for: date), reader: reader)
                        }
                        .id(id)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 12)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $centeredDateID, anchor: .center)
            .onAppear {
                let today = cal.startOfDay(for: selectedDate)
                dates = makeWindow(around: today)
                let id = FFDateID(today).value
                centeredDateID = id
                DispatchQueue.main.async { reader.scrollTo(id, anchor: .center) }
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
                guard !ignoreCenterChange, let newID else { return }
                guard let newDate = dates.first(where: { FFDateID($0).value == newID }) else { return }
                
                debounceWork?.cancel()
                let work = DispatchWorkItem {
                    paginateIfNeeded(around: cal.startOfDay(for: newDate), reader: reader)
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
        (-windowRadius...windowRadius).compactMap { offset in
            cal.date(byAdding: .day, value: offset, to: center).map { cal.startOfDay(for: $0) }
        }
    }
}

private struct DatePill: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let theme: AppTheme
    let showsDot: Bool
    let action: () -> Void
    
    private var weekday: String {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.setLocalizedDateFormatFromTemplate("EEE")
        return String(f.string(from: date).prefix(3)).uppercased()
    }
    
    private var dayNumber: String {
        "\(Calendar.autoupdatingCurrent.component(.day, from: date))"
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(weekday)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isSelected ? .black.opacity(0.7) : .white.opacity(0.5))
                
                Text(dayNumber)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .black : .white)
                
                if showsDot {
                    Circle()
                        .fill(isSelected ? Color.black.opacity(0.4) : theme.accentPrimary)
                        .frame(width: 5, height: 5)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(width: 48, height: 64)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else if isToday {
                        Color.white.opacity(0.08)
                    } else {
                        Color.clear
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isToday && !isSelected ? theme.accentPrimary.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// =========================================================
// MARK: - Quick Add Sheet
// =========================================================

private struct QuickAddSheet: View {
    let theme: AppTheme
    let selectedDay: Date
    let onSave: (String, Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var selectedDuration: Int = 25
    
    private let durations = [15, 25, 30, 45, 60, 90]
    
    var body: some View {
        ZStack {
            PremiumAppBackground(theme: theme, showParticles: false)
            
            VStack(spacing: 20) {
                // Header
                Text("Quick Add Task")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 28)
                
                // Title field
                TextField("What needs to be done?", text: $title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(16)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                
                // Duration chips
                VStack(alignment: .leading, spacing: 10) {
                    Text("DURATION")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)
                        .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(durations, id: \.self) { mins in
                                Button {
                                    Haptics.impact(.light)
                                    selectedDuration = mins
                                } label: {
                                    Text(mins >= 60 ? "\(mins/60)h\(mins % 60 > 0 ? " \(mins % 60)m" : "")" : "\(mins)m")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(selectedDuration == mins ? .black : .white)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 12)
                                        .background(
                                            selectedDuration == mins
                                                ? AnyShapeStyle(LinearGradient(colors: [theme.accentPrimary, theme.accentSecondary], startPoint: .leading, endPoint: .trailing))
                                                : AnyShapeStyle(Color.white.opacity(0.06))
                                        )
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer()
                
                // Buttons
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    Button {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        Haptics.impact(.medium)
                        onSave(title.trimmingCharacters(in: .whitespaces), selectedDuration)
                    } label: {
                        Text("Add Task")
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
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }
}

// =========================================================
// MARK: - Jump To Date Sheet
// =========================================================

private struct JumpToDateSheet: View {
    let theme: AppTheme
    let initialDate: Date
    let onDone: (Date) -> Void
    let onCancel: () -> Void
    
    @State private var tempDate: Date = Date()
    
    var body: some View {
        ZStack {
            PremiumAppBackground(theme: theme, showParticles: false)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Jump to Date")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("Select any day")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    Button {
                        Haptics.impact(.light)
                        tempDate = Date()
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
                
                DatePicker("", selection: $tempDate, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .tint(theme.accentPrimary)
                    .padding(.horizontal, 8)
                
                Spacer()
                
                Button {
                    Haptics.impact(.medium)
                    onDone(tempDate)
                } label: {
                    Text("Go to Date")
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
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .colorScheme(.dark)
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
    @State private var remindersEnabled: Bool = true
    @State private var reminderDate: Date? = nil
    @State private var reminderTime: Date = Date()
    @State private var durationHours: Int = 0
    @State private var durationMinutes: Int = 25
    @State private var repeatRule: FFTaskRepeatRule = .none
    @State private var customWeekdays: Set<Int> = []
    @State private var convertToPreset: Bool = false
    
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    @State private var showDurationPicker = false
    @State private var showRepeatPicker = false
    @State private var showCustomDays = false
    
    private var canSave: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var sheetTitle: String { taskToEdit == nil ? "New Task" : "Edit Task" }
    private var totalMinutes: Int { durationHours * 60 + durationMinutes }
    
    /// Returns a user-friendly display value for the repeat setting
    private var repeatDisplayValue: String {
        if repeatRule == .customDays && !customWeekdays.isEmpty {
            // Show abbreviated day names for selected days
            let dayAbbreviations = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let sortedDays = customWeekdays.sorted()
            
            // Check for common patterns
            let weekdays = Set([1, 2, 3, 4, 5]) // Mon-Fri
            let weekends = Set([0, 6]) // Sat, Sun
            
            if customWeekdays == weekdays {
                return "Weekdays"
            } else if customWeekdays == weekends {
                return "Weekends"
            } else if customWeekdays.count == 7 {
                return "Every day"
            } else {
                // Show individual days
                let dayNames = sortedDays.map { dayAbbreviations[$0] }
                return dayNames.joined(separator: ", ")
            }
        }
        return repeatRule.displayName
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                PremiumAppBackground(theme: theme, showParticles: false)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Title Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TITLE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1)
                            
                            TextField("What needs to be done?", text: $title)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)
                        
                        // Notes Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTES")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1)
                            
                            TextField("Add details...", text: $notes, axis: .vertical)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .lineLimit(3...6)
                                .padding(14)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)
                        
                        // Schedule Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SCHEDULE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 0) {
                                // Reminders toggle
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Reminders")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("Get notified")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                    Spacer()
                                    Toggle("", isOn: $remindersEnabled)
                                        .labelsHidden()
                                }
                                .padding(16)
                                
                                if remindersEnabled {
                                    Divider().background(Color.white.opacity(0.06)).padding(.leading, 16)
                                    
                                    // Date
                                    settingRow(title: "Date", value: formatDate(reminderDate)) {
                                        showDatePicker = true
                                    }
                                    
                                    Divider().background(Color.white.opacity(0.06)).padding(.leading, 16)
                                    
                                    // Time
                                    settingRow(title: "Time", value: formatTime(reminderTime)) {
                                        showTimePicker = true
                                    }
                                    .opacity(reminderDate != nil ? 1 : 0.4)
                                    .disabled(reminderDate == nil)
                                    
                                    Divider().background(Color.white.opacity(0.06)).padding(.leading, 16)
                                    
                                    // Repeat
                                    settingRow(title: "Repeat", value: repeatDisplayValue) {
                                        showRepeatPicker = true
                                    }
                                    .opacity(reminderDate != nil ? 1 : 0.4)
                                    .disabled(reminderDate == nil)
                                }
                                
                                Divider().background(Color.white.opacity(0.06)).padding(.leading, 16)
                                
                                // Duration
                                settingRow(title: "Duration", value: formatDuration()) {
                                    showDurationPicker = true
                                }
                            }
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)
                        }
                        
                        // Focus Preset Toggle
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Create Focus Preset")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("Auto-create a focus session")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                Spacer()
                                Toggle("", isOn: $convertToPreset)
                                    .labelsHidden()
                            }
                            .padding(16)
                        }
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard canSave else { return }
                        Haptics.impact(.medium)
                        onSave(buildDraft())
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(canSave ? theme.accentPrimary : .white.opacity(0.3))
                    .disabled(!canSave)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onAppear { hydrate() }
        .onChange(of: remindersEnabled) { _, enabled in
            if enabled && reminderDate == nil {
                reminderDate = selectedDay
            }
            if !enabled {
                repeatRule = .none
                customWeekdays = []
            }
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
        .sheet(isPresented: $showTimePicker) {
            timePickerSheet
        }
        .sheet(isPresented: $showDurationPicker) {
            durationPickerSheet
        }
        .sheet(isPresented: $showRepeatPicker) {
            repeatPickerSheet
        }
    }
    
    private func settingRow(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
        }
    }
    
    // MARK: - Picker Sheets
    
    private var datePickerSheet: some View {
        ZStack {
            PremiumAppBackground(theme: theme, showParticles: false)
            
            VStack(spacing: 14) {
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 44, height: 4)
                    .padding(.top, 10)
                
                Text("Select Date")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text("When is this task due?")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                
                DatePicker("", selection: Binding(
                    get: { reminderDate ?? selectedDay },
                    set: { reminderDate = Calendar.autoupdatingCurrent.startOfDay(for: $0) }
                ), displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .tint(theme.accentPrimary)
                    .colorScheme(.dark)
                    .padding(.horizontal, 12)
                
                HStack(spacing: 12) {
                    Button {
                        showDatePicker = false
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }
                    
                    Button {
                        showDatePicker = false
                    } label: {
                        Text("Set")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                
                Spacer(minLength: 6)
            }
            .padding(.bottom, 14)
        }
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
        .presentationDetents([.fraction(0.75), .large])
    }
    
    private var timePickerSheet: some View {
        ZStack {
            PremiumAppBackground(theme: theme, showParticles: false)
            
            VStack(spacing: 14) {
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 44, height: 4)
                    .padding(.top, 10)
                
                Text("Select Time")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text("When should this task remind you?")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                
                DatePicker("", selection: $reminderTime, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 170)
                    .colorScheme(.dark)
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                
                HStack(spacing: 12) {
                    Button {
                        showTimePicker = false
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }
                    
                    Button {
                        showTimePicker = false
                    } label: {
                        Text("Set")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                
                Spacer(minLength: 6)
            }
            .padding(.bottom, 14)
        }
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
        .presentationDetents([.fraction(0.52), .medium, .large])
    }
    
    private var durationPickerSheet: some View {
        ZStack {
            PremiumAppBackground(theme: theme, showParticles: false)
            
            VStack(spacing: 14) {
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 44, height: 4)
                    .padding(.top, 10)
                
                Text("Duration")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text("How long will this task take?")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                
                HStack(spacing: 0) {
                    VStack(spacing: 6) {
                        Text("Hours")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))
                        
                        Picker("Hours", selection: $durationHours) {
                            ForEach(0..<13, id: \.self) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .background(Color.white.opacity(0.10))
                        .padding(.vertical, 10)
                    
                    VStack(spacing: 6) {
                        Text("Minutes")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))
                        
                        Picker("Minutes", selection: $durationMinutes) {
                            ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) { min in
                                Text(String(format: "%02d", min)).tag(min)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 170)
                .colorScheme(.dark)
                .padding(.horizontal, 18)
                .padding(.top, 8)
                
                HStack(spacing: 12) {
                    Button {
                        showDurationPicker = false
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }
                    
                    Button {
                        showDurationPicker = false
                    } label: {
                        Text("Set")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                
                Spacer(minLength: 6)
            }
            .padding(.bottom, 14)
        }
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
        .presentationDetents([.fraction(0.52), .medium, .large])
    }
    
    private var repeatPickerSheet: some View {
        ZStack {
            PremiumAppBackground(theme: theme, showParticles: false)
            
            VStack(spacing: 14) {
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 44, height: 4)
                    .padding(.top, 10)
                
                Text("Repeat")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text("How often should this task repeat?")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                
                Picker("Repeat", selection: $repeatRule) {
                    ForEach(FFTaskRepeatRule.allCases) { rule in
                        Text(rule.displayName).tag(rule)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 170)
                .colorScheme(.dark)
                .padding(.horizontal, 18)
                .padding(.top, 8)
                
                // Show custom days selector when customDays is selected
                if repeatRule == .customDays {
                    VStack(spacing: 12) {
                        Text("SELECT DAYS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1)
                        
                        HStack(spacing: 8) {
                            ForEach(0..<7, id: \.self) { dayIndex in
                                let dayNames = ["S", "M", "T", "W", "T", "F", "S"]
                                let isSelected = customWeekdays.contains(dayIndex)
                                
                                Button {
                                    Haptics.impact(.light)
                                    if isSelected {
                                        customWeekdays.remove(dayIndex)
                                    } else {
                                        customWeekdays.insert(dayIndex)
                                    }
                                } label: {
                                    Text(dayNames[dayIndex])
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                                        .frame(width: 40, height: 40)
                                        .background(
                                            isSelected
                                                ? LinearGradient(colors: [theme.accentPrimary, theme.accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
                                                : LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(isSelected ? 0 : 0.1), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        if customWeekdays.isEmpty {
                            Text("Select at least one day")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.orange.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                }
                
                HStack(spacing: 12) {
                    Button {
                        showRepeatPicker = false
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }
                    
                    Button {
                        // Validate custom days selection
                        if repeatRule == .customDays && customWeekdays.isEmpty {
                            Haptics.notification(.warning)
                            return
                        }
                        showRepeatPicker = false
                    } label: {
                        Text("Set")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                
                Spacer(minLength: 6)
            }
            .padding(.bottom, 14)
        }
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
        .presentationDetents([.fraction(0.52), .fraction(0.70), .large])
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: repeatRule)
    }
    
    // MARK: - Helpers
    
    private func hydrate() {
        if let t = taskToEdit {
            title = t.title
            notes = t.notes ?? ""
            remindersEnabled = t.reminderDate != nil
            reminderDate = t.reminderDate.map { Calendar.autoupdatingCurrent.startOfDay(for: $0) }
            reminderTime = t.reminderDate ?? Date()
            repeatRule = t.repeatRule
            customWeekdays = t.customWeekdays
            durationHours = max(0, t.durationMinutes) / 60
            durationMinutes = max(0, t.durationMinutes) % 60
            convertToPreset = t.convertToPreset
        } else {
            title = ""
            notes = ""
            remindersEnabled = true
            reminderDate = selectedDay
            reminderTime = Date()
            durationHours = 0
            durationMinutes = 25
            repeatRule = .none
            customWeekdays = []
            convertToPreset = false
        }
    }
    
    private func buildDraft() -> FFTaskItem {
        let cal = Calendar.autoupdatingCurrent
        
        var mergedReminder: Date? = nil
        if remindersEnabled, let d = reminderDate {
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
        
        return FFTaskItem(
            id: taskToEdit?.id ?? UUID(),
            sortIndex: taskToEdit?.sortIndex ?? 0,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.isEmpty ? nil : notes,
            reminderDate: mergedReminder,
            repeatRule: remindersEnabled ? repeatRule : .none,
            customWeekdays: (remindersEnabled && repeatRule == .customDays) ? customWeekdays : [],
            durationMinutes: max(0, totalMinutes),
            convertToPreset: convertToPreset,
            presetCreated: taskToEdit?.presetCreated ?? false,
            createdAt: taskToEdit?.createdAt ?? selectedDay
        )
    }
    
    private func formatDate(_ d: Date?) -> String {
        guard let d else { return "None" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: d)
    }
    
    private func formatTime(_ d: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: d)
    }
    
    private func formatDuration() -> String {
        if totalMinutes == 0 { return "None" }
        if durationHours > 0 && durationMinutes > 0 { return "\(durationHours)h \(durationMinutes)m" }
        if durationHours > 0 { return "\(durationHours)h" }
        return "\(durationMinutes)m"
    }
}

#Preview {
    TasksView()
}
