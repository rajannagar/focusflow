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
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var notifications = NotificationCenterManager.shared
    @ObservedObject private var presetStore = FocusPresetStore.shared
    
    @State private var showingTimePicker = false
    @State private var selectedHours: Int = 0
    @State private var selectedMinutes: Int = 25
    
    @State private var showingSoundSheet = false
    @State private var showingNotificationCenter = false
    @State private var showingPresetManager = false
    @State private var showingAmbientPicker = false
    @State private var showingFocusInfoSheet = false
    
    
    @State private var ambientMode: AmbientMode = .minimal
    @State private var ambientIntensity: Double = 0.7
    
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
    
    // ✅ Track original theme before preset is applied (for reset restoration)
    @State private var originalThemeBeforePreset: AppTheme? = nil
    
    // ✅ Premium in-app completion overlay
    @State private var showingCompletionOverlay: Bool = false
    @State private var completionOverlaySessionName: String = ""
    
    // ✅ Prevent overlay from reappearing after user acknowledged completion
    @State private var didAcknowledgeCompletion: Bool = false
    
    @State private var activeAlert: ActiveAlert? = nil
    
    // ✅ Background bridge monitoring for sound control
    @State private var bridgeMonitorTimer: Timer?
    @State private var lastBridgeCheckTime: TimeInterval = 0
    
    private let calendar = Calendar.current
    
    private var activePreset: FocusPreset? { presetStore.activePreset }
    
    private var isRunning: Bool { viewModel.phase == .running }
    private var isPaused: Bool { viewModel.phase == .paused }
    private var isCompleted: Bool { viewModel.phase == .completed }
    private var isIdle: Bool { viewModel.phase == .idle }
    
    private var currentSessionDisplayName: String {
        if !sessionName.isEmpty { return sessionName }
        if let preset = activePreset { return preset.name }
        return "Focus session"
    }
    
    private var currentPresetSubtitle: String {
        guard let preset = activePreset else { return "Choose how you want to focus today." }
        return "Stay present with \(preset.name.lowercased())."
    }
    
    // ✅ helper: are we actually in the foreground?
    private var isAppActive: Bool {
        UIApplication.shared.applicationState == .active
    }
    
    private var theme: AppTheme { appSettings.profileTheme }
    
    var body: some View {
        GeometryReader { proxy in
            content(size: proxy.size)
        }
    }
    
    // MARK: - Main content (split to avoid type-check timeouts)
    private func content(size: CGSize) -> some View {
        let accentPrimary: Color = theme.accentPrimary
        let accentSecondary: Color = theme.accentSecondary
        let isTyping: Bool = isIntentionFocused
        let todayTotal: TimeInterval = progressStore.totalToday
        let totalMinutes: Int = max(viewModel.totalSeconds / 60, 1)

        // ✅ Type-erasure here prevents "unable to type-check" explosions
        let root = AnyView(
            ZStack {
                AmbientBackground(
                    mode: ambientMode,
                    theme: theme,
                    isActive: isRunning,
                    intensity: ambientIntensity
                )

                VStack(spacing: 20) {
                    header(accentPrimary: accentPrimary)

                    // ✅ IMPORTANT: call the function version
                    intentionSection(accentPrimary: accentPrimary)
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

                if showingCompletionOverlay {
                    CompletionOverlay(
                        theme: theme,
                        sessionTitle: completionOverlaySessionName,
                        durationText: "\(max(viewModel.totalSeconds / 60, 1)) min",
                        onDone: { acknowledgeCompletionAndResetReady() }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 1.01)))
                    .zIndex(50)
                }
            }
        )

        let viewWithAppear = root
            .onAppear {
                viewModel.sessionName = currentSessionDisplayName
                syncFromLiveActivityIfPossible()
                if isIdle { showingCompletionOverlay = false }
                
                // ✅ If there's a running/paused session with an active preset, apply its settings
                if let preset = activePreset, (isRunning || isPaused) {
                    applyPresetSettingsOnly(preset)
                }
                
                // ✅ If there's a running session, ensure sound is playing if it should be
                // This handles the case where the session was restored from app launch
                if isRunning, appSettings.soundEnabled, let selected = appSettings.selectedFocusSound {
                    if activeSessionSound != selected {
                        // Sound changed or wasn't set - start it
                        activeSessionSound = selected
                        soundChangedWhilePaused = false
                        FocusSoundManager.shared.play(sound: selected)
                    } else {
                        // Sound is already set - make sure it's playing (might have stopped when app was killed)
                        FocusSoundManager.shared.play(sound: selected)
                    }
                }
                
                // ✅ Start monitoring bridge for sound control when session is active
                if #available(iOS 18.0, *) {
                    startBridgeMonitoring()
                }
            }
            .onDisappear {
                if #available(iOS 18.0, *) {
                    stopBridgeMonitoring()
                }
            }
        
        let viewWithNotifications = viewWithAppear
            .onReceive(NotificationCenter.default.publisher(for: .focusSessionExternalToggle)) { notification in
                guard
                    let userInfo = notification.userInfo,
                    let isPaused = userInfo["isPaused"] as? Bool,
                    let remaining = userInfo["remainingSeconds"] as? Int
                else { return }

                applyExternalSessionState(isPaused: isPaused, remaining: remaining)
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FocusFlow.applyPresetFromWidget"))) { notification in
                handleWidgetPresetNotification(notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FocusFlow.widgetPauseAction"))) { _ in
                handleWidgetPauseAction()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FocusFlow.widgetResumeAction"))) { _ in
                handleWidgetResumeAction()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FocusFlow.widgetStartAction"))) { _ in
                handleWidgetStartAction()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FocusFlow.widgetSwitchPreset"))) { notification in
                handleWidgetSwitchPreset(notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FocusFlow.widgetResetConfirm"))) { _ in
                handleWidgetResetConfirm()
            }
        
        return viewWithNotifications
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }

                if #available(iOS 18.0, *) {
                    FocusSessionStore.shared.applyExternalToggleIfNeeded()
                }
                syncFromLiveActivityIfPossible()

                if isIdle { showingCompletionOverlay = false }
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
                
                // ✅ Restart bridge monitoring when phase changes (session starts/stops)
                if #available(iOS 18.0, *) {
                    if newPhase == .running || newPhase == .paused {
                        startBridgeMonitoring()
                    } else {
                        stopBridgeMonitoring()
                    }
                }
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
            .onChange(of: presetStore.activePresetID) { _, newPresetID in
                // ✅ When preset is restored during a running session, apply all its settings
                if let presetID = newPresetID,
                   let preset = presetStore.presets.first(where: { $0.id == presetID }),
                   (isRunning || isPaused) {
                    // Apply preset settings (theme, ambiance, sound) without changing duration
                    applyPresetSettingsOnly(preset)
                }
            }
            .sheet(isPresented: $showingTimePicker) { timePickerSheet }
            .sheet(isPresented: $showingSoundSheet) { FocusSoundPicker() }
            .sheet(isPresented: $showingNotificationCenter) { NotificationCenterView() }
            .sheet(isPresented: $showingPresetManager) { FocusPresetManagerView() }
            .sheet(isPresented: $showingAmbientPicker) {
                AmbientPickerSheet(theme: theme, selectedMode: $ambientMode, intensity: $ambientIntensity)
                    .presentationDetents([.large])
            }
            // ✅ Your new Focus Info Sheet
            .sheet(isPresented: $showingFocusInfoSheet) {
                FocusInfoSheet(theme: theme)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.clear)
                    .presentationCornerRadius(32)
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .presetSwitch:
                    return Alert(
                        title: Text("Switch preset?"),
                        message: Text("This will reset your current session and apply \"\(pendingPresetToApply?.name ?? "")\"."),
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
                    let message = isPaused 
                        ? "Reset will clear the paused session and return everything to default."
                        : "Reset will stop the current session and return everything to default."
                    return Alert(
                        title: Text("Reset session?"),
                        message: Text(message),
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
        
        didAcknowledgeCompletion = true
        withAnimation(.spring(response: 0.38, dampingFraction: 0.9)) {
            showingCompletionOverlay = false
        }
        
        viewModel.resetToIdleKeepDuration()
        didFireCompletionSideEffectsForThisSession = false
        
        FocusLocalNotificationManager.shared.clearDeliveredSessionCompletionNotifications()
    }
    
    // MARK: - Header (Premium style)
    private func header(accentPrimary: Color) -> some View {
        let name = appSettings.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasUnread = notifications.notifications.contains { !$0.isRead }
        
        return HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Image("Focusflow_Logo")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.30), radius: 8, x: 0, y: 4)
                    
                    Text("FocusFlow")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                if name.isEmpty {
                    Text("Lock in a win.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                } else {
                    Text("\(greetingTitle), \(name)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // ✅ Only keep Bell + Info on the top-right
            HStack(spacing: 10) {
                Button {
                    simpleTap()
                    showingNotificationCenter = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: hasUnread ? "bell.fill" : "bell")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                        
                        if hasUnread {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Button {
                    simpleTap()
                    showingFocusInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
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
    
    // MARK: - Intention (Premium glass)
    private func intentionSection(accentPrimary: Color) -> some View {
        HStack(spacing: 10) {

            // Music icon (left)
            Button {
                simpleTap()
                showingSoundSheet = true
            } label: {
                Image(systemName: "headphones")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Vibe / ambience icon (left)
            Button {
                simpleTap()
                showingAmbientPicker = true
            } label: {
                Image(systemName: ambientMode.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Intention field (fills the rest)
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(accentPrimary.opacity(0.70))

                TextField("Deep work, exam prep, client project...", text: $sessionName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .submitLabel(.done)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Presets (Premium chips)
    private func presetSelector(accentPrimary: Color, accentSecondary: Color) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button {
                    simpleTap()
                    showingPresetManager = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                ForEach(presetStore.presets) { preset in
                    let isSelected = (presetStore.activePresetID == preset.id)

                    Button {
                        simpleTap()
                        handlePresetTap(preset)
                    } label: {
                        Text(preset.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isSelected ? .black : .white.opacity(0.85))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Group {
                                    if isSelected {
                                        LinearGradient(
                                            colors: [accentPrimary, accentSecondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    } else {
                                        Color.white.opacity(0.04)
                                    }
                                }
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(isSelected ? 0.0 : 0.06), lineWidth: 1)
                            )
                            .shadow(color: isSelected ? accentPrimary.opacity(0.3) : .clear, radius: isSelected ? 8 : 0)
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
    
    // MARK: - Widget Notification Handlers
    
    private func handleWidgetPresetNotification(_ notification: Notification) {
        guard let presetID = notification.userInfo?["presetID"] as? UUID,
              let preset = presetStore.presets.first(where: { $0.id == presetID }) else { return }
        
        let autoStart = notification.userInfo?["autoStart"] as? Bool ?? false
        
        // If idle, apply the full preset (duration, theme, sound, etc.)
        if isIdle {
            applyPreset(preset)
            
            // Auto-start if requested
            if autoStart {
                handleWidgetAutoStart()
            }
        } else if isRunning || isPaused {
            // Session active - show confirmation dialog
            pendingPresetToApply = preset
            activeAlert = .presetSwitch
        }
    }
    
    private func handleWidgetPauseAction() {
        if isRunning {
            viewModel.pause()
        }
    }
    
    private func handleWidgetResumeAction() {
        if isPaused {
            viewModel.toggle(sessionName: currentSessionDisplayName)
        }
    }
    
    private func handleWidgetAutoStart() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.viewModel.toggle(sessionName: self.currentSessionDisplayName)
        }
    }
    
    private func handleWidgetStartAction() {
        // Start with current settings (no preset)
        if isIdle || isCompleted {
            viewModel.toggle(sessionName: currentSessionDisplayName)
        }
    }
    
    private func handleWidgetSwitchPreset(_ notification: Notification) {
        guard let presetID = notification.userInfo?["presetID"] as? UUID,
              let preset = presetStore.presets.first(where: { $0.id == presetID }) else { return }
        
        // If session is running, show confirmation
        if isRunning || isPaused {
            pendingPresetToApply = preset
            activeAlert = .presetSwitch
        } else {
            // No session - just apply the preset
            applyPreset(preset)
        }
    }
    
    private func handleWidgetResetConfirm() {
        // If session is running, show reset confirmation
        if isRunning || isPaused {
            activeAlert = .resetConfirm
        } else {
            // No session - just clear preset selection
            clearWidgetPresetSelection()
            presetStore.activePresetID = nil
        }
    }
    
    private func clearWidgetPresetSelection() {
        let defaults = UserDefaults(suiteName: "group.ca.softcomputers.FocusFlow")
        defaults?.removeObject(forKey: "widget.selectedPresetID")
        defaults?.removeObject(forKey: "widget.selectedPresetDuration")
        
        // Sync all data to clear widget state
        WidgetDataManager.shared.syncAll()
    }

    private func applyPreset(_ preset: FocusPreset) {
        presetStore.activePresetID = preset.id

        if let themeRaw = preset.themeRaw,
           let presetTheme = AppTheme(rawValue: themeRaw) {
            // ✅ Save original theme before applying preset (only on first preset application)
            if originalThemeBeforePreset == nil {
                originalThemeBeforePreset = appSettings.profileTheme
            }
            
            // ✅ Keep new + old theme paths in sync
            appSettings.profileTheme = presetTheme
            appSettings.selectedTheme = presetTheme
        }

        // Apply ambiance mode from preset
        if let presetAmbiance = preset.ambianceMode {
            ambientMode = presetAmbiance
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
    
    /// ✅ Apply preset settings (theme, ambiance, sound) without changing duration or session name
    /// This is used when restoring a preset during a running session
    private func applyPresetSettingsOnly(_ preset: FocusPreset) {
        // Apply theme
        if let themeRaw = preset.themeRaw,
           let presetTheme = AppTheme(rawValue: themeRaw) {
            // Save original theme before applying preset (only on first preset application)
            if originalThemeBeforePreset == nil {
                originalThemeBeforePreset = appSettings.profileTheme
            }
            
            // Keep new + old theme paths in sync
            appSettings.profileTheme = presetTheme
            appSettings.selectedTheme = presetTheme
        }
        
        // Apply ambiance mode from preset
        if let presetAmbiance = preset.ambianceMode {
            ambientMode = presetAmbiance
        }
        
        // Apply sound settings from preset
        if let app = preset.externalMusicApp {
            appSettings.selectedExternalMusicApp = app
            appSettings.selectedFocusSound = nil
            
            // Only stop sound if session is paused (don't interrupt running session)
            if isPaused {
                FocusSoundManager.shared.stop()
                activeSessionSound = nil
                soundChangedWhilePaused = false
            }
        } else if let sound = soundForPreset(preset) {
            appSettings.selectedExternalMusicApp = nil
            appSettings.selectedFocusSound = sound
            
            // If session is running, start the sound
            if isRunning {
                activeSessionSound = sound
                soundChangedWhilePaused = false
                if appSettings.soundEnabled {
                    FocusSoundManager.shared.play(sound: sound)
                }
            } else if isPaused {
                activeSessionSound = sound
                soundChangedWhilePaused = false
            }
        } else {
            appSettings.selectedExternalMusicApp = nil
            appSettings.selectedFocusSound = nil
            
            // Only stop sound if session is paused (don't interrupt running session)
            if isPaused {
                FocusSoundManager.shared.stop()
                activeSessionSound = nil
                soundChangedWhilePaused = false
            }
        }
    }

    // MARK: - Orb
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
        let timeFontSize: CGFloat = compact ? 32 : 44
        let subtitleFontSize: CGFloat = compact ? 11 : 12
        let hintFontSize: CGFloat = compact ? 10 : 11

        let hintText: String = {
            if isRunning { return "Stay with it." }
            if isPaused { return "Paused. Tap to resume." }
            if isCompleted { return "Nice. Tap to start again." }
            return "Tap the orb to begin."
        }()

        return VStack(spacing: 16) {
            Text(currentPresetSubtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            ZStack {
                // Outer breathing glow - starts OUTSIDE the orb
                Circle()
                    .stroke(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                accentPrimary.opacity(0.6),
                                accentSecondary.opacity(0.3),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: size.width * 0.28,
                            endRadius: size.width * 0.55
                        ),
                        lineWidth: size.width * 0.25
                    )
                    .frame(width: size.width * 0.70, height: size.width * 0.70)
                    .blur(radius: 30)
                    .scaleEffect(outerBreathScale)
                    .opacity(isRunning ? 0.8 : 0.0)

                // Rotating ring glow
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                accentPrimary.opacity(0.15),
                                accentSecondary.opacity(0.35),
                                accentPrimary.opacity(0.15)
                            ]),
                            center: .center
                        ),
                        lineWidth: 24
                    )
                    .frame(width: size.width * 0.68, height: size.width * 0.68)
                    .blur(radius: 12)
                    .opacity(isRunning ? 1.0 : 0.5)
                    .rotationEffect(.degrees(isRunning ? 360 : 0))
                    .animation(
                        isRunning
                        ? .linear(duration: 16).repeatForever(autoreverses: false)
                        : .easeOut(duration: 0.4),
                        value: isRunning
                    )

                // Background track
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 16)
                    .frame(width: size.width * 0.56, height: size.width * 0.56)

                // Progress arc
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
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: size.width * 0.56, height: size.width * 0.56)

                // Inner orb - Dark with Theme Gradient
                ZStack {
                    // Dark base with subtle theme gradient
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    accentPrimary.opacity(0.15),
                                    accentSecondary.opacity(0.08),
                                    Color(red: 0.08, green: 0.08, blue: 0.10)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: size.width * 0.22
                            )
                        )
                    
                    // Timer content
                    VStack(spacing: 4) {
                        Text(displayedTimeString())
                            .font(.system(size: timeFontSize, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)

                        Text("\(totalMinutes)-minute session")
                            .font(.system(size: subtitleFontSize, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))

                        Text(hintText)
                            .font(.system(size: hintFontSize, weight: .medium))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
                .frame(width: size.width * 0.42, height: size.width * 0.42)
                .clipShape(Circle())
                // Subtle border
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    accentPrimary.opacity(0.5),
                                    accentSecondary.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .scaleEffect(innerBreathScale)
                .scaleEffect(orbTapFlash ? 1.02 : 1.0)
                .animation(.easeOut(duration: 0.15), value: orbTapFlash)
                .onTapGesture {
                    simpleTap()
                    orbTapFlash = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        orbTapFlash = false
                    }
                    userDidPressPrimaryToggle()
                }
            }
            .scaleEffect(compact ? 0.85 : 1.0)
            .offset(y: compact ? -10 : 0)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Controls (Premium chips + CTA)
    private func primaryControls(accentPrimary: Color, accentSecondary: Color) -> some View {
        HStack(spacing: 10) {
            Button {
                simpleTap()
                if isRunning || isPaused {
                    activeAlert = .resetConfirm
                } else {
                    resetAllToDefault()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Reset")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.04))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.06), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button {
                simpleTap()
                if isRunning {
                    activeAlert = .lengthChange
                } else {
                    prepareTimePicker()
                    showingTimePicker = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Length")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.04))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.06), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                simpleTap()
                userDidPressPrimaryToggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: primaryButtonIconName)
                        .font(.system(size: 14, weight: .bold))
                    Text(primaryButtonTitle)
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
                .background(
                    LinearGradient(
                        colors: isRunning ? [accentSecondary, accentPrimary] : [accentPrimary, accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: accentPrimary.opacity(0.3), radius: isRunning ? 10 : 16, x: 0, y: 8)
                .scaleEffect(isRunning ? 0.98 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isRunning)
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
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 11))
                    .foregroundColor(theme.accentPrimary.opacity(0.8))
                Text(todayTotal.asReadableDuration + " today")
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.orange.opacity(0.8))
                Text("\(currentStreak) day streak")
            }
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(.white.opacity(0.5))
        .padding(.horizontal, 4)
        .opacity(isTyping ? 0 : 1)
    }

    private var currentStreak: Int {
        let daysWithFocus: Set<Date> = Set(
            progressStore.sessions
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

    // MARK: - Time picker sheet (with PremiumAppBackground)
    private var timePickerSheet: some View {
        ZStack {
            PremiumAppBackground(theme: theme, showParticles: false)

            VStack(spacing: 14) {
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 44, height: 4)
                    .padding(.top, 10)

                Text("Session Length")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text("Set a length that fits what you're about to do.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)

                HStack(spacing: 0) {
                    VStack(spacing: 6) {
                        Text("Hours")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))

                        Picker("Hours", selection: $selectedHours) {
                            ForEach(0..<13) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .background(Color.white.opacity(0.10))
                        .padding(.vertical, 10)

                    VStack(spacing: 6) {
                        Text("Minutes")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))

                        Picker("Minutes", selection: $selectedMinutes) {
                            ForEach(0..<60) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 170)
                .colorScheme(.dark)
                .padding(.horizontal, 18)
                .padding(.top, 8)

                HStack(spacing: 12) {
                    Button {
                        simpleTap()
                        showingTimePicker = false
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        simpleTap()
                        let totalMinutes = selectedHours * 60 + selectedMinutes
                        guard totalMinutes > 0 else {
                            showingTimePicker = false
                            return
                        }
                        applyCustomLength(totalMinutes)
                        showingTimePicker = false
                    } label: {
                        Text("Set")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)

                Spacer(minLength: 6)
            }
            .padding(.bottom, 14)
        }
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
        .presentationDetents([.fraction(0.52), .medium, .large])
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

            // ✅ Phase 2: Use NotificationsCoordinator instead of direct FocusLocalNotificationManager call
            NotificationsCoordinator.shared.scheduleSessionCompletionIfEnabled(
                afterSeconds: viewModel.remainingSeconds,
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

            // ❌ IMPORTANT:
            // Do NOT save the session here.
            // The session is logged from the timer/view-model (single source of truth)
            // to avoid duplicates in Progress/Profile/Journey.

            if old == .running {
                NotificationCenterManager.shared.add(
                    kind: .sessionCompleted,
                    title: "Session complete",
                    body: "You finished \"\(currentSessionDisplayName)\"."
                )
            }

            // In-app: show overlay + cancel completion notification
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

        if clamped == 0, (didAcknowledgeCompletion || viewModel.phase == .idle) {
            if viewModel.phase == .idle, viewModel.remainingSeconds == 0 {
                viewModel.resetToIdleKeepDuration()
            }
            return
        }

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

        // ✅ Handle sound pause/resume when toggling from Live Activity
        let wasPaused = viewModel.phase == .paused
        let willBePaused = isPaused
        
        // If state is changing (paused <-> running), handle sound immediately
        if wasPaused != willBePaused {
            if willBePaused {
                // Pausing from Live Activity - pause the sound
                FocusSoundManager.shared.pause()
            } else {
                // Resuming from Live Activity - resume the sound if it was playing
                if let selected = appSettings.selectedFocusSound, appSettings.soundEnabled {
                    if activeSessionSound == selected {
                        FocusSoundManager.shared.resume()
                    } else {
                        activeSessionSound = selected
                        FocusSoundManager.shared.play(sound: selected)
                    }
                }
            }
        }

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

        // ✅ Restore original theme from settings (before preset was applied)
        // If no preset was applied, restore to profileTheme (user's chosen theme)
        if let originalTheme = originalThemeBeforePreset {
            appSettings.profileTheme = originalTheme
            appSettings.selectedTheme = originalTheme
            originalThemeBeforePreset = nil
        } else {
            // No preset was applied, just sync selectedTheme to profileTheme
            appSettings.selectedTheme = appSettings.profileTheme
        }

        // ✅ Reset ambiance to default
        ambientMode = .minimal
        ambientIntensity = 0.7

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
        
        // ✅ Clear widget preset selection
        clearWidgetPresetSelection()
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
    
    // MARK: - Bridge Monitoring for Sound Control
    
    @available(iOS 18.0, *)
    private func startBridgeMonitoring() {
        stopBridgeMonitoring() // Stop any existing timer
        
        // Only monitor when session is active
        guard isRunning || isPaused else { return }
        
        // Check immediately
        checkBridgeAndHandleSound()
        
        // Set up periodic checking (every 1 second when app is active)
        // Note: No need for weak capture since FocusView is a struct (value type)
        bridgeMonitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Only check if session is still active
            if isRunning || isPaused {
                checkBridgeAndHandleSound()
            } else {
                stopBridgeMonitoring()
            }
        }
    }
    
    private func stopBridgeMonitoring() {
        bridgeMonitorTimer?.invalidate()
        bridgeMonitorTimer = nil
    }
    
    @available(iOS 18.0, *)
    private func checkBridgeAndHandleSound() {
        guard let bridgeState = FocusSessionBridge.peekState() else { return }
        
        // Only process if this is a new update (timestamp changed)
        guard bridgeState.lastUpdateTime > lastBridgeCheckTime else { return }
        lastBridgeCheckTime = bridgeState.lastUpdateTime
        
        // Post notification to trigger applyExternalSessionState which handles both state and sound
        NotificationCenter.default.post(
            name: .focusSessionExternalToggle,
            object: nil,
            userInfo: [
                "isPaused": bridgeState.isPaused,
                "remainingSeconds": bridgeState.remainingSeconds
            ]
        )
    }
}

// MARK: - Completion Overlay (Premium, blends with theme)

private struct CompletionOverlay: View {
    let theme: AppTheme
    let sessionTitle: String
    let durationText: String
    let onDone: () -> Void

    @State private var appear: Bool = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .ignoresSafeArea()
                .onTapGesture { }

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [theme.accentPrimary, theme.accentSecondary]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: theme.accentPrimary.opacity(0.4), radius: 24, x: 0, y: 12)

                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                }

                Text("Session Complete")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text("You finished \"\(sessionTitle)\"")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text("Ready for another \(durationText) session")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))

                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [theme.accentPrimary, theme.accentSecondary]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: theme.accentPrimary.opacity(0.3), radius: 16, x: 0, y: 8)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(red: 0.10, green: 0.10, blue: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.4), radius: 32, x: 0, y: 20)
            .padding(.horizontal, 32)
            .scaleEffect(appear ? 1.0 : 0.95)
            .opacity(appear ? 1.0 : 0.0)
            .onAppear {
                Haptics.notification(.success)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    appear = true
                }
            }
        }
    }
}

// MARK: - Sound engine for short UI events (kept local to this file)
final class FocusSoundEngine {
    enum Event { case start, pause, completed, minuteTick }

    static let shared = FocusSoundEngine()

    private var player: AVAudioPlayer?
    private let queue = DispatchQueue(label: "focusflow.soundengine")

    func playEvent(_ event: Event) {
        queue.async { [weak self] in
            guard let self else { return }
            let name: String
            switch event {
            case .start: name = "focus_start"
            case .pause: name = "focus_pause"
            case .completed: name = "focus_completed"
            case .minuteTick: name = "focus_tick"
            }

            guard let url = Bundle.main.url(forResource: name, withExtension: "mp3")
                    ?? Bundle.main.url(forResource: name, withExtension: "wav")
            else { return }

            do {
                self.player = try AVAudioPlayer(contentsOf: url)
                self.player?.prepareToPlay()
                self.player?.play()
            } catch {
                // fail silently (premium feel > noisy logs)
            }
        }
    }
}

#Preview {
    FocusView()
}
