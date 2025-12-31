//
//  SettingsSyncEngine.swift
//  FocusFlow
//
//  Syncs AppSettings ↔ user_settings table.
//  Safe for first-time users (0 rows) and avoids .single() PGRST116.
//

import Foundation
import Combine
import Supabase

// MARK: - Remote Model

/// Matches the `user_settings` table schema
struct UserSettingsDTO: Codable {
    let userId: UUID
    var displayName: String?
    var tagline: String?
    var avatarId: String?
    var selectedTheme: String?
    var profileTheme: String?
    var soundEnabled: Bool?
    var hapticsEnabled: Bool?
    var dailyReminderEnabled: Bool?
    var dailyReminderHour: Int?
    var dailyReminderMinute: Int?
    var selectedFocusSound: String?
    var externalMusicApp: String?
    var dailyGoalMinutes: Int?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case tagline
        case avatarId = "avatar_id"
        case selectedTheme = "selected_theme"
        case profileTheme = "profile_theme"
        case soundEnabled = "sound_enabled"
        case hapticsEnabled = "haptics_enabled"
        case dailyReminderEnabled = "daily_reminder_enabled"
        case dailyReminderHour = "daily_reminder_hour"
        case dailyReminderMinute = "daily_reminder_minute"
        case selectedFocusSound = "selected_focus_sound"
        case externalMusicApp = "external_music_app"
        case dailyGoalMinutes = "daily_goal_minutes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Sync Engine

@MainActor
final class SettingsSyncEngine {

    private var cancellables = Set<AnyCancellable>()
    private var isRunning = false
    private var userId: UUID?
    private var isApplyingRemote = false

    // MARK: - Start / Stop

    func start(userId: UUID) async throws {
        self.userId = userId
        self.isRunning = true

        try await pullFromRemote(userId: userId)
        observeLocalChanges()
    }

    func stop() {
        isRunning = false
        userId = nil
        cancellables.removeAll()
    }

    // MARK: - Pull

    func pullFromRemote(userId: UUID) async throws {
        let client = SupabaseManager.shared.client

        // ✅ Avoid .single() so first-time users (0 rows) don't throw PGRST116
        let rows: [UserSettingsDTO] = try await client
            .from("user_settings")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        if let remote = rows.first {
            applyRemoteToLocal(remote)
        } else {
            // No settings row yet — totally fine. It will be created on first push.
            #if DEBUG
            print("[SettingsSyncEngine] No remote user_settings row yet (first-time user).")
            #endif
        }

        #if DEBUG
        print("[SettingsSyncEngine] Pulled settings from remote")
        #endif
    }

    // MARK: - Push

    /// Force immediate push (bypasses debounce) - use when app is entering background/terminating
    func forcePushNow() async {
        guard isRunning else { return }
        await pushToRemote()
    }

    private func pushToRemote() async {
        guard isRunning, let userId = userId else { return }
        guard !isApplyingRemote else { return }

        let settings = AppSettings.shared

        let dto = UserSettingsDTO(
            userId: userId,
            displayName: settings.displayName,
            tagline: settings.tagline,
            avatarId: settings.avatarID,
            selectedTheme: settings.selectedTheme.rawValue,
            profileTheme: settings.profileTheme.rawValue,
            soundEnabled: settings.soundEnabled,
            hapticsEnabled: settings.hapticsEnabled,
            dailyReminderEnabled: settings.dailyReminderEnabled,
            dailyReminderHour: settings.dailyReminderHour,
            dailyReminderMinute: settings.dailyReminderMinute,
            selectedFocusSound: settings.selectedFocusSound?.rawValue,
            externalMusicApp: settings.externalMusicApp?.rawValue,
            dailyGoalMinutes: settings.dailyGoalMinutes
        )

        do {
            try await SupabaseManager.shared.client
                .from("user_settings")
                .upsert(dto, onConflict: "user_id")
                .execute()

            #if DEBUG
            print("[SettingsSyncEngine] Pushed settings to remote")
            #endif
        } catch {
            #if DEBUG
            print("[SettingsSyncEngine] Push error: \(error)")
            #endif
        }
    }

    // MARK: - Apply Remote

    private func applyRemoteToLocal(_ remote: UserSettingsDTO) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }

        let settings = AppSettings.shared
        guard let userId = userId else { return }
        let namespace = userId.uuidString
        let remoteTimestamp = remote.updatedAt ?? remote.createdAt

        // ✅ NEW: Field-level conflict resolution using timestamps
        // Only apply remote values if local is NOT newer

        if let name = remote.displayName {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "displayName", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                // Only set if value actually changed to prevent unnecessary publisher fires
                if settings.displayName != name {
                    settings.displayName = name
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "displayName", namespace: namespace)
            }
        }

        if let tag = remote.tagline {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "tagline", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                if settings.tagline != tag {
                    settings.tagline = tag
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "tagline", namespace: namespace)
            }
        }

        if let avatar = remote.avatarId {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "avatarID", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                if settings.avatarID != avatar {
                    settings.avatarID = avatar
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "avatarID", namespace: namespace)
            }
        }

        if let themeRaw = remote.selectedTheme, let theme = AppTheme(rawValue: themeRaw) {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "selectedTheme", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                if settings.selectedTheme != theme {
                    settings.selectedTheme = theme
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "selectedTheme", namespace: namespace)
            }
        }

        if let profileThemeRaw = remote.profileTheme, let theme = AppTheme(rawValue: profileThemeRaw) {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "profileTheme", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                if settings.profileTheme != theme {
                    settings.profileTheme = theme
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "profileTheme", namespace: namespace)
            }
        }

        if let soundEnabled = remote.soundEnabled {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "soundEnabled", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                if settings.soundEnabled != soundEnabled {
                    settings.soundEnabled = soundEnabled
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "soundEnabled", namespace: namespace)
            }
        }

        if let hapticsEnabled = remote.hapticsEnabled {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "hapticsEnabled", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                if settings.hapticsEnabled != hapticsEnabled {
                    settings.hapticsEnabled = hapticsEnabled
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "hapticsEnabled", namespace: namespace)
            }
        }

        if let enabled = remote.dailyReminderEnabled {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "dailyReminderEnabled", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                if settings.dailyReminderEnabled != enabled {
                    settings.dailyReminderEnabled = enabled
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "dailyReminderEnabled", namespace: namespace)
            }
        }

        // ✅ dailyReminderHour/minute are get-only accessors; set dailyReminderTime
        let reminderHour = remote.dailyReminderHour
        let reminderMinute = remote.dailyReminderMinute
        if reminderHour != nil || reminderMinute != nil {
            if !LocalTimestampTracker.shared.isLocalNewer(field: "dailyReminderTime", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                let cal = Calendar.current
                var comps = cal.dateComponents([.year, .month, .day], from: settings.dailyReminderTime)
                comps.hour = reminderHour ?? settings.dailyReminderHour
                comps.minute = reminderMinute ?? settings.dailyReminderMinute
                if let newTime = cal.date(from: comps) {
                    // Only set if time actually changed
                    let oldComps = cal.dateComponents([.hour, .minute], from: settings.dailyReminderTime)
                    if oldComps.hour != comps.hour || oldComps.minute != comps.minute {
                        settings.dailyReminderTime = newTime
                    }
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "dailyReminderTime", namespace: namespace)
            }
        }

        // ✅ Sound should only be restored from session persistence, not from remote sync
        // Skip applying sound from remote - it will be restored by timer restoration if session is active

        // ✅ Sound and external app should only be restored from session persistence, not from remote sync
        // Check if there's an active session - if not, don't apply sound/app from remote
        let defaults = UserDefaults.standard
        let isSessionActive = defaults.bool(forKey: "FocusFlow.focusSession.isActive")
        
        if !isSessionActive {
            // No session active - clear sound/app (they should only exist during sessions)
            settings.selectedFocusSound = nil
            settings.selectedExternalMusicApp = nil
        }
        // If session is active, sound/app will be restored by timer restoration, not from remote sync

        if let goal = remote.dailyGoalMinutes {
            // ✅ Check if local is newer before applying remote daily goal
            if !LocalTimestampTracker.shared.isLocalNewer(field: "dailyGoalMinutes", namespace: namespace, remoteTimestamp: remoteTimestamp) {
                if settings.dailyGoalMinutes != goal {
                    settings.dailyGoalMinutes = goal
                }
                LocalTimestampTracker.shared.clearLocalTimestamp(field: "dailyGoalMinutes", namespace: namespace)
            }
        }

        // ✅ Sync to Home Screen widgets after applying remote settings
        WidgetDataManager.shared.syncAll()
        
        #if DEBUG
        print("[SettingsSyncEngine] Applied remote settings to local (with conflict resolution)")
        #endif
    }

    // MARK: - Observe Local Changes

    private func observeLocalChanges() {
        let settings = AppSettings.shared
        let progress = ProgressStore.shared

        let publishers: [AnyPublisher<Void, Never>] = [
            settings.$displayName.map { _ in () }.eraseToAnyPublisher(),
            settings.$tagline.map { _ in () }.eraseToAnyPublisher(),
            settings.$avatarID.map { _ in () }.eraseToAnyPublisher(),
            settings.$selectedTheme.map { _ in () }.eraseToAnyPublisher(),
            settings.$profileTheme.map { _ in () }.eraseToAnyPublisher(),
            settings.$soundEnabled.map { _ in () }.eraseToAnyPublisher(),
            settings.$hapticsEnabled.map { _ in () }.eraseToAnyPublisher(),
            settings.$dailyReminderEnabled.map { _ in () }.eraseToAnyPublisher(),
            settings.$dailyReminderTime.map { _ in () }.eraseToAnyPublisher(),
            settings.$selectedFocusSound.map { _ in () }.eraseToAnyPublisher(),
            settings.$selectedExternalMusicApp.map { _ in () }.eraseToAnyPublisher(),
            progress.$dailyGoalMinutes.map { _ in () }.eraseToAnyPublisher()
        ]

        Publishers.MergeMany(publishers)
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main) // Reduced from 1s to 0.5s for faster sync
            .sink { [weak self] _ in
                guard let self = self, self.isRunning, !self.isApplyingRemote else { return }
                
                // ✅ NEW: Enqueue change in sync queue for reliability
                // This ensures changes are never lost, even if app is killed
                // The queue will process and push automatically
                Task { @MainActor in
                    guard AuthManagerV2.shared.state.userId != nil else { return }
                    
                    // Create a simple marker data (just to track that settings changed)
                    // The actual sync will read from AppSettings directly
                    struct SettingsMarker: Codable {
                        let settingsChanged: Bool
                        let timestamp: Double
                    }
                    let marker = SettingsMarker(settingsChanged: true, timestamp: Date().timeIntervalSince1970)
                    if let data = try? JSONEncoder().encode(marker) {
                        SyncQueue.shared.enqueueSettingsChange(data: data)
                    }
                }
                
                // ✅ REMOVED: Immediate push - let the queue handle it to prevent loops
                // The queue will process and push, avoiding double-push cycles
            }
            .store(in: &cancellables)
    }
}
