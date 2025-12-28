//
//  SessionsSyncEngine.swift
//  FocusFlow
//
//  Syncs ProgressSession ↔ focus_sessions table
//  Updates user_stats table with aggregated data
//

import Foundation
import Combine
import Supabase

// MARK: - Remote Models

/// Matches the `focus_sessions` table schema
struct FocusSessionDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var startedAt: Date
    var durationSeconds: Int
    var sessionName: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case startedAt = "started_at"
        case durationSeconds = "duration_seconds"
        case sessionName = "session_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Matches the `user_stats` table schema
struct UserStatsDTO: Codable {
    let userId: UUID
    var lifetimeFocusSeconds: Int
    var lifetimeSessionCount: Int
    var lifetimeBestStreak: Int
    var currentStreak: Int
    var lastFocusDate: String? // Date as "YYYY-MM-DD"
    var totalXp: Int
    var currentLevel: Int
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case lifetimeFocusSeconds = "lifetime_focus_seconds"
        case lifetimeSessionCount = "lifetime_session_count"
        case lifetimeBestStreak = "lifetime_best_streak"
        case currentStreak = "current_streak"
        case lastFocusDate = "last_focus_date"
        case totalXp = "total_xp"
        case currentLevel = "current_level"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Sync Engine

@MainActor
final class SessionsSyncEngine {

    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()
    private var isRunning = false
    private var userId: UUID?

    private var isApplyingRemote = false

    /// Track which session IDs we've already synced
    private var syncedSessionIds = Set<UUID>()

    // MARK: - Start/Stop

    func start(userId: UUID) async throws {
        self.userId = userId
        self.isRunning = true

        // Initial pull
        try await pullFromRemote(userId: userId)

        // Observe local changes
        observeLocalChanges()
    }

    func stop() {
        isRunning = false
        userId = nil
        cancellables.removeAll()
        syncedSessionIds.removeAll()
    }

    // MARK: - Pull from Remote

    func pullFromRemote(userId: UUID) async throws {
        let db = SupabaseManager.shared.database

        // Fetch all sessions
        let remoteSessions: [FocusSessionDTO] = try await db
            .from("focus_sessions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("started_at", ascending: false)
            .execute()
            .value

        // Fetch user stats (optional - may not exist yet)
        let remoteStats: UserStatsDTO? = try? await db
            .from("user_stats")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        applyRemoteToLocal(sessions: remoteSessions, stats: remoteStats)

        // Track synced IDs
        syncedSessionIds = Set(remoteSessions.map { $0.id })

        #if DEBUG
        print("[SessionsSyncEngine] Pulled \(remoteSessions.count) sessions")
        #endif
    }

    // MARK: - Push Single Session

    /// Push a newly completed session to remote
    func pushSession(_ session: ProgressSession) async {
        guard isRunning, let userId = userId else { return }
        guard !syncedSessionIds.contains(session.id) else { return }

        let dto = FocusSessionDTO(
            id: session.id,
            userId: userId,
            startedAt: session.date,
            durationSeconds: Int(session.duration),
            sessionName: session.sessionName
        )

        do {
            try await SupabaseManager.shared.database
                .from("focus_sessions")
                .insert(dto)
                .execute()

            syncedSessionIds.insert(session.id)

            // Update stats after adding session
            await updateRemoteStats()

            #if DEBUG
            print("[SessionsSyncEngine] Pushed session \(session.id)")
            #endif
        } catch {
            #if DEBUG
            print("[SessionsSyncEngine] Push session error: \(error)")
            #endif
        }
    }

    // MARK: - Update Remote Stats

    private func updateRemoteStats() async {
        guard let userId = userId else { return }

        let store = ProgressStore.shared

        // ProgressStore computes these as derived properties
        let dto = UserStatsDTO(
            userId: userId,
            lifetimeFocusSeconds: Int(store.lifetimeFocusSeconds),
            lifetimeSessionCount: store.lifetimeSessionCount,
            lifetimeBestStreak: store.lifetimeBestStreak,
            currentStreak: 0, // TODO: Compute current streak
            lastFocusDate: lastFocusDateString(from: store),
            totalXp: 0, // TODO: XP system
            currentLevel: 1 // TODO: Level system
        )

        do {
            try await SupabaseManager.shared.database
                .from("user_stats")
                .upsert(dto, onConflict: "user_id")
                .execute()

            #if DEBUG
            print("[SessionsSyncEngine] Updated remote stats")
            #endif
        } catch {
            #if DEBUG
            print("[SessionsSyncEngine] Stats update error: \(error)")
            #endif
        }
    }

    private func lastFocusDateString(from store: ProgressStore) -> String? {
        guard let lastSession = store.sessions.first else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: lastSession.date)
    }

    // MARK: - Push All Local (for migration)

    /// Push all local sessions to remote (used for initial sync after sign-in)
    func pushAllLocalSessions() async {
        guard isRunning, let userId = userId else { return }

        let store = ProgressStore.shared
        let localSessions = store.sessions

        // Filter out already synced
        let newSessions = localSessions.filter { !syncedSessionIds.contains($0.id) }
        guard !newSessions.isEmpty else { return }

        let dtos = newSessions.map { session in
            FocusSessionDTO(
                id: session.id,
                userId: userId,
                startedAt: session.date,
                durationSeconds: Int(session.duration),
                sessionName: session.sessionName
            )
        }

        do {
            try await SupabaseManager.shared.database
                .from("focus_sessions")
                .upsert(dtos, onConflict: "id")
                .execute()

            syncedSessionIds.formUnion(newSessions.map { $0.id })
            await updateRemoteStats()

            #if DEBUG
            print("[SessionsSyncEngine] Pushed \(newSessions.count) local sessions to remote")
            #endif
        } catch {
            #if DEBUG
            print("[SessionsSyncEngine] Push all error: \(error)")
            #endif
        }
    }

    // MARK: - Apply Remote to Local

    private func applyRemoteToLocal(sessions: [FocusSessionDTO], stats: UserStatsDTO?) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }

        let store = ProgressStore.shared

        // Convert DTOs to local models
        let remoteSessions = sessions.map { dto in
            ProgressSession(
                id: dto.id,
                date: dto.startedAt,
                duration: TimeInterval(dto.durationSeconds),
                sessionName: dto.sessionName
            )
        }

        // Merge: add remote sessions that don't exist locally
        store.mergeRemoteSessions(remoteSessions)

        #if DEBUG
        print("[SessionsSyncEngine] Applied remote sessions to local")
        #endif
    }

    // MARK: - Observe Local Changes

    private func observeLocalChanges() {
        let store = ProgressStore.shared

        // Observe sessions array changes
        store.$sessions
            .dropFirst()
            .sink { [weak self] sessions in
                guard let self = self, self.isRunning, !self.isApplyingRemote else { return }

                // Find new sessions
                let newSessions = sessions.filter { !self.syncedSessionIds.contains($0.id) }
                for session in newSessions {
                    Task {
                        await self.pushSession(session)
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// Note:
// ProgressStore already implements `mergeRemoteSessions(_:)` and
// `applyRemoteSessionState(_:)` in Features/Progress/ProgressStore.swift.
// (Keeping those helpers in one place avoids duplicate symbol / redeclaration errors.)
