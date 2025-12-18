import SwiftUI

// MARK: - Glass group card (Shared Aesthetic)

private struct ProfileGlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
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
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Avatar System (No Photos / No Permissions)

private enum AvatarCategory: String, CaseIterable, Identifiable {
    case focus = "Focus"
    case vibes = "Vibes"
    case productivity = "Productivity"
    case fun = "Fun"
    case nature = "Nature"

    var id: String { rawValue }
}

private struct AvatarOption: Identifiable, Equatable {
    let id: String
    let symbol: String
    let category: AvatarCategory
    let gradientA: Color
    let gradientB: Color
}

private enum AvatarLibrary {
    // 48 options (safe SF Symbols, fun, focus-ish)
    static let options: [AvatarOption] = [
        // Focus
        .init(id: "target", symbol: "target", category: .focus, gradientA: .pink.opacity(0.95), gradientB: .purple.opacity(0.90)),
        .init(id: "timer", symbol: "timer", category: .focus, gradientA: .teal.opacity(0.92), gradientB: .blue.opacity(0.90)),
        .init(id: "hourglass", symbol: "hourglass", category: .focus, gradientA: .orange.opacity(0.92), gradientB: .yellow.opacity(0.88)),
        .init(id: "brain", symbol: "brain.head.profile", category: .focus, gradientA: .cyan.opacity(0.92), gradientB: .blue.opacity(0.92)),
        .init(id: "sparkles", symbol: "sparkles", category: .focus, gradientA: .purple.opacity(0.95), gradientB: .pink.opacity(0.92)),
        .init(id: "flame", symbol: "flame.fill", category: .focus, gradientA: .orange.opacity(0.95), gradientB: .red.opacity(0.88)),
        .init(id: "bolt", symbol: "bolt.fill", category: .focus, gradientA: .blue.opacity(0.92), gradientB: .cyan.opacity(0.92)),
        .init(id: "check", symbol: "checkmark.seal.fill", category: .focus, gradientA: .green.opacity(0.92), gradientB: .mint.opacity(0.90)),
        .init(id: "trophy", symbol: "trophy.fill", category: .focus, gradientA: .yellow.opacity(0.95), gradientB: .orange.opacity(0.88)),
        .init(id: "crown", symbol: "crown.fill", category: .focus, gradientA: .yellow.opacity(0.92), gradientB: .pink.opacity(0.88)),
        .init(id: "chart", symbol: "chart.line.uptrend.xyaxis", category: .focus, gradientA: .blue.opacity(0.92), gradientB: .purple.opacity(0.88)),
        .init(id: "badge", symbol: "rosette", category: .focus, gradientA: .indigo.opacity(0.92), gradientB: .purple.opacity(0.88)),

        // Productivity
        .init(id: "pencil", symbol: "pencil.and.outline", category: .productivity, gradientA: .yellow.opacity(0.92), gradientB: .mint.opacity(0.90)),
        .init(id: "book", symbol: "book.fill", category: .productivity, gradientA: .mint.opacity(0.92), gradientB: .teal.opacity(0.90)),
        .init(id: "bookmark", symbol: "bookmark.fill", category: .productivity, gradientA: .blue.opacity(0.92), gradientB: .indigo.opacity(0.90)),
        .init(id: "folder", symbol: "folder.fill", category: .productivity, gradientA: .orange.opacity(0.92), gradientB: .yellow.opacity(0.88)),
        .init(id: "calendar", symbol: "calendar", category: .productivity, gradientA: .red.opacity(0.92), gradientB: .orange.opacity(0.88)),
        .init(id: "paperplane", symbol: "paperplane.fill", category: .productivity, gradientA: .blue.opacity(0.92), gradientB: .cyan.opacity(0.90)),
        .init(id: "lightbulb", symbol: "lightbulb.fill", category: .productivity, gradientA: .yellow.opacity(0.95), gradientB: .orange.opacity(0.88)),
        .init(id: "clipboard", symbol: "clipboard.fill", category: .productivity, gradientA: .gray.opacity(0.75), gradientB: .white.opacity(0.35)),
        .init(id: "doc", symbol: "doc.text.fill", category: .productivity, gradientA: .indigo.opacity(0.92), gradientB: .blue.opacity(0.90)),
        .init(id: "tray", symbol: "tray.full.fill", category: .productivity, gradientA: .teal.opacity(0.92), gradientB: .mint.opacity(0.90)),
        .init(id: "wand", symbol: "wand.and.stars", category: .productivity, gradientA: .purple.opacity(0.92), gradientB: .indigo.opacity(0.90)),
        .init(id: "gear", symbol: "gearshape.fill", category: .productivity, gradientA: .gray.opacity(0.80), gradientB: .blue.opacity(0.45)),

        // Vibes
        .init(id: "moon", symbol: "moon.stars.fill", category: .vibes, gradientA: .indigo.opacity(0.95), gradientB: .purple.opacity(0.88)),
        .init(id: "sun", symbol: "sun.max.fill", category: .vibes, gradientA: .yellow.opacity(0.95), gradientB: .orange.opacity(0.90)),
        .init(id: "cloud", symbol: "cloud.fill", category: .vibes, gradientA: .cyan.opacity(0.92), gradientB: .blue.opacity(0.88)),
        .init(id: "headphones", symbol: "headphones", category: .vibes, gradientA: .blue.opacity(0.92), gradientB: .purple.opacity(0.90)),
        .init(id: "music", symbol: "music.note", category: .vibes, gradientA: .pink.opacity(0.92), gradientB: .purple.opacity(0.90)),
        .init(id: "coffee", symbol: "cup.and.saucer.fill", category: .vibes, gradientA: .orange.opacity(0.88), gradientB: .brown.opacity(0.88)),
        .init(id: "drop", symbol: "drop.fill", category: .vibes, gradientA: .cyan.opacity(0.92), gradientB: .mint.opacity(0.88)),
        .init(id: "wind", symbol: "wind", category: .vibes, gradientA: .white.opacity(0.55), gradientB: .blue.opacity(0.55)),
        .init(id: "bell", symbol: "bell.fill", category: .vibes, gradientA: .yellow.opacity(0.92), gradientB: .orange.opacity(0.88)),
        .init(id: "bubble", symbol: "bubble.left.and.bubble.right.fill", category: .vibes, gradientA: .blue.opacity(0.92), gradientB: .cyan.opacity(0.88)),

        // Fun
        .init(id: "party", symbol: "party.popper.fill", category: .fun, gradientA: .pink.opacity(0.95), gradientB: .yellow.opacity(0.90)),
        .init(id: "game", symbol: "gamecontroller.fill", category: .fun, gradientA: .indigo.opacity(0.95), gradientB: .purple.opacity(0.88)),
        .init(id: "star", symbol: "star.fill", category: .fun, gradientA: .yellow.opacity(0.95), gradientB: .orange.opacity(0.88)),
        .init(id: "heart", symbol: "heart.fill", category: .fun, gradientA: .pink.opacity(0.95), gradientB: .red.opacity(0.88)),
        .init(id: "rocket", symbol: "rocket.fill", category: .fun, gradientA: .blue.opacity(0.92), gradientB: .purple.opacity(0.90)),
        .init(id: "theater", symbol: "theatermasks.fill", category: .fun, gradientA: .purple.opacity(0.92), gradientB: .pink.opacity(0.88)),
        .init(id: "wand2", symbol: "sparkle", category: .fun, gradientA: .mint.opacity(0.92), gradientB: .cyan.opacity(0.90)),
        .init(id: "gift", symbol: "gift.fill", category: .fun, gradientA: .red.opacity(0.92), gradientB: .pink.opacity(0.88)),
        .init(id: "balloon", symbol: "balloon.2.fill", category: .fun, gradientA: .purple.opacity(0.92), gradientB: .blue.opacity(0.88)),
        .init(id: "dice", symbol: "die.face.5.fill", category: .fun, gradientA: .white.opacity(0.55), gradientB: .gray.opacity(0.55)),

        // Nature
        .init(id: "leaf", symbol: "leaf.fill", category: .nature, gradientA: .green.opacity(0.92), gradientB: .mint.opacity(0.90)),
        .init(id: "paw", symbol: "pawprint.fill", category: .nature, gradientA: .mint.opacity(0.92), gradientB: .green.opacity(0.90)),
        .init(id: "tree", symbol: "tree.fill", category: .nature, gradientA: .green.opacity(0.92), gradientB: .teal.opacity(0.88)),
        .init(id: "mountain", symbol: "mountain.2.fill", category: .nature, gradientA: .blue.opacity(0.85), gradientB: .indigo.opacity(0.85)),
        .init(id: "globe", symbol: "globe.americas.fill", category: .nature, gradientA: .blue.opacity(0.92), gradientB: .green.opacity(0.88)),
        .init(id: "fish", symbol: "fish.fill", category: .nature, gradientA: .cyan.opacity(0.92), gradientB: .blue.opacity(0.88))
    ]

    static func option(for id: String) -> AvatarOption {
        options.first(where: { $0.id == id }) ?? options[0]
    }

    static func options(in category: AvatarCategory?) -> [AvatarOption] {
        guard let category else { return options }
        return options.filter { $0.category == category }
    }
}

private struct AvatarCircleView: View {
    let option: AvatarOption
    let size: CGFloat
    let isSelected: Bool

    private var gradient: LinearGradient {
        LinearGradient(colors: [option.gradientA, option.gradientB], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(gradient)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )

            Image(systemName: option.symbol)
                .font(.system(size: size * 0.40, weight: .bold))
                .foregroundColor(.white.opacity(0.95))
                .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 6)
        }
        .overlay(
            Circle()
                .stroke(Color.white.opacity(isSelected ? 0.95 : 0.0), lineWidth: isSelected ? 2.5 : 0)
        )
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isSelected)
    }
}

// MARK: - Avatar Picker Sheet (Search + Categories)

private struct AvatarPickerSheet: View {
    @Binding var avatarID: String
    let theme: AppTheme

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: AvatarCategory? = nil
    @State private var searchText: String = ""

    private var filtered: [AvatarOption] {
        let base = AvatarLibrary.options(in: selectedCategory)
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return base }
        let q = searchText.lowercased()
        return base.filter { $0.id.lowercased().contains(q) || $0.symbol.lowercased().contains(q) || $0.category.rawValue.lowercased().contains(q) }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: theme.backgroundColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("Choose Avatar")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)

                // Search
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.55))
                    TextField("Search avatars…", text: $searchText)
                        .foregroundColor(.white)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        Button {
                            Haptics.impact(.light)
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.55))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 20)

                // Categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        categoryChip(title: "All", isSelected: selectedCategory == nil) {
                            Haptics.impact(.light)
                            selectedCategory = nil
                        }
                        ForEach(AvatarCategory.allCases) { cat in
                            categoryChip(title: cat.rawValue, isSelected: selectedCategory == cat) {
                                Haptics.impact(.light)
                                selectedCategory = cat
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                }

                // Grid
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(filtered) { option in
                            Button {
                                Haptics.impact(.light)
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.80)) {
                                    avatarID = option.id
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                    dismiss()
                                }
                            } label: {
                                AvatarCircleView(
                                    option: option,
                                    size: 52,
                                    isSelected: avatarID == option.id
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func categoryChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(isSelected ? 0.95 : 0.70))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? Color.white.opacity(0.16) : Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MAIN PROFILE VIEW

struct ProfileView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var stats = StatsManager.shared
    @ObservedObject private var authManager = AuthManager.shared

    @State private var showingEditProfile = false
    @State private var showingSettings = false

    // Help Sheets
    @State private var showingAchievementsHelp = false
    @State private var showingLevelHelp = false

    @State private var iconPulse = false
    private let calendar = Calendar.current

    // MARK: - Computed Stats
    private var lifetimeFocusReadable: String { stats.lifetimeFocusSeconds.asReadableDuration }
    private var lifetimeSessionCount: Int { stats.lifetimeSessionCount }
    private var lifetimeBestStreak: Int { stats.lifetimeBestStreak }

    // MARK: - Level Logic
    private var currentLevel: Int {
        let hours = Int(stats.lifetimeFocusSeconds / 3600)
        return max(1, (hours / 5) + 1)
    }

    private var levelProgress: Double {
        let totalHours = Double(stats.lifetimeFocusSeconds) / 3600.0
        let currentLevelBase = Double(currentLevel - 1) * 5.0
        let progressHours = totalHours - currentLevelBase
        return min(max(progressHours / 5.0, 0.0), 1.0)
    }

    private var currentRankTitle: String {
        switch currentLevel {
        case 1...5: return "Novice"
        case 6...10: return "Apprentice"
        case 11...20: return "Pro"
        case 21...50: return "Expert"
        default: return "Master"
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let theme = settings.selectedTheme
            let accentPrimary = theme.accentPrimary
            let accentSecondary = theme.accentSecondary

            ZStack {
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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        profileHeader
                            .padding(.horizontal, 22)
                            .padding(.top, 18)

                        levelCard
                            .padding(.horizontal, 22)

                        achievementsSection
                            .padding(.horizontal, 22)

                        heroStatsGrid
                            .padding(.horizontal, 22)

                        recentActivityCard
                            .padding(.horizontal, 22)

                        footerSection
                            .padding(.top, 10)
                            .padding(.bottom, 120)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileSheet(
                name: $settings.displayName,
                tagline: $settings.tagline,
                avatarID: $settings.avatarID
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingAchievementsHelp) {
            AchievementLegendSheet(achievements: achievements)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingLevelHelp) {
            LevelLegendSheet(currentLevel: currentLevel)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            iconPulse = true
            loadCloudProfileIfNeeded()
        }
        .onChange(of: settings.displayName) { _, newValue in
            syncDisplayNameToCloud(newName: newValue)
        }
    }

    // MARK: - Header
    private var profileHeader: some View {
        HStack(spacing: 16) {
            profileAvatarView

            VStack(alignment: .leading, spacing: 4) {
                let name = settings.displayName.trimmingCharacters(in: .whitespaces)
                Text(name.isEmpty ? "Your Name" : name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                if !settings.tagline.isEmpty {
                    Text(settings.tagline)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                } else {
                    Text("Focus Enthusiast")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }

                Button {
                    Haptics.impact(.light)
                    showingEditProfile = true
                } label: {
                    Text("Edit Profile")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(settings.selectedTheme.accentColor)
                        .padding(.top, 2)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                Haptics.impact(.light)
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var profileAvatarView: some View {
        let size: CGFloat = 70
        let option = AvatarLibrary.option(for: settings.avatarID)
        return AvatarCircleView(option: option, size: size, isSelected: false)
            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Level Card
    private var levelCard: some View {
        ProfileGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Text("Level \(currentLevel)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Button {
                            Haptics.impact(.light)
                            showingLevelHelp = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    Image(systemName: "trophy.fill")
                        .foregroundColor(Color.yellow.opacity(0.9))
                        .font(.system(size: 28))
                        .shadow(color: .yellow.opacity(0.5), radius: 8)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [settings.selectedTheme.accentPrimary, settings.selectedTheme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(levelProgress), height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text(currentRankTitle)
                        .font(.caption.weight(.bold))
                        .foregroundColor(settings.selectedTheme.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(settings.selectedTheme.accentColor.opacity(0.15))
                        .clipShape(Capsule())

                    Spacer()

                    let percentLeft = Int((1.0 - levelProgress) * 100)
                    Text("\(percentLeft)% to Level \(currentLevel + 1)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }

    // MARK: - Achievements
    private var achievements: [AchievementItem] {
        let totalHours = stats.lifetimeFocusSeconds / 3600

        return [
            AchievementItem(icon: "sparkles", title: "First Step", desc: "Complete your first session.", isUnlocked: stats.lifetimeSessionCount >= 1),
            AchievementItem(icon: "flame.fill", title: "On Fire", desc: "Reach a 3-day streak.", isUnlocked: stats.lifetimeBestStreak >= 3),
            AchievementItem(icon: "bolt.fill", title: "Unstoppable", desc: "Reach a 7-day streak.", isUnlocked: stats.lifetimeBestStreak >= 7),
            AchievementItem(icon: "clock.fill", title: "Dedicated", desc: "Focus for 10 hours total.", isUnlocked: totalHours >= 10),
            AchievementItem(icon: "star.fill", title: "Master", desc: "Complete 100 sessions.", isUnlocked: stats.lifetimeSessionCount >= 100),
            AchievementItem(icon: "figure.run", title: "Marathon", desc: "Focus for 50 hours total.", isUnlocked: totalHours >= 50),
            AchievementItem(icon: "crown.fill", title: "Legend", desc: "Reach a 30-day streak.", isUnlocked: stats.lifetimeBestStreak >= 30),
            AchievementItem(icon: "moon.stars.fill", title: "Night Owl", desc: "Complete 50 sessions.", isUnlocked: stats.lifetimeSessionCount >= 50),
            AchievementItem(icon: "sun.max.fill", title: "Early Bird", desc: "Complete 25 sessions.", isUnlocked: stats.lifetimeSessionCount >= 25),
            AchievementItem(icon: "infinity", title: "Zen Master", desc: "Focus for 100+ hours.", isUnlocked: totalHours >= 100)
        ]
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Achievements")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                Button {
                    Haptics.impact(.light)
                    showingAchievementsHelp = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.leading, 4)
            .padding(.trailing, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(achievements) { item in
                        AchievementBadgeView(item: item, theme: settings.selectedTheme)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - Hero Stats
    private var heroStatsGrid: some View {
        HStack(spacing: 12) {
            statBox(icon: "hourglass", value: lifetimeFocusReadable, label: "Total Time")
            statBox(icon: "checkmark.circle.fill", value: "\(lifetimeSessionCount)", label: "Sessions")
            statBox(icon: "flame.fill", value: "\(lifetimeBestStreak)", label: "Top Streak")
        }
    }

    private func statBox(icon: String, value: String, label: String) -> some View {
        ProfileGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(settings.selectedTheme.accentColor)

                VStack(alignment: .leading, spacing: 0) {
                    Text(value)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(label)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }

    // MARK: - Recent Activity
    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Activity")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.9))
                .padding(.leading, 4)

            ProfileGlassCard {
                Group {
                    let recent = Array(stats.sessions.prefix(3))
                    if recent.isEmpty {
                        Text("No sessions yet. Start focusing!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(recent.enumerated()), id: \.element.id) { index, session in
                                HStack {
                                    Circle()
                                        .fill(settings.selectedTheme.accentPrimary.opacity(0.8))
                                        .frame(width: 8, height: 8)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(session.sessionName ?? "Focus")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                        Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    Spacer()
                                    Text(session.duration.asReadableDuration)
                                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .padding(.vertical, 10)
                                if index < recent.count - 1 {
                                    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Footer (Socials)
    private var footerSection: some View {
        VStack(spacing: 20) {
            HStack(spacing: 24) {
                SocialLink(icon: "camera.fill", label: "Instagram")
                SocialLink(icon: "network", label: "Facebook")
                SocialLink(icon: "briefcase.fill", label: "LinkedIn")
                SocialLink(icon: "terminal.fill", label: "GitHub")
            }
            .opacity(0.7)

            VStack(spacing: 4) {
                Text("FocusFlow")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))

                Text("Version 1.0 • Built with Focus")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Cloud Sync (✅ fixed: pass accessToken)

    private func loadCloudProfileIfNeeded() {
        guard let session = currentSession, !session.isGuest else { return }
        guard let token = session.accessToken, !token.isEmpty else { return }

        Task {
            do {
                if let profile = try await UserProfileAPI.shared.fetchProfile(for: session.userId, accessToken: token),
                   let name = profile.displayName, !name.isEmpty {
                    await MainActor.run { settings.displayName = name }
                }
            } catch {
                print("ProfileView: fetch profile failed:", error)
            }
        }
    }

    private func syncDisplayNameToCloud(newName: String) {
        guard let session = currentSession, !session.isGuest else { return }
        guard let token = session.accessToken, !token.isEmpty else { return }

        Task {
            do {
                _ = try await UserProfileAPI.shared.upsertProfile(
                    for: session.userId,
                    displayName: newName,
                    accessToken: token
                )
            } catch {
                print("ProfileView: upsert displayName failed:", error)
            }
        }
    }

    private var currentSession: UserSession? {
        if case let .authenticated(session) = authManager.state { return session }
        return nil
    }
}

// MARK: - Helper Views

struct SocialLink: View {
    let icon: String
    let label: String

    var body: some View {
        Button {
            Haptics.impact(.light)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
            }
            .foregroundColor(.white)
        }
    }
}

struct AchievementItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let desc: String
    let isUnlocked: Bool
}

struct AchievementBadgeView: View {
    let item: AchievementItem
    let theme: AppTheme

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        item.isUnlocked
                        ? LinearGradient(colors: [theme.accentPrimary, theme.accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle().stroke(Color.white.opacity(item.isUnlocked ? 0.3 : 0.1), lineWidth: 1)
                    )

                Image(systemName: item.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(item.isUnlocked ? .white : .white.opacity(0.3))
            }
            .shadow(color: item.isUnlocked ? theme.accentPrimary.opacity(0.4) : .clear, radius: 8)

            VStack(spacing: 2) {
                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(item.isUnlocked ? .white : .white.opacity(0.5))
            }
        }
        .frame(width: 80)
        .opacity(item.isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - Edit Profile Sheet (Avatar button opens picker)

private struct EditProfileSheet: View {
    @Binding var name: String
    @Binding var tagline: String
    @Binding var avatarID: String

    @Environment(\.dismiss) var dismiss
    @ObservedObject private var settings = AppSettings.shared

    @State private var showingAvatarPicker = false

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: settings.selectedTheme.backgroundColors), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Text("Edit Profile").font(.title3.bold()).foregroundColor(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.top, 16)

                // ✅ Choose Avatar Row (opens sheet)
                ProfileGlassCard {
                    HStack(spacing: 14) {
                        AvatarCircleView(option: AvatarLibrary.option(for: avatarID), size: 54, isSelected: false)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Avatar")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.95))
                            Text("Choose something fun")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.45))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Haptics.impact(.light)
                        showingAvatarPicker = true
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name").font(.caption).foregroundColor(.white.opacity(0.7))
                    TextField("Your Name", text: $name)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tagline").font(.caption).foregroundColor(.white.opacity(0.7))
                    TextField("How do you like to focus?", text: $tagline)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }

                Spacer()

                Button {
                    Haptics.impact(.medium)
                    dismiss()
                } label: {
                    Text("Save Changes")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $showingAvatarPicker) {
            AvatarPickerSheet(avatarID: $avatarID, theme: settings.selectedTheme)
        }
    }
}

// MARK: - Level Legend Sheet

struct LevelLegendSheet: View {
    let currentLevel: Int
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: settings.selectedTheme.backgroundColors), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("Level Guide").font(.title3.bold()).foregroundColor(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)

                ScrollView {
                    VStack(spacing: 16) {
                        Text("You gain 1 Level for every 5 hours of total focus time.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 10)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Current Rank")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Text(rankTitle(for: currentLevel))
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.yellow)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                        .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ranks").font(.headline).foregroundColor(.white)
                            levelRow(range: "Level 1-5", title: "Novice")
                            levelRow(range: "Level 6-10", title: "Apprentice")
                            levelRow(range: "Level 11-20", title: "Pro")
                            levelRow(range: "Level 21-50", title: "Expert")
                            levelRow(range: "Level 50+", title: "Master")
                        }
                        .padding(24)
                    }
                }
            }
        }
    }

    private func rankTitle(for level: Int) -> String {
        switch level {
        case 1...5: return "Novice"
        case 6...10: return "Apprentice"
        case 11...20: return "Pro"
        case 21...50: return "Expert"
        default: return "Master"
        }
    }

    private func levelRow(range: String, title: String) -> some View {
        HStack {
            Text(range).font(.subheadline).foregroundColor(.white.opacity(0.7)).frame(width: 100, alignment: .leading)
            Text(title).font(.subheadline.weight(.semibold)).foregroundColor(.white)
            Spacer()
        }
        .padding(.vertical, 4)
        .overlay(Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1).padding(.top, 24), alignment: .bottom)
    }
}

// MARK: - Achievement Legend Sheet

struct AchievementLegendSheet: View {
    let achievements: [AchievementItem]
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: settings.selectedTheme.backgroundColors), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("Achievements Legend")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(achievements) { item in
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: item.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(item.isUnlocked ? .white : .white.opacity(0.3))
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.headline)
                                        .foregroundColor(item.isUnlocked ? .white : .white.opacity(0.5))

                                    Text(item.desc)
                                        .font(.subheadline)
                                        .foregroundColor(item.isUnlocked ? .white.opacity(0.8) : .white.opacity(0.4))
                                }

                                Spacer()

                                if item.isUnlocked {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.white.opacity(0.3))
                                        .font(.caption)
                                }
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(16)
                        }
                    }
                    .padding(24)
                }
            }
        }
    }
}

// MARK: - SETTINGS VIEW (Same as your existing file)

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var stats = StatsManager.shared
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showingResetSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: settings.selectedTheme.backgroundColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        preferencesGroup
                        accountGroup
                        dataAboutGroup
                        Text("Version 1.0").font(.caption).foregroundColor(.white.opacity(0.4)).padding(.top, 20)
                    }.padding(20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Haptics.impact(.light); dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 22))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showingResetSheet) {
            ResetStatsSheet(isPresented: $showingResetSheet) { stats.clearAll() }
        }
    }

    private var preferencesGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PREFERENCES").font(.caption.weight(.bold)).foregroundColor(.white.opacity(0.6)).padding(.leading, 8)
            ProfileGlassCard {
                VStack(spacing: 0) {
                    settingsRow(icon: "paintpalette.fill", color: settings.selectedTheme.accentPrimary, title: "Appearance") { themeChips }
                    divider
                    toggleRow(icon: "speaker.wave.2.fill", color: .blue, title: "Timer Sounds", binding: $settings.soundEnabled)
                    divider
                    toggleRow(icon: "iphone.radiowaves.left.and.right", color: .green, title: "Haptics", binding: $settings.hapticsEnabled)
                    divider
                    settingsRow(icon: "target", color: .orange, title: "Daily Goal") {
                        HStack(spacing: 12) {
                            Button("-") { Haptics.impact(.light); stats.dailyGoalMinutes = max(15, stats.dailyGoalMinutes - 5) }
                            Text("\(stats.dailyGoalMinutes)m").font(.subheadline.monospacedDigit()).foregroundColor(.white).frame(minWidth: 40)
                            Button("+") { Haptics.impact(.light); stats.dailyGoalMinutes = min(240, stats.dailyGoalMinutes + 5) }
                        }
                        .foregroundColor(.white).font(.system(size: 16, weight: .bold))
                    }
                }
            }
        }
    }

    private var accountGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACCOUNT").font(.caption.weight(.bold)).foregroundColor(.white.opacity(0.6)).padding(.leading, 8)
            ProfileGlassCard {
                VStack(spacing: 0) {
                    if case let .authenticated(session) = authManager.state, !session.isGuest {
                        settingsRow(icon: "person.fill", color: .blue, title: session.email ?? "User") { Text("Signed In").font(.caption).foregroundColor(.green) }
                        divider
                        Button { Haptics.impact(.medium); authManager.signOut() } label: {
                            settingsRow(icon: "rectangle.portrait.and.arrow.right", color: .red, title: "Sign Out") {
                                Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.5))
                            }
                        }
                    } else {
                        Button { Haptics.impact(.light); authManager.signOut() } label: {
                            settingsRow(icon: "person.crop.circle.badge.plus", color: settings.selectedTheme.accentColor, title: "Sign In / Sign Up") {
                                Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                }
            }
        }
    }

    private var dataAboutGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DATA").font(.caption.weight(.bold)).foregroundColor(.white.opacity(0.6)).padding(.leading, 8)
            ProfileGlassCard {
                Button { Haptics.impact(.medium); showingResetSheet = true } label: {
                    HStack {
                        Image(systemName: "trash.fill").foregroundColor(.red).frame(width: 24)
                        Text("Reset All Data").foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private var themeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AppTheme.allCases) { theme in
                    let isSelected = settings.selectedTheme == theme
                    ZStack {
                        Circle().fill(theme.accentColor).frame(width: 24, height: 24)
                        if isSelected { Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.white) }
                    }
                    .overlay(Circle().stroke(Color.white.opacity(isSelected ? 0.8 : 0.0), lineWidth: 2))
                    .onTapGesture {
                        Haptics.impact(.light)
                        withAnimation {
                            settings.profileTheme = theme
                            settings.selectedTheme = theme
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func settingsRow<Content: View>(icon: String, color: Color, title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 30, height: 30)
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(color)
            }
            Text(title).foregroundColor(.white.opacity(0.9)).font(.system(size: 16))
            Spacer()
            content()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private func toggleRow(icon: String, color: Color, title: String, binding: Binding<Bool>) -> some View {
        settingsRow(icon: icon, color: color, title: title) {
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(settings.selectedTheme.accentColor)
        }
    }

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1).padding(.leading, 42)
    }
}

// MARK: - Reset Sheet (Same as before)
private struct ResetStatsSheet: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    @State private var text = ""
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: settings.selectedTheme.backgroundColors), startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 20) {
                Capsule().fill(Color.white.opacity(0.2)).frame(width: 40, height: 4).padding(.top, 10)
                Text("Reset All Data?").font(.title2.bold()).foregroundColor(.white)
                Text("Type 'reset' to confirm.").font(.subheadline).foregroundColor(.white.opacity(0.7))
                TextField("reset", text: $text)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .autocorrectionDisabled()

                Button {
                    Haptics.impact(.heavy)
                    onConfirm()
                    isPresented = false
                } label: {
                    Text("Confirm Reset")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(text.lowercased() == "reset" ? 1.0 : 0.3))
                        .cornerRadius(16)
                }
                .disabled(text.lowercased() != "reset")

                Spacer()
            }
            .padding(24)
        }
        .presentationDetents([.fraction(0.45)])
    }
}

#Preview {
    ProfileView()
}
