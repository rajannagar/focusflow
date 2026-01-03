import SwiftUI
import StoreKit
import UIKit

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
    @State private var expirationDate: Date? = nil
    @State private var willAutoRenew: Bool = true  // Track auto-renew status
    @State private var appearAnimation = false
    @State private var wavePhase: CGFloat = 0
    @State private var lastRefreshTime: Date = Date()
    @State private var refreshTrigger: Int = 0  // Force view updates
    @Environment(\.scenePhase) private var scenePhase
    
    enum SubscriptionStatus {
        case notSubscribed
        case active
        case cancelled  // Has access but won't renew
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
    
    // Calculate days remaining until expiration
    private var daysRemaining: Int? {
        guard let expDate = expirationDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expDate).day
        return max(0, days ?? 0) // Ensure non-negative
    }
    
    // Format expiration date nicely
    private var formattedExpirationDate: String? {
        guard let expDate = expirationDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: expDate)
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
                    
                    // Plan Selector (show for all states - users can choose when resubscribing)
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
            // Always refresh when view appears (e.g., after returning from Settings or reopening)
            Task {
                // Delay to ensure StoreKit has updated after returning from Settings
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await refreshSubscriptionStatus()
                lastRefreshTime = Date()
            }
            
            // Start periodic refresh when view is visible
            startPeriodicRefresh()
        }
        .onDisappear {
            // Stop periodic refresh when view disappears
            stopPeriodicRefresh()
        }
        .task {
            #if DEBUG
            print("[PaywallView] 📱 PaywallView appeared (context: \(context.rawValue))")
            print("[PaywallView] 📊 Current Pro status: \(pro.isPro)")
            #endif
            if pro.products.isEmpty {
                #if DEBUG
                print("[PaywallView] 📦 Loading products...")
                #endif
                await pro.loadProducts()
            }
            await refreshSubscriptionStatus()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Refresh when app comes back to foreground (e.g., after cancelling in Settings)
            if oldPhase == .background && newPhase == .active {
                #if DEBUG
                print("[PaywallView] 🔔 Scene phase changed: background → active")
                #endif
                Task {
                    // Use retry mechanism for more reliable updates
                    await refreshSubscriptionStatusWithRetry()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh when app enters foreground (e.g., returning from Settings)
            #if DEBUG
            print("[PaywallView] 🔔 willEnterForegroundNotification fired")
            #endif
            Task {
                let timeSinceLastRefresh = Date().timeIntervalSince(lastRefreshTime)
                if timeSinceLastRefresh > 1.0 {
                    await refreshSubscriptionStatusWithRetry()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Most reliable: refresh when app becomes active (e.g., returning from Settings)
            #if DEBUG
            print("[PaywallView] 🔔 didBecomeActiveNotification fired")
            #endif
            Task {
                // Check if we need to refresh (avoid too frequent refreshes)
                let timeSinceLastRefresh = Date().timeIntervalSince(lastRefreshTime)
                if timeSinceLastRefresh > 1.0 { // Only refresh if it's been more than 1 second
                    // Use retry mechanism for more reliable updates
                    await refreshSubscriptionStatusWithRetry()
                }
            }
        }
    }
    
    // Helper to refresh both entitlement and subscription status
    private func refreshSubscriptionStatus() async {
        #if DEBUG
        print("[PaywallView] 🔄 Refreshing entitlement...")
        #endif
        await pro.refreshEntitlement()
        await checkSubscriptionStatus()
        #if DEBUG
        print("[PaywallView] ✅ Refresh complete. Pro status: \(pro.isPro), Subscription status: \(subscriptionStatus)")
        #endif
    }
    
    // Start periodic refresh when view is visible
    private func startPeriodicRefresh() {
        // Cancel any existing timer
        stopPeriodicRefresh()
        
        // Start a periodic refresh task
        Task {
            // Wait a bit first
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            // Then refresh periodically every 5 seconds
            while !Task.isCancelled {
                let timeSinceLastRefresh = Date().timeIntervalSince(lastRefreshTime)
                if timeSinceLastRefresh > 2.0 { // Only refresh if it's been more than 2 seconds
                    #if DEBUG
                    print("[PaywallView] ⏰ Periodic refresh triggered")
                    #endif
                    await refreshSubscriptionStatus()
                }
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            }
        }
    }
    
    // Stop periodic refresh
    private func stopPeriodicRefresh() {
        // Task cancellation is handled by the Task itself
    }
    
    // Aggressive refresh with retry - useful when returning from Settings
    private func refreshSubscriptionStatusWithRetry() async {
        #if DEBUG
        print("[PaywallView] 🔄 Starting aggressive refresh with retry...")
        #endif
        
        // Reload products first to get fresh data
        await pro.loadProducts()
        
        // First refresh immediately
        await refreshSubscriptionStatus()
        
        // Retry after delays in case StoreKit hasn't updated yet
        for delay in [1_000_000_000, 2_000_000_000, 3_000_000_000] as [UInt64] { // 1s, 2s, 3s
            try? await Task.sleep(nanoseconds: delay)
            await refreshSubscriptionStatus()
            
            // If status changed to cancelled, we're done
            if subscriptionStatus == .cancelled {
                #if DEBUG
                print("[PaywallView] ✅ Detected cancelled status, stopping retry")
                #endif
                break
            }
        }
        
        lastRefreshTime = Date()
    }
    
    // FIXED: Check subscription status using Product.SubscriptionInfo
    @MainActor
    private func checkSubscriptionStatus() async {
        #if DEBUG
        print("[PaywallView] 🔍 Checking subscription status...")
        #endif
        
        // First get transaction info for expiration date
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == ProEntitlementManager.monthlyID ||
                   transaction.productID == ProEntitlementManager.yearlyID {
                    
                    // Store expiration date
                    self.expirationDate = transaction.expirationDate
                    
                        #if DEBUG
                    print("[PaywallView] 📦 Found transaction: \(transaction.productID)")
                    print("[PaywallView] 📅 Expiration: \(transaction.expirationDate?.description ?? "nil")")
                        #endif
                    
                    break
                }
            }
        }
        
        // Now check renewal status using Product.SubscriptionInfo
        // This is the correct way to detect if auto-renew is off (cancelled)
        guard let product = yearlyProduct ?? monthlyProduct else {
                            #if DEBUG
            print("[PaywallView] ❌ No products loaded, cannot check subscription status")
                            #endif
            let newStatus: SubscriptionStatus = pro.isPro ? .active : .notSubscribed
            if subscriptionStatus != newStatus {
                subscriptionStatus = newStatus
                refreshTrigger += 1
            }
            return
        }
        
        do {
            // Get subscription status for this product's subscription group
            guard let subscriptionGroupID = product.subscription?.subscriptionGroupID else {
                            #if DEBUG
                print("[PaywallView] ❌ No subscription group ID found")
                            #endif
                subscriptionStatus = pro.isPro ? .active : .notSubscribed
                return
            }
            
            let statuses = try await Product.SubscriptionInfo.status(for: subscriptionGroupID)
            
            #if DEBUG
            print("[PaywallView] 📋 Found \(statuses.count) subscription status(es)")
            #endif
            
            for status in statuses {
                // Check the renewal info
                guard case .verified(let renewalInfo) = status.renewalInfo else {
                    #if DEBUG
                    print("[PaywallView] ⚠️ Unverified renewal info")
                    #endif
                    continue
                }
                
                // Check the transaction
                guard case .verified(let transaction) = status.transaction else {
                    #if DEBUG
                    print("[PaywallView] ⚠️ Unverified transaction in status")
                    #endif
                    continue
                }
                
                // Only check our products
                guard transaction.productID == ProEntitlementManager.monthlyID ||
                      transaction.productID == ProEntitlementManager.yearlyID else {
                    continue
                }
                
                // Update expiration date from status (more reliable)
                self.expirationDate = transaction.expirationDate
                self.willAutoRenew = renewalInfo.willAutoRenew
                
                let isExpired = transaction.expirationDate.map { $0 <= Date() } ?? false
                
                #if DEBUG
                print("[PaywallView] 🔄 Will auto-renew: \(renewalInfo.willAutoRenew)")
                print("[PaywallView] 📅 Expiration: \(transaction.expirationDate?.description ?? "nil")")
                print("[PaywallView] ⏰ Is expired: \(isExpired)")
                print("[PaywallView] 📊 State: \(status.state)")
                #endif
                
                // Update status (already on main actor)
                let newStatus: SubscriptionStatus
                if isExpired {
                    newStatus = .expired
                } else if !renewalInfo.willAutoRenew {
                    // User cancelled but still has access
                    newStatus = .cancelled
                    #if DEBUG
                    print("[PaywallView] ⚠️ Subscription CANCELLED (will not auto-renew)")
                    #endif
                } else {
                    newStatus = .active
                }
                
                // Only update if status changed to force view refresh
                if subscriptionStatus != newStatus {
                    subscriptionStatus = newStatus
                    refreshTrigger += 1  // Force view update
                    #if DEBUG
                    print("[PaywallView] 🔄 Status changed, triggering view refresh")
                    #endif
                }
                
                #if DEBUG
                print("[PaywallView] ✅ Final status: \(subscriptionStatus)")
                #endif
                return
            }
            
            // No matching subscription found
            let newStatus: SubscriptionStatus = pro.isPro ? .active : .notSubscribed
            if subscriptionStatus != newStatus {
                subscriptionStatus = newStatus
                refreshTrigger += 1
            }
            
        } catch {
            #if DEBUG
            print("[PaywallView] ❌ Error checking subscription status: \(error)")
            #endif
            // Fallback based on Pro status
            let newStatus: SubscriptionStatus = pro.isPro ? .active : .notSubscribed
            if subscriptionStatus != newStatus {
                subscriptionStatus = newStatus
                refreshTrigger += 1
            }
        }
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
            SoundWaveVisual(theme: theme)
            
        case .theme:
            ThemeSwatchesVisual(theme: theme)
            
        case .ambiance:
            AmbianceOrbsVisual(theme: theme)
            
        case .xpLevels, .journey:
            ProgressVisual(theme: theme)
            
        case .cloudSync:
            CloudSyncVisual(theme: theme)
            
        case .widget, .liveActivity:
            WidgetVisual(theme: theme)
            
        default:
            CrownVisual(theme: theme)
        }
    }

    // MARK: - Benefits Checklist
    
    private var benefitsChecklist: some View {
        VStack(spacing: 14) {
            ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                benefitRow(benefit.icon, benefit.text, delay: Double(index) * 0.05)
            }
            
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
                switch subscriptionStatus {
                case .cancelled:
                    cancelledSubscriptionView
                    
                case .active:
                    activeSubscriptionView
                    
                case .expired, .notSubscribed:
                    // Edge case: has Pro access but status unclear - show active view
                    activeSubscriptionView
                }
            } else {
                purchaseCTAView
            }
            
            if let msg = pro.lastErrorMessage {
                Text(msg)
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // Cancelled subscription view
    private var cancelledSubscriptionView: some View {
        VStack(spacing: 16) {
            // Warning card
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                    
                    Text("Subscription Ending")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                // Expiration info
                VStack(spacing: 6) {
                    if let days = daysRemaining, let dateStr = formattedExpirationDate {
                        HStack {
                            Text("Pro access until")
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text(dateStr)
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                        }
                        .font(.system(size: 14))
                        
                        HStack {
                            Text("Time remaining")
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text(days <= 0 ? "Less than a day" : days == 1 ? "1 day" : "\(days) days")
                                .foregroundColor(days <= 3 ? .orange : .white)
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 14))
                    }
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.orange.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            
            // Resubscribe button (prominent) - uses selected plan
            Button {
                Haptics.impact(.medium)
                // Trigger purchase flow - use the selected product (user can choose monthly or yearly)
                guard let product = selectedProduct else {
                    // Fallback to manage subscriptions if products not loaded
                    Task { await pro.openManageSubscriptions() }
                    return
                }
                isBusy = true
                Task {
                    await pro.purchase(product)
                    isBusy = false
                    await refreshSubscriptionStatus()
                }
            } label: {
                HStack(spacing: 8) {
                    if isBusy {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    VStack(spacing: 2) {
                        Text(isBusy ? "Processing..." : "Resubscribe to Pro")
                            .font(.system(size: 17, weight: .bold))
                        if !isBusy, let product = selectedProduct {
                            Text(product.displayPrice + (isYearlySelected ? "/year" : "/month"))
                                .font(.system(size: 12, weight: .medium))
                                .opacity(0.8)
                        }
                    }
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
            
            // Secondary actions
            HStack(spacing: 16) {
                // Refresh button
                Button {
                    Haptics.impact(.light)
                    Task {
                        await refreshSubscriptionStatus()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .medium))
                        Text("Refresh")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
                
                Text("·")
                    .foregroundColor(.white.opacity(0.3))
                
                // Manage subscription link
                Button {
                    Haptics.impact(.light)
                    Task { await pro.openManageSubscriptions() }
                    // Status will refresh automatically when app returns to foreground
                } label: {
                    Text("Manage Subscription")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }
    
    // Active subscription view
    private var activeSubscriptionView: some View {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                Text("You're a Pro member!")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
            
            // Show next renewal date if available
            if let dateStr = formattedExpirationDate {
                Text("Renews \(dateStr)")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Button {
                        Haptics.impact(.light)
                        Task { await pro.openManageSubscriptions() }
                    } label: {
                Text("Manage Subscription")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
    }
    
    // Purchase CTA view
    private var purchaseCTAView: some View {
        VStack(spacing: 12) {
                Button {
                    guard let product = selectedProduct else {
                        #if DEBUG
                        print("[PaywallView] ❌ No product selected for purchase")
                        #endif
                        return
                    }
                    #if DEBUG
                    print("[PaywallView] 💳 Purchase button tapped")
                    print("[PaywallView] 📦 Product: \(product.id) - \(product.displayPrice)")
                    print("[PaywallView] 📋 Context: \(context.rawValue)")
                    #endif
                    isBusy = true
                    Task {
                        let wasProBefore = pro.isPro
                        await pro.purchase(product)
                        isBusy = false
                        let isProAfter = pro.isPro
                        #if DEBUG
                        print("[PaywallView] ✅ Purchase flow completed")
                        print("[PaywallView] 📊 Pro status: \(wasProBefore) → \(isProAfter)")
                        #endif
                        if isProAfter {
                            await refreshSubscriptionStatus()
                            #if DEBUG
                            print("[PaywallView] 🎉 User is now Pro! Features should be unlocked.")
                            #endif
                        }
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
                
                Text("Cancel anytime · Secure with App Store")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
        }
    }

    // MARK: - Footer
    
    private var footer: some View {
        VStack(spacing: 12) {
            Button("Restore Purchases") {
                Haptics.impact(.light)
                Task {
                    await pro.restorePurchases()
                    await refreshSubscriptionStatus()
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
            HStack(spacing: 40) {
                Image(systemName: "iphone")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.8))
                
                Image(systemName: "ipad")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.8))
            }
            
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
            Circle()
                .fill(theme.accentPrimary.opacity(0.15))
                .frame(width: 100, height: 100)
                .blur(radius: 30)
                .scaleEffect(pulse ? 1.1 : 0.95)
            
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
        .environmentObject(ProEntitlementManager.shared)
}

#Preview("Sound") {
    PaywallView(context: .sound)
        .environmentObject(ProEntitlementManager.shared)
}

#Preview("Theme") {
    PaywallView(context: .theme)
        .environmentObject(ProEntitlementManager.shared)
}

#Preview("Cloud Sync") {
    PaywallView(context: .cloudSync)
        .environmentObject(ProEntitlementManager.shared)
}
