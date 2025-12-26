import SwiftUI

struct FocusPresetEditorView: View {
    // MARK: - Environment & shared state
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appSettings = AppSettings.shared

    // MARK: - Input / output
    private let originalPreset: FocusPreset
    private let onSave: (FocusPreset) -> Void

    // MARK: - Local editing state
    @State private var name: String
    @State private var durationMinutes: Int
    @State private var soundID: String

    /// External music app for this preset (if any).
    @State private var presetExternalApp: AppSettings.ExternalMusicApp?

    /// Theme for this preset (only used when `useDefaultTheme == false`)
    @State private var presetTheme: AppTheme

    /// If true, preset does NOT override theme and just uses the app's current theme.
    @State private var useDefaultTheme: Bool

    // Duration sheet state
    @State private var showingDurationSheet = false
    @State private var selectedHours: Int = 0
    @State private var selectedMinutesComponent: Int = 25

    // Sound picker state
    @State private var showingSoundSheet = false

    // MARK: - Init

    init(preset: FocusPreset, onSave: @escaping (FocusPreset) -> Void) {
        self.originalPreset = preset
        self.onSave = onSave

        _name = State(initialValue: preset.name)
        _durationMinutes = State(initialValue: max(preset.durationSeconds / 60, 1))
        _soundID = State(initialValue: preset.soundID)

        if let app = preset.externalMusicApp {
            _presetExternalApp = State(initialValue: app)
        } else {
            _presetExternalApp = State(initialValue: nil)
        }

        if let raw = preset.themeRaw, let t = AppTheme(rawValue: raw) {
            _presetTheme = State(initialValue: t)
            _useDefaultTheme = State(initialValue: false)
        } else {
            let fallback = AppSettings.shared.profileTheme
            _presetTheme = State(initialValue: fallback)
            _useDefaultTheme = State(initialValue: true)
        }
    }

    // MARK: - Body

    var body: some View {
        let theme = appSettings.profileTheme

        ZStack {
            PremiumAppBackground(theme: theme, showParticles: true, particleCount: 16)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 14, pinnedViews: []) {
                    header(theme: theme)

                    descriptionBlock

                    sectionCard {
                        nameField
                    }

                    sectionCard {
                        sessionSettings
                    }

                    sectionCard {
                        themeSettings
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 0) // ✅ no bottom padding
            }
            .ignoresSafeArea(edges: .bottom) // ✅ scroll flush to bottom
        }
        .sheet(isPresented: $showingDurationSheet) {
            durationPickerSheet
        }
        .sheet(isPresented: $showingSoundSheet, onDismiss: applySelectedSoundFromSettings) {
            FocusSoundPicker()
        }
        // ✅ Full-page sheet
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
        .presentationCornerRadius(32)
    }

    // MARK: - Header

    private func header(theme: AppTheme) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(originalPreset.name.isEmpty ? "Preset" : originalPreset.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Text("Customize your focus mode")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.62))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                Haptics.impact(.light)
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button {
                saveAndClose()
            } label: {
                Text("Save")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: theme.accentPrimary.opacity(0.20), radius: 12, x: 0, y: 10)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Description

    private var descriptionBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Set up how this focus mode behaves.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            Text("Name it, set a default length, and choose a sound or music app.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 2)
    }

    // MARK: - Cards (subtle, not glass)

    private func sectionCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
    }

    // MARK: - Name

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Name")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.70))

            TextField("New Preset", text: $name)
                .foregroundColor(.white)
                .tint(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        }
    }

    // MARK: - Session settings

    private var sessionSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session settings")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.70))

            Button {
                openDurationSheet()
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Duration")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Default length for this preset.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.58))
                    }

                    Spacer()

                    Text("\(durationMinutes) min")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.90))

                    Image(systemName: "chevron.right")
                        .imageScale(.small)
                        .foregroundColor(.white.opacity(0.55))
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            Divider().background(Color.white.opacity(0.10))

            Button {
                openSoundPicker()
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Sound")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Built-in ambience or a music app.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.58))
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(soundDisplayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.90))
                        .lineLimit(1)

                    Image(systemName: "chevron.right")
                        .imageScale(.small)
                        .foregroundColor(.white.opacity(0.55))
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Theme

    private var themeSettings: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Theme for this preset")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.70))

            Text("Use the app theme, or pick a custom look for this mode.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.58))

            presetThemeChips
        }
    }

    private var presetThemeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                let isUsingDefault = useDefaultTheme
                Button {
                    Haptics.impact(.light)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        useDefaultTheme = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Use app theme")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(isUsingDefault ? .black : .white.opacity(0.85))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Group {
                            if isUsingDefault {
                                LinearGradient(
                                    colors: [appSettings.profileTheme.accentPrimary, appSettings.profileTheme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                Color.white.opacity(0.04)
                            }
                        }
                    )
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(isUsingDefault ? 0.0 : 0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)

                ForEach(AppTheme.allCases) { theme in
                    let isSelected = !useDefaultTheme && presetTheme == theme
                    Button {
                        Haptics.impact(.light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            useDefaultTheme = false
                            presetTheme = theme
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [theme.accentPrimary, theme.accentSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 16, height: 16)

                            Text(theme.displayName)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(isSelected ? .black : .white.opacity(0.85))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if isSelected {
                                    LinearGradient(
                                        colors: [theme.accentPrimary, theme.accentSecondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    Color.white.opacity(0.04)
                                }
                            }
                        )
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(isSelected ? 0.0 : 0.10), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Duration sheet (same vibe as FocusView time picker)

    private var durationPickerSheet: some View {
        let theme = appSettings.profileTheme
        let sheetBG = Color(red: 0.08, green: 0.08, blue: 0.10)

        return ZStack {
            sheetBG.ignoresSafeArea()

            VStack(spacing: 14) {
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 44, height: 4)
                    .padding(.top, 10)

                Text("Preset focus length")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text("Dial in how long this mode runs by default.")
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

                        Picker("Minutes", selection: $selectedMinutesComponent) {
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
                        Haptics.impact(.light)
                        showingDurationSheet = false
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
                        Haptics.impact(.light)
                        let total = selectedHours * 60 + selectedMinutesComponent
                        if total > 0 { durationMinutes = total }
                        showingDurationSheet = false
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
                            .shadow(color: theme.accentPrimary.opacity(0.22), radius: 14, x: 0, y: 10)
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
        .presentationBackground(sheetBG)
        .presentationCornerRadius(32)
        .presentationDetents([.fraction(0.52)])
    }

    // MARK: - Helpers

    private var soundDisplayName: String {
        if let app = presetExternalApp { return app.displayName }
        return humanReadableSoundName(for: soundID)
    }

    private func openDurationSheet() {
        let total = max(durationMinutes, 1)
        selectedHours = total / 60
        selectedMinutesComponent = total % 60
        showingDurationSheet = true
    }

    private func openSoundPicker() {
        if let app = presetExternalApp {
            appSettings.selectedExternalMusicApp = app
            appSettings.selectedFocusSound = nil
        } else if !soundID.isEmpty, let sound = FocusSound(rawValue: soundID) {
            appSettings.selectedFocusSound = sound
            appSettings.selectedExternalMusicApp = nil
        } else {
            appSettings.selectedFocusSound = nil
            appSettings.selectedExternalMusicApp = nil
        }
        showingSoundSheet = true
    }

    private func applySelectedSoundFromSettings() {
        if let sound = appSettings.selectedFocusSound {
            soundID = sound.id
            presetExternalApp = nil
        } else if let app = appSettings.selectedExternalMusicApp {
            soundID = ""
            presetExternalApp = app
        } else {
            soundID = ""
            presetExternalApp = nil
        }
    }

    private func saveAndClose() {
        var updated = originalPreset
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.name = trimmedName.isEmpty ? "New Preset" : trimmedName
        updated.durationSeconds = FocusPreset.minutes(durationMinutes)
        updated.soundID = soundID
        updated.externalMusicAppRaw = presetExternalApp?.rawValue

        if useDefaultTheme {
            updated.themeRaw = nil
        } else {
            updated.themeRaw = presetTheme.rawValue
        }

        onSave(updated)
        dismiss()
    }

    private func humanReadableSoundName(for id: String) -> String {
        guard !id.isEmpty else { return "Choose sound" }

        let map: [String: String] = [
            "angelsbymyside": "Angels by My Side",
            "fireplace": "Cozy Fireplace",
            "floatinggarden": "Floating Garden",
            "hearty": "Hearty",
            "light-rain-ambient": "Light Rain (Ambient)",
            "longnight": "Long Night",
            "sound-ambience": "Soft Ambience",
            "street-market-gap-france": "French Street Market",
            "thelightbetweenus": "The Light Between Us",
            "underwater": "Underwater",
            "yesterday": "Yesterday"
        ]

        if let pretty = map[id.lowercased()] { return pretty }

        let replaced = id
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")

        return replaced
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

#Preview {
    let sample = FocusPreset(
        id: UUID(),
        name: "Deep Work",
        durationSeconds: 50 * 60,
        soundID: "",
        emoji: nil,
        isSystemDefault: false,
        themeRaw: nil,
        externalMusicAppRaw: "spotify"
    )
    return FocusPresetEditorView(preset: sample) { _ in }
}
