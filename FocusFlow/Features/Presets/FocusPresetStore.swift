import Foundation
import Combine

@MainActor
final class FocusPresetStore: ObservableObject {
    static let shared = FocusPresetStore()

    // MARK: - Namespacing

    private var activeNamespace: String = "guest"
    private var lastNamespace: String? = nil
    private var cancellables = Set<AnyCancellable>()
    private var isApplyingNamespaceOrRemote = false

    private func namespace(for state: AuthState) -> String {
        switch state {
        case .authenticated(let session):
            return session.isGuest ? "guest" : session.userId.uuidString
        case .unauthenticated, .unknown:
            return "guest"
        }
    }

    private func key(_ base: String) -> String {
        "\(base)_\(activeNamespace)"
    }

    // MARK: - Published

    @Published var presets: [FocusPreset] = [] {
        didSet {
            guard !isApplyingNamespaceOrRemote else { return }
            savePresets()
        }
    }

    @Published var activePresetID: UUID? {
        didSet {
            guard !isApplyingNamespaceOrRemote else { return }
            saveActivePresetID()
        }
    }

    // MARK: - Keys (base)

    private struct Keys {
        static let presets = "ff_focus_presets"
        static let activePresetID = "ff_focus_active_preset_id"
    }

    private init() {
        observeAuthChanges()
        applyNamespace(for: AuthManager.shared.state)
        startSyncIfNeeded()
    }

    // MARK: - Public

    var activePreset: FocusPreset? {
        get {
            guard let id = activePresetID else { return nil }
            return presets.first(where: { $0.id == id })
        }
        set {
            activePresetID = newValue?.id
        }
    }

    func upsert(_ preset: FocusPreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
        } else {
            presets.append(preset)
        }
    }

    func save(_ preset: FocusPreset) {
        let isNew = !presets.contains(where: { $0.id == preset.id })
        upsert(preset)

        if isNew && activePresetID == nil {
            activePresetID = preset.id
        }
    }

    func delete(_ preset: FocusPreset) {
        presets.removeAll { $0.id == preset.id }
        if activePresetID == preset.id {
            activePresetID = nil
        }
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        let movingItems = source.map { presets[$0] }
        for index in source.sorted(by: >) {
            presets.remove(at: index)
        }
        var targetIndex = destination
        let removedBeforeDestination = source.filter { $0 < destination }.count
        targetIndex -= removedBeforeDestination
        presets.insert(contentsOf: movingItems, at: targetIndex)
    }

    // MARK: - Defaults

    /// Used by the sync engine when a signed-in user has no cloud presets yet.
    func seedDefaultsIfNeeded() -> [FocusPreset] {
        guard presets.isEmpty else { return presets }

        let defaults: [FocusPreset] = [
            FocusPreset(
                name: "Deep Work",
                durationSeconds: FocusPreset.minutes(50),
                soundID: "angelsbymyside",
                emoji: "🧠",
                isSystemDefault: true
            ),
            FocusPreset(
                name: "Study",
                durationSeconds: FocusPreset.minutes(40),
                soundID: "floatinggarden",
                emoji: "📚",
                isSystemDefault: true
            ),
            FocusPreset(
                name: "Writing",
                durationSeconds: FocusPreset.minutes(30),
                soundID: "light-rain-ambient",
                emoji: "✍️",
                isSystemDefault: true
            ),
            FocusPreset(
                name: "Reading",
                durationSeconds: FocusPreset.minutes(25),
                soundID: "fireplace",
                emoji: "📖",
                isSystemDefault: true
            )
        ]

        presets = defaults
        return defaults
    }

    // MARK: - Auth observation + namespace switching

    private func observeAuthChanges() {
        AuthManager.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.applyNamespace(for: state)
            }
            .store(in: &cancellables)
    }

    private func applyNamespace(for state: AuthState) {
        let newNamespace = namespace(for: state)
        if newNamespace == activeNamespace, lastNamespace != nil { return }

        lastNamespace = activeNamespace
        activeNamespace = newNamespace

        isApplyingNamespaceOrRemote = true
        defer { isApplyingNamespaceOrRemote = false }

        // Reset to clean state
        presets = []
        activePresetID = nil

        // Load from this namespace
        loadPresets()
        loadActivePresetID()

        // For guest only, seed defaults locally (offline friendly)
        if newNamespace == "guest" {
            _ = seedDefaultsIfNeeded()
        }

        print("FocusPresetStore: active namespace -> \(activeNamespace)")
    }

    // MARK: - Persistence (namespaced)

    private func loadPresets() {
        guard let data = UserDefaults.standard.data(forKey: key(Keys.presets)) else {
            presets = []
            return
        }
        do {
            presets = try JSONDecoder().decode([FocusPreset].self, from: data)
        } catch {
            print("⚠️ Failed to decode FocusPresets:", error)
            presets = []
        }
    }

    private func savePresets() {
        do {
            let data = try JSONEncoder().encode(presets)
            UserDefaults.standard.set(data, forKey: key(Keys.presets))
        } catch {
            print("⚠️ Failed to encode FocusPresets:", error)
        }
    }

    private func loadActivePresetID() {
        guard let idString = UserDefaults.standard.string(forKey: key(Keys.activePresetID)),
              let id = UUID(uuidString: idString) else {
            activePresetID = nil
            return
        }
        activePresetID = id
    }

    private func saveActivePresetID() {
        if let id = activePresetID {
            UserDefaults.standard.set(id.uuidString, forKey: key(Keys.activePresetID))
        } else {
            UserDefaults.standard.removeObject(forKey: key(Keys.activePresetID))
        }
    }

    // MARK: - Sync wiring

    private var didStartSync = false

    private func startSyncIfNeeded() {
        guard didStartSync == false else { return }
        didStartSync = true

        // ✅ CRITICAL: do not emit pushes while we are applying namespace/remote updates
        let presetsPublisher = $presets
            .filter { [weak self] _ in (self?.isApplyingNamespaceOrRemote == false) }
            .eraseToAnyPublisher()

        let activePublisher = $activePresetID
            .filter { [weak self] _ in (self?.isApplyingNamespaceOrRemote == false) }
            .eraseToAnyPublisher()

        FocusPresetSyncEngine.shared.start(
            presetsPublisher: presetsPublisher,
            activePresetIdPublisher: activePublisher,
            getLocalPresets: { [weak self] in self?.presets ?? [] },
            getLocalActivePresetId: { [weak self] in self?.activePresetID },
            seedDefaults: { [weak self] in
                guard let self else { return [] }
                return self.seedDefaultsIfNeeded()
            },
            applyRemote: { [weak self] remotePresets, remoteActiveId in
                guard let self else { return }
                self.isApplyingNamespaceOrRemote = true
                defer { self.isApplyingNamespaceOrRemote = false }

                self.presets = remotePresets
                self.activePresetID = remoteActiveId
            }
        )

        print("FocusPresetStore: FocusPresetSyncEngine started")
    }
}
