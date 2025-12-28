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
        applyNamespace(for: AuthManagerV2.shared.state)
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
        AuthManagerV2.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.applyNamespace(for: state)
            }
            .store(in: &cancellables)
    }

    private func applyNamespace(for state: CloudAuthState) {
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

    /// Read presets directly from disk (used for "bootstrap/guard" decisions).
    private func readPresetsFromDisk(namespace: String? = nil) -> [FocusPreset] {
        let ns = namespace ?? activeNamespace
        let diskKey = "\(Keys.presets)_\(ns)"
        guard let data = UserDefaults.standard.data(forKey: diskKey) else { return [] }
        return (try? JSONDecoder().decode([FocusPreset].self, from: data)) ?? []
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

    // MARK: - Remote merge/guards

    private func isDefaultsOnly(_ list: [FocusPreset]) -> Bool {
        !list.isEmpty && list.allSatisfy { $0.isSystemDefault == true }
    }

    private func hasAnyCustom(_ list: [FocusPreset]) -> Bool {
        list.contains(where: { $0.isSystemDefault == false })
    }

    /// Merge remote into local:
    /// - Prefer remote for IDs it contains
    /// - Keep any local-only custom presets if remote looks suspicious (defaults-only)
    private func applyRemoteSafely(remotePresets: [FocusPreset], remoteActiveId: UUID?) {
        // Snapshot what we truly have persisted (not just in-memory)
        let disk = readPresetsFromDisk()

        // If remote is defaults-only but disk/local has custom, do NOT overwrite.
        // This is the exact scenario causing "custom preset disappears on relaunch".
        if isDefaultsOnly(remotePresets), hasAnyCustom(disk) {
            print("SYNC[PRESETS] ⚠️ remoteDefaultsOnly_keepLocal=true diskCustomCount=\(disk.filter { !$0.isSystemDefault }.count)")
            // Keep local as-is; engine will push local up on next change / bootstrap.
            // We still can apply remoteActiveId only if it matches an existing preset.
            if let rid = remoteActiveId, presets.contains(where: { $0.id == rid }) {
                activePresetID = rid
            }
            return
        }

        // Normal: apply remote (authoritative)
        presets = remotePresets
        activePresetID = remoteActiveId
    }
}

// MARK: - Cloud Sync Extension (for new SyncCoordinator)

extension FocusPresetStore {
    
    /// Apply remote state to local store.
    /// Called by PresetsSyncEngine when remote data is pulled.
    func applyRemoteState(presets: [FocusPreset], activePresetId: UUID?) {
        isApplyingNamespaceOrRemote = true
        defer { isApplyingNamespaceOrRemote = false }
        
        applyRemoteSafely(remotePresets: presets, remoteActiveId: activePresetId)
    }
}
