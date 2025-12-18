import Foundation
import Combine
import SwiftUI

enum HabitRepeat: String, Codable, CaseIterable, Identifiable {
    case none, daily, weekly, monthly, yearly
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .none: return "No repeat"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

struct Habit: Identifiable, Codable {
    let id: UUID
    let name: String
    var isDoneToday: Bool
    var reminderDate: Date?
    var repeatOption: HabitRepeat
    var durationMinutes: Int?
    var sortIndex: Int
    var updatedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        isDoneToday: Bool,
        reminderDate: Date? = nil,
        repeatOption: HabitRepeat = .none,
        durationMinutes: Int? = nil,
        sortIndex: Int = 0,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.isDoneToday = isDoneToday
        self.reminderDate = reminderDate
        self.repeatOption = repeatOption
        self.durationMinutes = durationMinutes
        self.sortIndex = sortIndex
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, name, isDoneToday, reminderDate, repeatOption, durationMinutes, sortIndex, updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        isDoneToday = try c.decode(Bool.self, forKey: .isDoneToday)
        reminderDate = try c.decodeIfPresent(Date.self, forKey: .reminderDate)
        repeatOption = (try? c.decode(HabitRepeat.self, forKey: .repeatOption)) ?? .none
        durationMinutes = try c.decodeIfPresent(Int.self, forKey: .durationMinutes)
        sortIndex = (try? c.decode(Int.self, forKey: .sortIndex)) ?? 0
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

extension Habit {
    func toRecord(userId: UUID, sortIndex: Int) -> HabitRecord {
        HabitRecord(
            id: id,
            userId: userId,
            name: name,
            isDoneToday: isDoneToday,
            reminderAt: reminderDate,
            repeatOption: repeatOption.rawValue,
            durationMinutes: durationMinutes,
            sortIndex: sortIndex,
            createdAt: nil,
            updatedAt: updatedAt
        )
    }

    static func fromRecord(_ r: HabitRecord) -> Habit {
        Habit(
            id: r.id,
            name: r.name,
            isDoneToday: r.isDoneToday,
            reminderDate: r.reminderAt,
            repeatOption: HabitRepeat(rawValue: r.repeatOption) ?? .none,
            durationMinutes: r.durationMinutes,
            sortIndex: r.sortIndex,
            updatedAt: r.updatedAt
        )
    }
}

final class HabitsViewModel: ObservableObject {
    @Published var habits: [Habit] = []

    private let guestStorageKey = "focusflow_habits_guest"

    private let auth = AuthManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var startedSync = false

    private var lastAuthedUserId: UUID?

    init() {
        applyAuthState(auth.state)

        auth.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.applyAuthState(state)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public API (unchanged)

    func addHabit(name: String, reminderDate: Date? = nil, repeatOption: HabitRepeat = .none, durationMinutes: Int? = nil) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newHabit = Habit(
            name: trimmed,
            isDoneToday: false,
            reminderDate: reminderDate,
            repeatOption: repeatOption,
            durationMinutes: durationMinutes,
            sortIndex: habits.count
        )

        habits.append(newHabit)
        normalizeSortIndexes()
        saveHabits()

        if let date = reminderDate {
            FocusLocalNotificationManager.shared.scheduleHabitReminder(
                habitId: newHabit.id,
                habitName: newHabit.name,
                date: date,
                repeatOption: repeatOption
            )
        }
    }

    func updateHabit(_ habit: Habit, name: String, reminderDate: Date?, repeatOption: HabitRepeat, durationMinutes: Int?) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        FocusLocalNotificationManager.shared.cancelHabitReminder(habitId: habit.id)

        let updatedHabit = Habit(
            id: habit.id,
            name: trimmed,
            isDoneToday: habit.isDoneToday,
            reminderDate: reminderDate,
            repeatOption: repeatOption,
            durationMinutes: durationMinutes,
            sortIndex: habits[index].sortIndex,
            updatedAt: habit.updatedAt
        )

        habits[index] = updatedHabit
        normalizeSortIndexes()
        saveHabits()

        if let date = reminderDate {
            FocusLocalNotificationManager.shared.scheduleHabitReminder(
                habitId: updatedHabit.id,
                habitName: updatedHabit.name,
                date: date,
                repeatOption: repeatOption
            )
        }
    }

    func delete(at offsets: IndexSet) {
        let toDelete = offsets.map { habits[$0] }
        toDelete.forEach { FocusLocalNotificationManager.shared.cancelHabitReminder(habitId: $0.id) }

        habits.remove(atOffsets: offsets)
        normalizeSortIndexes()
        saveHabits()
    }

    func delete(habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            FocusLocalNotificationManager.shared.cancelHabitReminder(habitId: habit.id)
            habits.remove(at: index)
            normalizeSortIndexes()
            saveHabits()
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        habits.move(fromOffsets: source, toOffset: destination)
        normalizeSortIndexes()
        saveHabits()
    }

    func toggle(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index].isDoneToday.toggle()
        saveHabits()
    }

    func resetAll() {
        for index in habits.indices { habits[index].isDoneToday = false }
        saveHabits()
    }

    // MARK: - Auth routing

    private func cloudStorageKey(for userId: UUID) -> String {
        "focusflow_habits_cloud_\(userId.uuidString)"
    }

    private func applyAuthState(_ state: AuthState) {
        switch state {
        case .authenticated(let session):
            if session.isGuest {
                HabitsSyncEngine.shared.disableSyncAndResetCloudState()

                loadHabits(storageKey: guestStorageKey)
                if habits.isEmpty {
                    habits = defaultHabits()
                    saveHabits(storageKey: guestStorageKey)
                }
                rescheduleAllReminders()
                lastAuthedUserId = nil
            } else {
                // ✅ If user changed, force a fresh pull baseline
                if lastAuthedUserId != session.userId {
                    HabitsSyncEngine.shared.resetPullState()
                    lastAuthedUserId = session.userId
                }

                HabitsSyncEngine.shared.enableSync()

                let key = cloudStorageKey(for: session.userId)
                loadHabits(storageKey: key)

                // ✅ TRUE SYNC: DO NOT seed defaults for authenticated users.
                // If the cloud is empty (because the user deleted everything),
                // the app should stay empty until the user adds habits.

                rescheduleAllReminders()
                startSyncIfNeeded()
            }

        case .unauthenticated, .unknown:
            HabitsSyncEngine.shared.disableSyncAndResetCloudState()

            loadHabits(storageKey: guestStorageKey)
            if habits.isEmpty {
                habits = defaultHabits()
                saveHabits(storageKey: guestStorageKey)
            }
            rescheduleAllReminders()
            lastAuthedUserId = nil
        }
    }

    private func startSyncIfNeeded() {
        guard startedSync == false else { return }
        startedSync = true

        HabitsSyncEngine.shared.start(
            habitsPublisher: $habits.eraseToAnyPublisher(),
            applyRemoteHabits: { [weak self] remote in
                guard let self else { return }

                // Decide mode based on current session
                let session = self.auth.currentUserSession
                let isAuthed = (session != nil && session?.isGuest == false)
                let userId = session?.userId

                if isAuthed {
                    // ✅ TRUE SYNC (AUTH): cloud is source of truth even if empty.
                    self.habits = remote
                    self.normalizeSortIndexes()
                    if let userId {
                        self.saveHabits(storageKey: self.cloudStorageKey(for: userId))
                    }
                    self.rescheduleAllReminders()
                    return
                }

                // ✅ GUEST/UNAUTH: keep old behavior (don’t wipe guest defaults on empty remote)
                if remote.isEmpty { return }

                self.habits = remote
                self.normalizeSortIndexes()
                self.saveHabits(storageKey: self.guestStorageKey)
                self.rescheduleAllReminders()
            }
        )
    }

    // MARK: - Persistence

    private func saveHabits() {
        saveHabits(storageKey: currentStorageKey())
    }

    private func saveHabits(storageKey: String) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(habits)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save habits: \(error)")
        }
    }

    private func loadHabits(storageKey: String) {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            habits = []
            return
        }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            habits = try decoder.decode([Habit].self, from: data)
        } catch {
            print("Failed to load habits: \(error)")
            habits = []
        }
    }

    private func currentStorageKey() -> String {
        if let session = auth.currentUserSession {
            if session.isGuest { return guestStorageKey }
            return cloudStorageKey(for: session.userId)
        }
        return guestStorageKey
    }

    private func defaultHabits() -> [Habit] {
        [
            Habit(name: "Read 20 minutes", isDoneToday: false, sortIndex: 0),
            Habit(name: "Workout", isDoneToday: false, sortIndex: 1),
            Habit(name: "Study / Learn", isDoneToday: false, sortIndex: 2),
            Habit(name: "Journal", isDoneToday: false, sortIndex: 3)
        ]
    }

    private func normalizeSortIndexes() {
        for i in habits.indices { habits[i].sortIndex = i }
    }

    private func rescheduleAllReminders() {
        for h in habits {
            FocusLocalNotificationManager.shared.cancelHabitReminder(habitId: h.id)
            if let date = h.reminderDate {
                FocusLocalNotificationManager.shared.scheduleHabitReminder(
                    habitId: h.id,
                    habitName: h.name,
                    date: date,
                    repeatOption: h.repeatOption
                )
            }
        }
    }
}
