//
//  PresetsSyncEngine.swift
//  FocusFlow
//
//  Syncs FocusPreset ↔ focus_presets table
//  Syncs active preset ↔ focus_preset_settings table
//

import Foundation
import Combine
import Supabase

// MARK: - Remote Models

/// Matches the `focus_presets` table schema
struct FocusPresetDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var name: String
    var durationSeconds: Int
    var soundId: String?
    var emoji: String?
    var isSystemDefault: Bool
    var themeRaw: String?
    var externalMusicAppRaw: String?
    var sortOrder: Int
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case durationSeconds = "duration_seconds"
        case soundId = "sound_id"
        case emoji
        case isSystemDefault = "is_system_default"
        case themeRaw = "theme_raw"
        case externalMusicAppRaw = "external_music_app_raw"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Matches the `focus_preset_settings` table schema
struct FocusPresetSettingsDTO: Codable {
    let userId: UUID
    var activePresetId: UUID?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case activePresetId = "active_preset_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Sync Engine

@MainActor
final class PresetsSyncEngine {

    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()
    private var isRunning = false
    private var userId: UUID?

    private var isApplyingRemote = false

    // MARK: - Start/Stop

    func start(userId: UUID) async throws {
        self.userId = userId
        self.isRunning = true

        // Initial sync
        try await pullFromRemote(userId: userId)

        // Push local presets that don't exist remotely (first-time sync)
        await pushNewLocalPresets()

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

        // Fetch presets
        let remotePresets: [FocusPresetDTO] = try await db
            .from("focus_presets")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("sort_order", ascending: true)
            .execute()
            .value

        // Fetch active preset setting (optional)
        let activePresetSetting: FocusPresetSettingsDTO? = try? await db
            .from("focus_preset_settings")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        applyRemoteToLocal(presets: remotePresets, activePresetId: activePresetSetting?.activePresetId)

        #if DEBUG
        print("[PresetsSyncEngine] Pulled \(remotePresets.count) presets")
        #endif
    }

    // MARK: - Push to Remote

    private func pushToRemote() async {
        guard isRunning, let userId = userId else { return }
        guard !isApplyingRemote else { return }

        let store = FocusPresetStore.shared
        let db = SupabaseManager.shared.database

        // Convert local presets to DTOs
        let presetDTOs: [FocusPresetDTO] = store.presets.enumerated().map { index, preset in
            FocusPresetDTO(
                id: preset.id,
                userId: userId,
                name: preset.name,
                durationSeconds: preset.durationSeconds,
                soundId: preset.soundID.isEmpty ? nil : preset.soundID,
                emoji: preset.emoji,
                isSystemDefault: preset.isSystemDefault,
                themeRaw: preset.themeRaw,
                externalMusicAppRaw: preset.externalMusicAppRaw,
                sortOrder: index
            )
        }

        do {
            if !presetDTOs.isEmpty {
                try await db
                    .from("focus_presets")
                    .upsert(presetDTOs, onConflict: "id")
                    .execute()
            }

            // ✅ Use activePresetID (published), not activePreset (computed)
            let settingsDTO = FocusPresetSettingsDTO(
                userId: userId,
                activePresetId: store.activePresetID
            )

            try await db
                .from("focus_preset_settings")
                .upsert(settingsDTO, onConflict: "user_id")
                .execute()

            #if DEBUG
            print("[PresetsSyncEngine] Pushed \(presetDTOs.count) presets to remote")
            #endif
        } catch {
            #if DEBUG
            print("[PresetsSyncEngine] Push error: \(error)")
            #endif
        }
    }

    // MARK: - Push New Local Presets

    private func pushNewLocalPresets() async {
        guard let userId = userId else { return }

        let store = FocusPresetStore.shared
        let db = SupabaseManager.shared.database

        // Fetch remote IDs
        let remoteIds: Set<UUID> = Set(
            ((try? await db
                .from("focus_presets")
                .select("id")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value) as [FocusPresetDTO]?)?.map { $0.id } ?? []
        )

        let localOnly = store.presets.filter { !remoteIds.contains($0.id) }
        guard !localOnly.isEmpty else { return }

        let dtos: [FocusPresetDTO] = localOnly.enumerated().map { offset, preset in
            FocusPresetDTO(
                id: preset.id,
                userId: userId,
                name: preset.name,
                durationSeconds: preset.durationSeconds,
                soundId: preset.soundID.isEmpty ? nil : preset.soundID,
                emoji: preset.emoji,
                isSystemDefault: preset.isSystemDefault,
                themeRaw: preset.themeRaw,
                externalMusicAppRaw: preset.externalMusicAppRaw,
                sortOrder: store.presets.count + offset
            )
        }

        do {
            try await db
                .from("focus_presets")
                .insert(dtos)
                .execute()

            #if DEBUG
            print("[PresetsSyncEngine] Pushed \(dtos.count) new local presets to remote")
            #endif
        } catch {
            #if DEBUG
            print("[PresetsSyncEngine] Push new presets error: \(error)")
            #endif
        }
    }

    // MARK: - Delete Preset

    func deletePresetRemote(presetId: UUID) async {
        guard isRunning, let userId = userId else { return }

        do {
            try await SupabaseManager.shared.database
                .from("focus_presets")
                .delete()
                .eq("id", value: presetId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()

            #if DEBUG
            print("[PresetsSyncEngine] Deleted preset \(presetId)")
            #endif
        } catch {
            #if DEBUG
            print("[PresetsSyncEngine] Delete error: \(error)")
            #endif
        }
    }

    // MARK: - Apply Remote to Local

    private func applyRemoteToLocal(presets: [FocusPresetDTO], activePresetId: UUID?) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }

        let store = FocusPresetStore.shared

        // Convert DTO -> local
        let localPresets: [FocusPreset] = presets.map { dto in
            FocusPreset(
                id: dto.id,
                name: dto.name,
                durationSeconds: dto.durationSeconds,
                soundID: dto.soundId ?? "",
                emoji: dto.emoji,
                isSystemDefault: dto.isSystemDefault,
                themeRaw: dto.themeRaw,
                externalMusicAppRaw: dto.externalMusicAppRaw
            )
        }

        // Single source of truth lives in FocusPresetStore.swift
        store.applyRemoteState(presets: localPresets, activePresetId: activePresetId)

        #if DEBUG
        print("[PresetsSyncEngine] Applied \(localPresets.count) presets to local")
        #endif
    }

    // MARK: - Observe Local Changes

    private func observeLocalChanges() {
        let store = FocusPresetStore.shared

        // Preset list changes
        store.$presets
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, self.isRunning, !self.isApplyingRemote else { return }
                Task { await self.pushToRemote() }
            }
            .store(in: &cancellables)

        // ✅ Active preset changes (observe published ID, not computed activePreset)
        store.$activePresetID
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, self.isRunning, !self.isApplyingRemote else { return }
                Task { await self.pushToRemote() }
            }
            .store(in: &cancellables)
    }
}
