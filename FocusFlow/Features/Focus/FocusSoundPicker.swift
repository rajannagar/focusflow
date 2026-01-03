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
        case .spotify:      return .green
        case .appleMusic:   return .red
        case .youtubeMusic: return Color(red: 0.90, green: 0.16, blue: 0.22)
        }
    }
}

// ============================================================
// MARK: - MAIN SHEET (PremiumAppBackground, full-page, no bottom padding)
// ============================================================

struct FocusSoundPicker: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var pro: ProEntitlementManager

    @State private var showingPaywall = false

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
    @State private var paywallContext: PaywallContext = .externalMusic

    var body: some View {
        let theme = appSettings.profileTheme
        let accentPrimary = theme.accentPrimary
        let accentSecondary = theme.accentSecondary

        ZStack {
            // ✅ Same Premium background as Profile/Progress/FocusView (with particles)
            PremiumAppBackground(theme: theme, showParticles: true, particleCount: 16)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                header(accentPrimary: accentPrimary, accentSecondary: accentSecondary)
                    .padding(.horizontal, 18)
                    .padding(.top, 8) // Reduced padding, safe area will add more

                // Show tab selector for all users (external music tab will show paywall for free users)
                tabSelector(accentPrimary: accentPrimary, accentSecondary: accentSecondary)
                    .padding(.horizontal, 18)

                Group {
                    switch selectedTab {
                    case .builtin:
                        BuiltInSoundsTab(
                            accentPrimary: accentPrimary,
                            accentSecondary: accentSecondary,
                            onShowPaywall: { 
                                paywallContext = .sound
                                showingPaywall = true 
                            }
                        )
                    case .externalMusic:
                        if pro.isPro {
                            ExternalMusicTab(
                                accentPrimary: accentPrimary,
                                accentSecondary: accentSecondary,
                                onShowPaywall: {
                                    paywallContext = .externalMusic
                                    showingPaywall = true
                                }
                            )
                            .environmentObject(pro)
                        } else {
                            // Show paywall teaser for free users
                            ExternalMusicPaywallTeaser(
                                accentPrimary: accentPrimary,
                                accentSecondary: accentSecondary,
                                onShowPaywall: {
                                    paywallContext = .externalMusic
                                    showingPaywall = true
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 2)

                // ✅ No bottom spacer/padding — allow content to go all the way down
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        // ✅ Full-page sheet
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        // ✅ Let Premium background show through
        .presentationBackground(.clear)
        .presentationCornerRadius(32)
        .onAppear {
            // Clear external music app selection for free users
            if !pro.isPro {
                if appSettings.selectedExternalMusicApp != nil {
                    appSettings.selectedExternalMusicApp = nil
                }
            }
        }
        .onChange(of: pro.isPro) { _, _ in
            print("[FocusSoundPicker] 🔄 Pro status changed: \(pro.isPro)")
            // Clear external music app selection if Pro status changes to false
            if !pro.isPro {
                if appSettings.selectedExternalMusicApp != nil {
                    appSettings.selectedExternalMusicApp = nil
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(context: paywallContext).environmentObject(pro)
        }
    }

    // MARK: - Header

    private func header(accentPrimary: Color, accentSecondary: Color) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .imageScale(.medium)
                        .foregroundColor(.white.opacity(0.9))

                    Text("Focus sound")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Pick how your focus should feel.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.62))
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
        }
    }

    // MARK: - Tab selector (premium pills)

    private func tabSelector(accentPrimary: Color, accentSecondary: Color) -> some View {
        HStack(spacing: 8) {
            // Show all tabs (externalMusic will show paywall for free users)
            ForEach(Tab.allCases) { tab in
                let isSelected = (tab == selectedTab)

                Button {
                    Haptics.impact(.light)
                    // Allow tab selection - free users will see paywall teaser content
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.iconName)
                            .imageScale(.small)

                        Text(tab.title)
                            .font(.system(size: 13, weight: .semibold))
                        
                        // Show crown icon for external music tab if not Pro
                        if tab == .externalMusic && !pro.isPro {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .foregroundColor(isSelected ? .black : .white.opacity(tab == .externalMusic && !pro.isPro ? 0.60 : 0.80))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(
                        Group {
                            if isSelected {
                                LinearGradient(
                                    colors: [accentPrimary, accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                Color.white.opacity(tab == .externalMusic && !pro.isPro ? 0.02 : 0.04)
                            }
                        }
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(isSelected ? 0.0 : 0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }
}

// ============================================================
// MARK: - BUILT-IN SOUND TAB (scrolls to bottom, no bottom padding)
// ============================================================

private struct BuiltInSoundsTab: View {
    @ObservedObject private var appSettings = AppSettings.shared

    let accentPrimary: Color
    let accentSecondary: Color
    let onShowPaywall: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Current selection (subtle)
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))

                    Image(systemName: appSettings.selectedFocusSound == nil ? "speaker.slash" : "waveform")
                        .imageScale(.small)
                        .foregroundColor(.white.opacity(0.9))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Session ambience")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))

                    Text(currentSelectionLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    noSoundRow()

                    ForEach(FocusSound.allCases) { sound in
                        soundRow(sound)
                    }

                    Text("Tip: tap a sound to preview. Your timer will use whichever sound you last chose.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                        .padding(.top, 10)
                }
                .padding(.top, 4)
                .padding(.bottom, 20) // Add bottom padding to prevent content cut-off by home indicator
            }
            // ✅ Extend scroll content all the way down (no safe-area padding)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private var currentSelectionLabel: String {
        if let sound = appSettings.selectedFocusSound { return sound.displayName }
        return "Silence"
    }

    private func soundRow(_ sound: FocusSound) -> some View {
        let isSelected = appSettings.selectedFocusSound == sound
        let isLocked = ProGatingHelper.shared.isSoundLocked(sound)

        return Button {
            Haptics.impact(.light)
            
            if isLocked {
                onShowPaywall()
            } else {
                // Built-in sound selected → clear external app
                appSettings.selectedFocusSound = sound
                appSettings.selectedExternalMusicApp = nil

                FocusSoundManager.shared.stop()
                FocusSoundManager.shared.play(sound: sound)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 42, height: 42)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )

                    Image(systemName: "waveform")
                        .foregroundColor(isSelected ? .black.opacity(0.85) : .white.opacity(0.9))
                    
                    // Premium lock overlay
                    if isLocked {
                        ZStack {
                            // Gradient overlay
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.black.opacity(0.7),
                                            Color.black.opacity(0.5)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 42, height: 42)
                            
                            // PRO badge
                            VStack(spacing: 1) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text("PRO")
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundColor(.white)
                                    .tracking(0.5)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(sound.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isSelected ? .black : .white)
                        
                        if isLocked {
                            HStack(spacing: 3) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Text("PRO")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .tracking(0.5)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                    }

                    Text(isLocked ? "Unlock with Pro" : "Loops quietly while your timer runs.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isSelected ? .black.opacity(0.60) : .white.opacity(0.58))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(.white)
                        .shadow(color: accentPrimary.opacity(0.45), radius: 10, x: 0, y: 6)
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
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [accentPrimary, accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.white.opacity(isLocked ? 0.02 : 0.04)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(isSelected ? 0.0 : 0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func noSoundRow() -> some View {
        let isSelected = appSettings.selectedFocusSound == nil

        return Button {
            Haptics.impact(.light)
            appSettings.selectedFocusSound = nil
            FocusSoundManager.shared.stop()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.red.opacity(0.16))
                        .frame(width: 42, height: 42)

                    Image(systemName: "speaker.slash.fill")
                        .foregroundColor(.red.opacity(0.92))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("No sound")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Total silence for this session.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red.opacity(0.82))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(.white)
                        .shadow(color: .red.opacity(0.45), radius: 10, x: 0, y: 6)
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
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// ============================================================
// MARK: - EXTERNAL MUSIC TAB (scrolls to bottom, no bottom padding)
// ============================================================

private struct ExternalMusicTab: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @EnvironmentObject private var pro: ProEntitlementManager
    let accentPrimary: Color
    let accentSecondary: Color
    let onShowPaywall: () -> Void

    private var selectionLabel: String {
        if let app = appSettings.selectedExternalMusicApp { return app.displayName }
        return "No music app selected"
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))

                    Image(systemName: "headphones")
                        .imageScale(.small)
                        .foregroundColor(.white.opacity(0.9))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Music app for this session")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))

                    Text(selectionLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Use any music app")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Choose a music app below. When you start a FocusFlow timer, we’ll open that app so you can pick a playlist. We don’t control the music – we just keep time.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 10) {
                        musicAppCard(app: .spotify, subtitle: "Lo-fi, deep focus, or your own playlists.", onShowPaywall: onShowPaywall)
                        musicAppCard(app: .appleMusic, subtitle: "Use your library or Apple Music radio.", onShowPaywall: onShowPaywall)
                        musicAppCard(app: .youtubeMusic, subtitle: "Focus playlists mixed with your favorites.", onShowPaywall: onShowPaywall)
                    }
                    .padding(.top, 6)

                    Text("Tip: after you start your timer and we open your music app, just swipe back to FocusFlow. Your session will keep running.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                }
                .padding(.vertical, 8)
                .padding(.bottom, 20) // Add bottom padding to prevent content cut-off by home indicator
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func musicAppCard(app: AppSettings.ExternalMusicApp, subtitle: String, onShowPaywall: @escaping () -> Void) -> some View {
        let isSelected = appSettings.selectedExternalMusicApp == app

        return Button {
            Haptics.impact(.medium)
            // Gate external music apps for Pro users only
            guard pro.isPro else {
                // This shouldn't happen since the tab is hidden, but safety check
                onShowPaywall()
                return
            }
            
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                if isSelected {
                    appSettings.selectedExternalMusicApp = nil
                } else {
                    appSettings.selectedExternalMusicApp = app
                    appSettings.selectedFocusSound = nil
                    FocusSoundManager.shared.stop()
                }
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(app.tintColor.opacity(0.16))
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
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
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
                    .background(
                        LinearGradient(
                            colors: [accentPrimary, accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                } else {
                    Text("Use this app")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.82))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.04))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// ============================================================
// MARK: - EXTERNAL MUSIC PAYWALL TEASER (for free users)
// ============================================================

private struct ExternalMusicPaywallTeaser: View {
    let accentPrimary: Color
    let accentSecondary: Color
    let onShowPaywall: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)
                
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentPrimary.opacity(0.2), accentSecondary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentPrimary, accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Text("Connect Your Music")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    Text("Use Spotify, Apple Music, or YouTube Music with your focus sessions")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                
                VStack(spacing: 16) {
                    musicAppTeaserCard(
                        icon: "music.quarternote.3",
                        name: "Spotify",
                        color: .green
                    )
                    
                    musicAppTeaserCard(
                        icon: "applelogo",
                        name: "Apple Music",
                        color: .red
                    )
                    
                    musicAppTeaserCard(
                        icon: "play.rectangle.fill",
                        name: "YouTube Music",
                        color: Color(red: 0.90, green: 0.16, blue: 0.22)
                    )
                }
                .padding(.top, 8)
                
                Button {
                    Haptics.impact(.medium)
                    onShowPaywall()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Upgrade to Pro")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [accentPrimary, accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.top, 8)
                
                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, 4)
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func musicAppTeaserCard(icon: String, name: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(color.opacity(0.16))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .imageScale(.medium)
            }
            .opacity(0.5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(14)
        .background(Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
    }
}

#Preview {
    FocusSoundPicker()
}
