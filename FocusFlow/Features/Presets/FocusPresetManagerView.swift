import SwiftUI

// MARK: - Glass card container (local to this file)

private struct GlassCard<Content: View>: View {
    let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Manager view

struct FocusPresetManagerView: View {
    @ObservedObject private var store = FocusPresetStore.shared
    @ObservedObject private var appSettings = AppSettings.shared

    // Sheet state
    @State private var selectedPreset: FocusPreset?
    @State private var showingNewPreset = false

    private var theme: AppTheme { appSettings.selectedTheme }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let accentPrimary = theme.accentPrimary
            let accentSecondary = theme.accentSecondary

            ZStack {
                // Background (match Focus/Habits/Stats)
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
                    header
                        .padding(.horizontal, 22)
                        .padding(.top, 18)

                    explainerCard
                        .padding(.horizontal, 22)

                    sectionHeader
                        .padding(.horizontal, 22)

                    presetsList
                        .padding(.horizontal, 22)

                    Spacer(minLength: 0)
                }
            }
        }
        // MARK: - Sheets

        // Edit existing preset
        .sheet(item: $selectedPreset) { preset in
            FocusPresetEditorView(
                preset: preset,
                onSave: { updated in
                    FocusPresetStore.shared.upsert(updated)
                }
            )
        }

        // Create new preset
        .sheet(isPresented: $showingNewPreset) {
            let defaultMinutes = 25
            let newPreset = FocusPreset(
                name: "New Preset",
                durationSeconds: FocusPreset.minutes(defaultMinutes),
                soundID: "",
                emoji: nil,
                isSystemDefault: false,
                themeRaw: AppSettings.shared.selectedTheme.rawValue,
                externalMusicAppRaw: nil
            )

            FocusPresetEditorView(
                preset: newPreset,
                onSave: { created in
                    // Save it, but do NOT auto-activate
                    FocusPresetStore.shared.upsert(created)
                }
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    // 👇 App logo instead of sparkles
                    Image("Focusflow_Logo")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)

                    Text("Presets")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("Save your favourite focus modes.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()

            Button {
                Haptics.impact(.light)
                showingNewPreset = true
            } label: {
                Image(systemName: "plus")
                    .imageScale(.medium)
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.20))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Explainer card

    private var explainerCard: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
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
                        .frame(width: 40, height: 40)

                    Image("Focusflow_Logo") // your logo
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Focus presets")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Create modes like Deep Work, Study, Yoga or Reading. Each preset remembers its own length, sound and theme so you can jump into the right mode in two taps.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Section header

    private var sectionHeader: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your presets")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))

                Text("Tap to edit. Swipe left to delete. Long press to reorder.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            if !store.presets.isEmpty {
                Text("# \(store.presets.count)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Presets list

    private var presetsList: some View {
        Group {
            if store.presets.isEmpty {
                GlassCard {
                    VStack(spacing: 10) {
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.9))

                        Text("No presets yet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Create a couple of go-to modes so you can start the right focus session in seconds.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Button {
                            Haptics.impact(.light)
                            showingNewPreset = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .imageScale(.small)
                                Text("Create first preset")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        theme.accentPrimary,
                                        theme.accentSecondary
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                // List with custom rows – supports swipe to delete + long-press reorder
                List {
                    ForEach(store.presets) { preset in
                        Button {
                            Haptics.impact(.light)
                            selectedPreset = preset
                        } label: {
                            presetRow(preset)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(
                            EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0)
                        )
                        .contentShape(Rectangle())
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Haptics.impact(.light)
                                store.delete(preset)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                    .onMove(perform: store.move(fromOffsets:toOffset:))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .padding(.bottom, -8)   // kill extra bottom padding so it scrolls flush
            }
        }
    }

    // MARK: - Row view

    private func presetRow(_ preset: FocusPreset) -> some View {
        let isActive = store.activePresetID == preset.id
        let presetTheme = preset.theme

        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(preset.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    if isActive {
                        Text("Active")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        theme.accentPrimary,
                                        theme.accentSecondary
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.black)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 6) {
                    // Duration
                    Text(preset.durationDisplay)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.80))

                    // Separator
                    Text("•")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.55))

                    // Sound / app
                    Text(preset.soundDisplayName)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.72))
                        .lineLimit(1)

                    // Theme (only if preset has one)
                    if let presetTheme {
                        Text("•")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.55))

                        HStack(spacing: 6) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            presetTheme.accentPrimary,
                                            presetTheme.accentSecondary
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
                                )

                            Text(presetTheme.displayName)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.78))
                        .lineLimit(1)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .imageScale(.small)
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.20),
                    Color.white.opacity(0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(isActive ? 0.32 : 0.16),
                        lineWidth: isActive ? 1.4 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Convenience helpers on FocusPreset

private extension FocusPreset {
    var durationDisplay: String {
        let minutes = durationSeconds / 60
        return "\(minutes) min"
    }

    /// Nicely formatted audio / app name for the list.
    /// Priority:
    /// 1. External music app (Spotify / Apple Music / YouTube Music)
    /// 2. Built-in focus sound
    /// 3. "No sound"
    var soundDisplayName: String {
        // 1) External music app
        if let app = externalMusicApp {
            return app.displayName
        }

        // 2) Built-in focus sound
        if soundID.isEmpty {
            return "No sound"
        }

        if let sound = FocusSound(rawValue: soundID) {
            return sound.displayName
        }

        // 3) Fallback – show raw ID
        return soundID
    }
}
