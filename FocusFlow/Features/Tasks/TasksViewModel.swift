import Foundation
import Combine

// =========================================================
// MARK: - TasksViewModel (Local persistence + reminders)
// =========================================================

/// Local-only storage (UserDefaults) for Tasks + per-day completion.
///
/// - We *do not* touch Habits.
/// - We namespace storage by auth state (guest vs authed user id) just like other stores.
/// - Reminders are scheduled via `FocusLocalNotificationManager`.
final class TasksViewModel: ObservableObject {

    // MARK: - Published

    @Published private(set) var tasks: [FFTaskItem] = []
    @Published private(set) var completedOccurrenceKeys: Set<String> = []

    // MARK: - Storage

    private struct Keys {
        static let guest = "focusflow_tasks_state_guest"
        static func cloud(userId: UUID) -> String { "focusflow_tasks_state_cloud_\(userId.uuidString)" }
    }

    private struct LocalState: Codable {
        var tasks: [FFTaskItem]
        var completedKeys: [String]
    }

    private let auth = AuthManager.shared
    private let notifier = FocusLocalNotificationManager.shared

    private var cancellables = Set<AnyCancellable>()

    // Prevent save loops while switching users / loading.
    private var isApplyingState = false

    // MARK: - Init

    init() {
        applyAuthState(auth.state)

        auth.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.applyAuthState(state)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public read helpers

    func tasksVisible(on day: Date, calendar: Calendar = .autoupdatingCurrent) -> [FFTaskItem] {
        let d = calendar.startOfDay(for: day)
        return tasks.filter { $0.occurs(on: d, calendar: calendar) }
    }

    func isCompleted(taskId: UUID, on day: Date, calendar: Calendar = .autoupdatingCurrent) -> Bool {
        completedOccurrenceKeys.contains(occurrenceKey(taskID: taskId, day: day, calendar: calendar))
    }

    // MARK: - Mutations

    func upsert(_ task: FFTaskItem) {
        // Always replace reminder state for this task (prevents duplicates).
        notifier.cancelTaskReminder(taskId: task.id)

        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
        } else {
            tasks.insert(task, at: 0)
        }

        save()

        if let date = task.reminderDate {
            notifier.scheduleTaskReminder(
                taskId: task.id,
                taskTitle: task.title,
                date: date,
                repeatRule: task.repeatRule,
                customWeekdays: task.customWeekdays
            )
        }
    }

    func delete(taskID: UUID) {
        notifier.cancelTaskReminder(taskId: taskID)

        tasks.removeAll { $0.id == taskID }

        // Remove orphaned completion keys for this task.
        let prefix = "\(taskID.uuidString)|"
        completedOccurrenceKeys = Set(completedOccurrenceKeys.filter { !$0.hasPrefix(prefix) })

        save()
    }

    func toggleCompletion(taskID: UUID, on day: Date, calendar: Calendar = .autoupdatingCurrent) {
        let key = occurrenceKey(taskID: taskID, day: day, calendar: calendar)
        if completedOccurrenceKeys.contains(key) {
            completedOccurrenceKeys.remove(key)
        } else {
            completedOccurrenceKeys.insert(key)
        }
        save()
    }

    func resetCompletions(for day: Date, calendar: Calendar = .autoupdatingCurrent) {
        let comps = calendar.dateComponents([.year, .month, .day], from: calendar.startOfDay(for: day))
        let suffix = "|\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
        completedOccurrenceKeys = Set(completedOccurrenceKeys.filter { !$0.hasSuffix(suffix) })
        save()
    }

    /// Marks a task's preset as created and clears the one-time intent flag.
    func markPresetCreated(taskID: UUID) {
        guard let idx = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[idx].presetCreated = true
        tasks[idx].convertToPreset = false
        save()
    }

    // MARK: - Internal

    private func occurrenceKey(taskID: UUID, day: Date, calendar: Calendar) -> String {
        let d = calendar.startOfDay(for: day)
        let comps = calendar.dateComponents([.year, .month, .day], from: d)
        return "\(taskID.uuidString)|\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }

    private func currentStorageKey() -> String {
        if let session = auth.currentUserSession {
            if session.isGuest { return Keys.guest }
            return Keys.cloud(userId: session.userId)
        }
        return Keys.guest
    }

    private func cancelAllCurrentTaskReminders() {
        tasks.forEach { notifier.cancelTaskReminder(taskId: $0.id) }
    }

    private func rescheduleAllTaskReminders() {
        tasks.forEach { task in
            guard let date = task.reminderDate else { return }
            notifier.scheduleTaskReminder(
                taskId: task.id,
                taskTitle: task.title,
                date: date,
                repeatRule: task.repeatRule,
                customWeekdays: task.customWeekdays
            )
        }
    }

    private func applyAuthState(_ state: AuthState) {
        // Local-only. We just switch the key used for local storage.
        isApplyingState = true
        defer { isApplyingState = false }

        // When switching users/namespaces, remove reminders from previous tasks
        cancelAllCurrentTaskReminders()

        switch state {
        case .authenticated(let session):
            let key = session.isGuest ? Keys.guest : Keys.cloud(userId: session.userId)
            load(storageKey: key)

        case .unauthenticated, .unknown:
            load(storageKey: Keys.guest)
        }

        // Ensure reminders match the loaded tasks (prevents stale reminders after edits/login switches)
        rescheduleAllTaskReminders()
    }

    // MARK: - Persistence

    private func save() {
        guard !isApplyingState else { return }
        save(storageKey: currentStorageKey())
    }

    private func save(storageKey: String) {
        do {
            let state = LocalState(tasks: tasks, completedKeys: Array(completedOccurrenceKeys))
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(state)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("TasksViewModel: Failed to save tasks: \(error)")
        }
    }

    private func load(storageKey: String) {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            tasks = []
            completedOccurrenceKeys = []
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let state = try decoder.decode(LocalState.self, from: data)
            tasks = state.tasks
            completedOccurrenceKeys = Set(state.completedKeys)
        } catch {
            print("TasksViewModel: Failed to load tasks: \(error)")
            tasks = []
            completedOccurrenceKeys = []
        }
    }
}
