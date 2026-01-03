import SwiftUI
import StoreKit

// MARK: - Paywall Context

/// Context for showing the paywall from different features
enum PaywallContext: String, Identifiable, CaseIterable {
    case general
    case sound
    case theme
    case ambiance
    case preset
    case task
    case reminder
    case history
    case xpLevels
    case journey
    case widget
    case liveActivity
    case externalMusic
    case cloudSync
    
    var id: String { rawValue }
    
    var headline: String {
        switch self {
        case .general: return "Unlock Everything"
        case .sound: return "Unlock All 11 Sounds"
        case .theme: return "Unlock All 10 Themes"
        case .ambiance: return "Unlock All 14 Backgrounds"
        case .preset: return "Create Unlimited Presets"
        case .task: return "Unlimited Tasks"
        case .reminder: return "Unlimited Reminders"
        case .history: return "Your Complete History"
        case .xpLevels: return "Track Your Progress"
        case .journey: return "Your Focus Journey"
        case .widget: return "Widgets & Live Activity"
        case .liveActivity: return "Focus from Dynamic Island"
        case .externalMusic: return "Connect Your Music"
        case .cloudSync: return "Sync Everywhere"
        }
    }
    
    var subheadline: String {
        switch self {
        case .general: return "Get the full FocusFlow experience"
        case .sound: return "Every sound for every mood"
        case .theme: return "Beautiful colors for your focus"
        case .ambiance: return "Immersive backgrounds for deep work"
        case .preset: return "Save your perfect focus setup"
        case .task: return "Never hit a limit again"
        case .reminder: return "Stay on track with unlimited reminders"
        case .history: return "See your focus journey over time"
        case .xpLevels: return "Level up with 50 levels & achievements"
        case .journey: return "Daily summaries & weekly reviews"
        case .widget: return "Control focus from your home screen"
        case .liveActivity: return "Quick access from Dynamic Island"
        case .externalMusic: return "Spotify & Apple Music integration"
        case .cloudSync: return "Access your data on all devices"
        }
    }
    
    var heroIcon: String {
        switch self {
        case .general: return "crown.fill"
        case .sound: return "waveform.circle.fill"
        case .theme: return "paintpalette.fill"
        case .ambiance: return "sparkles"
        case .preset: return "slider.horizontal.3"
        case .task: return "checklist"
        case .reminder: return "bell.fill"
        case .history: return "calendar"
        case .xpLevels: return "trophy.fill"
        case .journey: return "book.pages.fill"
        case .widget: return "square.grid.2x2.fill"
        case .liveActivity: return "iphone.badge.play"
        case .externalMusic: return "music.note"
        case .cloudSync: return "icloud.fill"
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let showPaywall = Notification.Name("FocusFlow.showPaywall")
}

// MARK: - PaywallView

struct PaywallView: View {
    var context: PaywallContext = .general
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var pro: ProEntitlementManager
    @ObservedObject private var appSettings = AppSettings.shared

    @State private var selectedID: String = ProEntitlementManager.yearlyID
    @State private var isBusy = false
    @State private var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @State private var appearAnimation = false
    @State private var wavePhase: CGFloat = 0
    
    enum SubscriptionStatus {
        case notSubscribed
        case active
        case cancelled
        case expired
    }

    private var theme: AppTheme { appSettings.profileTheme }

    private var monthlyProduct: Product? {
        pro.products.first(where: { $0.id == ProEntitlementManager.monthlyID })
    }

    private var yearlyProduct: Product? {
        pro.products.first(where: { $0.id == ProEntitlementManager.yearlyID })
    }

    private var selectedProduct: Product? {
        pro.products.first(where: { $0.id == selectedID })
    }

    private var isYearlySelected: Bool { selectedID == ProEntitlementManager.yearlyID }
    
    private var yearlyMonthlyEquivalent: String {
        guard let yearly = yearlyProduct else { return "" }
        let monthlyPrice = yearly.price / 12
        return yearly.priceFormatStyle.format(monthlyPrice)
    }

    var body: some View {
        ZStack {
            // Background
            PremiumAppBackground(theme: theme)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Close button
                    closeButton
                        .padding(.top, 8)
                    
                    // Hero Section - Contextual Visual
                    heroSection
                        .padding(.top, 20)
                    
                    // Benefits Checklist
                    benefitsChecklist
                        .padding(.top, 32)
                    
                    // Plan Selector
                    planSelector
                        .padding(.top, 28)
                    
                    // CTA Button
                    ctaSection
                        .padding(.top, 24)
                    
                    // Footer
                    footer
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appearAnimation = true
            }
        }
        .task {
            if pro.products.isEmpty { await pro.loadProducts() }
            await pro.refreshEntitlement()
            await checkSubscriptionStatus()
        }
    }
    
    private func checkSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == ProEntitlementManager.monthlyID ||
                   transaction.productID == ProEntitlementManager.yearlyID {
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            subscriptionStatus = transaction.revocationDate != nil ? .cancelled : .active
                        } else {
                            subscriptionStatus = .expired
                        }
                    }
                    return
                }
            }
        }
        subscriptionStatus = .notSubscribed
    }

    // MARK: - Close Button
    
    private var closeButton: some View {
        HStack {
            Spacer()
            Button {
                Haptics.impact(.light)
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 24) {
            // Only show hero visual for specific contexts, not general
            if context != .general {
                heroVisual
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .opacity(appearAnimation ? 1 : 0)
                    .scaleEffect(appearAnimation ? 1 : 0.9)
            }
            
            // Headlines
            VStack(spacing: 12) {
                if context == .general {
                    // FocusFlow Pro branding for general
                    HStack(spacing: 8) {
                        Text("FocusFlow")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Pro")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .padding(.top, 20)
                    
                    Text(context.subheadline)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                } else {
                    // PRO Badge for specific contexts
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 11))
                        Text("PRO")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(2)
                    }
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.yellow.opacity(0.15))
                    .clipShape(Capsule())
                    
                    Text(context.headline)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(context.subheadline)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            }
            .opacity(appearAnimation ? 1 : 0)
            .offset(y: appearAnimation ? 0 : 20)
        }
    }
    
    // MARK: - Hero Visual (Changes by Context)
    
    @ViewBuilder
    private var heroVisual: some View {
        switch context {
        case .sound, .externalMusic:
            // Animated waveform
            SoundWaveVisual(theme: theme)
            
        case .theme:
            // Theme swatches
            ThemeSwatchesVisual(theme: theme)
            
        case .ambiance:
            // Gradient orbs
            AmbianceOrbsVisual(theme: theme)
            
        case .xpLevels, .journey:
            // Progress visual
            ProgressVisual(theme: theme)
            
        case .cloudSync:
            // Cloud sync visual
            CloudSyncVisual(theme: theme)
            
        case .widget, .liveActivity:
            // Widget preview
            WidgetVisual(theme: theme)
            
        default:
            // Crown visual for task, reminder, history, preset contexts
            CrownVisual(theme: theme)
        }
    }

    // MARK: - Benefits Checklist
    
    private var benefitsChecklist: some View {
        VStack(spacing: 14) {
            // Show contextual benefit first, then others
            ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                benefitRow(benefit.icon, benefit.text, delay: Double(index) * 0.05)
            }
            
            // "And more" row
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(theme.accentPrimary.opacity(0.5))
                
                Text("And so much more...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                
                Spacer()
            }
            .padding(.top, 4)
        }
    }
    
    private var benefits: [(icon: String, text: String)] {
        // Return benefits based on context, putting relevant one first
        var list: [(String, String)] = []
        
        switch context {
        case .sound:
            list.append(("waveform.circle.fill", "All 11 focus sounds"))
        case .theme:
            list.append(("paintpalette.fill", "All 10 beautiful themes"))
        case .ambiance:
            list.append(("sparkles", "All 14 immersive backgrounds"))
        case .preset:
            list.append(("slider.horizontal.3", "Unlimited custom presets"))
        case .task, .reminder:
            list.append(("checklist", "Unlimited tasks & reminders"))
        case .history:
            list.append(("calendar", "Complete focus history"))
        case .xpLevels:
            list.append(("trophy.fill", "XP system with 50 levels"))
        case .journey:
            list.append(("book.pages.fill", "Daily & weekly focus insights"))
        case .widget, .liveActivity:
            list.append(("square.grid.2x2.fill", "All widgets & Live Activity"))
        case .externalMusic:
            list.append(("music.note", "Spotify & Apple Music"))
        case .cloudSync:
            list.append(("icloud.fill", "Sync across all devices"))
        case .general:
            list.append(("sparkles", "All 14 immersive backgrounds"))
        }
        
        // Add remaining benefits (skip if already added)
        let allBenefits: [(String, String)] = [
            ("waveform.circle.fill", "All 11 focus sounds"),
            ("sparkles", "All 14 immersive backgrounds"),
            ("paintpalette.fill", "All 10 beautiful themes"),
            ("checklist", "Unlimited tasks & reminders"),
            ("trophy.fill", "XP, levels & achievements"),
            ("icloud.fill", "Cloud sync across devices"),
        ]
        
        for benefit in allBenefits {
            if !list.contains(where: { $0.0 == benefit.0 }) && list.count < 6 {
                list.append(benefit)
            }
        }
        
        return list
    }
    
    private func benefitRow(_ icon: String, _ text: String, delay: Double) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(x: appearAnimation ? 0 : -20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay + 0.2), value: appearAnimation)
    }

    // MARK: - Plan Selector
    
    private var planSelector: some View {
        VStack(spacing: 10) {
            // Yearly
            planOption(
                isSelected: isYearlySelected,
                title: "Yearly",
                price: yearlyProduct?.displayPrice ?? "...",
                period: "/year",
                detail: "Just \(yearlyMonthlyEquivalent)/month",
                badge: "BEST VALUE"
            ) {
                Haptics.impact(.light)
                selectedID = ProEntitlementManager.yearlyID
            }
            
            // Monthly
            planOption(
                isSelected: !isYearlySelected,
                title: "Monthly",
                price: monthlyProduct?.displayPrice ?? "...",
                period: "/month",
                detail: "Cancel anytime",
                badge: nil
            ) {
                Haptics.impact(.light)
                selectedID = ProEntitlementManager.monthlyID
            }
        }
    }
    
    private func planOption(
        isSelected: Bool,
        title: String,
        price: String,
        period: String,
        detail: String,
        badge: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 22, height: 22)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.yellow)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(detail)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text(period)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected
                            ? LinearGradient(colors: [theme.accentPrimary, theme.accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA Section
    
    private var ctaSection: some View {
        VStack(spacing: 12) {
            if pro.isPro {
                // Already Pro
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: subscriptionStatus == .cancelled ? "exclamationmark.circle.fill" : "checkmark.seal.fill")
                            .foregroundColor(subscriptionStatus == .cancelled ? .orange : .green)
                        Text(subscriptionStatus == .cancelled ? "Subscription Cancelled" : "You're a Pro member!")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Button {
                        Haptics.impact(.light)
                        Task { await pro.openManageSubscriptions() }
                    } label: {
                        Text(subscriptionStatus == .cancelled ? "Resubscribe" : "Manage Subscription")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            } else {
                // Purchase CTA
                Button {
                    guard let product = selectedProduct else { return }
                    isBusy = true
                    Task {
                        await pro.purchase(product)
                        isBusy = false
                        if pro.isPro { await checkSubscriptionStatus() }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isBusy {
                            ProgressView()
                                .tint(.black)
                        }
                        Text(isBusy ? "Processing..." : "Start 3-Day Free Trial")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: theme.accentPrimary.opacity(0.4), radius: 12, y: 6)
                }
                .disabled(isBusy || selectedProduct == nil)
                
                // Trust signal
                Text("Cancel anytime · Secure with App Store")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            if let msg = pro.lastErrorMessage {
                Text(msg)
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Footer
    
    private var footer: some View {
        VStack(spacing: 12) {
            Button("Restore Purchases") {
                Haptics.impact(.light)
                Task {
                    await pro.restorePurchases()
                    await checkSubscriptionStatus()
                }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.5))
            
            HStack(spacing: 16) {
                Link("Privacy", destination: URL(string: "https://rajannagar.github.io/FocusFlow/privacy.html")!)
                Text("·").foregroundColor(.white.opacity(0.2))
                Link("Terms", destination: URL(string: "https://rajannagar.github.io/FocusFlow/terms.html")!)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white.opacity(0.35))
        }
    }
}

// MARK: - Hero Visual Components

struct SoundWaveVisual: View {
    let theme: AppTheme
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<12, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 6)
                    .frame(height: animate ? CGFloat.random(in: 30...80) : CGFloat.random(in: 20...50))
                    .animation(
                        .easeInOut(duration: Double.random(in: 0.4...0.8))
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.05),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

struct ThemeSwatchesVisual: View {
    let theme: AppTheme
    @State private var animate = false
    
    private let colors: [[Color]] = [
        [.green, .mint],
        [.pink, .orange],
        [.purple, .blue],
        [.yellow, .orange],
        [.cyan, .blue],
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: colors[i],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 70)
                    .offset(y: animate ? (i % 2 == 0 ? -8 : 8) : 0)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.1),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

struct AmbianceOrbsVisual: View {
    let theme: AppTheme
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(theme.accentPrimary.opacity(0.6))
                .frame(width: 80, height: 80)
                .blur(radius: 30)
                .offset(x: animate ? -30 : -50, y: animate ? -20 : 20)
            
            Circle()
                .fill(theme.accentSecondary.opacity(0.6))
                .frame(width: 60, height: 60)
                .blur(radius: 25)
                .offset(x: animate ? 40 : 30, y: animate ? 10 : -10)
            
            Circle()
                .fill(Color.purple.opacity(0.5))
                .frame(width: 50, height: 50)
                .blur(radius: 20)
                .offset(x: animate ? 0 : 20, y: animate ? 30 : -20)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct ProgressVisual: View {
    let theme: AppTheme
    @State private var progress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Level badge
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("LEVEL 24")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())
            
            // XP Bar
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 8)
                .frame(width: 160)
                
                Text("2,450 / 3,000 XP")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1).delay(0.3)) {
                progress = 0.82
            }
        }
    }
}

struct CloudSyncVisual: View {
    let theme: AppTheme
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Devices
            HStack(spacing: 40) {
                Image(systemName: "iphone")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.8))
                
                Image(systemName: "ipad")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Cloud
            Image(systemName: "icloud.fill")
                .font(.system(size: 36))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.accentSecondary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: animate ? -45 : -40)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animate)
            
            // Sync arrows
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .rotationEffect(.degrees(animate ? 360 : 0))
                .offset(y: -45)
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: animate)
        }
        .onAppear { animate = true }
    }
}

struct WidgetVisual: View {
    let theme: AppTheme
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Small widget
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .frame(width: 70, height: 70)
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 18))
                        Text("25:00")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white.opacity(0.7))
                )
                .offset(y: animate ? -5 : 5)
            
            // Medium widget
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
                .frame(width: 150, height: 70)
                .overlay(
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Focus")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                            Text("25:00")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            )
                    }
                    .padding(.horizontal, 14)
                )
                .offset(y: animate ? 5 : -5)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct CrownVisual: View {
    let theme: AppTheme
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            // Subtle glow
            Circle()
                .fill(theme.accentPrimary.opacity(0.15))
                .frame(width: 100, height: 100)
                .blur(radius: 30)
                .scaleEffect(pulse ? 1.1 : 0.95)
            
            // Crown icon
            Image(systemName: "crown.fill")
                .font(.system(size: 50, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .yellow.opacity(0.4), radius: 15, y: 4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Previews

#Preview("General") {
    PaywallView()
        .environmentObject(ProEntitlementManager())
}

#Preview("Sound") {
    PaywallView(context: .sound)
        .environmentObject(ProEntitlementManager())
}

#Preview("Theme") {
    PaywallView(context: .theme)
        .environmentObject(ProEntitlementManager())
}

#Preview("Cloud Sync") {
    PaywallView(context: .cloudSync)
        .environmentObject(ProEntitlementManager())
}
