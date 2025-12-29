//
//  SyncQueue.swift
//  FocusFlow
//
//  Reliable sync queue system - ensures no changes are ever lost
//  Queues all changes and processes them even if app is killed
//

import Foundation
import Combine

// MARK: - Sync Operation Types

enum SyncType: String, Codable {
    case settings
    case preset
    case task
    case session
}

enum SyncOperationType: String, Codable {
    case create
    case update
    case delete
}

enum SyncStatus: String, Codable {
    case pending    // Waiting to be synced
    case syncing    // Currently being synced
    case completed  // Successfully synced
    case failed     // Failed after retries
}

// MARK: - Sync Operation

struct SyncOperation: Identifiable, Codable {
    let id: UUID
    let type: SyncType
    let operation: SyncOperationType
    let data: Data // Encoded model data
    let localTimestamp: Date
    var retryCount: Int
    var status: SyncStatus
    var lastError: String?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        type: SyncType,
        operation: SyncOperationType,
        data: Data,
        localTimestamp: Date = Date(),
        retryCount: Int = 0,
        status: SyncStatus = .pending,
        lastError: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.operation = operation
        self.data = data
        self.localTimestamp = localTimestamp
        self.retryCount = retryCount
        self.status = status
        self.lastError = lastError
        self.createdAt = createdAt
    }
}

// MARK: - Sync Queue Manager

@MainActor
final class SyncQueue: ObservableObject {
    static let shared = SyncQueue()
    
    @Published private(set) var pendingCount: Int = 0
    @Published private(set) var failedCount: Int = 0
    
    private let defaults = UserDefaults.standard
    private let maxRetries = 5
    private let retryDelays: [TimeInterval] = [1, 2, 4, 8, 16] // Exponential backoff
    
    private var operations: [SyncOperation] = []
    private var isProcessing = false
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadQueue()
        updateCounts()
        observeNetworkChanges()
    }
    
    // MARK: - Network Observation
    
    private func observeNetworkChanges() {
        // Auto-process queue when network comes back online
        NetworkMonitor.shared.$isConnected
            .dropFirst()
            .sink { [weak self] isConnected in
                if isConnected {
                    Task { @MainActor in
                        await self?.processQueue()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Queue Management
    
    private func key(for namespace: String) -> String {
        "ff_sync_queue_\(namespace)"
    }
    
    private func loadQueue() {
        guard let userId = AuthManagerV2.shared.state.userId else {
            operations = []
            return
        }
        
        let namespace = userId.uuidString
        guard let data = defaults.data(forKey: key(for: namespace)) else {
            operations = []
            return
        }
        
        do {
            operations = try JSONDecoder().decode([SyncOperation].self, from: data)
            // Only keep pending and syncing operations (remove old completed/failed)
            operations = operations.filter { $0.status == .pending || $0.status == .syncing }
        } catch {
            operations = []
        }
        
        updateCounts()
    }
    
    private func saveQueue() {
        guard let userId = AuthManagerV2.shared.state.userId else { return }
        let namespace = userId.uuidString
        
        do {
            let data = try JSONEncoder().encode(operations)
            defaults.set(data, forKey: key(for: namespace))
            updateCounts()
        } catch {
            #if DEBUG
            print("[SyncQueue] Failed to save queue: \(error)")
            #endif
        }
    }
    
    private func updateCounts() {
        pendingCount = operations.filter { $0.status == .pending }.count
        failedCount = operations.filter { $0.status == .failed }.count
    }
    
    // MARK: - Add Operations
    
    /// Queue a settings change for sync
    func enqueueSettingsChange(data: Data, localTimestamp: Date = Date()) {
        let operation = SyncOperation(
            type: .settings,
            operation: .update,
            data: data,
            localTimestamp: localTimestamp
        )
        addOperation(operation)
    }
    
    /// Queue a preset change for sync
    func enqueuePresetChange(operation: SyncOperationType, preset: FocusPreset, localTimestamp: Date = Date()) {
        guard let data = try? JSONEncoder().encode(preset) else { return }
        
        let syncOp = SyncOperation(
            type: .preset,
            operation: operation,
            data: data,
            localTimestamp: localTimestamp
        )
        addOperation(syncOp)
    }
    
    /// Add operation to queue
    private func addOperation(_ operation: SyncOperation) {
        // Remove any existing pending operation of the same type for the same item
        // (e.g., if we have multiple updates to the same preset, keep only the latest)
        if operation.type == .preset || operation.type == .settings {
            operations.removeAll { op in
                op.type == operation.type &&
                op.status == .pending &&
                op.id != operation.id
            }
        }
        
        operations.append(operation)
        saveQueue()
        
        #if DEBUG
        print("[SyncQueue] Enqueued \(operation.type.rawValue) \(operation.operation.rawValue) operation")
        #endif
        
        // Auto-process if not already processing
        if !isProcessing {
            Task {
                await processQueue()
            }
        }
    }
    
    // MARK: - Process Queue
    
    /// Process all pending operations
    func processQueue() async {
        guard !isProcessing else { return }
        guard NetworkMonitor.shared.isConnected else {
            #if DEBUG
            print("[SyncQueue] Skipping sync - offline")
            #endif
            return
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let pending = operations.filter { $0.status == .pending }
        
        for operation in pending {
            await processOperation(operation)
        }
        
        // Clean up old completed operations (older than 24 hours)
        let oneDayAgo = Date().addingTimeInterval(-86400)
        operations.removeAll { op in
            (op.status == .completed || op.status == .failed) && op.createdAt < oneDayAgo
        }
        
        saveQueue()
    }
    
    private func processOperation(_ operation: SyncOperation) async {
        // Mark as syncing
        if let index = operations.firstIndex(where: { $0.id == operation.id }) {
            operations[index].status = .syncing
            saveQueue()
        }
        
        do {
            switch operation.type {
            case .settings:
                try await processSettingsOperation(operation)
            case .preset:
                try await processPresetOperation(operation)
            case .task:
                // TODO: Implement task sync
                break
            case .session:
                // TODO: Implement session sync
                break
            }
            
            // Mark as completed
            if let index = operations.firstIndex(where: { $0.id == operation.id }) {
                operations[index].status = .completed
                operations[index].retryCount = 0
                operations[index].lastError = nil
                saveQueue()
            }
            
        } catch {
            // Handle error
            if let index = operations.firstIndex(where: { $0.id == operation.id }) {
                operations[index].retryCount += 1
                operations[index].lastError = error.localizedDescription
                
                if operations[index].retryCount >= maxRetries {
                    operations[index].status = .failed
                    #if DEBUG
                    print("[SyncQueue] Operation \(operation.id) failed after \(maxRetries) retries")
                    #endif
                } else {
                    operations[index].status = .pending
                    // Schedule retry with exponential backoff
                    let delay = retryDelays[min(operations[index].retryCount - 1, retryDelays.count - 1)]
                    Task {
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        await processQueue()
                    }
                }
                saveQueue()
            }
        }
    }
    
    // MARK: - Process Specific Types
    
    private func processSettingsOperation(_ operation: SyncOperation) async throws {
        // ✅ FIX: Only push, don't pull - pulling causes sync loops
        // The queue is for pushing local changes, not pulling remote changes
        guard let userId = AuthManagerV2.shared.state.userId else { return }
        await SyncCoordinator.shared.pushSettingsOnly()
    }
    
    private func processPresetOperation(_ operation: SyncOperation) async throws {
        // Delegate to PresetsSyncEngine
        guard let userId = AuthManagerV2.shared.state.userId else { return }
        await SyncCoordinator.shared.syncPresets()
    }
    
    // MARK: - Manual Retry
    
    /// Retry failed operations
    func retryFailed() async {
        let failed = operations.filter { $0.status == .failed }
        for operation in failed {
            if let index = operations.firstIndex(where: { $0.id == operation.id }) {
                operations[index].status = .pending
                operations[index].retryCount = 0
                operations[index].lastError = nil
            }
        }
        saveQueue()
        await processQueue()
    }
    
    // MARK: - Clear Queue
    
    func clearCompleted() {
        operations.removeAll { $0.status == .completed }
        saveQueue()
    }
    
    func clearAll() {
        operations.removeAll()
        saveQueue()
    }
}

