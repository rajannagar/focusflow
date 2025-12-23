import Foundation
import UserNotifications

final class FocusLocalNotificationManager {
    static let shared = FocusLocalNotificationManager()

    private let center = UNUserNotificationCenter.current()

    // ✅ SINGLE completion id (prevents duplicates)
    private let sessionCompletionId = "focusflow.sessionCompletion"
    var sessionCompletionIdentifier: String { sessionCompletionId }

    // Repeating daily nudges (3x per day)
    private let dailyNudgeIds = [
        "focusflow.nudge.morning",
        "focusflow.nudge.afternoon",
        "focusflow.nudge.evening"
    ]

    // Single user-configurable daily reminder (Profile → Daily focus reminder)
    private let dailyReminderId = "focusflow.dailyReminder"

    // Per-habit reminder prefix
    private let habitReminderPrefix = "focusflow.habit."

    // ✅ Per-task reminder prefix
    private let taskReminderPrefix = "focusflow.task."

    // Category ids (premium future-ready)
    private let categorySessionComplete = "focusflow.category.sessionComplete"

    private init() {}

    // MARK: - Authorization Helpers

    enum Authorization {
        case authorized
        case provisional
        case denied
        case notDetermined
        case unknown
    }

    private func map(_ status: UNAuthorizationStatus) -> Authorization {
        switch status {
        case .authorized: return .authorized
        case .provisional: return .provisional
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .ephemeral:
            return .provisional
        @unknown default:
            return .unknown
        }
    }

    private func isAllowedToSchedule(_ auth: Authorization) -> Bool {
        switch auth {
        case .authorized, .provisional:
            return true
        case .denied, .notDetermined, .unknown:
            return false
        }
    }

    func requestAuthorizationIfNeeded(completion: ((Authorization) -> Void)? = nil) {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            let mapped = self.map(settings.authorizationStatus)

            if mapped == .denied {
                print("🔔 Notifications denied in Settings (no scheduling possible).")
                completion?(mapped)
                return
            }

            if mapped != .notDetermined {
                completion?(mapped)
                return
            }

            self.center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("🔔 Notification permission error: \(error)")
                } else {
                    print("🔔 Notification permission granted: \(granted)")
                }

                self.center.getNotificationSettings { newSettings in
                    completion?(self.map(newSettings.authorizationStatus))
                }
            }
        }
    }

    // MARK: - Categories (optional / premium-ready)

    func registerNotificationCategoriesIfNeeded() {
        // You can add actions later if desired. For now, register category so we can attach it.
        let category = UNNotificationCategory(
            identifier: categorySessionComplete,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    // MARK: - Session completion (single notification)

    func scheduleSessionCompletionNotification(after seconds: Int, sessionName: String) {
        guard seconds > 0 else { return }

        requestAuthorizationIfNeeded { [weak self] auth in
            guard let self else { return }
            guard self.isAllowedToSchedule(auth) else { return }

            // Replace any existing completion notification
            self.cancelSessionCompletionNotification()

            let content = UNMutableNotificationContent()
            content.title = "Session complete"
            content.body = "Your focus session ended: \(sessionName)"
            content.sound = .default
            content.categoryIdentifier = self.categorySessionComplete

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)

            let request = UNNotificationRequest(
                identifier: self.sessionCompletionId,
                content: content,
                trigger: trigger
            )

            self.center.add(request) { error in
                if let error = error {
                    print("🔔 Failed to schedule session notification: \(error)")
                } else {
                    print("🔔 Scheduled session notification in \(seconds)s")
                }
            }
        }
    }

    func cancelSessionCompletionNotification() {
        center.removePendingNotificationRequests(withIdentifiers: [sessionCompletionId])
        center.removeDeliveredNotifications(withIdentifiers: [sessionCompletionId])
    }

    func clearDeliveredSessionCompletionNotifications() {
        center.removeDeliveredNotifications(withIdentifiers: [sessionCompletionId])
    }

    // MARK: - Daily nudges (3× per day)

    func scheduleDailyNudges() {
        requestAuthorizationIfNeeded { [weak self] auth in
            guard let self else { return }
            guard self.isAllowedToSchedule(auth) else { return }

            self.center.removePendingNotificationRequests(withIdentifiers: self.dailyNudgeIds)

            self.scheduleDailyNudge(
                id: self.dailyNudgeIds[0],
                hour: 9,
                minute: 0,
                title: "Set your focus for today",
                body: "Take 2 minutes to set your intention and start a FocusFlow session."
            )

            self.scheduleDailyNudge(
                id: self.dailyNudgeIds[1],
                hour: 14,
                minute: 0,
                title: "Midday check-in",
                body: "How’s your energy? A short focus block now can move something important forward."
            )

            self.scheduleDailyNudge(
                id: self.dailyNudgeIds[2],
                hour: 20,
                minute: 0,
                title: "Close the loop",
                body: "Wrap up the day with one last calm, focused session or review your stats in FocusFlow."
            )
        }
    }

    func cancelDailyNudges() {
        center.removePendingNotificationRequests(withIdentifiers: dailyNudgeIds)
        center.removeDeliveredNotifications(withIdentifiers: dailyNudgeIds)
    }

    // MARK: - User-configurable daily reminder

    func applyDailyReminderSettings(enabled: Bool, time: Date) {
        if enabled {
            requestAuthorizationIfNeeded { [weak self] auth in
                guard let self else { return }
                guard self.isAllowedToSchedule(auth) else { return }
                self.scheduleDailyReminder(at: time)
            }
        } else {
            cancelDailyReminder()
        }
    }

    private func scheduleDailyReminder(at time: Date) {
        cancelDailyReminder()

        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        var dateComponents = DateComponents()
        dateComponents.hour = comps.hour ?? 9
        dateComponents.minute = comps.minute ?? 0

        let content = UNMutableNotificationContent()
        content.title = "Time to focus"
        content.body = "Take a moment to start your focus goal in FocusFlow."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: dailyReminderId,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("🔔 Failed to schedule daily reminder: \(error)")
            } else {
                let h = dateComponents.hour ?? 0
                let m = dateComponents.minute ?? 0
                print("🔔 Scheduled daily reminder at \(h):\(String(format: "%02d", m))")
            }
        }
    }

    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderId])
        center.removeDeliveredNotifications(withIdentifiers: [dailyReminderId])
    }

    // MARK: - Habit reminders

    func scheduleHabitReminder(
        habitId: UUID,
        habitName: String,
        date: Date,
        repeatOption: HabitRepeat
    ) {
        requestAuthorizationIfNeeded { [weak self] auth in
            guard let self else { return }
            guard self.isAllowedToSchedule(auth) else { return }

            let calendar = Calendar.current
            var dateComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .weekday],
                from: date
            )

            let trigger: UNCalendarNotificationTrigger
            switch repeatOption {
            case .none:
                trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            case .daily:
                dateComponents = DateComponents(hour: dateComponents.hour, minute: dateComponents.minute)
                trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            case .weekly:
                dateComponents = DateComponents(hour: dateComponents.hour, minute: dateComponents.minute, weekday: dateComponents.weekday)
                trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            case .monthly:
                dateComponents = DateComponents(day: dateComponents.day, hour: dateComponents.hour, minute: dateComponents.minute)
                trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            case .yearly:
                dateComponents = DateComponents(month: dateComponents.month, day: dateComponents.day, hour: dateComponents.hour, minute: dateComponents.minute)
                trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            }

            let content = UNMutableNotificationContent()
            content.title = "Habit Reminder"
            content.body = "It’s time for: \(habitName)"
            content.sound = .default

            let identifier = self.habitReminderPrefix + habitId.uuidString
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            self.center.add(request) { error in
                if let error = error {
                    print("🔔 Failed to schedule habit reminder for \(habitName): \(error)")
                } else {
                    print("🔔 Scheduled habit reminder for \(habitName) with id \(identifier)")
                }
            }
        }
    }

    func cancelHabitReminder(habitId: UUID) {
        let identifier = habitReminderPrefix + habitId.uuidString
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    // MARK: - ✅ Task reminders

    /// Schedules a task reminder based on repeat rule.
    /// - For `.customDays`, we schedule one notification per weekday (each with its own identifier).
    func scheduleTaskReminder(
        taskId: UUID,
        taskTitle: String,
        date: Date,
        repeatRule: FFTaskRepeatRule,
        customWeekdays: Set<Int>
    ) {
        requestAuthorizationIfNeeded { [weak self] auth in
            guard let self else { return }
            guard self.isAllowedToSchedule(auth) else { return }

            // Always replace existing task reminder(s)
            self.cancelTaskReminder(taskId: taskId)

            let calendar = Calendar.current

            let content = UNMutableNotificationContent()
            content.title = "Task Reminder"
            content.body = "It’s time for: \(taskTitle)"
            content.sound = .default

            let baseId = self.taskReminderPrefix + taskId.uuidString

            // If it's a one-time reminder but already in the past, skip.
            if repeatRule == .none, date <= Date() {
                print("🔔 Skipping past one-time task reminder for \(taskTitle)")
                return
            }

            // Build time components from chosen date (hour/minute).
            let timeComps = calendar.dateComponents([.hour, .minute, .weekday, .day, .month, .year], from: date)
            let hour = timeComps.hour ?? 9
            let minute = timeComps.minute ?? 0
            let weekdayFromDate = timeComps.weekday ?? 2 // fallback Monday-ish

            func addRequest(id: String, trigger: UNCalendarNotificationTrigger) {
                let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                self.center.add(req) { error in
                    if let error = error {
                        print("🔔 Failed to schedule task reminder for \(taskTitle) (\(id)): \(error)")
                    } else {
                        print("🔔 Scheduled task reminder for \(taskTitle) with id \(id)")
                    }
                }
            }

            switch repeatRule {
            case .none:
                // Exact date/time
                var dc = DateComponents()
                dc.year = timeComps.year
                dc.month = timeComps.month
                dc.day = timeComps.day
                dc.hour = hour
                dc.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
                addRequest(id: baseId, trigger: trigger)

            case .daily:
                let dc = DateComponents(hour: hour, minute: minute)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                addRequest(id: baseId, trigger: trigger)

            case .weekly:
                let dc = DateComponents(hour: hour, minute: minute, weekday: weekdayFromDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                addRequest(id: baseId, trigger: trigger)

            case .monthly:
                let day = timeComps.day ?? 1
                let dc = DateComponents(day: day, hour: hour, minute: minute)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                addRequest(id: baseId, trigger: trigger)

            case .yearly:
                let day = timeComps.day ?? 1
                let month = timeComps.month ?? 1
                let dc = DateComponents(month: month, day: day, hour: hour, minute: minute)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                addRequest(id: baseId, trigger: trigger)

            case .customDays:
                // One per weekday (1...7), repeats weekly.
                let days = customWeekdays.isEmpty ? [weekdayFromDate] : Array(customWeekdays).sorted()
                for wd in days {
                    let dc = DateComponents(hour: hour, minute: minute, weekday: wd)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                    let id = baseId + ".w\(wd)"
                    addRequest(id: id, trigger: trigger)
                }
            }
        }
    }

    func cancelTaskReminder(taskId: UUID) {
        let baseId = taskReminderPrefix + taskId.uuidString
        let ids = [baseId] + (1...7).map { baseId + ".w\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    // MARK: - Debug (optional)

    func debugPrintPendingRequests() {
        center.getPendingNotificationRequests { requests in
            print("🔔 Pending notifications: \(requests.count)")
            for r in requests {
                print("   • \(r.identifier) trigger=\(String(describing: r.trigger))")
            }
        }
    }

    // MARK: - Internal helper

    private func scheduleDailyNudge(
        id: String,
        hour: Int,
        minute: Int,
        title: String,
        body: String
    ) {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("🔔 Failed to schedule daily nudge (\(id)): \(error)")
            } else {
                print("🔔 Scheduled daily nudge \(id) at \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
}
