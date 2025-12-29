import Foundation
import Combine

/// Manages data backup and restore functionality for FocusFlow
/// Provides 7-day backup retention for undo capability
/// Stores backups as JSON files in Documents directory for easy export/sharing
@MainActor
final class DataBackupManager: ObservableObject {
    static let shared = DataBackupManager()
    
    @Published private(set) var hasBackup: Bool = false
    @Published private(set) var backupDate: Date?
    
    private let backupRetentionDays = 7
    private let backupFileName = "FocusFlow_Backup.json"
    
    /// Returns the URL for the backup file in Documents directory
    private var backupFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(backupFileName)
    }
    
    /// Returns the URL for the backup metadata file
    private var backupMetadataURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("FocusFlow_Backup_Metadata.json")
    }
    
    private init() {
        checkBackupStatus()
    }
    
    // MARK: - Backup Data Structure
    
    struct AppDataBackup: Codable {
        let sessions: [ProgressSession]
        let dailyGoalMinutes: Int
        let tasks: [FFTaskItem]
        let completedOccurrenceKeys: [String]
        let goalHistory: [String: Int] // date string -> goal minutes
        let backupDate: Date
        let version: String
        
        init(
            sessions: [ProgressSession],
            dailyGoalMinutes: Int,
            tasks: [FFTaskItem],
            completedOccurrenceKeys: [String],
            goalHistory: [String: Int]
        ) {
            self.sessions = sessions
            self.dailyGoalMinutes = dailyGoalMinutes
            self.tasks = tasks
            self.completedOccurrenceKeys = completedOccurrenceKeys
            self.goalHistory = goalHistory
            self.backupDate = Date()
            self.version = "1.0"
        }
    }
    
    // MARK: - Public Methods
    
    /// Creates a backup of all app data
    func createBackup() throws {
        let progressStore = ProgressStore.shared
        let tasksStore = TasksStore.shared
        
        // Export goal history
        let goalHistory = exportGoalHistory()
        
        let backup = AppDataBackup(
            sessions: progressStore.sessions,
            dailyGoalMinutes: progressStore.dailyGoalMinutes,
            tasks: tasksStore.tasks,
            completedOccurrenceKeys: Array(tasksStore.completedOccurrenceKeys),
            goalHistory: goalHistory
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(backup)
        
        // Save backup to Documents directory
        try data.write(to: backupFileURL, options: [.atomic])
        
        // Save metadata (backup date)
        let metadata = ["backupDate": backup.backupDate]
        let metadataData = try JSONEncoder().encode(metadata)
        try metadataData.write(to: backupMetadataURL, options: [.atomic])
        
        checkBackupStatus()
    }
    
    /// Restores data from the most recent backup
    func restoreBackup() throws {
        guard FileManager.default.fileExists(atPath: backupFileURL.path),
              let data = try? Data(contentsOf: backupFileURL) else {
            throw BackupError.noBackupFound
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(AppDataBackup.self, from: data)
        
        // Check if backup is expired
        let daysSinceBackup = Calendar.current.dateComponents([.day], from: backup.backupDate, to: Date()).day ?? 0
        if daysSinceBackup > backupRetentionDays {
            throw BackupError.backupExpired(daysOld: daysSinceBackup)
        }
        
        // Restore data
        let progressStore = ProgressStore.shared
        let tasksStore = TasksStore.shared
        
        // Restore progress sessions using the public restore method
        progressStore.restore(sessions: backup.sessions, dailyGoalMinutes: backup.dailyGoalMinutes)
        
        // Restore tasks using the applyRemoteState method (this handles saving internally)
        tasksStore.applyRemoteState(tasks: backup.tasks, completionKeys: Set(backup.completedOccurrenceKeys))
        
        // Restore goal history
        importGoalHistory(backup.goalHistory)
        
        AppSyncManager.shared.forceRefresh()
    }
    
    /// Deletes the current backup
    func deleteBackup() {
        try? FileManager.default.removeItem(at: backupFileURL)
        try? FileManager.default.removeItem(at: backupMetadataURL)
        checkBackupStatus()
    }
    
    /// Returns the backup file URL for sharing/exporting
    func getBackupFileURL() throws -> URL {
        guard FileManager.default.fileExists(atPath: backupFileURL.path) else {
            throw BackupError.noBackupFound
        }
        return backupFileURL
    }
    
    /// Exports backup data as JSON string for sharing
    func exportBackupAsJSON() throws -> String {
        guard FileManager.default.fileExists(atPath: backupFileURL.path),
              let data = try? Data(contentsOf: backupFileURL) else {
            throw BackupError.noBackupFound
        }
        
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw BackupError.encodingFailed
        }
        
        return jsonString
    }
    
    /// Checks if backup exists and is still valid
    private func checkBackupStatus() {
        guard FileManager.default.fileExists(atPath: backupFileURL.path),
              let metadataData = try? Data(contentsOf: backupMetadataURL),
              let metadata = try? JSONDecoder().decode([String: Date].self, from: metadataData),
              let backupDate = metadata["backupDate"] else {
            hasBackup = false
            self.backupDate = nil
            return
        }
        
        let daysSinceBackup = Calendar.current.dateComponents([.day], from: backupDate, to: Date()).day ?? 0
        
        if daysSinceBackup > backupRetentionDays {
            // Backup expired, delete it
            deleteBackup()
            hasBackup = false
            self.backupDate = nil
        } else {
            hasBackup = true
            self.backupDate = backupDate
        }
    }
    
    /// Returns formatted backup age string
    func backupAgeString() -> String? {
        guard let backupDate = backupDate else { return nil }
        
        let daysSince = Calendar.current.dateComponents([.day], from: backupDate, to: Date()).day ?? 0
        
        if daysSince == 0 {
            return "Backed up today"
        } else if daysSince == 1 {
            return "Backed up yesterday"
        } else {
            return "Backed up \(daysSince) days ago"
        }
    }
    
    /// Returns days remaining until backup expires
    func daysUntilExpiration() -> Int? {
        guard let backupDate = backupDate else { return nil }
        let daysSince = Calendar.current.dateComponents([.day], from: backupDate, to: Date()).day ?? 0
        return max(0, backupRetentionDays - daysSince)
    }
    
    // MARK: - Errors
    
    enum BackupError: LocalizedError {
        case noBackupFound
        case backupExpired(daysOld: Int)
        case encodingFailed
        case decodingFailed
        
        var errorDescription: String? {
            switch self {
            case .noBackupFound:
                return "No backup found"
            case .backupExpired(let days):
                return "Backup expired (\(days) days old)"
            case .encodingFailed:
                return "Failed to encode backup data"
            case .decodingFailed:
                return "Failed to decode backup data"
            }
        }
    }
}

// MARK: - GoalHistory Export/Import

// Note: GoalHistory is a private enum in ProfileView.swift
// We access it via UserDefaults using the known key
private extension DataBackupManager {
    static let goalHistoryKey = "focusflow.pv2.dailyGoalHistory.v1"
    
    func exportGoalHistory() -> [String: Int] {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: Self.goalHistoryKey),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return dict
    }
    
    func importGoalHistory(_ goalHistory: [String: Int]) {
        guard let data = try? JSONEncoder().encode(goalHistory) else { return }
        UserDefaults.standard.set(data, forKey: Self.goalHistoryKey)
    }
}

