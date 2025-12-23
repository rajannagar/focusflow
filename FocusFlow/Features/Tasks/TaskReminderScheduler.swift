import Foundation
import Combine

// =========================================================
// MARK: - TaskReminderScheduler (notifications only)
// =========================================================

/// Watches TasksStore and schedules/cancels notifications.
/// This keeps reminders correct even if Tasks tab isn't opened.
final class TaskReminderScheduler {
    static let shared = TaskReminderScheduler()

    private let notifier = FocusLocalNotificationManager.shared
    private let store = TasksStore.shared

    private var cancellables = Set<AnyCancellable>()
    private let queue = DispatchQueue(label: "TaskReminderScheduler.queue")

    private struct Signature: Hashable {
        let title: String
        let date: Date
        let repeatRule: FFTaskRepeatRule
        let weekdays: Set<Int>
    }

    private var lastScheduled: [UUID: Signature] = [:]

    private init() {
        store.$tasks
            .receive(on: queue)
            .debounce(for: .milliseconds(250), scheduler: queue)
            .sink { [weak self] tasks in
                self?.reconcile(tasks)
            }
            .store(in: &cancellables)
    }

    private func reconcile(_ tasks: [FFTaskItem]) {
        let currentIDs = Set(tasks.map { $0.id })

        // Cancel reminders for tasks that no longer exist
        for (taskId, _) in lastScheduled where !currentIDs.contains(taskId) {
            notifier.cancelTaskReminder(taskId: taskId)
            lastScheduled.removeValue(forKey: taskId)
        }

        for t in tasks {
            let id = t.id

            guard let date = t.reminderDate else {
                if lastScheduled[id] != nil {
                    notifier.cancelTaskReminder(taskId: id)
                    lastScheduled.removeValue(forKey: id)
                }
                continue
            }

            let sig = Signature(
                title: t.title,
                date: date,
                repeatRule: t.repeatRule,
                weekdays: t.customWeekdays
            )

            if lastScheduled[id] != sig {
                notifier.scheduleTaskReminder(
                    taskId: id,
                    taskTitle: t.title,
                    date: date,
                    repeatRule: t.repeatRule,
                    customWeekdays: t.customWeekdays
                )
                lastScheduled[id] = sig
            }
        }
    }

    /// Manual trigger (useful right after permission changes).
    func rescheduleAllNow() {
        queue.async { [weak self] in
            guard let self else { return }
            self.reconcile(self.store.tasks)
        }
    }
}
