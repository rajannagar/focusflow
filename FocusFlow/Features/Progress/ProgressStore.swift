import Foundation
import Combine

// MARK: - ProgressSession (local-only)

struct ProgressSession: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let duration: TimeInterval          // seconds
    let sessionName: String?

    init(id: UUID = UUID(), date: Date = Date(), duration: TimeInterval, sessionName: String?) {
        self.id = id
        self.date = date
        self.duration = duration
        self.sessionName = sessionName
    }
}

// MARK: - ProgressStore (Namespace-aware, guest persists)

@MainActor
final class ProgressStore: ObservableObject {
    static let shared = ProgressStore()

    // MARK: - Published
    @Published private(set) var sessions: [ProgressSession] = []
    @Published var dailyGoalMinutes: Int = 60 {
        didSet {
            guard !isLoading else { return }
            persist()
            AppSyncManager.shared.goalDidUpdate(minutes: dailyGoalMinutes)
            
            // ✅ Record local timestamp for conflict resolution
            let namespace = activeNamespace
            if namespace != "guest" {
                LocalTimestampTracker.shared.recordLocalChange(field: "dailyGoalMinutes", namespace: namespace)
            }
            
            // ✅ Sync to Home Screen widgets
            WidgetDataManager.shared.syncAll()
        }
    }

    // MARK: - Storage
    private let defaults = UserDefaults.standard
    private let calendar = Calendar.autoupdatingCurrent
    private var isLoading = false

    private enum Keys {
        static let sessions = "ff_local_progress.sessions.v1"
        static let goalMinutes = "ff_local_progress.goalMinutes.v1"
    }

    // MARK: - Namespace
    private var activeNamespace: String = "guest"
    private var lastNamespace: String?
    private var cancellables = Set<AnyCancellable>()

    private func key(_ base: String) -> String {
        "\(base)_\(activeNamespace)"
    }

    private init() {
        applyAuthState(AuthManagerV2.shared.state)

        AuthManagerV2.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.applyAuthState(state)
            }
            .store(in: &cancellables)
    }

    // Made internal for GuestMigrationManager access
    func applyAuthState(_ state: CloudAuthState) {
        let newNamespace: String
        switch state {
        case .signedIn(let userId):
            newNamespace = userId.uuidString
        case .guest, .unknown, .signedOut:
            newNamespace = "guest"
        }

        // IMPORTANT:
        // We do NOT wipe guest storage. Guest is meant to persist locally.
        // Isolation is guaranteed by namespacing + race-safe switching.
        if newNamespace == activeNamespace, lastNamespace != nil { return }

        // ✅ Clear timestamps for OLD namespace when switching accounts (not new)
        // This prevents timestamp data from bleeding across accounts
        if let oldNamespace = lastNamespace, oldNamespace != "guest", oldNamespace != newNamespace {
            LocalTimestampTracker.shared.clearAllTimestamps(namespace: oldNamespace)
        }

        lastNamespace = activeNamespace
        activeNamespace = newNamespace

        load()
    }

    // MARK: - Derived stats

    var lifetimeFocusSeconds: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    var lifetimeSessionCount: Int {
        sessions.count
    }

    var totalToday: TimeInterval {
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        return sessions
            .filter { $0.date >= today && $0.date < tomorrow }
            .reduce(0) { $0 + $1.duration }
    }

    var lifetimeBestStreak: Int {
        Self.bestStreak(from: sessions, calendar: calendar)
    }

    // MARK: - Mutations

    func addSession(duration: TimeInterval, sessionName: String?) {
        addSession(duration: duration, sessionName: sessionName, date: Date())
    }

    func addSession(duration: TimeInterval, sessionName: String?, date: Date) {
        let safeDuration = max(0, duration)
        guard safeDuration > 0 else { return }

        let trimmed = (sessionName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let nameToStore: String? = trimmed.isEmpty ? nil : trimmed

        let s = ProgressSession(date: date, duration: safeDuration, sessionName: nameToStore)

        sessions.insert(s, at: 0)
        
        // ✅ Record timestamp for new session
        let namespace = activeNamespace
        if namespace != "guest" {
            LocalTimestampTracker.shared.recordLocalChange(field: "session_\(s.id.uuidString)", namespace: namespace)
        }
        
        persist()

        AppSyncManager.shared.sessionDidComplete(
            duration: safeDuration,
            sessionName: nameToStore ?? "Focus Session"
        )
        
        // ✅ Sync to Home Screen widgets
        WidgetDataManager.shared.syncAll()
    }

    func clearAll() {
        sessions.removeAll()
        persist()
        AppSyncManager.shared.forceRefresh()
    }
    
    /// Restores data from backup (used by DataBackupManager)
    func restore(sessions: [ProgressSession], dailyGoalMinutes: Int) {
        isLoading = true
        defer { isLoading = false }
        self.sessions = sessions
        self.dailyGoalMinutes = dailyGoalMinutes
        persist()
    }

    // MARK: - Persistence

    private func load() {
        isLoading = true
        defer { isLoading = false }

        // Goal minutes (namespaced)
        if defaults.object(forKey: key(Keys.goalMinutes)) != nil {
            dailyGoalMinutes = defaults.integer(forKey: key(Keys.goalMinutes))
        } else {
            dailyGoalMinutes = 60
        }

        // Sessions (namespaced)
        guard let data = defaults.data(forKey: key(Keys.sessions)) else {
            sessions = []
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            sessions = try decoder.decode([ProgressSession].self, from: data)
        } catch {
            sessions = []
        }
    }

    // Made internal for GuestMigrationManager access
    func persist() {
        defaults.set(dailyGoalMinutes, forKey: key(Keys.goalMinutes))

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(sessions)
            defaults.set(data, forKey: key(Keys.sessions))
        } catch {
            // best effort
        }
    }

    // MARK: - Streak helpers

    private static func bestStreak(from sessions: [ProgressSession], calendar: Calendar) -> Int {
        let days = Set(sessions.filter { $0.duration > 0 }.map { calendar.startOfDay(for: $0.date) })
        let sorted = days.sorted()
        guard !sorted.isEmpty else { return 0 }

        var best = 1
        var current = 1

        for i in 1..<sorted.count {
            let prev = sorted[i - 1]
            let curr = sorted[i]
            if let next = calendar.date(byAdding: .day, value: 1, to: prev), next == curr {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }

        return best
    }
}

// MARK: - Cloud Sync Extension

extension ProgressStore {
    func mergeRemoteSessions(_ remoteSessions: [ProgressSession]) {
        let existingIds = Set(sessions.map { $0.id })
        let newSessions = remoteSessions.filter { !existingIds.contains($0.id) }
        guard !newSessions.isEmpty else { return }

        var allSessions = sessions + newSessions
        allSessions.sort { $0.date > $1.date }

        isLoading = true
        defer { isLoading = false }

        sessions = allSessions
        persist()
    }
    
    /// Apply merged sessions with conflict resolution (used by sync engine)
    func applyMergedSessions(_ mergedSessions: [ProgressSession]) {
        isLoading = true
        defer { isLoading = false }
        sessions = mergedSessions
        persist()
        
        // ✅ Sync to Home Screen widgets after applying remote sessions
        WidgetDataManager.shared.syncAll()
    }

    func applyRemoteSessionState(_ newSessions: [ProgressSession]) {
        isLoading = true
        defer { isLoading = false }

        sessions = newSessions
        persist()
        
        // ✅ Sync to Home Screen widgets after applying remote sessions
        WidgetDataManager.shared.syncAll()
    }
}

// MARK: - TimeInterval Helpers

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
