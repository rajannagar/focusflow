import Foundation
import Combine

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

    /// Optional session label to store with Stats (set by FocusView before start/resume)
    @Published var sessionName: String = ""

    // MARK: - Private
    private var timer: Timer?
    private var endDate: Date?

    /// Captured planned length on first start (pause/resume doesn't change this)
    private var plannedSessionTotalSeconds: Int = 0

    /// Prevent double-logging
    private var didLogCompletion: Bool = false

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

    /// Single “one true toggle” used by the orb + the main button.
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
            // Start again with same duration
            remainingSeconds = totalSeconds
            self.sessionName = sessionName
            startInternal(isFresh: true)
        }
    }

    func pause() {
        pauseInternal()
    }

    /// “Factory reset” for the focus timer only (FocusView may also clear presets/theme/sound).
    func resetToDefault() {
        stopTimer()
        totalSeconds = 25 * 60
        remainingSeconds = totalSeconds
        plannedSessionTotalSeconds = 0
        didLogCompletion = false
        phase = .idle
    }

    /// Reset UI to ready state with same duration the user selected.
    func resetToIdleKeepDuration() {
        stopTimer()
        remainingSeconds = totalSeconds
        plannedSessionTotalSeconds = 0
        didLogCompletion = false
        phase = .idle
    }

    func updateMinutes(_ minutes: Int) {
        stopTimer()
        totalSeconds = max(1, minutes) * 60
        remainingSeconds = totalSeconds
        plannedSessionTotalSeconds = 0
        didLogCompletion = false
        phase = .idle
    }

    /// Called when syncing from Live Activity / external controls.
    func applyExternalState(isPaused: Bool, remaining: Int, sessionName: String) {
        let clamped = max(0, remaining)

        if clamped == 0 {
            completeIfNeeded()
            return
        }

        self.sessionName = sessionName
        remainingSeconds = clamped

        if isPaused {
            if phase == .running {
                pauseInternal()
            } else {
                stopTimer(keepRemaining: true)
                phase = .paused
            }
        } else {
            startInternal(isFresh: false)
        }
    }

    /// Smooth progress based on the endDate while running.
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
            didLogCompletion = false
        }

        phase = .running
        endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))

        timer?.invalidate()

        // ✅ Create unscheduled timer and add once (prevents runloop weirdness)
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
            // ceil keeps display from dropping early (premium feel)
            remainingSeconds = Int(ceil(timeLeft))
        }
    }

    private func completeIfNeeded() {
        guard phase != .completed else { return }

        remainingSeconds = 0
        stopTimer(keepRemaining: true)
        phase = .completed
        logCompletedSessionIfNeeded()
    }

    private func logCompletedSessionIfNeeded() {
        guard !didLogCompletion else { return }
        didLogCompletion = true

        let durationToLog = TimeInterval(max(plannedSessionTotalSeconds, 0))
        guard durationToLog > 0 else { return }

        let trimmed = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameToStore: String? = trimmed.isEmpty ? nil : trimmed

        StatsManager.shared.addSession(duration: durationToLog, sessionName: nameToStore)
    }
}
