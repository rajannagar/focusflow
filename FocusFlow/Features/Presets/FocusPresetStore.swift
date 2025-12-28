import Foundation
import Combine

@MainActor
final class FocusPresetStore: ObservableObject {
    static let shared = FocusPresetStore()

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

    private struct Keys {
        static let presets = "ff_focus_presets"
        static let activePresetID = "ff_focus_active_preset_id"
    }

    private init() {
        observeAuthChanges()
        applyNamespace(for: AuthManagerV2.shared.state)
    }

    var activePreset: FocusPreset? {
        get {
            guard let id = activePresetID else { return nil }
            return presets.first(where: { $0.id == id })
        }
        set {
            activePresetID = newValue?.id
        }
    }

    // API expected by your views
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

    func seedDefaultsIfNeeded() -> [FocusPreset] {
        guard presets.isEmpty else { return presets }

        let defaults: [FocusPreset] = [
            FocusPreset(name: "Deep Work", durationSeconds: FocusPreset.minutes(50), soundID: "angelsbymyside", emoji: "🧠", isSystemDefault: true),
            FocusPreset(name: "Study", durationSeconds: FocusPreset.minutes(40), soundID: "floatinggarden", emoji: "📚", isSystemDefault: true),
            FocusPreset(name: "Writing", durationSeconds: FocusPreset.minutes(30), soundID: "light-rain-ambient", emoji: "✍️", isSystemDefault: true),
            FocusPreset(name: "Reading", durationSeconds: FocusPreset.minutes(25), soundID: "fireplace", emoji: "📖", isSystemDefault: true)
        ]

        presets = defaults
        activePresetID = defaults.first?.id
        return defaults
    }

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

        presets = []
        activePresetID = nil

        loadPresets()
        loadActivePresetID()

        if newNamespace == "guest" {
            _ = seedDefaultsIfNeeded()
        }

        print("FocusPresetStore: active namespace -> \(activeNamespace)")
    }

    private func loadPresets() {
        guard let data = UserDefaults.standard.data(forKey: key(Keys.presets)) else {
            presets = []
            return
        }
        do {
            presets = try JSONDecoder().decode([FocusPreset].self, from: data)
        } catch {
            presets = []
        }
    }

    private func savePresets() {
        do {
            let data = try JSONEncoder().encode(presets)
            UserDefaults.standard.set(data, forKey: key(Keys.presets))
        } catch {
            // best effort
        }
    }

    private func loadActivePresetID() {
        guard let idString = UserDefaults.standard.string(forKey: key(Keys.activePresetID)),
              let id = UUID(uuidString: idString) else {
            activePresetID = presets.first?.id
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
}

extension FocusPresetStore {
    func applyRemoteState(presets remotePresets: [FocusPreset], activePresetId: UUID?) {
        isApplyingNamespaceOrRemote = true
        defer { isApplyingNamespaceOrRemote = false }

        presets = remotePresets
        activePresetID = activePresetId ?? remotePresets.first?.id
    }
}
