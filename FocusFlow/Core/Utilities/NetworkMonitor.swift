//
//  NetworkMonitor.swift
//  FocusFlow
//
//  Monitors network connectivity status using iOS Network framework.
//

import Foundation
import Network
import Combine

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    // MARK: - Published State
    
    @Published private(set) var isConnected = true
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    // MARK: - Connection Type
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case other
        case unknown
        
        var displayName: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .other: return "Network"
            case .unknown: return "Unknown"
            }
        }
    }
    
    // MARK: - Private
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // MARK: - Init
    
    private init() {
        startMonitoring()
    }
    
    // MARK: - Monitoring
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self else { return }
                
                let wasConnected = self.isConnected
                self.isConnected = path.status == .satisfied
                
                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .ethernet
                } else if path.status == .satisfied {
                    self.connectionType = .other
                } else {
                    self.connectionType = .unknown
                }
                
                #if DEBUG
                if wasConnected != self.isConnected {
                    print("[NetworkMonitor] Connection changed: \(self.isConnected ? "Connected" : "Disconnected") via \(self.connectionType.displayName)")
                }
                #endif
            }
        }
        
        monitor.start(queue: queue)
    }
    
    // MARK: - Public Helpers
    
    var isOffline: Bool {
        !isConnected
    }
    
    var statusMessage: String {
        if isConnected {
            return "Connected via \(connectionType.displayName)"
        } else {
            return "Offline - No internet connection"
        }
    }
}

