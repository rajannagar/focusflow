import Foundation
import Combine

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
    private var hasInitialized = false

    private init() {
        observeAuthChanges()
        applyNamespace(for: AuthManagerV2.shared.state)
        hasInitialized = true
    }

    // MARK: - Namespace Management
    private func namespace(for state: CloudAuthState) -> String {
        switch state {
        case .signedIn(let userId): return userId.uuidString
        case .guest, .unknown, .signedOut: return "guest"
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

        if hasInitialized, newNamespace == activeNamespace { return }

        activeNamespace = newNamespace
        isApplyingNamespace = true
        defer { isApplyingNamespace = false }

        load()
        print("NotificationPreferencesStore: namespace → \(activeNamespace)")

        // Optional: reconcile on namespace switch so scheduled notifications match the new prefs.
        Task { await NotificationsCoordinator.shared.reconcileAll(reason: "namespace changed") }
    }

    // MARK: - Persistence

    private func load() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: key(storageKey)),
           let decoded = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            self.preferences = decoded
            return
        }

        // Migration default: hydrate from AppSettings only when no stored prefs exist
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

    func update(_ transform: (inout NotificationPreferences) -> Void) {
        var copy = preferences
        transform(&copy)
        guard copy != preferences else { return }

        preferences = copy
        save()

        Task { await NotificationsCoordinator.shared.reconcileAll(reason: "preferences changed") }
    }

    func setMasterEnabled(_ enabled: Bool) { update { $0.masterEnabled = enabled } }
    func setSessionCompletionEnabled(_ enabled: Bool) { update { $0.sessionCompletionEnabled = enabled } }
    func setDailyReminderEnabled(_ enabled: Bool) { update { $0.dailyReminderEnabled = enabled } }
    func setDailyReminderTime(_ time: Date) { update { $0.dailyReminderTime = time } }
    func setDailyNudgesEnabled(_ enabled: Bool) { update { $0.dailyNudgesEnabled = enabled } }
    func setTaskRemindersEnabled(_ enabled: Bool) { update { $0.taskRemindersEnabled = enabled } }
    func setDailyRecapEnabled(_ enabled: Bool) { update { $0.dailyRecapEnabled = enabled } }
    func setDailyRecapTime(_ time: Date) { update { $0.dailyRecapTime = time } }

    func reset() {
        preferences = .default
        save()
        Task { await NotificationsCoordinator.shared.reconcileAll(reason: "preferences reset") }
    }
}
