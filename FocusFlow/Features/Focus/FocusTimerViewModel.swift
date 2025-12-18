import SwiftUI
import Combine

@MainActor
final class FocusTimerViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var totalSeconds: Int = 25 * 60 // Default 25 min
    @Published var remainingSeconds: Int = 25 * 60
    @Published var isRunning: Bool = false
    @Published var didCompleteSession: Bool = false

    /// Optional session label to store with Stats (set by FocusView before start/resume)
    @Published var sessionName: String = ""

    // MARK: - Private Properties
    private var timer: Timer?
    private var endDate: Date? // Used to track time accurately when app is in background

    /// Planned session length captured on the FIRST start of a run (so pause/resume doesn't shrink it)
    private var plannedSessionTotalSeconds: Int = 0

    /// Prevent double-logging
    private var didLogCompletion: Bool = false

    // MARK: - Computed Properties
    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Public Methods

    func start() {
        guard remainingSeconds > 0 else { return }

        // If this is a fresh run (or we never captured a plan), capture planned duration once.
        let isFresh = (remainingSeconds == totalSeconds) || (plannedSessionTotalSeconds == 0)
        if isFresh {
            plannedSessionTotalSeconds = remainingSeconds
            didLogCompletion = false
            didCompleteSession = false
        }

        isRunning = true

        // Calculate exactly when the timer should end
        endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))

        timer?.invalidate()

        // Ensure the Timer lives on the main runloop; keep updates on MainActor
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    /// Stop WITHOUT logging (stop = user interrupted / paused)
    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        endDate = nil
    }

    func reset() {
        stop()
        remainingSeconds = totalSeconds
        didCompleteSession = false
        didLogCompletion = false
        plannedSessionTotalSeconds = 0
    }

    func updateMinutes(_ minutes: Int) {
        stop()
        totalSeconds = max(1, minutes) * 60
        remainingSeconds = totalSeconds
        didCompleteSession = false
        didLogCompletion = false
        plannedSessionTotalSeconds = 0
    }

    // MARK: - Private Logic

    private func tick() {
        guard let endDate else {
            // Safety: if something cleared endDate while running, stop cleanly.
            if isRunning {
                stop()
            }
            return
        }

        let timeLeft = endDate.timeIntervalSinceNow

        if timeLeft <= 0 {
            remainingSeconds = 0
            stop()
            didCompleteSession = true
            logCompletedSessionIfNeeded()
        } else {
            remainingSeconds = Int(ceil(timeLeft))
        }
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
