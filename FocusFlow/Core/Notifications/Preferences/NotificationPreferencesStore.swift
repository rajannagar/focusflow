//
//  NotificationPreferencesStore.swift
//  FocusFlow
//
//  Namespace-aware persistence for notification preferences.
//  Updated to use AuthManagerV2 instead of legacy AuthManager.
//

import Foundation
import Combine

// =========================================================
// MARK: - NotificationPreferencesStore
// =========================================================
// Namespace-aware persistence for notification preferences.
// Follows the same pattern as AppSettings (per-account storage).

@MainActor
final class NotificationPreferencesStore: ObservableObject {
    static let shared = NotificationPreferencesStore()
    
    // MARK: - Published State
    
    @Published private(set) var preferences: NotificationPreferences = .default
    
    // MARK: - Private
    
    private let storageKey = "ff_notificationPreferences"
    private var activeNamespace: String = "guest"
    private var cancellables = Set<AnyCancellable>()
    private var isApplyingNamespace = false
    
    // MARK: - Init
    
    private init() {
        observeAuthChanges()
        applyNamespace(for: AuthManagerV2.shared.state)
    }
    
    // MARK: - Namespace Management (matches AppSettings pattern)
    
    private func namespace(for state: CloudAuthState) -> String {
        switch state {
        case .signedIn(let userId):
            return userId.uuidString
        case .guest, .unknown, .signedOut:
            return "guest"
        }
    }
    
    private func key(_ base: String) -> String {
        "\(base)_\(activeNamespace)"
    }
    
    private func observeAuthChanges() {
        AuthManagerV2.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.applyNamespace(for: newState)
            }
            .store(in: &cancellables)
    }
    
    private func applyNamespace(for state: CloudAuthState) {
        let newNamespace = namespace(for: state)
        guard newNamespace != activeNamespace || cancellables.isEmpty else { return }
        
        activeNamespace = newNamespace
        isApplyingNamespace = true
        defer { isApplyingNamespace = false }
        
        load()
        
        print("NotificationPreferencesStore: namespace → \(activeNamespace)")
    }
    
    // MARK: - Persistence
    
    private func load() {
        let defaults = UserDefaults.standard
        
        // First, try to load from new unified storage
        if let data = defaults.data(forKey: key(storageKey)),
           let decoded = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            self.preferences = decoded
            return
        }
        
        // Migration: read existing dailyReminder settings from AppSettings if available
        // This preserves existing user preferences during transition
        let appSettings = AppSettings.shared
        var prefs = NotificationPreferences.default
        prefs.dailyReminderEnabled = appSettings.dailyReminderEnabled
        prefs.dailyReminderTime = appSettings.dailyReminderTime
        
        self.preferences = prefs
    }
    
    private func save() {
        guard !isApplyingNamespace else { return }
        
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(preferences) {
            defaults.set(data, forKey: key(storageKey))
        }
    }
    
    // MARK: - Public API
    
    /// Update preferences and persist. Triggers reconcileAll via NotificationsCoordinator.
    func update(_ transform: (inout NotificationPreferences) -> Void) {
        var copy = preferences
        transform(&copy)
        
        guard copy != preferences else { return }
        
        preferences = copy
        save()
        
        // Trigger reconcile after preference change
        Task {
            await NotificationsCoordinator.shared.reconcileAll(reason: "preferences changed")
        }
    }
    
    /// Convenience: update a single property
    func setMasterEnabled(_ enabled: Bool) {
        update { $0.masterEnabled = enabled }
    }
    
    func setSessionCompletionEnabled(_ enabled: Bool) {
        update { $0.sessionCompletionEnabled = enabled }
    }
    
    func setDailyReminderEnabled(_ enabled: Bool) {
        update { $0.dailyReminderEnabled = enabled }
    }
    
    func setDailyReminderTime(_ time: Date) {
        update { $0.dailyReminderTime = time }
    }
    
    func setDailyNudgesEnabled(_ enabled: Bool) {
        update { $0.dailyNudgesEnabled = enabled }
    }
    
    func setTaskRemindersEnabled(_ enabled: Bool) {
        update { $0.taskRemindersEnabled = enabled }
    }
    
    func setDailyRecapEnabled(_ enabled: Bool) {
        update { $0.dailyRecapEnabled = enabled }
    }
    
    func setDailyRecapTime(_ time: Date) {
        update { $0.dailyRecapTime = time }
    }
    
    /// Reset to defaults (useful for logout/account switch)
    func reset() {
        preferences = .default
        save()
    }
}
