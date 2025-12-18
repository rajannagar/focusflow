import Foundation
import AVFoundation

final class FocusSoundManager: NSObject {
    static let shared = FocusSoundManager()

    private let session = AVAudioSession.sharedInstance()
    private var audioPlayer: AVAudioPlayer?
    private var isSessionConfigured = false
    private var shouldResumeAfterInterruption = false

    // MARK: - Init / deinit

    private override init() {
        super.init()

        // Listen for system audio interruptions (phone calls, Siri, etc.)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: session
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - AVAudioSession

    /// Configure the audio session for FocusFlow ambience.
    ///
    /// We *do not* use `.mixWithOthers` here because:
    /// - When FocusFlow plays a sound (preview or session), we want other music apps to stop.
    private func prepareSessionIfNeeded() {
        guard !isSessionConfigured else { return }

        do {
            try session.setCategory(
                .playback,
                mode: .default,
                options: []              // no .mixWithOthers → we take audio focus
            )
            try session.setActive(true)
            isSessionConfigured = true
        } catch {
            print("🎧 FocusSoundManager – session error:", error)
        }
    }

    // MARK: - Public API

    /// Play a given focus sound from the start, looping forever.
    /// This is used for both previews (in the picker) and actual focus sessions.
    /// Either way, it will interrupt external music.
    func play(sound: FocusSound) {
        stop() // fully reset first

        guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: "mp3") else {
            print("❌ FocusSoundManager – missing sound file:", sound.fileName)
            return
        }

        prepareSessionIfNeeded()

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1          // infinite loop
            player.volume = 1.0                // default volume; can be changed via setVolume(_:)
            player.prepareToPlay()
            player.play()

            audioPlayer = player
        } catch {
            print("🎧 FocusSoundManager – audio error:", error)
        }
    }

    /// Pause (keep playback position)
    func pause() {
        guard let player = audioPlayer, player.isPlaying else { return }
        player.pause()
    }

    /// Resume (continue from last position)
    func resume() {
        guard let player = audioPlayer else { return }

        // Make sure session is active again if needed
        prepareSessionIfNeeded()
        player.play()
    }

    /// Full stop (reset position and release player).
    /// We keep the audio session configured; if you want to
    /// aggressively release it, you could also setActive(false),
    /// but it's not required.
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        shouldResumeAfterInterruption = false
    }

    /// Optional: external volume control (0.0 – 1.0)
    func setVolume(_ value: Float) {
        let clamped = max(0.0, min(1.0, value))
        audioPlayer?.volume = clamped
    }

    // MARK: - Interruption handling

    @objc private func handleInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            // Another audio source took over (phone call, Siri, etc.)
            if let player = audioPlayer, player.isPlaying {
                shouldResumeAfterInterruption = true
                player.pause()
            } else {
                shouldResumeAfterInterruption = false
            }

        case .ended:
            guard
                let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt
            else { return }

            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)

            // Only resume if we were playing before & system says it's OK.
            if options.contains(.shouldResume), shouldResumeAfterInterruption {
                shouldResumeAfterInterruption = false
                resume()
            }

        @unknown default:
            break
        }
    }
}
