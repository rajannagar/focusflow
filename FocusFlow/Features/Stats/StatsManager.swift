import Foundation
import Combine

// MARK: - Model

struct FocusSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval   // seconds
    let sessionName: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        duration: TimeInterval,
        sessionName: String? = nil
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.sessionName = sessionName
    }
}

struct DailyFocusStat: Identifiable {
    let id = UUID()
    let date: Date
    let totalDuration: TimeInterval
}

// MARK: - Stats Manager

@MainActor
final class StatsManager: ObservableObject {
    static let shared = StatsManager()

    // All recorded sessions (this is the ONLY thing totals are derived from)
    @Published private(set) var sessions: [FocusSession] = []

    // History-only hidden IDs (kept for future use; currently no UI uses this)
    @Published private(set) var hiddenHistorySessionIDs: Set<UUID> = [] {
        didSet { saveHiddenHistory() }
    }

    /// User-configurable daily goal in minutes
    @Published var dailyGoalMinutes: Int = 60 {
        didSet { saveGoal() }
    }

    // Lifetime stats (per-account namespace)
    @Published private(set) var lifetimeFocusSeconds: TimeInterval = 0
    @Published private(set) var lifetimeSessionCount: Int = 0
    @Published private(set) var lifetimeBestStreak: Int = 0

    // Base keys (we suffix these with a namespace)
    private let storageKeySessionsBase = "focus_sessions_v1"
    private let storageKeyGoalBase = "daily_goal_minutes_v1"

    private let storageKeyLifetimeFocusBase = "lifetime_focus_seconds_v1"
    private let storageKeyLifetimeCountBase = "lifetime_session_count_v1"
    private let storageKeyLifetimeBestStreakBase = "lifetime_best_streak_v1"

    private let storageKeyHiddenHistoryBase = "hidden_history_session_ids_v1"

    private let calendar = Calendar.current

    // Namespace handling
    private var activeNamespace: String = "guest"
    private var lastNamespace: String? = nil

    private var cancellables = Set<AnyCancellable>()

    // ✅ Start sync engine once
    private var didStartSyncEngine = false

    private init() {
        observeAuthChanges()

        // Load immediately based on current auth state (might be .unknown at launch).
        applyNamespace(for: AuthManager.shared.state)

        // ✅ Wire sync engine after local store is ready
        startSyncIfNeeded()
    }

    // MARK: - Public API (recording)

    func addSession(duration: TimeInterval, sessionName: String?) {
        guard duration > 0 else { return }

        let trimmedName = sessionName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameToStore = (trimmedName?.isEmpty == true) ? nil : trimmedName

        let session = FocusSession(duration: duration, sessionName: nameToStore)
        sessions.append(session)
        saveSessions()

        // Lifetime stats (never reduced)
        lifetimeFocusSeconds += duration
        lifetimeSessionCount += 1

        let currentBest = bestStreakFromCurrentSessions()
        if currentBest > lifetimeBestStreak {
            lifetimeBestStreak = currentBest
        }

        saveLifetime()
    }

    // MARK: - History-only actions (kept for later)

    func hideFromHistory(_ session: FocusSession) {
        hiddenHistorySessionIDs.insert(session.id)
    }

    func hideAllHistory() {
        hiddenHistorySessionIDs.formUnion(sessions.map { $0.id })
    }

    func unhideAllHistory() {
        hiddenHistorySessionIDs.removeAll()
    }

    // MARK: - Stats-changing actions (kept for later admin/tools)

    func clearDayFromStats(_ dayStart: Date) {
        let start = calendar.startOfDay(for: dayStart)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return }

        let removedIDs: [UUID] = sessions
            .filter { $0.date >= start && $0.date < end }
            .map { $0.id }

        sessions.removeAll { $0.date >= start && $0.date < end }
        saveSessions()

        if !removedIDs.isEmpty {
            hiddenHistorySessionIDs.subtract(removedIDs)
        }
    }

    func clearAll() {
        sessions.removeAll()
        saveSessions()

        hiddenHistorySessionIDs.removeAll()

        lifetimeFocusSeconds = 0
        lifetimeSessionCount = 0
        lifetimeBestStreak = 0
        saveLifetime()
    }

    // MARK: - Aggregates (based on sessions ONLY)

    var totalToday: TimeInterval {
        let startOfToday = calendar.startOfDay(for: Date())
        return sessions
            .filter { $0.date >= startOfToday }
            .reduce(0) { $0 + $1.duration }
    }

    var totalThisWeek: TimeInterval {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return 0 }
        return sessions
            .filter { $0.date >= weekInterval.start && $0.date < weekInterval.end }
            .reduce(0) { $0 + $1.duration }
    }

    var totalAllTime: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    var recentSessions: [FocusSession] {
        sessions
            .sorted { $0.date > $1.date }
            .prefix(60)
            .map { $0 }
    }

    var visibleHistorySessions: [FocusSession] {
        sessions
            .filter { !hiddenHistorySessionIDs.contains($0.id) }
            .sorted { $0.date > $1.date }
            .prefix(60)
            .map { $0 }
    }

    var last7DaysStats: [DailyFocusStat] {
        let today = calendar.startOfDay(for: Date())

        return (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today),
                  let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { return nil }

            let total = sessions
                .filter { $0.date >= day && $0.date < nextDay }
                .reduce(0) { $0 + $1.duration }

            return DailyFocusStat(date: day, totalDuration: total)
        }
    }

    // MARK: - Auth → Namespace wiring

    private func observeAuthChanges() {
        AuthManager.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                guard let self else { return }
                self.applyNamespace(for: newState)
            }
            .store(in: &cancellables)
    }

    private func namespace(for state: AuthState) -> String {
        switch state {
        case .authenticated(let session):
            return session.isGuest ? "guest" : session.userId.uuidString
        case .unauthenticated, .unknown:
            return "guest"
        }
    }

    /// Switch Stats storage to the right user namespace.
    /// Also prevents account bleed when logging out / switching users.
    private func applyNamespace(for state: AuthState) {
        let newNamespace = namespace(for: state)

        if newNamespace == activeNamespace, lastNamespace != nil {
            return
        }

        // If we are transitioning from a real account → guest,
        // reset guest stats to defaults and reset cloud sync engine state.
        if newNamespace == "guest", let last = lastNamespace, last != "guest" {
            wipeLocalStorage(namespace: "guest")
            FocusStatsSyncEngine.shared.disableSyncAndResetCloudState()
        }

        lastNamespace = activeNamespace
        activeNamespace = newNamespace

        // Reset in-memory first (avoid mixing UI)
        sessions = []
        hiddenHistorySessionIDs = []
        dailyGoalMinutes = 60
        lifetimeFocusSeconds = 0
        lifetimeSessionCount = 0
        lifetimeBestStreak = 0

        // Load from the namespace
        loadSessions()
        loadGoal()
        loadLifetime()
        loadHiddenHistory()

        print("StatsManager: active namespace -> \(activeNamespace)")
    }

    // MARK: - ✅ Sync engine wiring

    private func startSyncIfNeeded() {
        guard didStartSyncEngine == false else { return }
        didStartSyncEngine = true

        // Publisher for "settings snapshot"
        let settingsSnapshotPublisher: AnyPublisher<FocusStatsSettingsLocal, Never> =
            Publishers.CombineLatest4(
                $dailyGoalMinutes,
                $hiddenHistorySessionIDs,
                $lifetimeFocusSeconds,
                Publishers.CombineLatest($lifetimeSessionCount, $lifetimeBestStreak)
            )
            .map { goal, hidden, focusSeconds, pair in
                FocusStatsSettingsLocal(
                    dailyGoalMinutes: goal,
                    hiddenHistorySessionIDs: hidden,
                    lifetimeFocusSeconds: focusSeconds,
                    lifetimeSessionCount: pair.0,
                    lifetimeBestStreak: pair.1
                )
            }
            .eraseToAnyPublisher()

        FocusStatsSyncEngine.shared.start(
            sessionsPublisher: $sessions.eraseToAnyPublisher(),
            settingsPublisher: settingsSnapshotPublisher,
            applyRemoteSessions: { [weak self] cloudSessions in
                guard let self else { return }
                self.replaceSessionsFromSyncEngine(cloudSessions)
                self.bumpLifetimeToAtLeastCurrentSessions()
            },
            applyRemoteSettings: { [weak self] cloudSettings in
                guard let self else { return }
                self.dailyGoalMinutes = max(1, cloudSettings.dailyGoalMinutes)
                self.hiddenHistorySessionIDs = cloudSettings.hiddenHistorySessionIDs

                self.lifetimeFocusSeconds = cloudSettings.lifetimeFocusSeconds
                self.lifetimeSessionCount = cloudSettings.lifetimeSessionCount
                self.lifetimeBestStreak = cloudSettings.lifetimeBestStreak

                self.saveLifetime()
            }
        )

        print("StatsManager: FocusStatsSyncEngine started")
    }

    // MARK: - Namespaced keys

    private func key(_ base: String) -> String {
        "\(base)_\(activeNamespace)"
    }

    private func wipeLocalStorage(namespace: String) {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "\(storageKeySessionsBase)_\(namespace)")
        defaults.removeObject(forKey: "\(storageKeyGoalBase)_\(namespace)")
        defaults.removeObject(forKey: "\(storageKeyLifetimeFocusBase)_\(namespace)")
        defaults.removeObject(forKey: "\(storageKeyLifetimeCountBase)_\(namespace)")
        defaults.removeObject(forKey: "\(storageKeyLifetimeBestStreakBase)_\(namespace)")
        defaults.removeObject(forKey: "\(storageKeyHiddenHistoryBase)_\(namespace)")
        print("StatsManager: wiped local storage for namespace=\(namespace)")
    }

    // MARK: - Persistence

    private func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: key(storageKeySessionsBase))
        } catch {
            print("Failed to save focus sessions: \(error)")
        }
    }

    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: key(storageKeySessionsBase)) else { return }
        do {
            let decoded = try JSONDecoder().decode([FocusSession].self, from: data)
            self.sessions = decoded
        } catch {
            print("Failed to load focus sessions: \(error)")
        }
    }

    private func saveGoal() {
        UserDefaults.standard.set(dailyGoalMinutes, forKey: key(storageKeyGoalBase))
    }

    private func loadGoal() {
        let stored = UserDefaults.standard.integer(forKey: key(storageKeyGoalBase))
        self.dailyGoalMinutes = stored > 0 ? stored : 60
    }

    private func saveLifetime() {
        let defaults = UserDefaults.standard
        defaults.set(lifetimeFocusSeconds, forKey: key(storageKeyLifetimeFocusBase))
        defaults.set(lifetimeSessionCount, forKey: key(storageKeyLifetimeCountBase))
        defaults.set(lifetimeBestStreak, forKey: key(storageKeyLifetimeBestStreakBase))
    }

    private func loadLifetime() {
        let defaults = UserDefaults.standard
        self.lifetimeFocusSeconds = defaults.double(forKey: key(storageKeyLifetimeFocusBase))
        self.lifetimeSessionCount = defaults.integer(forKey: key(storageKeyLifetimeCountBase))
        self.lifetimeBestStreak = defaults.integer(forKey: key(storageKeyLifetimeBestStreakBase))
    }

    private func saveHiddenHistory() {
        let ids = hiddenHistorySessionIDs.map { $0.uuidString }
        UserDefaults.standard.set(ids, forKey: key(storageKeyHiddenHistoryBase))
    }

    private func loadHiddenHistory() {
        let ids = UserDefaults.standard.stringArray(forKey: key(storageKeyHiddenHistoryBase)) ?? []
        self.hiddenHistorySessionIDs = Set(ids.compactMap(UUID.init(uuidString:)))
    }

    // MARK: - Internal helpers

    private func bestStreakFromCurrentSessions() -> Int {
        let daysWithFocus: Set<Date> = Set(
            sessions
                .filter { $0.duration > 0 }
                .map { calendar.startOfDay(for: $0.date) }
        )

        if daysWithFocus.isEmpty { return 0 }

        let sorted = daysWithFocus.sorted()
        var best = 1
        var temp = 1

        for i in 1..<sorted.count {
            if let prev = calendar.date(byAdding: .day, value: -1, to: sorted[i]),
               calendar.isDate(prev, inSameDayAs: sorted[i - 1]) {
                temp += 1
            } else {
                best = max(best, temp)
                temp = 1
            }
        }

        return max(best, temp)
    }

    // MARK: - ✅ Sync Engine hooks

    func replaceSessionsFromSyncEngine(_ newSessions: [FocusSession]) {
        sessions = newSessions
        saveSessions()

        let keep = Set(newSessions.map { $0.id })
        if !hiddenHistorySessionIDs.isEmpty {
            hiddenHistorySessionIDs = hiddenHistorySessionIDs.intersection(keep)
        }
    }

    func bumpLifetimeToAtLeastCurrentSessions() {
        let total = sessions.reduce(0) { $0 + $1.duration }
        let count = sessions.count
        let best = bestStreakFromCurrentSessions()

        if total > lifetimeFocusSeconds { lifetimeFocusSeconds = total }
        if count > lifetimeSessionCount { lifetimeSessionCount = count }
        if best > lifetimeBestStreak { lifetimeBestStreak = best }

        saveLifetime()
    }
}

// MARK: - Helpers

extension TimeInterval {
    var asReadableDuration: String {
        let totalMinutes = Int(self / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%d min", minutes)
        }
    }
}
