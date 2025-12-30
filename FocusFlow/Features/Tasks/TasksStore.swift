import Foundation
import Combine

final class TasksStore: ObservableObject {
    static let shared = TasksStore()

    @Published internal(set) var tasks: [FFTaskItem] = []
    @Published internal(set) var completedOccurrenceKeys: Set<String> = []

    private struct Keys {
        static let guest = "focusflow_tasks_state_guest"
        static func cloud(userId: UUID) -> String { "focusflow_tasks_state_cloud_\(userId.uuidString)" }
    }

    private struct LocalState: Codable {
        var tasks: [FFTaskItem]
        var completedKeys: [String]
    }

    private var cancellables = Set<AnyCancellable>()
    private var isApplyingState = false

    /// Race-safe namespace lock
    private var activeStorageKey: String = Keys.guest
    private var lastStorageKey: String?

    private init() {
        applyAuthState(AuthManagerV2.shared.state)

        AuthManagerV2.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.applyAuthState(state)
            }
            .store(in: &cancellables)
    }

    func tasksVisible(on day: Date, calendar: Calendar = .autoupdatingCurrent) -> [FFTaskItem] {
        let d = calendar.startOfDay(for: day)
        return orderedTasks().filter { $0.occurs(on: d, calendar: calendar) }
    }

    func isCompleted(taskId: UUID, on day: Date, calendar: Calendar = .autoupdatingCurrent) -> Bool {
        completedOccurrenceKeys.contains(occurrenceKey(taskID: taskId, day: day, calendar: calendar))
    }

    func orderedTasks() -> [FFTaskItem] {
        tasks.sorted { a, b in
            if a.sortIndex != b.sortIndex { return a.sortIndex < b.sortIndex }
            return a.createdAt < b.createdAt
        }
    }

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

        for i in ordered.indices { ordered[i].sortIndex = i }
        tasks = ordered
        save()
    }

    func upsert(_ task: FFTaskItem) {
        var incoming = task

        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            if incoming.sortIndex == 0 { incoming.sortIndex = tasks[idx].sortIndex }
            tasks[idx] = incoming
            // ✅ Record timestamp for updated task
            let namespace = getActiveNamespace()
            LocalTimestampTracker.shared.recordLocalChange(field: "task_\(task.id.uuidString)", namespace: namespace)
        } else {
            let minIndex = tasks.map { $0.sortIndex }.min() ?? 0
            incoming.sortIndex = minIndex - 1
            tasks.append(incoming)
            // ✅ Record timestamp for new task
            let namespace = getActiveNamespace()
            LocalTimestampTracker.shared.recordLocalChange(field: "task_\(task.id.uuidString)", namespace: namespace)
        }

        var ordered = orderedTasks()
        for i in ordered.indices { ordered[i].sortIndex = i }
        tasks = ordered

        save()
    }

    func delete(taskID: UUID) {
        tasks.removeAll { $0.id == taskID }
        let prefix = "\(taskID.uuidString)|"
        completedOccurrenceKeys = Set(completedOccurrenceKeys.filter { !$0.hasPrefix(prefix) })

        // ✅ Record timestamp for deleted task (for conflict resolution)
        let namespace = getActiveNamespace()
        LocalTimestampTracker.shared.recordLocalChange(field: "task_\(taskID.uuidString)", namespace: namespace)

        var ordered = orderedTasks()
        for i in ordered.indices { ordered[i].sortIndex = i }
        tasks = ordered

        save()
    }

    func deleteOccurrence(taskID: UUID, on day: Date, calendar: Calendar = .autoupdatingCurrent) {
        guard let idx = tasks.firstIndex(where: { $0.id == taskID }) else { return }

        let key = FFTaskItem.dayKey(day, calendar: calendar)
        tasks[idx].excludedDayKeys.insert(key)

        let completionKey = occurrenceKey(taskID: taskID, day: day, calendar: calendar)
        completedOccurrenceKeys.remove(completionKey)

        save()
    }

    func toggleCompletion(taskID: UUID, on day: Date, calendar: Calendar = .autoupdatingCurrent) {
        let key = occurrenceKey(taskID: taskID, day: day, calendar: calendar)

        if completedOccurrenceKeys.contains(key) {
            completedOccurrenceKeys.remove(key)
            // ✅ Record timestamp for completion change
            let namespace = getActiveNamespace()
            LocalTimestampTracker.shared.recordLocalChange(field: "task_completion_\(taskID.uuidString)", namespace: namespace)
            save()
        } else {
            completedOccurrenceKeys.insert(key)
            // ✅ Record timestamp for completion change
            let namespace = getActiveNamespace()
            LocalTimestampTracker.shared.recordLocalChange(field: "task_completion_\(taskID.uuidString)", namespace: namespace)
            save()

            if let task = tasks.first(where: { $0.id == taskID }) {
                AppSyncManager.shared.taskDidComplete(
                    taskId: taskID,
                    taskTitle: task.title,
                    on: calendar.startOfDay(for: day)
                )
            }
        }
    }

    func resetCompletions(for day: Date, calendar: Calendar = .autoupdatingCurrent) {
        let comps = calendar.dateComponents([.year, .month, .day], from: calendar.startOfDay(for: day))
        let suffix = "|\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
        completedOccurrenceKeys = Set(completedOccurrenceKeys.filter { !$0.hasSuffix(suffix) })
        save()
    }

    func markPresetCreated(taskID: UUID) {
        guard let idx = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[idx].presetCreated = true
        tasks[idx].convertToPreset = false
        save()
    }

    func clearAll() {
        tasks = []
        completedOccurrenceKeys = []
        save()
    }

    private func occurrenceKey(taskID: UUID, day: Date, calendar: Calendar) -> String {
        let d = calendar.startOfDay(for: day)
        let comps = calendar.dateComponents([.year, .month, .day], from: d)
        return "\(taskID.uuidString)|\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }

    private func applyAuthState(_ state: CloudAuthState) {
        let nextKey: String
        let namespace: String
        switch state {
        case .signedIn(let userId):
            nextKey = Keys.cloud(userId: userId)
            namespace = userId.uuidString
        case .guest, .unknown, .signedOut:
            nextKey = Keys.guest
            namespace = "guest"
        }

        isApplyingState = true
        defer { isApplyingState = false }

        // ✅ Clear timestamps for OLD namespace when switching accounts (not new)
        // This prevents timestamp data from bleeding across accounts
        if let oldKey = lastStorageKey, oldKey != nextKey {
            // Extract namespace from old key
            if oldKey != Keys.guest, let oldNamespace = extractNamespace(from: oldKey) {
                LocalTimestampTracker.shared.clearAllTimestamps(namespace: oldNamespace)
            }
        }

        // lock key first
        lastStorageKey = activeStorageKey
        activeStorageKey = nextKey
        load(storageKey: nextKey)
    }
    
    private func getActiveNamespace() -> String {
        switch AuthManagerV2.shared.state {
        case .signedIn(let userId):
            return userId.uuidString
        case .guest, .unknown, .signedOut:
            return "guest"
        }
    }
    
    /// Extract namespace (userId) from storage key
    private func extractNamespace(from key: String) -> String? {
        // Key format: "focusflow_tasks_state_cloud_\(userId.uuidString)"
        let prefix = "focusflow_tasks_state_cloud_"
        guard key.hasPrefix(prefix) else { return nil }
        return String(key.dropFirst(prefix.count))
    }

    private func save() {
        guard !isApplyingState else { return }
        save(storageKey: activeStorageKey)
    }

    private func save(storageKey: String) {
        do {
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

extension TasksStore {
    func applyRemoteState(tasks newTasks: [FFTaskItem], completionKeys newKeys: Set<String>) {
        isApplyingState = true
        defer { isApplyingState = false }
        self.tasks = newTasks
        self.completedOccurrenceKeys = newKeys
    }
}

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
