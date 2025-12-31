import Foundation
import SwiftUI
import Combine
import Supabase

// MARK: - Theme model

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    // Core favourites (kept)
    case forest
    case neon
    case peach
    case cyber

    // New themes (6x)
    case ocean
    case sunrise
    case amber
    case mint
    case royal
    case slate

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .forest:  return "Forest"
        case .neon:    return "Neon Glow"
        case .peach:   return "Soft Peach"
        case .cyber:   return "Cyber Violet"

        case .ocean:   return "Ocean Mist"
        case .sunrise: return "Sunrise Coral"
        case .amber:   return "Solar Amber"
        case .mint:    return "Mint Aura"
        case .royal:   return "Royal Indigo"
        case .slate:   return "Cosmic Slate"
        }
    }

    /// Background gradient colors (legacy support, still used by a few views)
    var backgroundColors: [Color] {
        switch self {
        case .forest:
            return [
                Color(red: 0.05, green: 0.11, blue: 0.09),
                Color(red: 0.13, green: 0.22, blue: 0.18)
            ]
        case .neon:
            return [
                Color(red: 0.02, green: 0.05, blue: 0.12),
                Color(red: 0.13, green: 0.02, blue: 0.24)
            ]
        case .peach:
            return [
                Color(red: 0.16, green: 0.08, blue: 0.11),
                Color(red: 0.31, green: 0.15, blue: 0.18)
            ]
        case .cyber:
            return [
                Color(red: 0.06, green: 0.04, blue: 0.18),
                Color(red: 0.18, green: 0.09, blue: 0.32)
            ]
        case .ocean:
            return [
                Color(red: 0.02, green: 0.08, blue: 0.15),
                Color(red: 0.03, green: 0.27, blue: 0.32)
            ]
        case .sunrise:
            return [
                Color(red: 0.10, green: 0.06, blue: 0.20),
                Color(red: 0.33, green: 0.17, blue: 0.24)
            ]
        case .amber:
            return [
                Color(red: 0.10, green: 0.06, blue: 0.04),
                Color(red: 0.30, green: 0.18, blue: 0.10)
            ]
        case .mint:
            return [
                Color(red: 0.02, green: 0.10, blue: 0.09),
                Color(red: 0.08, green: 0.30, blue: 0.26)
            ]
        case .royal:
            return [
                Color(red: 0.05, green: 0.05, blue: 0.16),
                Color(red: 0.11, green: 0.17, blue: 0.32)
            ]
        case .slate:
            return [
                Color(red: 0.06, green: 0.07, blue: 0.11),
                Color(red: 0.16, green: 0.18, blue: 0.24)
            ]
        }
    }

    /// Main accent color
    var accentPrimary: Color {
        switch self {
        case .forest:  return Color(red: 0.55, green: 0.90, blue: 0.70)
        case .neon:    return Color(red: 0.25, green: 0.95, blue: 0.85)
        case .peach:   return Color(red: 1.00, green: 0.72, blue: 0.63)
        case .cyber:   return Color(red: 0.80, green: 0.60, blue: 1.00)

        case .ocean:   return Color(red: 0.48, green: 0.84, blue: 1.00)
        case .sunrise: return Color(red: 1.00, green: 0.62, blue: 0.63)
        case .amber:   return Color(red: 1.00, green: 0.78, blue: 0.45)
        case .mint:    return Color(red: 0.60, green: 0.96, blue: 0.78)
        case .royal:   return Color(red: 0.65, green: 0.72, blue: 1.00)
        case .slate:   return Color(red: 0.75, green: 0.82, blue: 0.96)
        }
    }

    /// Secondary accent (for gradients)
    var accentSecondary: Color {
        switch self {
        case .forest:  return Color(red: 0.42, green: 0.78, blue: 0.62)
        case .neon:    return Color(red: 0.60, green: 0.40, blue: 1.00)
        case .peach:   return Color(red: 1.00, green: 0.85, blue: 0.70)
        case .cyber:   return Color(red: 0.38, green: 0.86, blue: 1.00)

        case .ocean:   return Color(red: 0.23, green: 0.95, blue: 0.96)
        case .sunrise: return Color(red: 1.00, green: 0.80, blue: 0.55)
        case .amber:   return Color(red: 1.00, green: 0.60, blue: 0.40)
        case .mint:    return Color(red: 0.46, green: 0.88, blue: 0.92)
        case .royal:   return Color(red: 0.50, green: 0.60, blue: 1.00)
        case .slate:   return Color(red: 0.70, green: 0.76, blue: 0.90)
        }
    }

    /// Legacy alias
    var accentColor: Color { accentPrimary }
}

// MARK: - App-wide settings / profile (namespaced + synced)

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // MARK: - External music app selection

    enum ExternalMusicApp: String, CaseIterable, Identifiable, Codable {
        case spotify
        case appleMusic
        case youtubeMusic

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .spotify:      return "Spotify"
            case .appleMusic:   return "Apple Music"
            case .youtubeMusic: return "YouTube Music"
            }
        }
    }

    // MARK: - Namespace handling (prevents account bleed)

    private var activeNamespace: String = "guest"
    private var lastNamespace: String? = nil

    private var cancellables = Set<AnyCancellable>()
    private var isApplyingNamespace = false
    private var didSetupNotificationObservers = false
    private var isUpdatingMutualExclusivity = false // ✅ Prevent recursive updates when enforcing mutual exclusivity

    // ✅ Updated to use CloudAuthState from AuthManagerV2
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

    // ✅ Updated to use AuthManagerV2
    private func observeAuthChanges() {
        AuthManagerV2.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.applyNamespace(for: newState)
            }
            .store(in: &cancellables)
    }

    // ✅ Phase 2: Forward daily reminder changes to NotificationPreferencesStore
    // The store will trigger reconcileAll() automatically
    private func observeNotificationPreferencesIfNeeded() {
        guard didSetupNotificationObservers == false else { return }
        didSetupNotificationObservers = true

        Publishers.CombineLatest($dailyReminderEnabled, $dailyReminderTime)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled, time in
                guard let self else { return }
                guard self.isApplyingNamespace == false else { return }
                
                // ✅ Update the new notification preferences store
                NotificationPreferencesStore.shared.update { prefs in
                    prefs.dailyReminderEnabled = enabled
                    prefs.dailyReminderTime = time
                }
            }
            .store(in: &cancellables)
    }

    // ✅ Updated to use CloudAuthState
    private func applyNamespace(for state: CloudAuthState) {
        let newNamespace = namespace(for: state)

        if newNamespace == activeNamespace, lastNamespace != nil {
            return
        }

        // If real account -> guest, wipe guest so it stays clean/safe
        if newNamespace == "guest", let last = lastNamespace, last != "guest" {
            wipeLocalStorage(namespace: "guest")
            LocalTimestampTracker.shared.clearAllTimestamps(namespace: "guest")
        }

        lastNamespace = activeNamespace
        activeNamespace = newNamespace

        isApplyingNamespace = true
        defer { isApplyingNamespace = false }

        // Reset in-memory to defaults first (prevents UI mixing)
        displayName = "You"
        tagline = "Staying focused."
        avatarID = "sparkles"

        accountFullName = ""
        accountEmail = nil

        selectedTheme = .forest
        profileTheme = .forest

        soundEnabled = true
        hapticsEnabled = true

        dailyReminderEnabled = false
        dailyReminderTime = Self.makeDate(hour: 9, minute: 0)

        // ✅ NEW (Focus logging UX)
        askToRecordIncompleteSessions = false

        profileImageData = nil

        selectedFocusSound = nil // ✅ Default to no sound
        selectedExternalMusicApp = nil // ✅ Default to no external app

        // Load from namespace
        loadAll()

        // ✅ If signed in and email is not set, fetch it from Supabase session
        // Use a small delay to ensure session is fully established after OAuth sign-in
        if case .signedIn = state, accountEmail == nil {
            Task { @MainActor in
                // Small delay to allow OAuth session to be fully established
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await fetchEmailFromSession()
            }
        }

        // ✅ Trigger notification reconcile for this namespace after switching
        Task { @MainActor in
            await NotificationsCoordinator.shared.reconcileAll(reason: "namespace changed")
        }

        print("AppSettings: active namespace -> \(activeNamespace)")
    }

    private func wipeLocalStorage(namespace: String) {
        let defaults = UserDefaults.standard

        defaults.removeObject(forKey: "\(Keys.displayName)_\(namespace)")
        defaults.removeObject(forKey: "\(Keys.tagline)_\(namespace)")
        defaults.removeObject(forKey: "\(Keys.avatarID)_\(namespace)")

        defaults.removeObject(forKey: "\(Keys.accountFullName)_\(namespace)")
        defaults.removeObject(forKey: "\(Keys.accountEmail)_\(namespace)")

        defaults.removeObject(forKey: "\(Keys.selectedTheme)_\(namespace)")
        defaults.removeObject(forKey: "\(Keys.profileTheme)_\(namespace)")

        defaults.removeObject(forKey: "\(Keys.soundEnabled)_\(namespace)")
        defaults.removeObject(forKey: "\(Keys.hapticsEnabled)_\(namespace)")

        defaults.removeObject(forKey: "\(Keys.dailyReminderEnabled)_\(namespace)")
        defaults.removeObject(forKey: "\(Keys.reminderHour)_\(namespace)")
        defaults.removeObject(forKey: "\(Keys.reminderMinute)_\(namespace)")

        // ✅ NEW
        defaults.removeObject(forKey: "\(Keys.askToRecordIncompleteSessions)_\(namespace)")

        defaults.removeObject(forKey: "\(Keys.profileImageData)_\(namespace)")
        defaults.removeObject(forKey: "\(Keys.selectedFocusSound)_\(namespace)")
        defaults.removeObject(forKey: "\(Keys.externalMusicApp)_\(namespace)")

        print("AppSettings: wiped local storage for namespace=\(namespace)")
    }

    // MARK: - Published properties (persisted per namespace)

    @Published var displayName: String {
        didSet {
            if !isApplyingNamespace {
                UserDefaults.standard.set(displayName, forKey: key(Keys.displayName))
                // Only record timestamp if value actually changed
                if displayName != oldValue {
                    LocalTimestampTracker.shared.recordLocalChange(field: "displayName", namespace: activeNamespace)
                }
            }
        }
    }

    @Published var tagline: String {
        didSet {
            if !isApplyingNamespace {
                UserDefaults.standard.set(tagline, forKey: key(Keys.tagline))
                if tagline != oldValue {
                    LocalTimestampTracker.shared.recordLocalChange(field: "tagline", namespace: activeNamespace)
                }
            }
        }
    }

    /// Avatar id (SF Symbol choice) — synced via user_settings
    @Published var avatarID: String {
        didSet {
            if !isApplyingNamespace {
                UserDefaults.standard.set(avatarID, forKey: key(Keys.avatarID))
                if avatarID != oldValue {
                    LocalTimestampTracker.shared.recordLocalChange(field: "avatarID", namespace: activeNamespace)
                }
            }
        }
    }

    /// Identity fields
    @Published var accountFullName: String {
        didSet { if !isApplyingNamespace { UserDefaults.standard.set(accountFullName, forKey: key(Keys.accountFullName)) } }
    }

    @Published var accountEmail: String? {
        didSet {
            guard !isApplyingNamespace else { return }
            let defaults = UserDefaults.standard
            if let v = accountEmail, !v.isEmpty {
                defaults.set(v, forKey: key(Keys.accountEmail))
            } else {
                defaults.removeObject(forKey: key(Keys.accountEmail))
            }
        }
    }

    @Published var selectedTheme: AppTheme {
        didSet {
            if !isApplyingNamespace {
                UserDefaults.standard.set(selectedTheme.rawValue, forKey: key(Keys.selectedTheme))
                if selectedTheme != oldValue {
                    LocalTimestampTracker.shared.recordLocalChange(field: "selectedTheme", namespace: activeNamespace)
                    // ✅ Sync to Home Screen widgets (theme affects widget appearance)
                    Task { @MainActor in
                        WidgetDataManager.shared.syncAll()
                    }
                }
            }
        }
    }

    @Published var profileTheme: AppTheme {
        didSet {
            if !isApplyingNamespace {
                UserDefaults.standard.set(profileTheme.rawValue, forKey: key(Keys.profileTheme))
                if profileTheme != oldValue {
                    LocalTimestampTracker.shared.recordLocalChange(field: "profileTheme", namespace: activeNamespace)
                }
            }
        }
    }

    @Published var soundEnabled: Bool {
        didSet {
            if !isApplyingNamespace {
                UserDefaults.standard.set(soundEnabled, forKey: key(Keys.soundEnabled))
                if soundEnabled != oldValue {
                    LocalTimestampTracker.shared.recordLocalChange(field: "soundEnabled", namespace: activeNamespace)
                }
            }
        }
    }

    @Published var hapticsEnabled: Bool {
        didSet {
            if !isApplyingNamespace {
                UserDefaults.standard.set(hapticsEnabled, forKey: key(Keys.hapticsEnabled))
                if hapticsEnabled != oldValue {
                    LocalTimestampTracker.shared.recordLocalChange(field: "hapticsEnabled", namespace: activeNamespace)
                }
            }
        }
    }

    @Published var dailyReminderEnabled: Bool {
        didSet {
            if !isApplyingNamespace {
                UserDefaults.standard.set(dailyReminderEnabled, forKey: key(Keys.dailyReminderEnabled))
                if dailyReminderEnabled != oldValue {
                    LocalTimestampTracker.shared.recordLocalChange(field: "dailyReminderEnabled", namespace: activeNamespace)
                }
            }
        }
    }

    @Published var selectedFocusSound: FocusSound? {
        didSet {
            guard !isApplyingNamespace else { return }
            
            // ✅ If a built-in sound is selected, clear external music app
            if !isUpdatingMutualExclusivity, selectedFocusSound != nil {
                isUpdatingMutualExclusivity = true
                defer { isUpdatingMutualExclusivity = false }
                selectedExternalMusicApp = nil
            }
            
            UserDefaults.standard.set(selectedFocusSound?.rawValue, forKey: key(Keys.selectedFocusSound))
            if selectedFocusSound != oldValue {
                LocalTimestampTracker.shared.recordLocalChange(field: "selectedFocusSound", namespace: activeNamespace)
            }
        }
    }

    @Published var dailyReminderTime: Date {
        didSet {
            guard !isApplyingNamespace else { return }
            // Only record if time actually changed (compare hour and minute)
            let oldComps = Calendar.current.dateComponents([.hour, .minute], from: oldValue)
            let newComps = Calendar.current.dateComponents([.hour, .minute], from: dailyReminderTime)
            let timeChanged = oldComps.hour != newComps.hour || oldComps.minute != newComps.minute
            
            let comps = Calendar.current.dateComponents([.hour, .minute], from: dailyReminderTime)
            UserDefaults.standard.set(comps.hour ?? 9, forKey: key(Keys.reminderHour))
            UserDefaults.standard.set(comps.minute ?? 0, forKey: key(Keys.reminderMinute))
            if timeChanged {
                LocalTimestampTracker.shared.recordLocalChange(field: "dailyReminderTime", namespace: activeNamespace)
            }
        }
    }

    // ✅ NEW: Focus logging UX setting (persisted)
    // When ON, you can prompt the user when an early-ended / interrupted session qualifies to be logged.
    @Published var askToRecordIncompleteSessions: Bool {
        didSet {
            if !isApplyingNamespace {
                UserDefaults.standard.set(askToRecordIncompleteSessions, forKey: key(Keys.askToRecordIncompleteSessions))
            }
        }
    }

    @Published var profileImageData: Data? {
        didSet {
            guard !isApplyingNamespace else { return }
            let defaults = UserDefaults.standard
            if let data = profileImageData {
                defaults.set(data, forKey: key(Keys.profileImageData))
            } else {
                defaults.removeObject(forKey: key(Keys.profileImageData))
            }
        }
    }

    // MARK: - External music app selection (persisted)

    @Published var selectedExternalMusicApp: ExternalMusicApp? {
        didSet {
            guard !isApplyingNamespace else { return }
            
            // ✅ If an external app is selected, clear built-in sound (set to nil = "no sound")
            if !isUpdatingMutualExclusivity, selectedExternalMusicApp != nil {
                isUpdatingMutualExclusivity = true
                defer { isUpdatingMutualExclusivity = false }
                selectedFocusSound = nil
            }
            
            let defaults = UserDefaults.standard
            if let value = selectedExternalMusicApp?.rawValue {
                defaults.set(value, forKey: key(Keys.externalMusicApp))
            } else {
                defaults.removeObject(forKey: key(Keys.externalMusicApp))
            }
            if selectedExternalMusicApp != oldValue {
                LocalTimestampTracker.shared.recordLocalChange(field: "selectedExternalMusicApp", namespace: activeNamespace)
            }
        }
    }

    /// Session-only (not persisted)
    @Published var isFocusTimerRunning: Bool = false

    // MARK: - Init

    private init() {
        // default placeholders (will be replaced by applyNamespace->loadAll)
        self.displayName = "You"
        self.tagline = "Staying focused."
        self.avatarID = "sparkles"

        self.accountFullName = ""
        self.accountEmail = nil

        self.selectedTheme = .forest
        self.profileTheme = .forest

        self.soundEnabled = true
        self.hapticsEnabled = true
        self.dailyReminderEnabled = false
        self.dailyReminderTime = Self.makeDate(hour: 9, minute: 0)

        // ✅ NEW
        self.askToRecordIncompleteSessions = false

        self.profileImageData = nil
        self.selectedFocusSound = nil // ✅ Default to no sound

        self.selectedExternalMusicApp = nil // ✅ Default to no external app

        observeAuthChanges()
        applyNamespace(for: AuthManagerV2.shared.state)

        // Start observing notification preferences once
        observeNotificationPreferencesIfNeeded()
        
        // ✅ Note: Sync is now handled by SettingsSyncEngine in SyncCoordinator
        // No need to start old sync engines here
    }

    // MARK: - Convenience accessors for SettingsSyncEngine

    /// Daily reminder hour (for sync)
    var dailyReminderHour: Int {
        Calendar.current.component(.hour, from: dailyReminderTime)
    }

    /// Daily reminder minute (for sync)
    var dailyReminderMinute: Int {
        Calendar.current.component(.minute, from: dailyReminderTime)
    }

    /// Daily goal in minutes (delegates to ProgressStore for now)
    var dailyGoalMinutes: Int {
        get { ProgressStore.shared.dailyGoalMinutes }
        set { ProgressStore.shared.dailyGoalMinutes = newValue }
    }

    /// External music app (alias for sync engine compatibility)
    var externalMusicApp: ExternalMusicApp? {
        get { selectedExternalMusicApp }
        set { selectedExternalMusicApp = newValue }
    }

    // MARK: - Load helpers

    private func loadAll() {
        let defaults = UserDefaults.standard

        self.displayName = defaults.string(forKey: key(Keys.displayName)) ?? "You"
        self.tagline = defaults.string(forKey: key(Keys.tagline)) ?? "Staying focused."
        self.avatarID = defaults.string(forKey: key(Keys.avatarID)) ?? "sparkles"

        self.accountFullName = defaults.string(forKey: key(Keys.accountFullName)) ?? ""
        self.accountEmail = defaults.string(forKey: key(Keys.accountEmail))

        let selectedRaw = defaults.string(forKey: key(Keys.selectedTheme)) ?? AppTheme.forest.rawValue
        self.selectedTheme = AppTheme(rawValue: selectedRaw) ?? .forest

        let profileRaw = defaults.string(forKey: key(Keys.profileTheme)) ?? selectedRaw
        self.profileTheme = AppTheme(rawValue: profileRaw) ?? self.selectedTheme

        self.soundEnabled = defaults.object(forKey: key(Keys.soundEnabled)) as? Bool ?? true
        self.hapticsEnabled = defaults.object(forKey: key(Keys.hapticsEnabled)) as? Bool ?? true
        self.dailyReminderEnabled = defaults.object(forKey: key(Keys.dailyReminderEnabled)) as? Bool ?? false

        let hour = defaults.object(forKey: key(Keys.reminderHour)) as? Int ?? 9
        let minute = defaults.object(forKey: key(Keys.reminderMinute)) as? Int ?? 0
        self.dailyReminderTime = Self.makeDate(hour: hour, minute: minute)

        // ✅ NEW
        self.askToRecordIncompleteSessions = defaults.object(forKey: key(Keys.askToRecordIncompleteSessions)) as? Bool ?? false

        self.profileImageData = defaults.data(forKey: key(Keys.profileImageData))

        // ✅ Check if there's an active session - if not, don't load sound/app from UserDefaults
        let isSessionActive = defaults.bool(forKey: "FocusFlow.focusSession.isActive")
        
        if isSessionActive {
            // Session is active - restore from session persistence
            if let soundRaw = defaults.string(forKey: "FocusFlow.focusSession.selectedFocusSound"),
               let sound = FocusSound(rawValue: soundRaw) {
                self.selectedFocusSound = sound
            } else {
                self.selectedFocusSound = nil
            }
            
            if let appRaw = defaults.string(forKey: "FocusFlow.focusSession.selectedExternalMusicApp"),
               let app = ExternalMusicApp(rawValue: appRaw) {
                self.selectedExternalMusicApp = app
            } else {
                self.selectedExternalMusicApp = nil
            }
        } else {
            // No session active - default to no sound and no external app
            self.selectedFocusSound = nil
            self.selectedExternalMusicApp = nil
        }
    }

    /// Returns "today at hour:minute" (safe for DatePicker / scheduling)
    private static func makeDate(hour: Int, minute: Int) -> Date {
        let cal = Calendar.current
        let now = Date()
        var comps = cal.dateComponents([.year, .month, .day], from: now)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        return cal.date(from: comps) ?? now
    }
    
    /// Fetches email and display name from current Supabase session if available
    private func fetchEmailFromSession() async {
        do {
            let session = try await SupabaseManager.shared.auth.session
            if let email = session.user.email, !email.isEmpty {
                // Only set if not already set (don't overwrite)
                if accountEmail == nil || accountEmail?.isEmpty == true {
                    accountEmail = email
                    #if DEBUG
                    print("[AppSettings] Fetched email from session: \(email)")
                    #endif
                }
            }
            
            // Try to get display name from user metadata
            // Check userMetadata first (OAuth providers often put name here)
            let userMetadata = session.user.userMetadata
            let appMetadata = session.user.appMetadata
            
            // Helper to extract string from AnyJSON
            func extractString(from json: AnyJSON?) -> String? {
                guard let json = json else { return nil }
                // AnyJSON can be decoded/encoded to extract underlying values
                // Try to get string representation
                if case .string(let value) = json {
                    return value
                }
                // Fallback: try to decode as string via JSON
                if let data = try? JSONEncoder().encode(json),
                   let decoded = try? JSONDecoder().decode(String.self, from: data) {
                    return decoded
                }
                return nil
            }
            
            // Common metadata keys for name: full_name, name, display_name
            var nameFromMetadata: String? = nil
            if let fullName = extractString(from: userMetadata["full_name"]), !fullName.isEmpty {
                nameFromMetadata = fullName
            } else if let name = extractString(from: userMetadata["name"]), !name.isEmpty {
                nameFromMetadata = name
            } else if let displayName = extractString(from: userMetadata["display_name"]), !displayName.isEmpty {
                nameFromMetadata = displayName
            } else if let fullName = extractString(from: appMetadata["full_name"]), !fullName.isEmpty {
                nameFromMetadata = fullName
            } else if let name = extractString(from: appMetadata["name"]), !name.isEmpty {
                nameFromMetadata = name
            }
            
            // Set display name if found and not already set (or only default "You")
            if let name = nameFromMetadata, !name.isEmpty {
                if displayName.isEmpty || displayName == "You" {
                    displayName = name
                    #if DEBUG
                    print("[AppSettings] Fetched display name from session: \(name)")
                    #endif
                }
            }
        } catch {
            #if DEBUG
            print("[AppSettings] Could not fetch email/name from session: \(error)")
            #endif
        }
    }

    // MARK: - Keys (base)

    private struct Keys {
        static let displayName = "ff_displayName"
        static let tagline = "ff_tagline"
        static let avatarID = "ff_avatarID"

        static let accountFullName = "ff_accountFullName"
        static let accountEmail = "ff_accountEmail"

        static let selectedTheme = "ff_selectedTheme"
        static let profileTheme = "ff_profileTheme"

        static let soundEnabled = "ff_soundEnabled"
        static let hapticsEnabled = "ff_hapticsEnabled"

        static let dailyReminderEnabled = "ff_dailyReminderEnabled"
        static let reminderHour = "ff_reminderHour"
        static let reminderMinute = "ff_reminderMinute"

        // ✅ NEW
        static let askToRecordIncompleteSessions = "ff_askToRecordIncompleteSessions"

        static let profileImageData = "ff_profileImageData"
        static let selectedFocusSound = "ff_selectedFocusSound"

        static let externalMusicApp = "ff_externalMusicApp"
    }
}
