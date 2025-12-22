import SwiftUI
import UIKit
import Combine
import AVFoundation
import ActivityKit

struct FocusView: View {
    @Environment(\.scenePhase) private var scenePhase

    private enum ActiveAlert: Identifiable {
        case presetSwitch
        case lengthChange
        case resetConfirm
        var id: Int { hashValue }
    }

    @StateObject private var viewModel = FocusTimerViewModel()

    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var stats = StatsManager.shared
    @ObservedObject private var notifications = NotificationCenterManager.shared
    @ObservedObject private var presetStore = FocusPresetStore.shared

    @State private var showingTimePicker = false
    @State private var selectedHours: Int = 0
    @State private var selectedMinutes: Int = 25

    @State private var showingSoundSheet = false
    @State private var showingNotificationCenter = false
    @State private var showingPresetManager = false

    @State private var pendingPresetToApply: FocusPreset?

    @State private var sessionName: String = ""
    @FocusState private var isIntentionFocused: Bool
    @State private var hasEditedIntention: Bool = false

    @State private var orbGlowPulse = false
    @State private var orbTapFlash = false

    @State private var activeSessionSound: FocusSound? = nil
    @State private var soundChangedWhilePaused: Bool = false

    @State private var lastKnownRemainingSeconds: Int? = nil
    @State private var lastUserStartDate: Date? = nil

    // Prevent duplicate completion side-effects
    @State private var didFireCompletionSideEffectsForThisSession: Bool = false

    // ✅ Premium in-app completion overlay
    @State private var showingCompletionOverlay: Bool = false
    @State private var completionOverlaySessionName: String = ""

    // ✅ Prevent overlay from reappearing after user acknowledged completion
    @State private var didAcknowledgeCompletion: Bool = false

    @State private var activeAlert: ActiveAlert? = nil

    private let calendar = Calendar.current

    private var activePreset: FocusPreset? { presetStore.activePreset }

    private var isRunning: Bool { viewModel.phase == .running }
    private var isPaused: Bool { viewModel.phase == .paused }
    private var isCompleted: Bool { viewModel.phase == .completed }
    private var isIdle: Bool { viewModel.phase == .idle }

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

    // ✅ helper: are we actually in the foreground?
    private var isAppActive: Bool {
        UIApplication.shared.applicationState == .active
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            let theme = appSettings.selectedTheme
            let accentPrimary = theme.accentPrimary
            let accentSecondary = theme.accentSecondary
            let isTyping = isIntentionFocused
            let todayTotal = stats.totalToday
            let totalMinutes = max(viewModel.totalSeconds / 60, 1)

            ZStack {
                background(theme: theme, size: size, accentPrimary: accentPrimary, accentSecondary: accentSecondary)

                VStack(spacing: 20) {
                    header(accentPrimary: accentPrimary)

                    intentionSection
                        .padding(.top, 4)

                    presetSelector(accentPrimary: accentPrimary, accentSecondary: accentSecondary)
                        .opacity(isTyping ? 0 : 1)

                    Spacer(minLength: 4)

                    TimelineView(.animation) { context in
                        let now = context.date
                        let smoothProgress = viewModel.smoothProgress(now: now)

                        let t = now.timeIntervalSinceReferenceDate
                        let period: Double = 2.0
                        let phase = sin((t / period) * 2 * .pi)

                        let outerBase: CGFloat = 0.9
                        let outerAmp: CGFloat = 0.18
                        let innerBase: CGFloat = 1.0
                        let innerAmp: CGFloat = 0.05

                        let outerBreath: CGFloat = isRunning
                        ? outerBase + outerAmp * CGFloat((phase + 1) / 2)
                        : outerBase

                        let innerBreath: CGFloat = isRunning
                        ? innerBase + innerAmp * CGFloat((phase + 1) / 2)
                        : innerBase

                        orbSection(
                            size: size,
                            accentPrimary: accentPrimary,
                            accentSecondary: accentSecondary,
                            totalMinutes: totalMinutes,
                            progress: smoothProgress,
                            compact: isTyping,
                            outerBreathScale: outerBreath,
                            innerBreathScale: innerBreath
                        )
                    }

                    Spacer(minLength: 6)

                    primaryControls(accentPrimary: accentPrimary, accentSecondary: accentSecondary)
                    bottomPersonalRow(todayTotal: todayTotal, isTyping: isTyping)

                    Spacer(minLength: 6)
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, isTyping ? 120 : 24)
                .animation(.spring(response: 0.45, dampingFraction: 0.9), value: isTyping)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                // ✅ Premium completion overlay (only when in-app and not yet acknowledged)
                if showingCompletionOverlay {
                    CompletionOverlay(
                        accentPrimary: accentPrimary,
                        accentSecondary: accentSecondary,
                        sessionTitle: completionOverlaySessionName,
                        durationText: "\(max(viewModel.totalSeconds / 60, 1)) min",
                        onDone: { acknowledgeCompletionAndResetReady() }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 1.01)))
                    .zIndex(50)
                }
            }
        }
        .onAppear {
            viewModel.sessionName = currentSessionDisplayName

            // ✅ Important: when returning to this tab, resync from Live Activity,
            // and don't allow a stale ".completed" to re-trigger the overlay.
            syncFromLiveActivityIfPossible()

            if isIdle {
                showingCompletionOverlay = false
            }
        }

        .onReceive(NotificationCenter.default.publisher(for: .focusSessionExternalToggle)) { notification in
            guard
                let userInfo = notification.userInfo,
                let isPaused = userInfo["isPaused"] as? Bool,
                let remaining = userInfo["remainingSeconds"] as? Int
            else { return }

            applyExternalSessionState(isPaused: isPaused, remaining: remaining)
        }

        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }

            if #available(iOS 18.0, *) {
                FocusSessionStore.shared.applyExternalToggleIfNeeded()
            }
            syncFromLiveActivityIfPossible()

            // ✅ If we are back active and already reset to idle, ensure overlay stays hidden.
            if isIdle {
                showingCompletionOverlay = false
            }
        }

        .onChange(of: viewModel.remainingSeconds) { oldValue, newValue in
            if newValue > 0 { lastKnownRemainingSeconds = newValue }

            guard isRunning,
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

        .onChange(of: viewModel.phase) { oldPhase, newPhase in
            handlePhaseTransition(from: oldPhase, to: newPhase)
        }

        .onChange(of: appSettings.soundEnabled) { _, enabled in
            if enabled {
                if isRunning { startOrSwitchSoundForCurrentState() }
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
            if !isShowing && !isRunning {
                FocusSoundManager.shared.stop()
            }
        }

        .onChange(of: sessionName) { _, _ in
            if isIdle || isPaused || isCompleted {
                viewModel.sessionName = currentSessionDisplayName
            }
            if isIntentionFocused {
                hasEditedIntention = true
            }
        }

        .sheet(isPresented: $showingTimePicker) { timePickerSheet }
        .sheet(isPresented: $showingSoundSheet) { FocusSoundPicker() }
        .sheet(isPresented: $showingNotificationCenter) { NotificationCenterView() }
        .sheet(isPresented: $showingPresetManager) { FocusPresetManagerView() }

        .alert(item: $activeAlert) { alert in
            switch alert {
            case .presetSwitch:
                return Alert(
                    title: Text("Switch preset?"),
                    message: Text("This will reset your current session and apply “\(pendingPresetToApply?.name ?? "")”."),
                    primaryButton: .destructive(Text("Switch")) {
                        if let preset = pendingPresetToApply {
                            resetAllToDefault()
                            applyPreset(preset)
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
                        viewModel.resetToIdleKeepDuration()
                        FocusLocalNotificationManager.shared.cancelSessionCompletionNotification()
                        if #available(iOS 18.0, *) { FocusLiveActivityManager.shared.endActivity() }

                        prepareTimePicker()
                        showingTimePicker = true
                    },
                    secondaryButton: .cancel()
                )

            case .resetConfirm:
                return Alert(
                    title: Text("Reset session?"),
                    message: Text("Reset will stop the current session and return everything to default."),
                    primaryButton: .destructive(Text("Reset")) {
                        resetAllToDefault()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    // MARK: - Completion acknowledge
    private func acknowledgeCompletionAndResetReady() {
        simpleTap()

        // ✅ Mark acknowledged so it never re-appears on tab switch
        didAcknowledgeCompletion = true

        withAnimation(.spring(response: 0.38, dampingFraction: 0.9)) {
            showingCompletionOverlay = false
        }

        // Reset to idle but keep chosen duration
        viewModel.resetToIdleKeepDuration()

        // allow next run to complete normally
        didFireCompletionSideEffectsForThisSession = false

        // premium cleanup
        FocusLocalNotificationManager.shared.clearDeliveredSessionCompletionNotifications()
    }

    // MARK: - Background
    private func background(theme: AppTheme, size: CGSize, accentPrimary: Color, accentSecondary: Color) -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: theme.backgroundColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .hueRotation(.degrees(isRunning ? 10 : 0))
            .animation(.easeInOut(duration: 1.0), value: isRunning)
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
        }
    }

    // MARK: - Header
    private func header(accentPrimary: Color) -> some View {
        let name = appSettings.displayName.trimmingCharacters(in: .whitespaces)
        let hasUnread = notifications.notifications.contains { !$0.isRead }

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
                        .fill(isRunning ? accentPrimary : Color.white.opacity(0.35))
                        .frame(width: 10, height: 10)
                        .shadow(color: isRunning ? accentPrimary.opacity(0.7) : .clear,
                                radius: isRunning ? 6 : 0)
                        .scaleEffect(isRunning ? (orbGlowPulse ? 1.25 : 1.0) : 1.0)
                        .opacity(isRunning ? (orbGlowPulse ? 1.0 : 0.7) : 0.5)
                        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: orbGlowPulse)
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
                Button(action: {
                    simpleTap()
                    showingNotificationCenter = true
                }) {
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

                Button(action: {
                    simpleTap()
                    showingSoundSheet = true
                }) {
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
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        case 21..<24, 0..<5: return "Good night"
        default: return "Hey"
        }
    }

    // MARK: - Intention
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
                    Button(action: {
                        simpleTap()
                        sessionName = ""
                        hasEditedIntention = false
                        viewModel.sessionName = currentSessionDisplayName
                    }) {
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

    // MARK: - Presets
    private func presetSelector(accentPrimary: Color, accentSecondary: Color) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button(action: {
                    simpleTap()
                    showingPresetManager = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.14))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                ForEach(presetStore.presets) { preset in
                    let isSelected = (presetStore.activePresetID == preset.id)

                    Button(action: {
                        simpleTap()
                        handlePresetTap(preset)
                    }) {
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
                            .shadow(color: isSelected ? accentPrimary.opacity(0.4) : .clear,
                                    radius: isSelected ? 8 : 0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func handlePresetTap(_ preset: FocusPreset) {
        if isRunning || isPaused {
            pendingPresetToApply = preset
            activeAlert = .presetSwitch
        } else {
            applyPreset(preset)
        }
    }

    private func applyPreset(_ preset: FocusPreset) {
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
    }

    private func suggestedIntention(for preset: FocusPreset) -> String {
        switch preset.name.lowercased() {
        case "deep work": return "Settle in and stay focused."
        case "study": return "Learn with clarity."
        case "writing": return "Write with focus."
        case "reading": return "Read without distraction."
        default: return "Focus: \(preset.name)"
        }
    }

    private func soundForPreset(_ preset: FocusPreset) -> FocusSound? {
        guard !preset.soundID.isEmpty else { return nil }
        return FocusSound(rawValue: preset.soundID)
    }

    // MARK: - Orb (UNCHANGED)
    private func displayedTimeString() -> String {
        if isRunning,
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
        compact: Bool,
        outerBreathScale: CGFloat,
        innerBreathScale: CGFloat
    ) -> some View {
        let timeFontSize: CGFloat = compact ? 32 : 42
        let subtitleFontSize: CGFloat = compact ? 11 : 13
        let hintFontSize: CGFloat = compact ? 10 : 11

        let hintText: String = {
            if isRunning { return "Stay with it." }
            if isPaused { return "Paused. Tap to resume." }
            if isCompleted { return "Nice. Tap to start again." }
            return "Tap the orb to begin."
        }()

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

                            Text(hintText)
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
                        userDidPressPrimaryToggle()
                    }
            }
            .scaleEffect(compact ? 0.9 : 1.0)
            .offset(y: compact ? -10 : 0)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Controls
    private func primaryControls(accentPrimary: Color, accentSecondary: Color) -> some View {
        HStack(spacing: 12) {
            Button(action: {
                simpleTap()
                if isRunning {
                    activeAlert = .resetConfirm
                } else {
                    resetAllToDefault()
                }
            }) {
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

            Button(action: {
                simpleTap()
                if isRunning {
                    activeAlert = .lengthChange
                } else {
                    prepareTimePicker()
                    showingTimePicker = true
                }
            }) {
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

            Button(action: {
                simpleTap()
                userDidPressPrimaryToggle()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: primaryButtonIconName)
                        .imageScale(.medium)
                    Text(primaryButtonTitle)
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
                .padding(.vertical, 14)
                .padding(.horizontal, 22)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: isRunning
                                           ? [accentSecondary, accentPrimary]
                                           : [accentPrimary, accentSecondary]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(radius: isRunning ? 12 : 18)
                .scaleEffect(isRunning ? 0.98 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isRunning)
            }
            .buttonStyle(.plain)
        }
    }

    private var primaryButtonTitle: String {
        switch viewModel.phase {
        case .idle: return "Start"
        case .running: return "Pause"
        case .paused: return "Resume"
        case .completed: return "Start again"
        }
    }

    private var primaryButtonIconName: String {
        switch viewModel.phase {
        case .idle: return "play.fill"
        case .running: return "pause.fill"
        case .paused: return "play.fill"
        case .completed: return "arrow.clockwise"
        }
    }

    private func userDidPressPrimaryToggle() {
        let prior = viewModel.phase

        // user is starting a new run => allow future overlay again
        if prior == .idle || prior == .completed {
            didAcknowledgeCompletion = false
        }

        viewModel.sessionName = currentSessionDisplayName
        viewModel.toggle(sessionName: currentSessionDisplayName)

        if (prior == .idle || prior == .completed),
           viewModel.phase == .running {
            lastUserStartDate = Date()
            didFireCompletionSideEffectsForThisSession = false
        }

        if prior == .idle || prior == .completed {
            if viewModel.phase == .running,
               viewModel.remainingSeconds == viewModel.totalSeconds,
               let app = appSettings.selectedExternalMusicApp {
                ExternalMusicLauncher.openSelectedApp(app)
            }
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

    private var currentStreak: Int {
        let daysWithFocus: Set<Date> = Set(
            stats.sessions
                .filter { $0.duration > 0 }
                .map { calendar.startOfDay(for: $0.date) }
        )

        if daysWithFocus.isEmpty { return 0 }

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
                                Text("\(hour)").tag(hour)
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
                                Text(String(format: "%02d", minute)).tag(minute)
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

    private func prepareTimePicker() {
        let totalMinutes = viewModel.totalSeconds / 60
        selectedHours = totalMinutes / 60
        selectedMinutes = totalMinutes % 60
    }

    private func applyCustomLength(_ minutes: Int) {
        viewModel.updateMinutes(minutes)
        FocusLocalNotificationManager.shared.cancelSessionCompletionNotification()
        if #available(iOS 18.0, *) { FocusLiveActivityManager.shared.endActivity() }
    }

    // MARK: - Phase transition side effects
    private func handlePhaseTransition(from old: FocusTimerViewModel.Phase, to new: FocusTimerViewModel.Phase) {
        appSettings.isFocusTimerRunning = (new == .running)

        switch new {
        case .idle:
            FocusLocalNotificationManager.shared.cancelSessionCompletionNotification()
            FocusSoundManager.shared.pause()
            didFireCompletionSideEffectsForThisSession = false
            showingCompletionOverlay = false
            if #available(iOS 18.0, *) { FocusLiveActivityManager.shared.endActivity() }

        case .running:
            if appSettings.soundEnabled, let selected = appSettings.selectedFocusSound {
                if old == .paused, !soundChangedWhilePaused, activeSessionSound == selected {
                    FocusSoundManager.shared.resume()
                } else {
                    activeSessionSound = selected
                    soundChangedWhilePaused = false
                    FocusSoundManager.shared.play(sound: selected)
                }
            } else {
                FocusSoundManager.shared.stop()
                activeSessionSound = nil
                soundChangedWhilePaused = false
            }

            didFireCompletionSideEffectsForThisSession = false
            didAcknowledgeCompletion = false

            FocusLocalNotificationManager.shared.scheduleSessionCompletionNotification(
                after: viewModel.remainingSeconds,
                sessionName: currentSessionDisplayName
            )

            if #available(iOS 18.0, *) {
                let seconds = max(0, viewModel.remainingSeconds)
                let endDate = Date().addingTimeInterval(TimeInterval(seconds))

                if old == .idle || old == .completed {
                    FocusLiveActivityManager.shared.startActivity(
                        totalSeconds: viewModel.totalSeconds,
                        sessionName: currentSessionDisplayName,
                        endDate: endDate
                    )
                } else {
                    FocusLiveActivityManager.shared.updatePaused(
                        remainingSeconds: seconds,
                        isPaused: false,
                        sessionName: currentSessionDisplayName
                    )
                }
            }

            if old == .idle || old == .paused || old == .completed {
                FocusSoundEngine.shared.playEvent(.start)
            }

        case .paused:
            FocusLocalNotificationManager.shared.cancelSessionCompletionNotification()
            FocusSoundManager.shared.pause()
            FocusSoundEngine.shared.playEvent(.pause)

            if #available(iOS 18.0, *) {
                FocusLiveActivityManager.shared.updatePaused(
                    remainingSeconds: viewModel.remainingSeconds,
                    isPaused: true,
                    sessionName: currentSessionDisplayName
                )
            }

        case .completed:
            guard didFireCompletionSideEffectsForThisSession == false else { return }
            didFireCompletionSideEffectsForThisSession = true

            successHaptic()
            FocusSoundEngine.shared.playEvent(.completed)

            if old == .running {
                NotificationCenterManager.shared.add(
                    kind: .sessionCompleted,
                    title: "Session complete",
                    body: "You finished “\(currentSessionDisplayName)”."
                )
            }

            // ✅ Premium behavior:
            // - In-app: show overlay (ack required) + cancel pending/delivered completion notification
            // - Not in-app: let the scheduled notification fire (no duplicates)
            if isAppActive {
                FocusLocalNotificationManager.shared.cancelSessionCompletionNotification()

                if !didAcknowledgeCompletion {
                    completionOverlaySessionName = currentSessionDisplayName
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.9)) {
                        showingCompletionOverlay = true
                    }
                }
            }

            FocusSoundManager.shared.stop()
            activeSessionSound = nil
            soundChangedWhilePaused = false

            if #available(iOS 18.0, *) { FocusLiveActivityManager.shared.endActivity() }
        }
    }

    // MARK: - External state helpers
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
        let clamped = max(0, remaining)

        // ✅ If user already acknowledged completion (Done) OR we are idle,
        // never let a stale Live Activity "0" force the UI to 00:00 again.
        if clamped == 0, (didAcknowledgeCompletion || viewModel.phase == .idle) {
            // Keep the ready state (duration stays the same)
            if viewModel.phase == .idle, viewModel.remainingSeconds == 0 {
                viewModel.resetToIdleKeepDuration()
            }
            return
        }

        // Existing Dynamic Island "instant complete" race guard
        if viewModel.phase == .running,
           viewModel.remainingSeconds > 1,
           clamped == 0 {

            let withinGrace: Bool = {
                guard let t = lastUserStartDate else { return false }
                return Date().timeIntervalSince(t) < 2.0
            }()

            if withinGrace { return }
            return
        }

        if clamped > 0 { lastKnownRemainingSeconds = clamped }

        viewModel.applyExternalState(
            isPaused: isPaused,
            remaining: clamped,
            sessionName: currentSessionDisplayName
        )
    }

    private func syncFromLiveActivityIfPossible() {
        guard #available(iOS 18.0, *) else { return }
        guard let activity = Activity<FocusSessionAttributes>.activities.first else { return }

        let state = activity.content.state
        let now = Date()

        let paused = state.isPaused
        let remaining: Int
        if paused {
            remaining = parseRemainingString(state.pausedDisplayTime)
        } else {
            remaining = max(0, Int(state.endDate.timeIntervalSince(now)))
        }

        // ✅ Same protection at source: ignore stale 0s after Done / while idle
        if remaining == 0, (didAcknowledgeCompletion || viewModel.phase == .idle) {
            return
        }

        applyExternalSessionState(isPaused: paused, remaining: remaining)
    }


    // MARK: - Reset all
    private func resetAllToDefault() {
        viewModel.resetToDefault()
        FocusLocalNotificationManager.shared.cancelSessionCompletionNotification()

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

        if #available(iOS 18.0, *) { FocusLiveActivityManager.shared.endActivity() }

        lastUserStartDate = nil
        didFireCompletionSideEffectsForThisSession = false
        didAcknowledgeCompletion = false
        showingCompletionOverlay = false
    }

    // MARK: - Haptics
    private func simpleTap() { Haptics.impact(.medium) }
    private func successHaptic() { Haptics.notification(.success) }
    private func minuteTickHaptic() { Haptics.impact(.rigid) }

    // MARK: - Sound helpers
    private func handleSelectedSoundChanged() {
        guard appSettings.soundEnabled,
              let sound = appSettings.selectedFocusSound else {
            FocusSoundManager.shared.stop()
            activeSessionSound = nil
            soundChangedWhilePaused = false
            return
        }

        if isRunning {
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

        guard isRunning else {
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

// MARK: - Completion Overlay (Premium, blends with theme)

private struct CompletionOverlay: View {
    let accentPrimary: Color
    let accentSecondary: Color
    let sessionTitle: String
    let durationText: String
    let onDone: () -> Void

    @State private var appear: Bool = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.45))
                .ignoresSafeArea()
                .onTapGesture { } // block tap-through

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [accentPrimary, accentSecondary]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: accentPrimary.opacity(0.35), radius: 22, x: 0, y: 12)

                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black.opacity(0.85))
                }

                Text("Session complete")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.94))

                Text("You finished “\(sessionTitle)”")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)

                Text("Ready for another \(durationText) session")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))

                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [accentPrimary, accentSecondary]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: accentPrimary.opacity(0.35), radius: 18, x: 0, y: 10)
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 28, x: 0, y: 18)
            .padding(.horizontal, 24)
            .scaleEffect(appear ? 1.0 : 0.97)
            .opacity(appear ? 1.0 : 0.0)
            .onAppear {
                Haptics.notification(.success)
                withAnimation(.spring(response: 0.42, dampingFraction: 0.9)) {
                    appear = true
                }
            }
        }
    }
}

// MARK: - Sound engine for short UI events (unchanged)
final class FocusSoundEngine {
    enum Event { case start, pause, completed, minuteTick }

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

            guard let url = Bundle.main.url(forResource: fileName, withExtension: "wav") else { return }

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
            withAnimation(.easeOut(duration: 0.8)) { titleOpacity = 1.0 }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { glowScale = 1.1 }
        }
    }
}

#Preview {
    FocusView()
}
