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
        // ✅ Process sync queue when engines start
        Task {
            await SyncQueue.shared.processQueue()
        }
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
            // Check if error is network-related
            let isNetworkError = Self.isNetworkError(error)
            syncError = error
            
            #if DEBUG
            print("[SyncCoordinator] Initial sync error: \(error)")
            if isNetworkError {
                print("[SyncCoordinator] Network error detected - sync requires internet connection")
            }
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
    
    /// Sync a specific data type (pulls from remote)
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
    
    /// Push settings to remote (without pulling) - used by sync queue
    func pushSettingsOnly() async {
        await settingsEngine.forcePushNow()
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
    
    // MARK: - Force Push (for app lifecycle)
    
    /// Force immediate push of all pending changes (bypasses debounce)
    /// Call this when app enters background or is about to terminate
    func forcePushAllPending() async {
        guard AuthManagerV2.shared.state.userId != nil else { return }
        
        // Push settings and presets immediately (they use debounce)
        await settingsEngine.forcePushNow()
        await presetsEngine.forcePushNow()
        
        // ✅ Process sync queue to ensure all queued changes are synced
        await SyncQueue.shared.processQueue()
        
        // Tasks and sessions push immediately on change, but we can trigger a push if needed
        // (They don't use debounce, so they should already be synced)
        
        #if DEBUG
        print("[SyncCoordinator] Force pushed all pending changes and processed sync queue")
        #endif
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
            if Self.isNetworkError(error) {
                return "Sync failed - No internet connection"
            }
            return "Sync error: \(error.localizedDescription)"
        }
        
        if let date = lastSyncDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Last synced \(formatter.localizedString(for: date, relativeTo: Date()))"
        }
        
        return "Not synced"
    }
    
    /// Check if error is network-related
    static func isNetworkError(_ error: Error) -> Bool {
        let nsError = error as NSError
        let networkErrorCodes = [
            NSURLErrorNotConnectedToInternet,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorTimedOut,
            NSURLErrorCannotConnectToHost,
            NSURLErrorCannotFindHost,
            NSURLErrorDNSLookupFailed,
            NSURLErrorInternationalRoamingOff,
            NSURLErrorCallIsActive,
            NSURLErrorDataNotAllowed
        ]
        return networkErrorCodes.contains(nsError.code)
    }
}
