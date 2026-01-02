//
//  ProGatingHelper.swift
//  FocusFlow
//
//  Created on January 2, 2026.
//
//  Centralized utility for Pro vs Free feature gating.
//  All gating logic lives here to ensure consistency across the app.
//

import Foundation
import SwiftUI

// MARK: - Cloud Sync Status

/// Describes the current state of cloud sync capability
enum CloudSyncStatus: Equatable {
    case active          // Pro + SignedIn → fully syncing
    case needsSignIn     // Pro + Guest → has Pro but no account to sync
    case needsUpgrade    // Free (any auth state) → needs Pro subscription
    
    var message: String {
        switch self {
        case .active:
            return "Cloud Sync: Active"
        case .needsSignIn:
            return "Sign in to sync across devices"
        case .needsUpgrade:
            return "Upgrade to Pro for cloud sync"
        }
    }
    
    var icon: String {
        switch self {
        case .active:
            return "checkmark.icloud.fill"
        case .needsSignIn:
            return "person.crop.circle.badge.plus"
        case .needsUpgrade:
            return "icloud.slash"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .active:
            return .green
        case .needsSignIn:
            return .orange
        case .needsUpgrade:
            return .gray
        }
    }
}

// MARK: - Pro Gating Helper

@MainActor
final class ProGatingHelper: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ProGatingHelper()
    
    private init() {}
    
    // MARK: - Free Tier Limits
    
    /// Maximum number of active (incomplete) tasks for free users
    static let freeTaskLimit = 3
    
    /// Maximum number of task reminders for free users
    static let freeReminderLimit = 1
    
    /// Number of days of history visible to free users
    static let freeHistoryDays = 3
    
    /// Number of default presets free users can view/use (Deep Work, Study, Writing)
    static let freePresetLimit = 3
    
    // MARK: - Free Content Sets
    
    /// Themes available to free users
    static let freeThemes: Set<AppTheme> = [.forest, .neon]
    
    /// Sounds available to free users
    static let freeSounds: Set<FocusSound> = [.lightRainAmbient, .fireplace, .soundAmbience]
    
    /// Ambiance modes available to free users
    static let freeAmbianceModes: Set<AmbientMode> = [.minimal, .stars, .forest]
    
    /// Default preset names that are free (first 3)
    static let freePresetNames: Set<String> = ["Deep Work", "Study", "Writing"]
    
    // MARK: - Pro Status
    
    /// Returns true if user has Pro subscription (via Apple ID)
    var isPro: Bool {
        ProEntitlementManager.shared.isPro
    }
    
    /// Returns true if user can use cloud sync (Pro + SignedIn)
    var canUseCloudSync: Bool {
        isPro && AuthManagerV2.shared.state.isSignedIn
    }
    
    /// Returns the current cloud sync status
    var cloudSyncStatus: CloudSyncStatus {
        if !isPro {
            return .needsUpgrade
        }
        if AuthManagerV2.shared.state.isSignedIn {
            return .active
        }
        return .needsSignIn
    }
    
    // MARK: - Theme Gating
    
    /// Returns true if the theme is available (free or user has Pro)
    func isThemeAvailable(_ theme: AppTheme) -> Bool {
        isPro || Self.freeThemes.contains(theme)
    }
    
    /// Returns true if the theme requires Pro
    func isThemeLocked(_ theme: AppTheme) -> Bool {
        !Self.freeThemes.contains(theme) && !isPro
    }
    
    // MARK: - Sound Gating
    
    /// Returns true if the sound is available (free or user has Pro)
    func isSoundAvailable(_ sound: FocusSound) -> Bool {
        isPro || Self.freeSounds.contains(sound)
    }
    
    /// Returns true if the sound requires Pro
    func isSoundLocked(_ sound: FocusSound) -> Bool {
        !Self.freeSounds.contains(sound) && !isPro
    }
    
    // MARK: - Ambiance Gating
    
    /// Returns true if the ambiance mode is available (free or user has Pro)
    func isAmbianceAvailable(_ mode: AmbientMode) -> Bool {
        isPro || Self.freeAmbianceModes.contains(mode)
    }
    
    /// Returns true if the ambiance mode requires Pro
    func isAmbianceLocked(_ mode: AmbientMode) -> Bool {
        !Self.freeAmbianceModes.contains(mode) && !isPro
    }
    
    // MARK: - Preset Gating
    
    /// Returns true if user can create custom presets
    var canCreatePresets: Bool {
        isPro
    }
    
    /// Returns true if user can edit presets
    var canEditPresets: Bool {
        isPro
    }
    
    /// Returns true if the preset is available to use
    /// - Free users can use first 3 default presets (Deep Work, Study, Writing)
    /// - Pro users can use all presets
    func isPresetAvailable(name: String, isSystemDefault: Bool) -> Bool {
        if isPro { return true }
        // Free users can only use the first 3 default presets
        return isSystemDefault && Self.freePresetNames.contains(name)
    }
    
    /// Returns true if the preset requires Pro
    func isPresetLocked(name: String, isSystemDefault: Bool) -> Bool {
        if isPro { return false }
        // Locked if not in the free preset names
        return !Self.freePresetNames.contains(name)
    }
    
    // MARK: - Task Gating
    
    /// Returns true if user can add more tasks
    /// - Parameter currentActiveCount: Number of currently active (incomplete) tasks
    func canAddTask(currentActiveCount: Int) -> Bool {
        isPro || currentActiveCount < Self.freeTaskLimit
    }
    
    /// Returns the number of remaining tasks user can add
    func remainingTasks(currentActiveCount: Int) -> Int {
        if isPro { return Int.max }
        return max(0, Self.freeTaskLimit - currentActiveCount)
    }
    
    // MARK: - Reminder Gating
    
    /// Returns true if user can add more task reminders
    /// - Parameter currentReminderCount: Number of tasks that have reminders set
    func canAddReminder(currentReminderCount: Int) -> Bool {
        isPro || currentReminderCount < Self.freeReminderLimit
    }
    
    // MARK: - History Gating
    
    /// Returns the cutoff date for history (sessions before this are locked)
    var historyLimitDate: Date? {
        if isPro { return nil } // No limit for Pro
        return Calendar.current.date(byAdding: .day, value: -Self.freeHistoryDays, to: Date())
    }
    
    /// Returns true if the session date is within the free history limit
    func isSessionVisible(date: Date) -> Bool {
        if isPro { return true }
        guard let limitDate = historyLimitDate else { return true }
        return date >= limitDate
    }
    
    // MARK: - Feature Gates (Pro-Only Features)
    
    /// XP & Levels system
    var canAccessXPLevels: Bool { isPro }
    
    /// Journey view with daily/weekly summaries
    var canAccessJourney: Bool { isPro }
    
    /// Live Activity / Dynamic Island
    var canUseLiveActivity: Bool { isPro }
    
    /// External music app integration
    var canUseExternalMusic: Bool { isPro }
    
    /// Medium and Large widgets (Small is free but view-only)
    var canUseFullWidgets: Bool { isPro }
    
    /// Widget interactivity (controls)
    var canUseWidgetControls: Bool { isPro }
    
    /// Focus Score and Week Comparison in Progress
    var canAccessAdvancedInsights: Bool { isPro }
}

// MARK: - ProEntitlementManager Shared Instance

extension ProEntitlementManager {
    /// Shared singleton for easy access
    @MainActor static let shared: ProEntitlementManager = {
        // Note: This assumes ProEntitlementManager is already initialized
        // In practice, it's injected via @EnvironmentObject
        ProEntitlementManager()
    }()
}

