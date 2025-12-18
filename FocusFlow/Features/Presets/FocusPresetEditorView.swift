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

    // Duration sheet state (reuse FocusView-style picker)
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

        // If preset already has a theme, use it; otherwise default to current app theme
        if let raw = preset.themeRaw, let t = AppTheme(rawValue: raw) {
            _presetTheme = State(initialValue: t)
            _useDefaultTheme = State(initialValue: false)
        } else {
            let fallback = AppSettings.shared.selectedTheme
            _presetTheme = State(initialValue: fallback)
            _useDefaultTheme = State(initialValue: true)   // use app theme by default
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let theme = appSettings.selectedTheme

            ZStack {
                // Background gradient to match app
                LinearGradient(
                    gradient: Gradient(colors: theme.backgroundColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Soft halos like other main screens
                Circle()
                    .fill(theme.accentPrimary.opacity(0.5))
                    .blur(radius: 90)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: -size.width * 0.45, y: -size.height * 0.55)

                Circle()
                    .fill(theme.accentSecondary.opacity(0.35))
                    .blur(radius: 100)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: size.width * 0.45, y: size.height * 0.5)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        header

                        descriptionBlock
                            .padding(.top, 2)

                        nameFieldCard

                        sessionSettingsCard

                        themeCard

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 18)
                    .padding(.bottom, 24)
                }
            }
        }
        // Duration picker sheet
        .sheet(isPresented: $showingDurationSheet) {
            durationPickerSheet
        }
        // Sound picker sheet
        .sheet(isPresented: $showingSoundSheet, onDismiss: applySelectedSoundFromSettings) {
            FocusSoundPicker()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(originalPreset.name.isEmpty ? "New Preset" : originalPreset.name)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Button {
                saveAndClose()
            } label: {
                Text("Save")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                appSettings.selectedTheme.accentPrimary,
                                appSettings.selectedTheme.accentSecondary
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(radius: 12)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Description

    private var descriptionBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Set up how this focus mode behaves.")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)

            Text("Give it a name, default length and sound. You can always tweak it later.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Name card

    private var nameFieldCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Name")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))

            TextField("New Preset", text: $name)
                .foregroundColor(.white)
                .tint(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.08)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }

    // MARK: - Session settings card

    private var sessionSettingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Session settings")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))

            // Duration row
            Button {
                openDurationSheet()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duration")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)

                        Text("Default length for this preset.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Text("\(durationMinutes) min")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.right")
                        .imageScale(.small)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            Divider().background(Color.white.opacity(0.18))

            // Sound row
            Button {
                openSoundPicker()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sound")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)

                        Text("Pick a track from the focus library or use a music app.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(soundDisplayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Image(systemName: "chevron.right")
                        .imageScale(.small)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.20),
                            Color.white.opacity(0.10)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }

    // MARK: - Theme card

    private var themeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Theme for this preset")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))

            Text("Choose a custom look for this mode, or just use your main app theme.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))

            presetThemeChips
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.20),
                            Color.white.opacity(0.10)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }

    private var presetThemeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // First chip: "Use app theme"
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
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(isUsingDefault ? 0.26 : 0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(isUsingDefault ? 0.9 : 0.0), lineWidth: 1)
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                // Divider between default and custom themes
                Rectangle()
                    .frame(width: 1, height: 20)
                    .foregroundColor(Color.white.opacity(0.25))
                    .padding(.horizontal, 2)

                // Custom theme chips
                ForEach(AppTheme.allCases) { theme in
                    let isSelected = !useDefaultTheme && presetTheme == theme

                    Button {
                        Haptics.impact(.light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            useDefaultTheme = false
                            presetTheme = theme
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            theme.accentPrimary,
                                            theme.accentSecondary
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: isSelected ? 22 : 18,
                                       height: isSelected ? 22 : 18)

                            Text(theme.displayName)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(isSelected ? 0.22 : 0.12))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(isSelected ? 0.9 : 0.0), lineWidth: 1)
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Duration sheet

    private var durationPickerSheet: some View {
        let theme = appSettings.selectedTheme

        return ZStack {
            LinearGradient(
                gradient: Gradient(colors: theme.backgroundColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer().frame(height: 24)

                Text("Preset focus length")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text("Dial in how long this mode runs by default.")
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
                        Picker("Minutes", selection: $selectedMinutesComponent) {
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
                        showingDurationSheet = false
                    }
                    .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Button("Set length") {
                        let total = selectedHours * 60 + selectedMinutesComponent
                        if total > 0 {
                            durationMinutes = total
                        }
                        showingDurationSheet = false
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
        .presentationDetents([.fraction(0.40)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Helpers

    private var soundDisplayName: String {
        // If this preset has a music app, show that.
        if let app = presetExternalApp {
            return app.displayName
        }

        // Otherwise, show the built-in sound or "Choose sound" when empty.
        return humanReadableSoundName(for: soundID)
    }

    private func openDurationSheet() {
        // Pre-fill wheels from current duration
        let total = max(durationMinutes, 1)
        selectedHours = total / 60
        selectedMinutesComponent = total % 60
        showingDurationSheet = true
    }

    private func openSoundPicker() {
        // Sync the sheet with this preset's current audio choice.

        if let app = presetExternalApp {
            // Preset uses an external app → reflect that in global settings
            appSettings.selectedExternalMusicApp = app
            appSettings.selectedFocusSound = nil
        } else if !soundID.isEmpty, let sound = FocusSound(rawValue: soundID) {
            // Preset uses a built-in sound
            appSettings.selectedFocusSound = sound
            appSettings.selectedExternalMusicApp = nil
        } else {
            // Nothing set yet
            appSettings.selectedFocusSound = nil
            appSettings.selectedExternalMusicApp = nil
        }

        showingSoundSheet = true
    }

    /// After the sound sheet closes, capture whatever is currently selected
    private func applySelectedSoundFromSettings() {
        if let sound = appSettings.selectedFocusSound {
            // Built-in sound selected
            soundID = sound.id
            presetExternalApp = nil
        } else if let app = appSettings.selectedExternalMusicApp {
            // External app selected
            soundID = ""                  // no built-in sound
            presetExternalApp = app
        } else {
            // Neither – full silence
            soundID = ""
            presetExternalApp = nil
        }
        // Preview is already stopped by FocusSoundPicker.onDisappear()
    }

    private func saveAndClose() {
        var updated = originalPreset
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.name = trimmedName.isEmpty ? "New Preset" : trimmedName
        updated.durationSeconds = FocusPreset.minutes(durationMinutes)
        updated.soundID = soundID
        updated.externalMusicAppRaw = presetExternalApp?.rawValue

        // Theme persistence:
        // nil = use app theme, non-nil = override with specific theme
        if useDefaultTheme {
            updated.themeRaw = nil
        } else {
            updated.themeRaw = presetTheme.rawValue
        }

        onSave(updated)
        dismiss()
    }

    // MARK: - Sound name mapping

    private func humanReadableSoundName(for id: String) -> String {
        // Empty = no built-in sound → default copy "Choose sound"
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

        if let pretty = map[id.lowercased()] {
            return pretty
        }

        // Fallback formatting for any future sound IDs
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
