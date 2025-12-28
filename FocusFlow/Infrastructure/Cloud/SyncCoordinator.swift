//
//  SyncCoordinator.swift
//  FocusFlow
//
//  Orchestrates sync engines based on authentication state.
//  Starts/stops engines when user signs in/out.
//

import Foundation
import Combine

@MainActor
final class SyncCoordinator: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = SyncCoordinator()
    
    // MARK: - Sync Engines
    
    private let settingsEngine = SettingsSyncEngine()
    private let tasksEngine = TasksSyncEngine()
    private let sessionsEngine = SessionsSyncEngine()
    private let presetsEngine = PresetsSyncEngine()
    
    // MARK: - State
    
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var syncError: Error?
    
    // MARK: - Private
    
    private var cancellables = Set<AnyCancellable>()
    private var isRunning = false
    
    // MARK: - Init
    
    private init() {
        observeAuthState()
    }
    
    // MARK: - Auth State Observation
    
    private func observeAuthState() {
        AuthManagerV2.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleAuthStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func handleAuthStateChange(_ state: CloudAuthState) {
        switch state {
        case .unknown:
            // Still loading, do nothing
            break
            
        case .guest:
            // Guest mode - stop all sync
            stopAllEngines()
            #if DEBUG
            print("[SyncCoordinator] Guest mode - sync disabled")
            #endif
            
        case .signedIn(let userId):
            // Start sync for this user
            startAllEngines(userId: userId)
            #if DEBUG
            print("[SyncCoordinator] Signed in - starting sync for \(userId)")
            #endif
            
        case .signedOut:
            // Signed out - stop all sync
            stopAllEngines()
            #if DEBUG
            print("[SyncCoordinator] Signed out - sync stopped")
            #endif
        }
    }
    
    // MARK: - Engine Control
    
    private func startAllEngines(userId: UUID) {
        guard !isRunning else { return }
        isRunning = true
        
        Task {
            await performInitialSync(userId: userId)
        }
    }
    
    private func stopAllEngines() {
        isRunning = false
        settingsEngine.stop()
        tasksEngine.stop()
        sessionsEngine.stop()
        presetsEngine.stop()
    }
    
    // MARK: - Initial Sync
    
    /// Performs initial sync when user signs in.
    /// Order matters: settings first, then data.
    private func performInitialSync(userId: UUID) async {
        guard isRunning else { return }
        
        isSyncing = true
        syncError = nil
        
        do {
            // Step 1: Sync settings (may affect other syncs)
            try await settingsEngine.start(userId: userId)
            
            guard isRunning else { return }
            
            // Step 2: Sync presets (needed for sessions)
            try await presetsEngine.start(userId: userId)
            
            guard isRunning else { return }
            
            // Step 3: Sync sessions
            try await sessionsEngine.start(userId: userId)
            
            guard isRunning else { return }
            
            // Step 4: Sync tasks and completions
            try await tasksEngine.start(userId: userId)
            
            lastSyncDate = Date()
            
            #if DEBUG
            print("[SyncCoordinator] Initial sync completed successfully")
            #endif
            
        } catch {
            syncError = error
            #if DEBUG
            print("[SyncCoordinator] Initial sync error: \(error)")
            #endif
        }
        
        isSyncing = false
    }
    
    // MARK: - Manual Sync
    
    /// Manually trigger a full sync (e.g., on pull-to-refresh)
    func syncNow() async {
        guard let userId = AuthManagerV2.shared.state.userId else {
            #if DEBUG
            print("[SyncCoordinator] Cannot sync - not signed in")
            #endif
            return
        }
        
        await performInitialSync(userId: userId)
    }
    
    /// Sync a specific data type
    func syncSettings() async {
        guard let userId = AuthManagerV2.shared.state.userId else { return }
        
        do {
            try await settingsEngine.pullFromRemote(userId: userId)
        } catch {
            #if DEBUG
            print("[SyncCoordinator] Settings sync error: \(error)")
            #endif
        }
    }
    
    func syncTasks() async {
        guard let userId = AuthManagerV2.shared.state.userId else { return }
        
        do {
            try await tasksEngine.pullFromRemote(userId: userId)
        } catch {
            #if DEBUG
            print("[SyncCoordinator] Tasks sync error: \(error)")
            #endif
        }
    }
    
    func syncSessions() async {
        guard let userId = AuthManagerV2.shared.state.userId else { return }
        
        do {
            try await sessionsEngine.pullFromRemote(userId: userId)
        } catch {
            #if DEBUG
            print("[SyncCoordinator] Sessions sync error: \(error)")
            #endif
        }
    }
    
    func syncPresets() async {
        guard let userId = AuthManagerV2.shared.state.userId else { return }
        
        do {
            try await presetsEngine.pullFromRemote(userId: userId)
        } catch {
            #if DEBUG
            print("[SyncCoordinator] Presets sync error: \(error)")
            #endif
        }
    }
}

// MARK: - Sync Status

extension SyncCoordinator {
    
    /// Human-readable sync status
    var statusMessage: String {
        if isSyncing {
            return "Syncing..."
        }
        
        if let error = syncError {
            return "Sync error: \(error.localizedDescription)"
        }
        
        if let date = lastSyncDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Last synced \(formatter.localizedString(for: date, relativeTo: Date()))"
        }
        
        return "Not synced"
    }
}
