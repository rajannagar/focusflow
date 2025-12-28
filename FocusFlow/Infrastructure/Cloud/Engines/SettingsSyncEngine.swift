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
        let db = SupabaseManager.shared.database

        // ✅ Avoid .single() so first-time users (0 rows) don't throw PGRST116
        let rows: [UserSettingsDTO] = try await db
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
            try await SupabaseManager.shared.database
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

        if let name = remote.displayName { settings.displayName = name }
        if let tag = remote.tagline { settings.tagline = tag }
        if let avatar = remote.avatarId { settings.avatarID = avatar }

        if let themeRaw = remote.selectedTheme, let theme = AppTheme(rawValue: themeRaw) {
            settings.selectedTheme = theme
        }
        if let profileThemeRaw = remote.profileTheme, let theme = AppTheme(rawValue: profileThemeRaw) {
            settings.profileTheme = theme
        }

        if let soundEnabled = remote.soundEnabled { settings.soundEnabled = soundEnabled }
        if let hapticsEnabled = remote.hapticsEnabled { settings.hapticsEnabled = hapticsEnabled }

        if let enabled = remote.dailyReminderEnabled { settings.dailyReminderEnabled = enabled }

        // ✅ dailyReminderHour/minute are get-only accessors; set dailyReminderTime
        let reminderHour = remote.dailyReminderHour
        let reminderMinute = remote.dailyReminderMinute
        if reminderHour != nil || reminderMinute != nil {
            let cal = Calendar.current
            var comps = cal.dateComponents([.year, .month, .day], from: settings.dailyReminderTime)
            comps.hour = reminderHour ?? settings.dailyReminderHour
            comps.minute = reminderMinute ?? settings.dailyReminderMinute
            if let newTime = cal.date(from: comps) {
                settings.dailyReminderTime = newTime
            }
        }

        if let soundRaw = remote.selectedFocusSound,
           let sound = FocusSound(rawValue: soundRaw) {
            settings.selectedFocusSound = sound
        }

        if let appRaw = remote.externalMusicApp {
            settings.selectedExternalMusicApp = AppSettings.ExternalMusicApp(rawValue: appRaw)
        }

        if let goal = remote.dailyGoalMinutes {
            settings.dailyGoalMinutes = goal
        }

        #if DEBUG
        print("[SettingsSyncEngine] Applied remote settings to local")
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
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, self.isRunning, !self.isApplyingRemote else { return }
                Task { await self.pushToRemote() }
            }
            .store(in: &cancellables)
    }
}
