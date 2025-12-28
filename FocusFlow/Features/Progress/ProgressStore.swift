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

// MARK: - ProgressStore (with Cloud Sync support)

@MainActor
final class ProgressStore: ObservableObject {
    static let shared = ProgressStore()

    // MARK: - Published
    // Changed to internal(set) to allow sync engine to update
    @Published internal(set) var sessions: [ProgressSession] = []
    @Published var dailyGoalMinutes: Int = 60 {
        didSet {
            guard !isLoading else { return }
            persist()
            AppSyncManager.shared.goalDidUpdate(minutes: dailyGoalMinutes)
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

    private init() {
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

        // newest first
        sessions.insert(s, at: 0)
        persist()

        AppSyncManager.shared.sessionDidComplete(
            duration: safeDuration,
            sessionName: nameToStore ?? "Focus Session"
        )
    }

    func clearAll() {
        sessions.removeAll()
        persist()
        AppSyncManager.shared.forceRefresh()
    }

    // MARK: - Persistence

    private func load() {
        isLoading = true
        defer { isLoading = false }

        if defaults.object(forKey: Keys.goalMinutes) != nil {
            dailyGoalMinutes = defaults.integer(forKey: Keys.goalMinutes)
        }

        guard let data = defaults.data(forKey: Keys.sessions) else {
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

    private func persist() {
        defaults.set(dailyGoalMinutes, forKey: Keys.goalMinutes)

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(sessions)
            defaults.set(data, forKey: Keys.sessions)
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
    
    /// Merge remote sessions into local store
    func mergeRemoteSessions(_ remoteSessions: [ProgressSession]) {
        let existingIds = Set(sessions.map { $0.id })
        let newSessions = remoteSessions.filter { !existingIds.contains($0.id) }
        
        guard !newSessions.isEmpty else { return }
        
        // Add new sessions and sort by date (newest first)
        var allSessions = sessions + newSessions
        allSessions.sort { $0.date > $1.date }
        
        // Update without triggering persist (we're receiving from remote)
        isLoading = true
        defer { isLoading = false }
        
        sessions = allSessions
        persist()
    }
    
    /// Apply remote session state (replaces local with remote)
    func applyRemoteSessionState(_ newSessions: [ProgressSession]) {
        isLoading = true
        defer { isLoading = false }
        
        sessions = newSessions
        persist()
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
