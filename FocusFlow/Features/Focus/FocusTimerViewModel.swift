import Foundation
import Combine
import SwiftUI

@MainActor
final class FocusTimerViewModel: ObservableObject {

    enum Phase: Equatable {
        case idle
        case running
        case paused
        case completed
    }

    // MARK: - Published
    @Published var totalSeconds: Int = 25 * 60
    @Published var remainingSeconds: Int = 25 * 60
    @Published private(set) var phase: Phase = .idle

    /// Optional session label (set by FocusView before start/resume)
    @Published var sessionName: String = ""

    // MARK: - Private
    private var timer: Timer?
    private var endDate: Date?

    /// Captured planned length on first start (pause/resume doesn't change this)
    private var plannedSessionTotalSeconds: Int = 0

    /// Captured start time (persisted) so we can restore accurately after lock/relaunch
    private var sessionStartDate: Date?

    /// Prevent double-logging (completion OR manual end)
    private var didLogThisSession: Bool = false

    // MARK: - Product rules (your decision)
    private let earlyEndMinimumCompletionRatio: Double = 0.40 // ✅ 40%
    private let earlyEndMinimumSeconds: Int = 5 * 60          // ✅ 5 minutes (OR rule)
    private let earlyEndHardFloorSeconds: Int = 60            // ✅ prevent junk accidental taps

    // MARK: - Persistence Keys
    private enum PersistKey {
        static let isActive = "FocusFlow.focusSession.isActive"
        static let isPaused = "FocusFlow.focusSession.isPaused"
        static let plannedSeconds = "FocusFlow.focusSession.plannedSeconds"
        static let startDate = "FocusFlow.focusSession.startDate" // TimeInterval since 1970
        static let pausedRemaining = "FocusFlow.focusSession.pausedRemaining"
        static let sessionName = "FocusFlow.focusSession.sessionName"
        static let activePresetID = "FocusFlow.focusSession.activePresetID" // ✅ Preset ID used for this session
        static let selectedFocusSound = "FocusFlow.focusSession.selectedFocusSound" // ✅ Sound used for this session
        static let selectedExternalMusicApp = "FocusFlow.focusSession.selectedExternalMusicApp" // ✅ External app used for this session
    }

    private let defaults = UserDefaults.standard

    // MARK: - Init
    init() {
        restoreIfNeeded()
    }

    // MARK: - Computed
    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Public API

    func toggle(sessionName: String) {
        switch phase {
        case .idle:
            self.sessionName = sessionName
            startInternal(isFresh: true)

        case .running:
            pauseInternal()

        case .paused:
            self.sessionName = sessionName
            startInternal(isFresh: false)

        case .completed:
            remainingSeconds = totalSeconds
            self.sessionName = sessionName
            startInternal(isFresh: true)
        }
    }

    func pause() {
        pauseInternal()
    }

    /// End session and return to default length.
    func resetToDefault() {
        logEarlyEndIfMeaningful()
        
        // ✅ Clear active preset when session is manually ended
        clearActivePresetIfSetBySession()
        clearPersistedSession()

        stopTimer()
        totalSeconds = 25 * 60
        remainingSeconds = totalSeconds
        plannedSessionTotalSeconds = 0
        sessionStartDate = nil
        didLogThisSession = false
        phase = .idle
    }

    /// End session and return to idle with same duration.
    func resetToIdleKeepDuration() {
        logEarlyEndIfMeaningful()
        
        // ✅ Clear active preset when session is manually ended
        clearActivePresetIfSetBySession()
        clearPersistedSession()

        stopTimer()
        remainingSeconds = totalSeconds
        plannedSessionTotalSeconds = 0
        sessionStartDate = nil
        didLogThisSession = false
        phase = .idle
    }

    /// Changing duration is treated as “setup”, not “ending a real session”.
    func updateMinutes(_ minutes: Int) {
        clearPersistedSession()

        stopTimer()
        totalSeconds = max(1, minutes) * 60
        remainingSeconds = totalSeconds
        plannedSessionTotalSeconds = 0
        sessionStartDate = nil
        didLogThisSession = false
        phase = .idle
    }

    /// External state (Live Activity / system)
    func applyExternalState(isPaused: Bool, remaining: Int, sessionName: String) {
        self.sessionName = sessionName

        // Ensure we have a planned duration if we’re restoring from outside
        if plannedSessionTotalSeconds == 0 {
            let planned = defaults.integer(forKey: PersistKey.plannedSeconds)
            plannedSessionTotalSeconds = planned > 0 ? planned : max(totalSeconds, 1)
        }
        if totalSeconds <= 0 {
            totalSeconds = plannedSessionTotalSeconds
        }

        let clamped = max(0, remaining)

        // If remaining hits 0 externally, we must complete + log reliably.
        if clamped == 0 {
            completeIfNeeded()
            return
        }

        remainingSeconds = clamped

        if isPaused {
            if phase == .running {
                pauseInternal()
            } else {
                stopTimer(keepRemaining: true)
                phase = .paused
                persistPaused(remainingSeconds: remainingSeconds)
            }
        } else {
            // Treat as running
            if sessionStartDate == nil {
                // If we don’t have a start, reconstruct one so remaining is accurate enough
                sessionStartDate = Date().addingTimeInterval(-TimeInterval(plannedSessionTotalSeconds - remainingSeconds))
            }
            startInternal(isFresh: false)
        }
    }

    func smoothProgress(now: Date) -> Double {
        if phase == .completed { return 1.0 }
        guard totalSeconds > 0 else { return 0 }

        if phase == .running,
           let endDate,
           plannedSessionTotalSeconds > 0 {
            let remaining = max(endDate.timeIntervalSince(now), 0)
            let elapsed = Double(plannedSessionTotalSeconds) - remaining
            return min(max(elapsed / Double(plannedSessionTotalSeconds), 0), 1)
        }

        return progress
    }

    // MARK: - Internals

    private func startInternal(isFresh: Bool) {
        guard remainingSeconds > 0 else { return }
        guard phase != .running else { return }

        if isFresh || plannedSessionTotalSeconds == 0 {
            plannedSessionTotalSeconds = remainingSeconds
            totalSeconds = plannedSessionTotalSeconds
            sessionStartDate = Date()
            didLogThisSession = false
        }

        phase = .running
        endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))

        persistRunning()

        timer?.invalidate()

        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.tick() }
        }
        newTimer.tolerance = 0.15
        timer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }

    private func pauseInternal() {
        guard phase == .running else { return }
        phase = .paused
        stopTimer(keepRemaining: true)
        persistPaused(remainingSeconds: remainingSeconds)
    }

    private func stopTimer(keepRemaining: Bool = true) {
        timer?.invalidate()
        timer = nil
        endDate = nil

        if !keepRemaining {
            remainingSeconds = totalSeconds
        }
    }

    private func tick() {
        guard phase == .running, let endDate else { return }

        let timeLeft = endDate.timeIntervalSinceNow
        if timeLeft <= 0 {
            completeIfNeeded()
        } else {
            remainingSeconds = Int(ceil(timeLeft))
            // keep persisted state fresh (cheap + keeps restore accurate)
            persistRunning()
        }
    }

    private func completeIfNeeded() {
        guard phase != .completed else { return }

        remainingSeconds = 0
        stopTimer(keepRemaining: true)
        phase = .completed

        // ✅ Completed sessions ALWAYS record
        let planned = plannedSessionTotalSeconds > 0 ? plannedSessionTotalSeconds : max(totalSeconds, 1)
        logSessionIfNeeded(durationSeconds: planned)

        // ✅ Clear active preset when session completes
        clearActivePresetIfSetBySession()
        clearPersistedSession()
    }

    /// ✅ Early-end rule:
    /// Record if:
    /// - elapsed >= 60s (hard floor)
    /// - AND (elapsed >= 5 minutes OR ratio >= 40%)
    private func logEarlyEndIfMeaningful() {
        guard phase == .running || phase == .paused else { return }
        guard plannedSessionTotalSeconds > 0 else { return }
        guard !didLogThisSession else { return }

        let elapsed = computeElapsedSeconds()
        guard elapsed >= earlyEndHardFloorSeconds else { return }

        let ratio = Double(elapsed) / Double(plannedSessionTotalSeconds)
        let meetsRule = (elapsed >= earlyEndMinimumSeconds) || (ratio >= earlyEndMinimumCompletionRatio)
        guard meetsRule else { return }

        logSessionIfNeeded(durationSeconds: elapsed)
    }

    private func computeElapsedSeconds() -> Int {
        let elapsed: Int

        switch phase {
        case .running:
            if let endDate {
                let remaining = max(endDate.timeIntervalSinceNow, 0)
                let raw = Double(plannedSessionTotalSeconds) - remaining
                elapsed = max(0, min(plannedSessionTotalSeconds, Int(floor(raw))))
            } else if let start = sessionStartDate {
                let raw = Date().timeIntervalSince(start)
                elapsed = max(0, min(plannedSessionTotalSeconds, Int(floor(raw))))
            } else {
                elapsed = max(0, min(plannedSessionTotalSeconds, plannedSessionTotalSeconds - remainingSeconds))
            }

        case .paused:
            elapsed = max(0, min(plannedSessionTotalSeconds, plannedSessionTotalSeconds - remainingSeconds))

        default:
            elapsed = 0
        }

        return elapsed
    }

    private func logSessionIfNeeded(durationSeconds: Int) {
        guard !didLogThisSession else { return }
        didLogThisSession = true

        let durationToLog = TimeInterval(max(durationSeconds, 0))
        guard durationToLog > 0 else { return }

        let trimmed = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameToStore: String? = trimmed.isEmpty ? nil : trimmed

        // ✅ Single source of truth:
        // ProgressStore persists the session and triggers AppSyncManager.sessionDidComplete internally.
        ProgressStore.shared.addSession(duration: durationToLog, sessionName: nameToStore)
    }

    // MARK: - Persistence

    private func persistRunning() {
        defaults.set(true, forKey: PersistKey.isActive)
        defaults.set(false, forKey: PersistKey.isPaused)
        defaults.set(plannedSessionTotalSeconds, forKey: PersistKey.plannedSeconds)

        let start = sessionStartDate ?? Date()
        defaults.set(start.timeIntervalSince1970, forKey: PersistKey.startDate)
        defaults.set(0, forKey: PersistKey.pausedRemaining)

        defaults.set(sessionName, forKey: PersistKey.sessionName)
        
        // ✅ Persist active preset ID so it can be restored when app relaunches
        if let presetID = FocusPresetStore.shared.activePresetID {
            defaults.set(presetID.uuidString, forKey: PersistKey.activePresetID)
        } else {
            defaults.removeObject(forKey: PersistKey.activePresetID)
        }
        
        // ✅ Persist sound and external app so they can be restored when app relaunches
        if let sound = AppSettings.shared.selectedFocusSound {
            defaults.set(sound.rawValue, forKey: PersistKey.selectedFocusSound)
        } else {
            defaults.removeObject(forKey: PersistKey.selectedFocusSound)
        }
        
        if let app = AppSettings.shared.selectedExternalMusicApp {
            defaults.set(app.rawValue, forKey: PersistKey.selectedExternalMusicApp)
        } else {
            defaults.removeObject(forKey: PersistKey.selectedExternalMusicApp)
        }
        
        // ✅ Sync to Home Screen widgets
        WidgetDataManager.shared.updateActiveSession(
            isActive: true,
            sessionName: sessionName,
            endDate: endDate,
            isPaused: false,
            totalSeconds: plannedSessionTotalSeconds,
            remainingSeconds: remainingSeconds
        )
    }

    private func persistPaused(remainingSeconds: Int) {
        defaults.set(true, forKey: PersistKey.isActive)
        defaults.set(true, forKey: PersistKey.isPaused)
        defaults.set(plannedSessionTotalSeconds, forKey: PersistKey.plannedSeconds)

        let start = sessionStartDate ?? Date()
        defaults.set(start.timeIntervalSince1970, forKey: PersistKey.startDate)
        defaults.set(remainingSeconds, forKey: PersistKey.pausedRemaining)

        defaults.set(sessionName, forKey: PersistKey.sessionName)
        
        // ✅ Persist active preset ID so it can be restored when app relaunches
        if let presetID = FocusPresetStore.shared.activePresetID {
            defaults.set(presetID.uuidString, forKey: PersistKey.activePresetID)
        } else {
            defaults.removeObject(forKey: PersistKey.activePresetID)
        }
        
        // ✅ Persist sound and external app so they can be restored when app relaunches
        if let sound = AppSettings.shared.selectedFocusSound {
            defaults.set(sound.rawValue, forKey: PersistKey.selectedFocusSound)
        } else {
            defaults.removeObject(forKey: PersistKey.selectedFocusSound)
        }
        
        if let app = AppSettings.shared.selectedExternalMusicApp {
            defaults.set(app.rawValue, forKey: PersistKey.selectedExternalMusicApp)
        } else {
            defaults.removeObject(forKey: PersistKey.selectedExternalMusicApp)
        }
        
        // ✅ Sync to Home Screen widgets (paused state)
        WidgetDataManager.shared.updateActiveSession(
            isActive: true,
            sessionName: sessionName,
            endDate: nil,
            isPaused: true,
            totalSeconds: plannedSessionTotalSeconds,
            remainingSeconds: remainingSeconds
        )
    }

    private func clearPersistedSession() {
        defaults.removeObject(forKey: PersistKey.isActive)
        defaults.removeObject(forKey: PersistKey.isPaused)
        defaults.removeObject(forKey: PersistKey.plannedSeconds)
        defaults.removeObject(forKey: PersistKey.startDate)
        defaults.removeObject(forKey: PersistKey.pausedRemaining)
        defaults.removeObject(forKey: PersistKey.sessionName)
        defaults.removeObject(forKey: PersistKey.activePresetID)
        defaults.removeObject(forKey: PersistKey.selectedFocusSound)
        defaults.removeObject(forKey: PersistKey.selectedExternalMusicApp)
        
        // ✅ Clear widget session state and sync all data
        WidgetDataManager.shared.updateActiveSession(
            isActive: false,
            sessionName: nil,
            endDate: nil,
            isPaused: false,
            totalSeconds: 0,
            remainingSeconds: 0
        )
        WidgetDataManager.shared.syncAll()
    }
    
    /// ✅ Clear active preset if it was set by the current session
    private func clearActivePresetIfSetBySession() {
        // Only clear if there's a persisted preset ID (meaning this session started with a preset)
        if let presetIDString = defaults.string(forKey: PersistKey.activePresetID),
           let presetID = UUID(uuidString: presetIDString),
           FocusPresetStore.shared.activePresetID == presetID {
            // Only clear if it matches the persisted one (to avoid clearing manually selected presets)
            FocusPresetStore.shared.activePresetID = nil
        }
        
        // ✅ Clear sound and external app if they were set by this session
        // Check if they match what was persisted for this session
        // Defer to next run loop to avoid publishing during view updates
        Task { @MainActor in
            if defaults.string(forKey: PersistKey.selectedFocusSound) != nil {
                AppSettings.shared.selectedFocusSound = nil
            }
            if defaults.string(forKey: PersistKey.selectedExternalMusicApp) != nil {
                AppSettings.shared.selectedExternalMusicApp = nil
            }
        }
    }

    private func restoreIfNeeded() {
        let isActive = defaults.bool(forKey: PersistKey.isActive)
        guard isActive else { return }

        let planned = defaults.integer(forKey: PersistKey.plannedSeconds)
        guard planned > 0 else {
            clearPersistedSession()
            return
        }

        let name = defaults.string(forKey: PersistKey.sessionName) ?? ""
        self.sessionName = name
        self.totalSeconds = planned
        self.plannedSessionTotalSeconds = planned
        self.didLogThisSession = false

        let isPaused = defaults.bool(forKey: PersistKey.isPaused)

        if isPaused {
            let pausedRemaining = defaults.integer(forKey: PersistKey.pausedRemaining)
            self.remainingSeconds = max(0, min(planned, pausedRemaining))
            self.phase = .paused
            self.sessionStartDate = Date(timeIntervalSince1970: defaults.double(forKey: PersistKey.startDate))
            
            // ✅ Restore active preset ID if session was started with a preset
            if let presetIDString = defaults.string(forKey: PersistKey.activePresetID),
               let presetID = UUID(uuidString: presetIDString),
               FocusPresetStore.shared.presets.contains(where: { $0.id == presetID }) {
                FocusPresetStore.shared.activePresetID = presetID
            }
            
            // ✅ Restore sound and external app if they were used for this session
            // Defer to next run loop to avoid publishing during view updates
            Task { @MainActor in
                if let soundRaw = defaults.string(forKey: PersistKey.selectedFocusSound),
                   let sound = FocusSound(rawValue: soundRaw) {
                    AppSettings.shared.selectedFocusSound = sound
                } else {
                    AppSettings.shared.selectedFocusSound = nil
                }
                
                if let appRaw = defaults.string(forKey: PersistKey.selectedExternalMusicApp),
                   let app = AppSettings.ExternalMusicApp(rawValue: appRaw) {
                    AppSettings.shared.selectedExternalMusicApp = app
                } else {
                    AppSettings.shared.selectedExternalMusicApp = nil
                }
            }
            
            return
        }

        // Running: compute remaining from startDate
        let startTS = defaults.double(forKey: PersistKey.startDate)
        guard startTS > 0 else {
            clearPersistedSession()
            return
        }

        let start = Date(timeIntervalSince1970: startTS)
        self.sessionStartDate = start

        let elapsed = Int(Date().timeIntervalSince(start))
        let remaining = planned - elapsed

        if remaining <= 0 {
            // It finished while we were away -> record it NOW
            self.remainingSeconds = 0
            self.phase = .completed
            logSessionIfNeeded(durationSeconds: planned)
            
            // ✅ Clear active preset when session completed while app was away
            clearActivePresetIfSetBySession()
            clearPersistedSession()
            return
        }

        self.remainingSeconds = remaining
        
        // ✅ Restore active preset ID if session was started with a preset
        if let presetIDString = defaults.string(forKey: PersistKey.activePresetID),
           let presetID = UUID(uuidString: presetIDString),
           FocusPresetStore.shared.presets.contains(where: { $0.id == presetID }) {
            FocusPresetStore.shared.activePresetID = presetID
        }
        
        // ✅ Restore sound and external app BEFORE changing phase so the phase transition handler can start playback
        // Defer to next run loop to avoid publishing during view updates
        Task { @MainActor in
            if let soundRaw = defaults.string(forKey: PersistKey.selectedFocusSound),
               let sound = FocusSound(rawValue: soundRaw) {
                AppSettings.shared.selectedFocusSound = sound
            } else {
                AppSettings.shared.selectedFocusSound = nil
            }
            
            if let appRaw = defaults.string(forKey: PersistKey.selectedExternalMusicApp),
               let app = AppSettings.ExternalMusicApp(rawValue: appRaw) {
                AppSettings.shared.selectedExternalMusicApp = app
            } else {
                AppSettings.shared.selectedExternalMusicApp = nil
            }
        }
        
        // Resume ticking (this will trigger phase change to .running, and sound will be ready)
        startInternal(isFresh: false)
    }
}
