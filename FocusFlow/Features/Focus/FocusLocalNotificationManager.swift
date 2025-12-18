import Foundation
import UserNotifications

final class FocusLocalNotificationManager {
    static let shared = FocusLocalNotificationManager()

    private let center = UNUserNotificationCenter.current()

    // Single-shot session completion notification
    private let sessionNotificationId = "focusflow.sessionCompletion"

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

    private init() {}

    // MARK: - Permission

    /// Ask for notification permission if not decided yet
    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }

            if settings.authorizationStatus == .notDetermined {
                self.center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("🔔 Notification permission error: \(error)")
                    } else {
                        print("🔔 Notification permission granted: \(granted)")
                    }
                }
            }
        }
    }

    // MARK: - Session completion notification

    /// Schedule a notification for session completion after `seconds`
    func scheduleSessionCompletionNotification(
        after seconds: Int,
        sessionName: String
    ) {
        guard seconds > 0 else { return }

        // Clear any previous session-completion notifications
        cancelSessionCompletionNotification()

        let content = UNMutableNotificationContent()
        content.title = "Session complete"
        content.body = "You finished your focus session: \(sessionName)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(seconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: sessionNotificationId,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("🔔 Failed to schedule session notification: \(error)")
            } else {
                print("🔔 Scheduled session notification in \(seconds)s")
            }
        }
    }

    /// Cancel any pending session-completion notifications
    func cancelSessionCompletionNotification() {
        center.removePendingNotificationRequests(withIdentifiers: [sessionNotificationId])
    }

    // MARK: - Daily nudges (3× per day, repeating)

    /// Schedule three repeating daily nudges (morning, afternoon, evening).
    /// Safe to call multiple times – requests with same identifiers will be replaced.
    func scheduleDailyNudges() {
        // Optional: clear existing nudges before re-adding
        center.removePendingNotificationRequests(withIdentifiers: dailyNudgeIds)

        // Morning – e.g. 9:00
        scheduleDailyNudge(
            id: dailyNudgeIds[0],
            hour: 9,
            minute: 0,
            title: "Set your focus for today",
            body: "Take 2 minutes to set your intention and start a FocusFlow session."
        )

        // Afternoon – e.g. 2:00 PM
        scheduleDailyNudge(
            id: dailyNudgeIds[1],
            hour: 14,
            minute: 0,
            title: "Midday check-in",
            body: "How’s your energy? A short focus block now can move something important forward."
        )

        // Evening – e.g. 8:00 PM
        scheduleDailyNudge(
            id: dailyNudgeIds[2],
            hour: 20,
            minute: 0,
            title: "Close the loop",
            body: "Wrap up the day with one last calm, focused session or review your stats in FocusFlow."
        )
    }

    /// Cancel all daily nudges (if you ever add a setting to turn them off)
    func cancelDailyNudges() {
        center.removePendingNotificationRequests(withIdentifiers: dailyNudgeIds)
    }

    // MARK: - User-configurable daily reminder (Profile setting)

    /// Apply the "Daily focus reminder" setting from the Profile screen.
    /// - enabled == true → schedule a repeating notification at the selected time
    /// - enabled == false → cancel that reminder
    func applyDailyReminderSettings(enabled: Bool, time: Date) {
        if enabled {
            // Make sure we have permission (no-op if already decided)
            requestAuthorizationIfNeeded()
            scheduleDailyReminder(at: time)
        } else {
            cancelDailyReminder()
        }
    }

    /// Schedule one repeating daily reminder at the given time of day.
    private func scheduleDailyReminder(at time: Date) {
        // Clear any previous reminder with this id
        cancelDailyReminder()

        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        var dateComponents = DateComponents()
        dateComponents.hour = comps.hour ?? 9
        dateComponents.minute = comps.minute ?? 0

        let content = UNMutableNotificationContent()
        content.title = "Time to focus"
        content.body = "Take a moment to start your focus goal in FocusFlow."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

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

    /// Cancel the user-configurable daily reminder only.
    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderId])
    }

    // MARK: - Habit reminders (per-habit)

    /// Schedule a reminder for a specific habit with optional repeat.
    func scheduleHabitReminder(
        habitId: UUID,
        habitName: String,
        date: Date,
        repeatOption: HabitRepeat
    ) {
        // Make sure permission is requested at least once
        requestAuthorizationIfNeeded()

        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .weekday],
            from: date
        )

        let trigger: UNCalendarNotificationTrigger

        switch repeatOption {
        case .none:
            // One-off reminder on that exact date/time
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        case .daily:
            // Every day at the same time
            dateComponents = DateComponents(
                hour: dateComponents.hour,
                minute: dateComponents.minute
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        case .weekly:
            // Same weekday + time every week
            dateComponents = DateComponents(
                hour: dateComponents.hour,
                minute: dateComponents.minute,
                weekday: dateComponents.weekday
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        case .monthly:
            // Same day-of-month + time
            dateComponents = DateComponents(
                day: dateComponents.day,
                hour: dateComponents.hour,
                minute: dateComponents.minute
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        case .yearly:
            // Same month/day + time every year
            dateComponents = DateComponents(
                month: dateComponents.month,
                day: dateComponents.day,
                hour: dateComponents.hour,
                minute: dateComponents.minute
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        }

        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder"
        content.body = "It’s time for: \(habitName)"
        content.sound = .default

        let identifier = habitReminderPrefix + habitId.uuidString

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("🔔 Failed to schedule habit reminder for \(habitName): \(error)")
            } else {
                print("🔔 Scheduled habit reminder for \(habitName) with id \(identifier)")
            }
        }
    }

    /// Cancel all pending reminders for a specific habit.
    func cancelHabitReminder(habitId: UUID) {
        let identifier = habitReminderPrefix + habitId.uuidString
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Internal helper for fixed nudges

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

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("🔔 Failed to schedule daily nudge (\(id)): \(error)")
            } else {
                print("🔔 Scheduled daily nudge \(id) at \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
}
