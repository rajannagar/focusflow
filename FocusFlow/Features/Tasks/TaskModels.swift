import Foundation

// =========================================================
// MARK: - Tasks Models
// =========================================================

/// Keep the FF prefix to avoid name collisions with Swift Concurrency's `Task`.
enum FFTaskRepeatRule: String, CaseIterable, Identifiable, Codable {
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

struct FFTaskItem: Identifiable, Equatable, Codable {
    let id: UUID

    var title: String
    var notes: String?

    /// If nil, task is "flexible" and will show according to repeat rules.
    var reminderDate: Date?

    var repeatRule: FFTaskRepeatRule
    var customWeekdays: Set<Int>

    /// 0 means no duration.
    var durationMinutes: Int

    /// UI intent: when true, the UI will create a focus preset one time.
    /// After creation, this is set back to false and `presetCreated` is set to true.
    var convertToPreset: Bool

    /// Persisted guard so we never create duplicate presets on relaunch.
    var presetCreated: Bool

    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        reminderDate: Date? = nil,
        repeatRule: FFTaskRepeatRule = .none,
        customWeekdays: Set<Int> = [],
        durationMinutes: Int = 0,
        convertToPreset: Bool = false,
        presetCreated: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.reminderDate = reminderDate
        self.repeatRule = repeatRule
        self.customWeekdays = customWeekdays
        self.durationMinutes = durationMinutes
        self.convertToPreset = convertToPreset
        self.presetCreated = presetCreated
        self.createdAt = createdAt
    }

    // MARK: - Scheduling

    func occurs(on day: Date, calendar: Calendar) -> Bool {
        let target = calendar.startOfDay(for: day)
        let anchor = calendar.startOfDay(for: reminderDate ?? createdAt)

        if repeatRule != .none, target < anchor { return false }

        switch repeatRule {
        case .none:
            // If no reminder date, treat it as a flexible task that always shows.
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

struct FFDateID: Hashable {
    let value: Int

    init(_ date: Date) {
        let c = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day], from: date)
        self.value = (c.year! * 10000) + (c.month! * 100) + c.day!
    }
}
