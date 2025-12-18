import SwiftUI
import UIKit
import Combine
import AVFoundation
import ActivityKit

struct FocusView: View {
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Alert type

    private enum ActiveAlert: Identifiable {
        case presetSwitch
        case lengthChange

        var id: Int { hashValue }
    }

    // Timer logic
    @StateObject private var viewModel = FocusTimerViewModel()
    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var stats = StatsManager.shared
    @ObservedObject private var notifications = NotificationCenterManager.shared
    @ObservedObject private var presetStore = FocusPresetStore.shared

    // Time picker
    @State private var showingTimePicker = false
    @State private var selectedHours: Int = 0
    @State private var selectedMinutes: Int = 25

    // Sound sheet
    @State private var showingSoundSheet = false

    // Notification center sheet
    @State private var showingNotificationCenter = false

    // Preset management
    @State private var showingPresetManager = false
    @State private var pendingPresetToApply: FocusPreset?

    // Session name / intention
    @State private var sessionName: String = ""
    @FocusState private var isIntentionFocused: Bool
    @State private var hasEditedIntention: Bool = false   // track manual edits

    // Orb animation states
    @State private var orbGlowPulse = false    // minute tick
    @State private var orbTapFlash = false     // quick tap feedback

    // Separate UI notion of "running" so everything matches what you see
    @State private var isRunningUI: Bool = false

    // Track that we've cleared any default preset / sound / external app this launch
    @State private var didClearPresetThisLaunch: Bool = false

    // Super-smooth ring progress (time-based)
    @State private var sessionEndDate: Date? = nil
    @State private var sessionTotalDuration: TimeInterval = 0
    @State private var progressOverride: Double? = nil   // e.g. lock at 1.0 on completion

    // Sound state for built-in sounds
    @State private var activeSessionSound: FocusSound? = nil        // sound tied to the current session
    @State private var soundChangedWhilePaused: Bool = false        // did user pick a new sound while timer was paused?

    // For avoiding 00:00 flash when resyncing
    @State private var lastKnownRemainingSeconds: Int? = nil

    // Active alert
    @State private var activeAlert: ActiveAlert? = nil

    private let calendar = Calendar.current

    // Active preset for convenience
    private var activePreset: FocusPreset? {
        presetStore.activePreset
    }

    // MARK: - Session display helper (for notifications + labels)

    private var currentSessionDisplayName: String {
        if !sessionName.isEmpty {
            return sessionName
        } else if let preset = activePreset {
            return preset.name
        } else {
            return "Focus session"
        }
    }

    private var currentPresetSubtitle: String {
        guard let preset = activePreset else {
            return "Choose how you want to focus today."
        }

        return "Stay present with \(preset.name.lowercased())."
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let theme = appSettings.selectedTheme
            let accentPrimary = theme.accentPrimary
            let accentSecondary = theme.accentSecondary

            // Derived stats
            let todayTotal = stats.totalToday
            let totalMinutes = max(viewModel.totalSeconds / 60, 1)
            let isTyping = isIntentionFocused

            ZStack {
                // Background – soft, calm, slightly reactive
                LinearGradient(
                    gradient: Gradient(colors: theme.backgroundColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .hueRotation(.degrees(isRunningUI ? 10 : 0))
                .animation(.easeInOut(duration: 1.0), value: isRunningUI)
                .ignoresSafeArea()

                Circle()
                    .fill(accentPrimary.opacity(0.5))
                    .blur(radius: 90)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: -size.width * 0.45, y: -size.height * 0.55)

                Circle()
                    .fill(accentSecondary.opacity(0.35))
                    .blur(radius: 100)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: size.width * 0.45, y: size.height * 0.5)

                // 🔹 Main layout
                VStack(spacing: 20) {
                    // 1. Header
                    header

                    // 2. Intention
                    intentionSection
                        .padding(.top, 4)

                    // 3. Preset pills
                    presetSelector(
                        accentPrimary: accentPrimary,
                        accentSecondary: accentSecondary
                    )
                    .opacity(isTyping ? 0 : 1)

                    Spacer(minLength: 4)

                    // 4. Orb (hero) – driven by TimelineView so it moves continuously
                    TimelineView(.animation) { context in
                        let now = context.date
                        let smoothProgress = smoothRingProgress(now: now)

                        // Time-based breathing, gated by isRunningUI
                        let t = now.timeIntervalSinceReferenceDate
                        let period: Double = 2.0 // seconds for a full breath cycle
                        let phase = sin((t / period) * 2 * .pi) // -1...1

                        let outerBase: CGFloat = 0.9
                        let outerAmp: CGFloat = 0.18
                        let innerBase: CGFloat = 1.0
                        let innerAmp: CGFloat = 0.05

                        let outerBreath = isRunningUI
                        ? outerBase + outerAmp * CGFloat((phase + 1) / 2)
                        : outerBase

                        let innerBreath = isRunningUI
                        ? innerBase + innerAmp * CGFloat((phase + 1) / 2)
                        : innerBase

                        orbSection(
                            size: size,
                            accentPrimary: accentPrimary,
                            accentSecondary: accentSecondary,
                            totalMinutes: totalMinutes,
                            progress: smoothProgress,
                            isRunning: isRunningUI,
                            compact: isTyping,
                            outerBreathScale: outerBreath,
                            innerBreathScale: innerBreath
                        )
                    }

                    Spacer(minLength: 6)

                    // 5. Controls under orb
                    primaryControls(
                        accentPrimary: accentPrimary,
                        accentSecondary: accentSecondary
                    )

                    // 6. Tiny footer stats
                    bottomPersonalRow(todayTotal: todayTotal, isTyping: isTyping)

                    Spacer(minLength: 6)
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, isTyping ? 120 : 24)
                .animation(.spring(response: 0.45, dampingFraction: 0.9), value: isTyping)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .onAppear {
                // Only once per app launch: ensure nothing is pre-selected by default
                if !didClearPresetThisLaunch {
                    didClearPresetThisLaunch = true

                    // No active preset by default
                    presetStore.activePresetID = nil

                    // No built-in focus sound by default
                    appSettings.selectedFocusSound = nil

                    // No external music app by default
                    appSettings.selectedExternalMusicApp = nil
                }

                // 🔔 Ask for notification permission when FocusView loads
                FocusLocalNotificationManager.shared.requestAuthorizationIfNeeded()

                // 🔔 Set up daily nudges (safe to call multiple times)
                FocusLocalNotificationManager.shared.scheduleDailyNudges()

                // Keep runtime state in sync on first load
                appSettings.isFocusTimerRunning = isRunningUI

                // Also try to snap to whatever the Live Activity is currently showing
                syncFromLiveActivityIfPossible()

                // Keep VM sessionName aligned on initial load too
                viewModel.sessionName = currentSessionDisplayName
            }
        }

        // 🔗 Respond when the Dynamic Island / Live Activity toggle updates the session
        .onReceive(NotificationCenter.default.publisher(for: .focusSessionExternalToggle)) { notification in
            guard
                let userInfo = notification.userInfo,
                let isPaused = userInfo["isPaused"] as? Bool,
                let remaining = userInfo["remainingSeconds"] as? Int
            else {
                return
            }

            print("FocusView: 🔁 received external toggle isPaused=\(isPaused), remaining=\(remaining), vm.remaining=\(viewModel.remainingSeconds)")
            applyExternalSessionState(isPaused: isPaused, remaining: remaining)
        }

        // 👇 When app becomes active, resync from the current Live Activity state
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }

            // First, consume any bridge message (if there was a pause/resume while app was in background)
            if #available(iOS 18.0, *) {
                FocusSessionStore.shared.applyExternalToggleIfNeeded()
            }

            // Then, force-snap to whatever the Live Activity says *right now*
            syncFromLiveActivityIfPossible()
        }

        // MARK: - Completion → haptic + notifications
        // ✅ Stats logging happens inside FocusTimerViewModel now.
        .onChange(of: viewModel.didCompleteSession) { _, newValue in
            if newValue == true {
                successHaptic()
                FocusSoundEngine.shared.playEvent(.completed)

                let duration = TimeInterval(viewModel.totalSeconds) // matches what user chose
                let name = currentSessionDisplayName

                // 🔔 Log into in-app notification center
                NotificationCenterManager.shared.add(
                    kind: .sessionCompleted,
                    title: "Session complete",
                    body: "You focused for \(duration.asReadableDuration) on “\(name)”."
                )

                // 🔔 Cancel any pending local notification for this session
                FocusLocalNotificationManager.shared.cancelSessionCompletionNotification()

                viewModel.didCompleteSession = false

                // Lock ring at 100% until user resets/starts again
                progressOverride = 1.0
                sessionEndDate = nil
                isRunningUI = false

                // Fully stop built-in sound on completion
                FocusSoundManager.shared.stop()
                activeSessionSound = nil
                soundChangedWhilePaused = false

                // End Live Activity when session completes
                if #available(iOS 18.0,*) {
                    FocusLiveActivityManager.shared.endActivity()
                }
            }
        }

        // MARK: - Minute tick haptics, glow, and last-known time
        .onChange(of: viewModel.remainingSeconds) { oldValue, newValue in
            if newValue > 0 {
                lastKnownRemainingSeconds = newValue
            }

            guard isRunningUI,
                  newValue < oldValue,
                  newValue > 0,
                  newValue % 60 == 0,
                  newValue != viewModel.totalSeconds
            else { return }

            minuteTickHaptic()
            FocusSoundEngine.shared.playEvent(.minuteTick)

            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                orbGlowPulse.toggle()
            }
        }

        // MARK: - Background focus sound: respond to running state + settings
        .onChange(of: isRunningUI) { _, running in
            appSettings.isFocusTimerRunning = running

            if running {
                guard appSettings.soundEnabled else {
                    FocusSoundManager.shared.stop()
                    activeSessionSound = nil
                    soundChangedWhilePaused = false
                    return
                }

                guard let selected = appSettings.selectedFocusSound else {
                    FocusSoundManager.shared.stop()
                    activeSessionSound = nil
                    soundChangedWhilePaused = false
                    return
                }

                if viewModel.remainingSeconds == viewModel.totalSeconds {
                    activeSessionSound = selected
                    soundChangedWhilePaused = false
                    FocusSoundManager.shared.play(sound: selected)
                } else {
                    if soundChangedWhilePaused || activeSessionSound == nil || activeSessionSound != selected {
                        activeSessionSound = selected
                        soundChangedWhilePaused = false
                        FocusSoundManager.shared.play(sound: selected)
                    } else {
                        FocusSoundManager.shared.resume()
                    }
                }
            } else {
                FocusSoundManager.shared.pause()
            }
        }

        .onChange(of: appSettings.soundEnabled) { _, newValue in
            if newValue {
                if isRunningUI {
                    startOrSwitchSoundForCurrentState()
                }
            } else {
                FocusSoundManager.shared.stop()
                activeSessionSound = nil
                soundChangedWhilePaused = false
            }
        }

        .onChange(of: appSettings.selectedFocusSound) { _, _ in
            handleSelectedSoundChanged()
        }

        .onChange(of: showingSoundSheet) { _, isShowing in
            if !isShowing && !isRunningUI {
                FocusSoundManager.shared.stop()
            }
        }

        // ✅ Keep VM session name aligned while user types (only matters for next start / Live Activity names)
        .onChange(of: sessionName) { _, _ in
            if !isRunningUI {
                viewModel.sessionName = currentSessionDisplayName
            }
            if isIntentionFocused {
                hasEditedIntention = true
            }
        }

        // MARK: - Sheets
        .sheet(isPresented: $showingTimePicker) { timePickerSheet }
        .sheet(isPresented: $showingSoundSheet) { FocusSoundPicker() }
        .sheet(isPresented: $showingNotificationCenter) { NotificationCenterView() }
        .sheet(isPresented: $showingPresetManager) { FocusPresetManagerView() }

        // MARK: - Unified Apple-style alerts
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .presetSwitch:
                return Alert(
                    title: Text("Switch preset?"),
                    message: Text("This will reset your current session and apply “\(pendingPresetToApply?.name ?? "")”."),
                    primaryButton: .destructive(Text("Switch")) {
                        if let preset = pendingPresetToApply {
                            viewModel.reset()
                            isRunningUI = false

                            FocusSoundManager.shared.stop()
                            activeSessionSound = nil
                            soundChangedWhilePaused = false

                            sessionEndDate = nil
                            progressOverride = nil

                            sessionName = ""
                            hasEditedIntention = false

                            if #available(iOS 18.0, *) {
                                FocusLiveActivityManager.shared.endActivity()
                            }

                            applyPreset(preset, overrideRunningState: true)
                        }
                        pendingPresetToApply = nil
                    },
                    secondaryButton: .cancel {
                        pendingPresetToApply = nil
                    }
                )

            case .lengthChange:
                return Alert(
                    title: Text("Change session length?"),
                    message: Text("This will reset your current focus session and let you pick a new length."),
                    primaryButton: .destructive(Text("Change length")) {
                        isRunningUI = false
                        viewModel.reset()
                        FocusLocalNotificationManager.shared.cancelSessionCompletionNotification()

                        FocusSoundManager.shared.stop()
                        activeSessionSound = nil
                        soundChangedWhilePaused = false

                        sessionEndDate = nil
                        sessionTotalDuration = 0
                        progressOverride = nil
                        if #available(iOS 18.0, *) {
                            FocusLiveActivityManager.shared.endActivity()
                        }

                        prepareTimePicker()
                        showingTimePicker = true
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    // MARK: - External state helpers (Live Activity → in-app timer)

    private func parseRemainingString(_ string: String) -> Int {
        let parts = string.split(separator: ":").map { Int($0) ?? 0 }
        guard !parts.isEmpty else { return 0 }

        if parts.count == 3 {
            return parts[0] * 3600 + parts[1] * 60 + parts[2]
        } else if parts.count == 2 {
            return parts[0] * 60 + parts[1]
        } else {
            return parts[0]
        }
    }

    private func applyExternalSessionState(isPaused: Bool, remaining: Int) {
        let clampedRemaining = max(0, remaining)

        print("FocusView: 🎯 applying external state isPaused=\(isPaused), remaining=\(clampedRemaining)")

        // ✅ prevent 00:00 flash during resync
        if clampedRemaining > 0 {
            lastKnownRemainingSeconds = clampedRemaining
        }

        viewModel.remainingSeconds = clampedRemaining

        if isPaused {
            isRunningUI = false
            viewModel.stop()

            FocusLocalNotificationManager.shared.cancelSessionCompletionNotification()

            sessionEndDate = nil
            progressOverride = nil
        } else {
            guard clampedRemaining > 0 else { return }

            isRunningUI = true

            // ✅ IMPORTANT: set name before start so VM logs correctly on completion
            viewModel.sessionName = currentSessionDisplayName

            // ✅ Only play start sound if this is a fresh start, not a resume from DI
            let isFresh = (clampedRemaining == viewModel.totalSeconds)
            if isFresh {
                FocusSoundEngine.shared.playEvent(.start)
            }

            viewModel.start()

            sessionTotalDuration = TimeInterval(viewModel.totalSeconds)
            sessionEndDate = Date().addingTimeInterval(TimeInterval(clampedRemaining))
            progressOverride = nil

            FocusLocalNotificationManager.shared.scheduleSessionCompletionNotification(
                after: clampedRemaining,
                sessionName: currentSessionDisplayName
            )
        }
    }

    private func syncFromLiveActivityIfPossible() {
        guard #available(iOS 18.0, *) else { return }

        guard let activity = Activity<FocusSessionAttributes>.activities.first else {
            return
        }

        let state = activity.content.state
        let now = Date()

        let isPaused = state.isPaused
        let remaining: Int

        if isPaused {
            remaining = parseRemainingString(state.pausedDisplayTime)
        } else {
            remaining = max(0, Int(state.endDate.timeIntervalSince(now)))
        }

        print("FocusView: 📡 syncFromLiveActivity isPaused=\(isPaused), remaining=\(remaining)")
        applyExternalSessionState(isPaused: isPaused, remaining: remaining)
    }

    // MARK: - Header (with status dot)

    private var header: some View {
        let name = appSettings.displayName.trimmingCharacters(in: .whitespaces)
        let hasUnread = notifications.notifications.contains { !$0.isRead }
        let accentPrimary = appSettings.selectedTheme.accentPrimary

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image("Focusflow_Logo")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)

                    Text("FocusFlow")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    Circle()
                        .fill(
                            isRunningUI
                            ? accentPrimary
                            : Color.white.opacity(0.35)
                        )
                        .frame(width: 10, height: 10)
                        .shadow(
                            color: isRunningUI
                            ? accentPrimary.opacity(0.7)
                            : .clear,
                            radius: isRunningUI ? 6 : 0
                        )
                        .scaleEffect(
                            isRunningUI
                            ? (orbGlowPulse ? 1.25 : 1.0)
                            : 1.0
                        )
                        .opacity(isRunningUI ? (orbGlowPulse ? 1.0 : 0.7) : 0.5)
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.7),
                            value: orbGlowPulse
                        )
                }

                if name.isEmpty {
                    Text("Welcome to FocusFlow")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))

                    Text("Tap the orb to begin.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Text("\(greetingTitle), \(name)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    simpleTap()
                    showingNotificationCenter = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: hasUnread ? "bell.fill" : "bell")
                            .imageScale(.medium)
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        if hasUnread {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 5, y: -5)
                        }
                    }
                }
                .buttonStyle(.plain)

                Button {
                    simpleTap()
                    showingSoundSheet = true
                } label: {
                    Image(systemName: "headphones")
                        .imageScale(.medium)
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var greetingTitle: String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<21:
            return "Good evening"
        case 21..<24, 0..<5:
            return "Good night"
        default:
            return "Hey"
        }
    }

    // MARK: - Intention section

    private var intentionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Intention for this session")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.82))

            HStack(spacing: 10) {
                Image("Focusflow_Logo")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(.white.opacity(0.75))

                TextField("Deep work, exam prep, client project…", text: $sessionName)
                    .foregroundColor(.white)
                    .tint(.white)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.sentences)
                    .focused($isIntentionFocused)

                if !sessionName.isEmpty {
                    Button {
                        simpleTap()
                        sessionName = ""
                        hasEditedIntention = false
                        if !isRunningUI {
                            viewModel.sessionName = currentSessionDisplayName
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .imageScale(.small)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.13))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    // MARK: - PRESET selector

    private func presetSelector(
        accentPrimary: Color,
        accentSecondary: Color
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button {
                    simpleTap()
                    showingPresetManager = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.14))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                ForEach(presetStore.presets) { preset in
                    let isSelected = presetStore.activePresetID == preset.id

                    Button {
                        simpleTap()
                        handlePresetTap(preset)
                    } label: {
                        Text(preset.name)
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundColor(isSelected ? .black : .white.opacity(0.9))
                            .background(
                                Group {
                                    if isSelected {
                                        LinearGradient(
                                            gradient: Gradient(colors: [accentPrimary, accentSecondary]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    } else {
                                        Color.white.opacity(0.14)
                                    }
                                }
                            )
                            .clipShape(Capsule())
                            .shadow(
                                color: isSelected ? accentPrimary.opacity(0.4) : .clear,
                                radius: isSelected ? 8 : 0
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func handlePresetTap(_ preset: FocusPreset) {
        if isRunningUI {
            pendingPresetToApply = preset
            activeAlert = .presetSwitch
        } else {
            applyPreset(preset, overrideRunningState: false)
        }
    }

    private func applyPreset(_ preset: FocusPreset, overrideRunningState: Bool) {
        presetStore.activePresetID = preset.id

        if let themeRaw = preset.themeRaw,
           let presetTheme = AppTheme(rawValue: themeRaw) {
            appSettings.selectedTheme = presetTheme
        }

        let minutes = max(1, preset.durationSeconds / 60)
        viewModel.updateMinutes(minutes)

        if !hasEditedIntention {
            sessionName = suggestedIntention(for: preset)
            viewModel.sessionName = currentSessionDisplayName
        }

        if let app = preset.externalMusicApp {
            appSettings.selectedExternalMusicApp = app
            appSettings.selectedFocusSound = nil

            FocusSoundManager.shared.stop()
            activeSessionSound = nil
            soundChangedWhilePaused = false
        } else if let sound = soundForPreset(preset) {
            appSettings.selectedExternalMusicApp = nil
            appSettings.selectedFocusSound = sound

            activeSessionSound = nil
            soundChangedWhilePaused = false
        } else {
            appSettings.selectedExternalMusicApp = nil
            appSettings.selectedFocusSound = nil

            FocusSoundManager.shared.stop()
            activeSessionSound = nil
            soundChangedWhilePaused = false
        }

        sessionTotalDuration = TimeInterval(viewModel.totalSeconds)
        progressOverride = nil
        sessionEndDate = nil

        if overrideRunningState {
            isRunningUI = false
        }
    }

    private func suggestedIntention(for preset: FocusPreset) -> String {
        switch preset.name.lowercased() {
        case "deep work":
            return "Settle in and stay focused."
        case "study":
            return "Learn with clarity."
        case "writing":
            return "Write with focus."
        case "reading":
            return "Read without distraction."
        default:
            return "Focus: \(preset.name)"
        }
    }

    private func soundForPreset(_ preset: FocusPreset) -> FocusSound? {
        guard !preset.soundID.isEmpty else { return nil }
        return FocusSound(rawValue: preset.soundID)
    }

    // MARK: - Orb section

    private func displayedTimeString() -> String {
        if isRunningUI,
           viewModel.remainingSeconds == 0,
           let cached = lastKnownRemainingSeconds {
            let minutes = cached / 60
            let seconds = cached % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }

        return viewModel.formattedTime
    }

    private func orbSection(
        size: CGSize,
        accentPrimary: Color,
        accentSecondary: Color,
        totalMinutes: Int,
        progress: Double,
        isRunning: Bool,
        compact: Bool,
        outerBreathScale: CGFloat,
        innerBreathScale: CGFloat
    ) -> some View {
        let timeFontSize: CGFloat = compact ? 32 : 42
        let subtitleFontSize: CGFloat = compact ? 11 : 13
        let hintFontSize: CGFloat = compact ? 10 : 11

        return VStack(spacing: 18) {
            Text(currentPresetSubtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                accentPrimary.opacity(0.95),
                                accentSecondary.opacity(0.0)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: size.width * 0.8
                        )
                    )
                    .blur(radius: 60)
                    .scaleEffect(outerBreathScale)
                    .opacity(isRunning ? 0.95 : 0.0)

                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                accentPrimary.opacity(0.18),
                                accentSecondary.opacity(0.4),
                                accentPrimary.opacity(0.18)
                            ]),
                            center: .center
                        ),
                        lineWidth: 26
                    )
                    .frame(width: size.width * 0.7, height: size.width * 0.7)
                    .blur(radius: 14)
                    .opacity(isRunning ? 1.0 : 0.6)
                    .rotationEffect(.degrees(isRunning ? 360 : 0))
                    .animation(
                        isRunning
                        ? .linear(duration: 16).repeatForever(autoreverses: false)
                        : .easeOut(duration: 0.4),
                        value: isRunning
                    )

                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 18)
                    .frame(width: size.width * 0.58, height: size.width * 0.58)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                accentPrimary,
                                accentSecondary,
                                accentPrimary
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: size.width * 0.58, height: size.width * 0.58)

                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white,
                                Color.white.opacity(0.92)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size.width * 0.44, height: size.width * 0.44)
                    .shadow(color: accentPrimary.opacity(0.7), radius: 32, x: 0, y: 22)
                    .scaleEffect(innerBreathScale)
                    .overlay(
                        VStack(spacing: 6) {
                            Text(displayedTimeString())
                                .font(.system(size: timeFontSize, weight: .semibold, design: .monospaced))
                                .foregroundColor(.black)

                            Text("\(totalMinutes)-minute session")
                                .font(.system(size: subtitleFontSize, weight: .medium))
                                .foregroundColor(.black.opacity(0.7))

                            Text(isRunning ? "Stay with it." : "Tap the orb to begin.")
                                .font(.system(size: hintFontSize, weight: .medium))
                                .foregroundColor(.black.opacity(0.5))
                        }
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.7),
                                        Color.white.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.3
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.9), lineWidth: 8)
                            .blur(radius: 14)
                            .opacity(orbGlowPulse ? 0.0 : 0.85)
                    )
                    .scaleEffect(orbTapFlash ? 1.03 : 1.0)
                    .animation(.easeOut(duration: 0.18), value: orbTapFlash)
                    .onTapGesture {
                        simpleTap()

                        orbTapFlash = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            orbTapFlash = false
                        }

                        if isRunningUI {
                            // PAUSE
                            isRunningUI = false
                            viewModel.stop()
                            FocusSoundEngine.shared.playEvent(.pause)
                            FocusLocalNotificationManager.shared.cancelSessionCompletionNotification()

                            sessionEndDate = nil
                            progressOverride = nil

                            if #available(iOS 18.0, *) {
                                FocusLiveActivityManager.shared.updatePaused(
                                    remainingSeconds: viewModel.remainingSeconds,
                                    isPaused: true,
                                    sessionName: currentSessionDisplayName
                                )
                            }
                        } else {
                            // START / RESUME
                            isRunningUI = true

                            // ✅ IMPORTANT: set name before start so VM logs correctly on completion
                            viewModel.sessionName = currentSessionDisplayName
                            viewModel.start()

                            FocusSoundEngine.shared.playEvent(.start)

                            progressOverride = nil
                            let isFreshSession = (viewModel.remainingSeconds == viewModel.totalSeconds)
                            let seconds = viewModel.remainingSeconds

                            if seconds > 0 {
                                sessionTotalDuration = TimeInterval(viewModel.totalSeconds)
                                sessionEndDate = Date().addingTimeInterval(TimeInterval(seconds))

                                if isFreshSession,
                                   let app = appSettings.selectedExternalMusicApp {
                                    ExternalMusicLauncher.openSelectedApp(app)
                                }

                                if #available(iOS 18.0, *) {
                                    if isFreshSession {
                                        FocusLiveActivityManager.shared.startActivity(
                                            totalSeconds: viewModel.totalSeconds,
                                            sessionName: currentSessionDisplayName,
                                            endDate: sessionEndDate ?? Date().addingTimeInterval(TimeInterval(seconds))
                                        )
                                    } else {
                                        FocusLiveActivityManager.shared.updatePaused(
                                            remainingSeconds: seconds,
                                            isPaused: false,
                                            sessionName: currentSessionDisplayName
                                        )
                                    }
                                }

                                FocusLocalNotificationManager.shared.scheduleSessionCompletionNotification(
                                    after: seconds,
                                    sessionName: currentSessionDisplayName
                                )
                            }
                        }
                    }
            }
            .scaleEffect(compact ? 0.9 : 1.0)
            .offset(y: compact ? -10 : 0)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Primary controls

    private func primaryControls(
        accentPrimary: Color,
        accentSecondary: Color
    ) -> some View {
        HStack(spacing: 12) {
            // Reset
            Button {
                simpleTap()
                viewModel.reset()
                FocusSoundEngine.shared.playEvent(.pause)
                FocusLocalNotificationManager.shared.cancelSessionCompletionNotification()

                sessionEndDate = nil
                sessionTotalDuration = 0
                progressOverride = nil
                isRunningUI = false

                FocusSoundManager.shared.stop()
                activeSessionSound = nil
                soundChangedWhilePaused = false

                presetStore.activePresetID = nil
                appSettings.selectedTheme = appSettings.profileTheme
                appSettings.selectedFocusSound = nil
                appSettings.selectedExternalMusicApp = nil

                sessionName = ""
                hasEditedIntention = false
                viewModel.sessionName = currentSessionDisplayName

                if #available(iOS 18.0, *) {
                    FocusLiveActivityManager.shared.endActivity()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .imageScale(.small)
                    Text("Reset")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.14))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            // Length
            Button {
                simpleTap()
                if isRunningUI {
                    activeAlert = .lengthChange
                } else {
                    prepareTimePicker()
                    showingTimePicker = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .imageScale(.small)
                    Text("Length")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.14))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            // Start / Pause
            Button {
                simpleTap()
                if isRunningUI {
                    // PAUSE
                    isRunningUI = false
                    viewModel.stop()
                    FocusSoundEngine.shared.playEvent(.pause)
                    FocusLocalNotificationManager.shared.cancelSessionCompletionNotification()

                    sessionEndDate = nil
                    progressOverride = nil

                    if #available(iOS 18.0, *) {
                        FocusLiveActivityManager.shared.updatePaused(
                            remainingSeconds: viewModel.remainingSeconds,
                            isPaused: true,
                            sessionName: currentSessionDisplayName
                        )
                    }
                } else {
                    // START / RESUME
                    isRunningUI = true

                    // ✅ IMPORTANT: set name before start so VM logs correctly on completion
                    viewModel.sessionName = currentSessionDisplayName
                    viewModel.start()

                    FocusSoundEngine.shared.playEvent(.start)

                    progressOverride = nil
                    let isFreshSession = (viewModel.remainingSeconds == viewModel.totalSeconds)
                    let seconds = viewModel.remainingSeconds

                    if seconds > 0 {
                        sessionTotalDuration = TimeInterval(viewModel.totalSeconds)
                        sessionEndDate = Date().addingTimeInterval(TimeInterval(seconds))

                        if isFreshSession,
                           let app = appSettings.selectedExternalMusicApp {
                            ExternalMusicLauncher.openSelectedApp(app)
                        }

                        if #available(iOS 18.0, *) {
                            if isFreshSession {
                                FocusLiveActivityManager.shared.startActivity(
                                    totalSeconds: viewModel.totalSeconds,
                                    sessionName: currentSessionDisplayName,
                                    endDate: sessionEndDate ?? Date().addingTimeInterval(TimeInterval(seconds))
                                )
                            } else {
                                FocusLiveActivityManager.shared.updatePaused(
                                    remainingSeconds: seconds,
                                    isPaused: false,
                                    sessionName: currentSessionDisplayName
                                )
                            }
                        }

                        FocusLocalNotificationManager.shared.scheduleSessionCompletionNotification(
                            after: seconds,
                            sessionName: currentSessionDisplayName
                        )
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isRunningUI ? "pause.fill" : "play.fill")
                        .imageScale(.medium)
                    Text(isRunningUI ? "Pause" : "Start")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
                .padding(.vertical, 14)
                .padding(.horizontal, 22)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: isRunningUI
                                            ? [accentSecondary, accentPrimary]
                                            : [accentPrimary, accentSecondary]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(radius: isRunningUI ? 12 : 18)
                .scaleEffect(isRunningUI ? 0.98 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isRunningUI)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Bottom row

    private func bottomPersonalRow(todayTotal: TimeInterval, isTyping: Bool) -> some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "sun.max")
                    .imageScale(.small)
                Text(todayTotal.asReadableDuration + " today")
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .imageScale(.small)
                Text("\(currentStreak) day streak")
            }
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(.white.opacity(0.78))
        .padding(.horizontal, 4)
        .opacity(isTyping ? 0 : 1)
    }

    // MARK: - Streak calculation

    private var currentStreak: Int {
        let daysWithFocus: Set<Date> = Set(
            stats.sessions
                .filter { $0.duration > 0 }
                .map { calendar.startOfDay(for: $0.date) }
        )

        if daysWithFocus.isEmpty {
            return 0
        }

        var current = 0
        var cursor = calendar.startOfDay(for: Date())
        while daysWithFocus.contains(cursor) {
            current += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }

        return current
    }

    // MARK: - Time picker

    private var timePickerSheet: some View {
        let theme = appSettings.selectedTheme

        return ZStack {
            LinearGradient(
                gradient: Gradient(colors: theme.backgroundColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 44, height: 4)
                    .padding(.top, 8)

                Text("Custom focus length")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text("Dial in a session that fits exactly what you’re about to do.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack {
                    VStack {
                        Text("Hours")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.85))
                        Picker("Hours", selection: $selectedHours) {
                            ForEach(0..<13) { hour in
                                Text("\(hour)")
                                    .tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                    }

                    VStack {
                        Text("Minutes")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.85))
                        Picker("Minutes", selection: $selectedMinutes) {
                            ForEach(0..<60) { minute in
                                Text(String(format: "%02d", minute))
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                }
                .frame(height: 150)
                .colorScheme(.dark)

                HStack {
                    Button("Cancel") {
                        simpleTap()
                        showingTimePicker = false
                    }
                    .foregroundColor(.white.opacity(0.75))

                    Spacer()

                    Button("Set timer") {
                        simpleTap()
                        let totalMinutes = selectedHours * 60 + selectedMinutes

                        guard totalMinutes > 0 else {
                            showingTimePicker = false
                            return
                        }

                        applyCustomLength(totalMinutes)
                        showingTimePicker = false
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                }
                .padding(.horizontal)

                Spacer(minLength: 12)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .presentationDetents([.fraction(0.4)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Time picker helpers

    private func prepareTimePicker() {
        let totalMinutes = viewModel.totalSeconds / 60
        selectedHours = totalMinutes / 60
        selectedMinutes = totalMinutes % 60
    }

    private func applyCustomLength(_ minutes: Int) {
        viewModel.updateMinutes(minutes)

        sessionTotalDuration = TimeInterval(viewModel.totalSeconds)
        progressOverride = nil
        sessionEndDate = nil
    }

    // MARK: - Ring progress helper (butter-smooth)

    private func smoothRingProgress(now: Date) -> Double {
        if let override = progressOverride {
            return override
        }

        guard viewModel.totalSeconds > 0 else { return 0 }

        guard isRunningUI, let end = sessionEndDate, sessionTotalDuration > 0 else {
            return viewModel.progress
        }

        let remaining = max(end.timeIntervalSince(now), 0)
        let elapsed = sessionTotalDuration - remaining

        let raw = elapsed / sessionTotalDuration
        return min(max(raw, 0), 1)
    }

    // MARK: - Haptics & sound hooks

    private func simpleTap() {
        Haptics.impact(.medium)
    }

    private func successHaptic() {
        Haptics.notification(.success)
    }

    private func minuteTickHaptic() {
        Haptics.impact(.rigid)
    }

    // MARK: - Sound helpers

    private func handleSelectedSoundChanged() {
        guard appSettings.soundEnabled,
              let sound = appSettings.selectedFocusSound else {
            FocusSoundManager.shared.stop()
            activeSessionSound = nil
            soundChangedWhilePaused = false
            return
        }

        if isRunningUI {
            activeSessionSound = sound
            soundChangedWhilePaused = false
            FocusSoundManager.shared.play(sound: sound)
        } else if showingSoundSheet {
            soundChangedWhilePaused = true
            FocusSoundManager.shared.play(sound: sound)
        } else {
            FocusSoundManager.shared.stop()
        }
    }

    private func startOrSwitchSoundForCurrentState() {
        guard appSettings.soundEnabled,
              let selected = appSettings.selectedFocusSound else {
            FocusSoundManager.shared.stop()
            activeSessionSound = nil
            soundChangedWhilePaused = false
            return
        }

        guard isRunningUI else {
            FocusSoundManager.shared.stop()
            return
        }

        if activeSessionSound == selected, !soundChangedWhilePaused {
            FocusSoundManager.shared.resume()
        } else {
            activeSessionSound = selected
            soundChangedWhilePaused = false
            FocusSoundManager.shared.play(sound: selected)
        }
    }
}

// MARK: - Sound engine for short UI events (unchanged)

final class FocusSoundEngine {
    enum Event {
        case start
        case pause
        case completed
        case minuteTick
    }

    static let shared = FocusSoundEngine()

    private var player: AVAudioPlayer?
    private let queue = DispatchQueue(label: "focusflow.soundengine")

    private init() {}

    func playEvent(_ event: Event) {
        queue.async { [weak self] in
            guard let self else { return }

            let fileName: String
            switch event {
            case .start:      fileName = "focus_start"
            case .pause:      fileName = "focus_pause"
            case .completed:  fileName = "focus_complete"
            case .minuteTick: fileName = "focus_tick"
            }

            guard let url = Bundle.main.url(forResource: fileName, withExtension: "wav") else {
                return // no sound file yet – safe to ignore
            }

            do {
                self.player = try AVAudioPlayer(contentsOf: url)
                self.player?.prepareToPlay()
                self.player?.play()
            } catch {
                // fail silently
            }
        }
    }
}

struct FocusSplashView: View {
    let accent: Color

    @State private var glowScale: CGFloat = 0.9
    @State private var titleOpacity: Double = 0.0

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    accent.opacity(0.85)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(accent.opacity(0.45))
                .frame(width: 240, height: 240)
                .blur(radius: 45)
                .scaleEffect(glowScale)

            VStack(spacing: 14) {
                Image("Focusflow_Logo")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)

                Text("FocusFlow")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(.white)

                Text("A calmer way to get serious work done.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.78))
            }
            .opacity(titleOpacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                titleOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                glowScale = 1.1
            }
        }
    }
}

#Preview {
    FocusView()
}
