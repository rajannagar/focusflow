//
//  SettingsSyncEngine.swift
//  FocusFlow
//
//  Syncs AppSettings ↔ user_settings table.
//  Handles: profile info, theme, sounds, daily reminder, daily goal
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
    
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var isRunning = false
    private var userId: UUID?
    
    /// Flag to prevent save loops during remote apply
    private var isApplyingRemote = false
    
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
    }
    
    // MARK: - Pull from Remote
    
    func pullFromRemote(userId: UUID) async throws {
        let db = SupabaseManager.shared.database
        
        let response: UserSettingsDTO? = try await db
            .from("user_settings")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
        if let remote = response {
            applyRemoteToLocal(remote)
        }
        
        #if DEBUG
        print("[SettingsSyncEngine] Pulled settings from remote")
        #endif
    }
    
    // MARK: - Push to Remote
    
    private func pushToRemote() async {
        guard isRunning, let userId = userId else { return }
        guard !isApplyingRemote else { return }
        
        let settings = AppSettings.shared
        
        let dto = UserSettingsDTO(
            userId: userId,
            displayName: settings.displayName.isEmpty ? nil : settings.displayName,
            tagline: settings.tagline.isEmpty ? nil : settings.tagline,
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
    
    // MARK: - Apply Remote to Local
    
    private func applyRemoteToLocal(_ remote: UserSettingsDTO) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }
        
        let settings = AppSettings.shared
        
        // Profile
        if let name = remote.displayName {
            settings.displayName = name
        }
        if let tagline = remote.tagline {
            settings.tagline = tagline
        }
        if let avatarId = remote.avatarId {
            settings.avatarID = avatarId
        }
        
        // Themes
        if let themeRaw = remote.selectedTheme,
           let theme = AppTheme(rawValue: themeRaw) {
            settings.selectedTheme = theme
        }
        if let profileThemeRaw = remote.profileTheme,
           let profileTheme = AppTheme(rawValue: profileThemeRaw) {
            settings.profileTheme = profileTheme
        }
        
        // Sounds & Haptics
        if let soundEnabled = remote.soundEnabled {
            settings.soundEnabled = soundEnabled
        }
        if let hapticsEnabled = remote.hapticsEnabled {
            settings.hapticsEnabled = hapticsEnabled
        }
        
        // Daily Reminder
        if let enabled = remote.dailyReminderEnabled {
            settings.dailyReminderEnabled = enabled
        }
        if let hour = remote.dailyReminderHour {
            settings.dailyReminderHour = hour
        }
        if let minute = remote.dailyReminderMinute {
            settings.dailyReminderMinute = minute
        }
        
        // Focus Settings
        if let soundRaw = remote.selectedFocusSound,
           let sound = FocusSound(rawValue: soundRaw) {
            settings.selectedFocusSound = sound
        }
        if let appRaw = remote.externalMusicApp,
           let app = ExternalMusicApp(rawValue: appRaw) {
            settings.externalMusicApp = app
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
        
        // Observe changes via Combine publishers
        // Debounce to avoid rapid-fire updates
        
        Publishers.MergeMany(
            settings.$displayName.map { _ in () },
            settings.$tagline.map { _ in () },
            settings.$avatarID.map { _ in () },
            settings.$selectedTheme.map { _ in () },
            settings.$profileTheme.map { _ in () },
            settings.$soundEnabled.map { _ in () },
            settings.$hapticsEnabled.map { _ in () },
            settings.$dailyReminderEnabled.map { _ in () },
            settings.$dailyReminderHour.map { _ in () },
            settings.$dailyReminderMinute.map { _ in () },
            settings.$selectedFocusSound.map { _ in () },
            settings.$externalMusicApp.map { _ in () },
            settings.$dailyGoalMinutes.map { _ in () }
        )
        .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            guard let self = self, self.isRunning, !self.isApplyingRemote else { return }
            Task {
                await self.pushToRemote()
            }
        }
        .store(in: &cancellables)
    }
}
