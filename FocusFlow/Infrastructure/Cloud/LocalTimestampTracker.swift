//
//  LocalTimestampTracker.swift
//  FocusFlow
//
//  Tracks when data was last modified locally for conflict resolution
//

import Foundation

@MainActor
final class LocalTimestampTracker {
    static let shared = LocalTimestampTracker()
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Timestamp Keys
    
    private func timestampKey(for field: String, namespace: String) -> String {
        "ff_local_ts_\(field)_\(namespace)"
    }
    
    // MARK: - Track Changes
    
    /// Record that a field was just modified locally
    func recordLocalChange(field: String, namespace: String) {
        let key = timestampKey(for: field, namespace: namespace)
        defaults.set(Date(), forKey: key)
        // Debug logging removed to reduce noise - only log in verbose mode if needed
    }
    
    /// Get when a field was last modified locally
    func getLocalTimestamp(field: String, namespace: String) -> Date? {
        let key = timestampKey(for: field, namespace: namespace)
        return defaults.object(forKey: key) as? Date
    }
    
    /// Check if local data is newer than remote
    func isLocalNewer(field: String, namespace: String, remoteTimestamp: Date?) -> Bool {
        guard let remoteTimestamp = remoteTimestamp else {
            // No remote timestamp means it's new, so local might be newer
            return getLocalTimestamp(field: field, namespace: namespace) != nil
        }
        
        guard let localTimestamp = getLocalTimestamp(field: field, namespace: namespace) else {
            // No local timestamp means remote is newer
            return false
        }
        
        return localTimestamp > remoteTimestamp
    }
    
    /// Clear timestamp for a field (when applying remote data)
    func clearLocalTimestamp(field: String, namespace: String) {
        let key = timestampKey(for: field, namespace: namespace)
        defaults.removeObject(forKey: key)
    }
    
    /// Clear all timestamps for a namespace (when switching accounts)
    func clearAllTimestamps(namespace: String) {
        let allKeys = defaults.dictionaryRepresentation().keys
        let prefix = "ff_local_ts_"
        let suffix = "_\(namespace)"
        
        for key in allKeys {
            if key.hasPrefix(prefix) && key.hasSuffix(suffix) {
                defaults.removeObject(forKey: key)
            }
        }
        
        #if DEBUG
        print("[LocalTimestampTracker] Cleared all timestamps for namespace: \(namespace)")
        #endif
    }
}

