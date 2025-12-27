// =========================================================
// TasksStore.swift  (FULL FILE — updated with clearAll())
// =========================================================

import Foundation
import Combine

// =========================================================
// MARK: - TasksStore (Local persistence only; no notifications)
// =========================================================

/// Single source of truth for Tasks + per-day completion.
/// - Local-only persistence (UserDefaults)
/// - Namespaced storage key (guest vs signed-in user) like other stores.
/// - NO notification scheduling side-effects (handled by TaskReminderScheduler).
final class TasksStore: ObservableObject {

    static let shared = TasksStore()

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
    private var cancellables = Set<AnyCancellable>()

    // Prevent save loops while switching users / loading.
    private var isApplyingState = false

    // MARK: - Init

    private init() {
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
        return orderedTasks().filter { $0.occurs(on: d, calendar: calendar) }
    }

    func isCompleted(taskId: UUID, on day: Date, calendar: Calendar = .autoupdatingCurrent) -> Bool {
        completedOccurrenceKeys.contains(occurrenceKey(taskID: taskId, day: day, calendar: calendar))
    }

    // MARK: - Ordering

    /// Stable manual order (sortIndex asc).
    func orderedTasks() -> [FFTaskItem] {
        tasks.sorted { a, b in
            if a.sortIndex != b.sortIndex { return a.sortIndex < b.sortIndex }
            return a.createdAt < b.createdAt
        }
    }

    /// Reorder the subset of tasks that are visible in the current list.
    func moveTasks(visibleTaskIDs: [UUID], fromOffsets: IndexSet, toOffset: Int) {
        guard visibleTaskIDs.count >= 2 else { return }

        var ordered = orderedTasks()
        let visibleSet = Set(visibleTaskIDs)

        var subset = ordered.filter { visibleSet.contains($0.id) }
        subset.move(fromOffsets: fromOffsets, toOffset: toOffset)

        var subsetIndex = 0
        for i in ordered.indices {
            if visibleSet.contains(ordered[i].id) {
                ordered[i] = subset[subsetIndex]
                subsetIndex += 1
            }
        }

        // Renormalize sortIndex
        for i in ordered.indices { ordered[i].sortIndex = i }

        tasks = ordered
        save()
    }

    // MARK: - Mutations

    func upsert(_ task: FFTaskItem) {
        var incoming = task

        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            // Preserve manual order if draft didn't carry it over
            if incoming.sortIndex == 0 {
                incoming.sortIndex = tasks[idx].sortIndex
            }
            tasks[idx] = incoming
        } else {
            // New tasks go to the top by default
            let minIndex = tasks.map { $0.sortIndex }.min() ?? 0
            incoming.sortIndex = minIndex - 1
            tasks.append(incoming)
        }

        // Ensure stable ordering and continuous sortIndex
        var ordered = orderedTasks()
        for i in ordered.indices { ordered[i].sortIndex = i }
        tasks = ordered

        save()
    }

    /// Delete the entire task (series).
    func delete(taskID: UUID) {
        tasks.removeAll { $0.id == taskID }

        // Remove orphaned completion keys for this task.
        let prefix = "\(taskID.uuidString)|"
        completedOccurrenceKeys = Set(completedOccurrenceKeys.filter { !$0.hasPrefix(prefix) })

        // Renormalize ordering.
        var ordered = orderedTasks()
        for i in ordered.indices { ordered[i].sortIndex = i }
        tasks = ordered

        save()
    }

    /// Outlook-style: delete ONLY this day's occurrence (keeps series).
    func deleteOccurrence(taskID: UUID, on day: Date, calendar: Calendar = .autoupdatingCurrent) {
        guard let idx = tasks.firstIndex(where: { $0.id == taskID }) else { return }

        let key = FFTaskItem.dayKey(day, calendar: calendar)
        tasks[idx].excludedDayKeys.insert(key)

        // Remove completion state for that day (if any)
        let completionKey = occurrenceKey(taskID: taskID, day: day, calendar: calendar)
        completedOccurrenceKeys.remove(completionKey)

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

    /// ✅ Used by Settings → Reset All Data
    func clearAll() {
        tasks = []
        completedOccurrenceKeys = []
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

    private func applyAuthState(_ state: AuthState) {
        isApplyingState = true
        defer { isApplyingState = false }

        switch state {
        case .authenticated(let session):
            let key = session.isGuest ? Keys.guest : Keys.cloud(userId: session.userId)
            load(storageKey: key)

        case .unauthenticated, .unknown:
            load(storageKey: Keys.guest)
        }
    }

    // MARK: - Persistence

    private func save() {
        guard !isApplyingState else { return }
        save(storageKey: currentStorageKey())
    }

    private func save(storageKey: String) {
        do {
            // Persist in stable order
            var ordered = orderedTasks()
            for i in ordered.indices { ordered[i].sortIndex = i }

            let state = LocalState(tasks: ordered, completedKeys: Array(completedOccurrenceKeys))

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(state)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("TasksStore: Failed to save tasks: \(error)")
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

            var loaded = state.tasks

            // Backwards compatibility: if sortIndex is missing/duplicated, normalize.
            let uniqueCount = Set(loaded.map { $0.sortIndex }).count
            if uniqueCount != loaded.count {
                for i in loaded.indices { loaded[i].sortIndex = i }
            }

            loaded.sort { a, b in
                if a.sortIndex != b.sortIndex { return a.sortIndex < b.sortIndex }
                return a.createdAt < b.createdAt
            }

            for i in loaded.indices { loaded[i].sortIndex = i }

            tasks = loaded
            completedOccurrenceKeys = Set(state.completedKeys)
        } catch {
            print("TasksStore: Failed to load tasks: \(error)")
            tasks = []
            completedOccurrenceKeys = []
        }
    }
}

// MARK: - Array helper

private extension Array {
    mutating func move(fromOffsets: IndexSet, toOffset: Int) {
        let moving = fromOffsets.map { self[$0] }
        let upper = fromOffsets.max() ?? 0

        for i in fromOffsets.sorted(by: >) {
            remove(at: i)
        }

        var target = toOffset
        if toOffset > upper {
            target = toOffset - fromOffsets.count
        }
        insert(contentsOf: moving, at: target)
    }
}
