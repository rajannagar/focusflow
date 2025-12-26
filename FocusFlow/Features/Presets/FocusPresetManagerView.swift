import SwiftUI

struct FocusPresetManagerView: View {
    @ObservedObject private var store = FocusPresetStore.shared
    @ObservedObject private var appSettings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss

    // Sheets
    @State private var selectedPreset: FocusPreset?
    @State private var showingNewPreset = false

    private var theme: AppTheme { appSettings.profileTheme }

    var body: some View {
        let accentPrimary = theme.accentPrimary
        let accentSecondary = theme.accentSecondary

        ZStack {
            PremiumAppBackground(theme: theme, showParticles: true, particleCount: 16)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                header(accentPrimary: accentPrimary, accentSecondary: accentSecondary)
                    .padding(.horizontal, 18)
                    .padding(.top, 18)

                explainer
                    .padding(.horizontal, 18)

                sectionHeader
                    .padding(.horizontal, 18)

                presetsList(accentPrimary: accentPrimary, accentSecondary: accentSecondary)
                    .padding(.horizontal, 18)

                // ✅ no Spacer/padding at bottom
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .sheet(item: $selectedPreset) { preset in
            FocusPresetEditorView(
                preset: preset,
                onSave: { updated in FocusPresetStore.shared.upsert(updated) }
            )
        }
        .sheet(isPresented: $showingNewPreset) {
            let defaultMinutes = 25
            let newPreset = FocusPreset(
                name: "New Preset",
                durationSeconds: FocusPreset.minutes(defaultMinutes),
                soundID: "",
                emoji: nil,
                isSystemDefault: false,
                themeRaw: nil,
                externalMusicAppRaw: nil
            )

            FocusPresetEditorView(
                preset: newPreset,
                onSave: { created in FocusPresetStore.shared.upsert(created) }
            )
        }
        // ✅ Full-page sheet
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
        .presentationCornerRadius(32)
    }

    // MARK: - Header

    private func header(accentPrimary: Color, accentSecondary: Color) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image("Focusflow_Logo")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)

                    Text("Presets")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("Your go-to focus modes")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.62))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                Haptics.impact(.light)
                showingNewPreset = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)

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
        }
    }

    // MARK: - Explainer (subtle, not glass)

    private var explainer: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image("Focusflow_Logo")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Focus presets")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text("Create modes like Deep Work, Study, Yoga or Reading. Each preset remembers its length and sound so you can start faster.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Section header

    private var sectionHeader: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your presets")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))

                Text("Tap to edit. Swipe to delete. Long press to reorder.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            if !store.presets.isEmpty {
                Text("\(store.presets.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
        }
    }

    // MARK: - Presets list

    private func presetsList(accentPrimary: Color, accentSecondary: Color) -> some View {
        Group {
            if store.presets.isEmpty {
                emptyState(accentPrimary: accentPrimary, accentSecondary: accentSecondary)
            } else {
                // ✅ Keep List for swipe + reorder, but make it visually clean and flush
                List {
                    ForEach(store.presets) { preset in
                        Button {
                            Haptics.impact(.light)
                            selectedPreset = preset
                        } label: {
                            presetRow(preset, accentPrimary: accentPrimary, accentSecondary: accentSecondary)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
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
                .padding(.bottom, 0)
                .ignoresSafeArea(edges: .bottom) // ✅ push list flush to bottom
            }
        }
    }

    private func emptyState(accentPrimary: Color, accentSecondary: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Text("No presets yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            Text("Create a couple of go-to modes so you can start the right session in seconds.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.62))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)

            Button {
                Haptics.impact(.light)
                showingNewPreset = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .imageScale(.small)
                    Text("Create first preset")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [accentPrimary, accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: accentPrimary.opacity(0.20), radius: 12, x: 0, y: 10)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Row view

    private func presetRow(_ preset: FocusPreset, accentPrimary: Color, accentSecondary: Color) -> some View {
        let isActive = store.activePresetID == preset.id

        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(preset.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    if isActive {
                        Text("Active")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [accentPrimary, accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.black)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 6) {
                    Text(preset.durationDisplay)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.78))

                    Text("•")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.45))

                    Text(preset.soundDisplayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.62))
                        .lineLimit(1)

                    if let pt = preset.theme {
                        Text("•")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.45))

                        HStack(spacing: 6) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [pt.accentPrimary, pt.accentSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 12, height: 12)

                            Text(pt.displayName)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.62))
                        .lineLimit(1)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .imageScale(.small)
                .foregroundColor(.white.opacity(0.50))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(isActive ? 0.06 : 0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(isActive ? 0.14 : 0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Convenience helpers on FocusPreset

private extension FocusPreset {
    var durationDisplay: String {
        let minutes = durationSeconds / 60
        return "\(minutes) min"
    }

    var soundDisplayName: String {
        if let app = externalMusicApp {
            return app.displayName
        }
        if soundID.isEmpty { return "No sound" }
        if let sound = FocusSound(rawValue: soundID) {
            return sound.displayName
        }
        return soundID
    }
}
