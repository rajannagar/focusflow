import SwiftUI

// MARK: - External music helper for UI

extension AppSettings.ExternalMusicApp {
    var iconName: String {
        switch self {
        case .spotify:      return "music.quarternote.3"
        case .appleMusic:   return "applelogo"
        case .youtubeMusic: return "play.rectangle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .spotify:
            return Color.green
        case .appleMusic:
            return Color.red
        case .youtubeMusic:
            return Color(red: 0.90, green: 0.16, blue: 0.22)
        }
    }
}

// ============================================================
// MARK: - MAIN SHEET
// ============================================================

struct FocusSoundPicker: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss

    // MARK: - Tabs

    private enum Tab: String, CaseIterable, Identifiable {
        case builtin
        case externalMusic

        var id: String { rawValue }

        var title: String {
            switch self {
            case .builtin:       return "Focus Sounds"
            case .externalMusic: return "Music Apps"
            }
        }

        var iconName: String {
            switch self {
            case .builtin:       return "waveform"
            case .externalMusic: return "headphones"
            }
        }
    }

    @State private var selectedTab: Tab = .builtin

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let theme = appSettings.selectedTheme
            let accentPrimary = theme.accentPrimary
            let accentSecondary = theme.accentSecondary

            ZStack {
                // Background – match Notifications / FocusView
                LinearGradient(
                    gradient: Gradient(colors: theme.backgroundColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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

                VStack(spacing: 18) {
                    // Header
                    header
                        .padding(.horizontal, 22)
                        .padding(.top, 18)

                    // Tabs
                    tabSelector(
                        accentPrimary: accentPrimary,
                        accentSecondary: accentSecondary
                    )
                    .padding(.horizontal, 22)

                    // Content
                    Group {
                        switch selectedTab {
                        case .builtin:
                            BuiltInSoundsTab(
                                accentPrimary: accentPrimary,
                                accentSecondary: accentSecondary
                            )
                        case .externalMusic:
                            ExternalMusicTab()
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 4)

                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .imageScale(.medium)
                        .foregroundColor(.white.opacity(0.9))

                    Text("Focus sound")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Text("Pick how your focus should feel.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.72))
            }

            Spacer()

            Button {
                Haptics.impact(.light)
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.small)
                    Text("Done")
                        .fontWeight(.semibold)
                }
                .font(.system(size: 14))
                .foregroundColor(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Tab selector

    private func tabSelector(
        accentPrimary: Color,
        accentSecondary: Color
    ) -> some View {
        HStack(spacing: 8) {
            ForEach(Tab.allCases) { tab in
                let isSelected = (tab == selectedTab)

                Button {
                    Haptics.impact(.light)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.iconName)
                            .imageScale(.small)

                        Text(tab.title)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(isSelected ? .black : .white.opacity(0.8))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(
                        Group {
                            if isSelected {
                                LinearGradient(
                                    gradient: Gradient(colors: [accentPrimary, accentSecondary]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                Color.white.opacity(0.18)
                            }
                        }
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }
}

// ============================================================
// MARK: - BUILT-IN SOUND TAB
// ============================================================

private struct BuiltInSoundsTab: View {
    @ObservedObject private var appSettings = AppSettings.shared

    let accentPrimary: Color
    let accentSecondary: Color

    var body: some View {
        VStack(spacing: 14) {
            // Current selection pill
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 28, height: 28)

                    Image(systemName: appSettings.selectedFocusSound == nil ? "speaker.slash" : "waveform")
                        .imageScale(.small)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Session ambience")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))

                    Text(currentSelectionLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.28))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            // List of built-in sounds
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    noSoundRow()

                    ForEach(FocusSound.allCases) { sound in
                        soundRow(sound)
                    }

                    Text("Tip: tap a sound to preview. Your timer will use whichever sound you last chose.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 8)
                }
                .padding(.top, 4)   // ← Only a little breathing room at the top
            }
            .ignoresSafeArea(edges: .bottom)   // ← EXTEND TO THE VERY BOTTOM
        }
    }

    private var currentSelectionLabel: String {
        if let sound = appSettings.selectedFocusSound {
            return sound.displayName
        }
        return "Silence"
    }

    private func soundRow(_ sound: FocusSound) -> some View {
        let isSelected = appSettings.selectedFocusSound == sound

        return Button {
            Haptics.impact(.light)

            // Built-in sound selected → clear external app
            appSettings.selectedFocusSound = sound
            appSettings.selectedExternalMusicApp = nil

            FocusSoundManager.shared.stop()
            FocusSoundManager.shared.play(sound: sound)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: "waveform")
                        .foregroundColor(isSelected ? .black.opacity(0.8) : .white.opacity(0.9))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(sound.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isSelected ? .black : .white)

                    Text("Loops quietly while your timer runs.")
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? .black.opacity(0.6) : .white.opacity(0.6))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(.white)
                        .shadow(color: accentPrimary.opacity(0.7), radius: 6, x: 0, y: 3)
                        .overlay(
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.black.opacity(0.8))
                                .imageScale(.medium)
                                .offset(x: -0.5, y: -0.5)
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: [accentPrimary, accentSecondary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.white.opacity(0.10)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func noSoundRow() -> some View {
        let isSelected = appSettings.selectedFocusSound == nil

        return Button {
            Haptics.impact(.light)

            appSettings.selectedFocusSound = nil
            FocusSoundManager.shared.stop()
            // External music app (if any) can remain selected.
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.red.opacity(0.18))
                        .frame(width: 42, height: 42)

                    Image(systemName: "speaker.slash.fill")
                        .foregroundColor(.red.opacity(0.9))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("No sound")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Total silence for this session.")
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.8))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(.white)
                        .shadow(color: .red.opacity(0.7), radius: 6, x: 0, y: 3)
                        .overlay(
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.black.opacity(0.85))
                                .imageScale(.medium)
                                .offset(x: -0.5, y: -0.5)
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.red.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// ============================================================
// MARK: - EXTERNAL MUSIC TAB
// ============================================================

private struct ExternalMusicTab: View {
    @ObservedObject private var appSettings = AppSettings.shared

    private var selectionLabel: String {
        if let app = appSettings.selectedExternalMusicApp {
            return app.displayName
        } else {
            return "No music app selected"
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            // Current selection pill
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 28, height: 28)

                    Image(systemName: "headphones")
                        .imageScale(.small)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Music app for this session")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))

                    Text(selectionLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.28))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Use any music app")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Choose a music app below. When you start a FocusFlow timer, we’ll open that app so you can pick a playlist. We don’t control the music – we just keep time.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 12) {
                        musicAppCard(
                            app: .spotify,
                            subtitle: "Lo-fi, deep focus, or your own playlists."
                        )

                        musicAppCard(
                            app: .appleMusic,
                            subtitle: "Use your library or Apple Music radio."
                        )

                        musicAppCard(
                            app: .youtubeMusic,
                            subtitle: "Focus playlists mixed with your favorites."
                        )
                    }
                    .padding(.top, 6)

                    Text("Tip: after you start your timer and we open your music app, just swipe back to FocusFlow. Your session will keep running.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)

                    Spacer(minLength: 12)
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Card builder

    private func musicAppCard(
        app: AppSettings.ExternalMusicApp,
        subtitle: String
    ) -> some View {
        let isSelected = appSettings.selectedExternalMusicApp == app

        return Button {
            Haptics.impact(.medium)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                if isSelected {
                    // Tap again to clear selection
                    appSettings.selectedExternalMusicApp = nil
                } else {
                    // Selecting a music app clears built-in focus sound
                    appSettings.selectedExternalMusicApp = app
                    appSettings.selectedFocusSound = nil
                    FocusSoundManager.shared.stop()
                }
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(app.tintColor.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: app.iconName)
                        .foregroundColor(app.tintColor)
                        .imageScale(.medium)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .imageScale(.small)
                        Text("Selected")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.white)
                    .clipShape(Capsule())
                } else {
                    Text("Use this app")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FocusSoundPicker()
}
