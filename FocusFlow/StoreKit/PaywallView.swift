import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var pro: ProEntitlementManager
    @ObservedObject private var appSettings = AppSettings.shared

    @State private var selectedID: String = ProEntitlementManager.yearlyID
    @State private var isBusy = false
    @State private var subscriptionStatus: SubscriptionStatus = .notSubscribed
    
    enum SubscriptionStatus {
        case notSubscribed
        case active
        case cancelled // Still has access but won't renew
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

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            ZStack {
                // Premium animated background
                PremiumAppBackground(theme: theme)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        header
                        
                        proIcon
                        
                        featuresSection
                        
                        planSelector
                        
                        ctaButton
                        
                        footer
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .task {
            if pro.products.isEmpty { await pro.loadProducts() }
            await pro.refreshEntitlement()
            await checkSubscriptionStatus()
        }
    }
    
    private func checkSubscriptionStatus() async {
        // Check actual subscription status from StoreKit
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == ProEntitlementManager.monthlyID ||
                   transaction.productID == ProEntitlementManager.yearlyID {
                    // Check if subscription will renew
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            // Still valid - check renewal status
                            if transaction.revocationDate != nil {
                                subscriptionStatus = .cancelled
                            } else {
                                // Check if auto-renew is disabled
                                let status = await Transaction.latest(for: transaction.productID)
                                if case .verified(let latestTransaction) = status {
                                    // If there's a newer transaction, use that
                                    if let renewal = try? await latestTransaction.subscriptionStatus {
                                        // Subscription is active
                                        subscriptionStatus = .active
                                    } else {
                                        subscriptionStatus = .active
                                    }
                                } else {
                                    subscriptionStatus = .active
                                }
                            }
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

    // MARK: - Header
    
    private var header: some View {
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

    // MARK: - Pro Icon
    
    private var proIcon: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: theme.accentPrimary.opacity(0.5), radius: 20)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 6) {
                Text("FocusFlow Pro")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Unlock your full potential")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Features
    
    private var featuresSection: some View {
        VStack(spacing: 12) {
            featureRow(icon: "slider.horizontal.3", title: "Custom Focus Presets", description: "Create & edit your own focus modes")
            featureRow(icon: "speaker.wave.3.fill", title: "Full Sound Library", description: "Access all ambient sounds")
            featureRow(icon: "checklist", title: "Unlimited Tasks", description: "No limits on your to-do list")
            featureRow(icon: "chart.bar.fill", title: "Stats Dashboard", description: "Deep insights into your focus")
            featureRow(icon: "trophy.fill", title: "Levels & Achievements", description: "Track progress with XP system")
            featureRow(icon: "paintpalette.fill", title: "All Themes", description: "Personalize your experience")
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(theme.accentPrimary)
                .frame(width: 36, height: 36)
                .background(theme.accentPrimary.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(theme.accentPrimary)
        }
    }

    // MARK: - Plan Selector
    
    private var planSelector: some View {
        VStack(spacing: 12) {
            // Yearly
            planCard(
                title: "Yearly",
                price: yearlyProduct?.displayPrice ?? "...",
                period: "/ year",
                badge: "Best Value",
                isSelected: isYearlySelected
            ) {
                Haptics.impact(.light)
                selectedID = ProEntitlementManager.yearlyID
            }
            
            // Monthly
            planCard(
                title: "Monthly",
                price: monthlyProduct?.displayPrice ?? "...",
                period: "/ month",
                badge: nil,
                isSelected: !isYearlySelected
            ) {
                Haptics.impact(.light)
                selectedID = ProEntitlementManager.monthlyID
            }
        }
    }
    
    private func planCard(title: String, price: String, period: String, badge: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isSelected ? .black : .white)
                        
                        if let badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(isSelected ? theme.accentPrimary : .yellow)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(isSelected ? Color.black.opacity(0.15) : Color.yellow.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text("3-day free trial")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? .black.opacity(0.6) : .white.opacity(0.5))
                }
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isSelected ? .black : .white)
                    Text(period)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? .black.opacity(0.6) : .white.opacity(0.5))
                }
            }
            .padding(16)
            .background(
                isSelected
                ? LinearGradient(colors: [theme.accentPrimary, theme.accentSecondary], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA Button
    
    private var ctaButton: some View {
        VStack(spacing: 12) {
            if pro.isPro {
                // Pro user - show status and manage
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: subscriptionStatus == .cancelled ? "exclamationmark.circle.fill" : "checkmark.seal.fill")
                            .font(.system(size: 20))
                            .foregroundColor(subscriptionStatus == .cancelled ? .orange : .green)
                        Text(subscriptionStatus == .cancelled ? "Subscription Cancelled" : "You're a Pro member!")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text(subscriptionStatus == .cancelled
                         ? "You still have access until your subscription expires"
                         : "You have access to all features")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                    
                    Button {
                        Haptics.impact(.light)
                        Task { await pro.openManageSubscriptions() }
                    } label: {
                        Text(subscriptionStatus == .cancelled ? "Resubscribe" : "Manage Subscription")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(subscriptionStatus == .cancelled ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                subscriptionStatus == .cancelled
                                ? AnyShapeStyle(LinearGradient(colors: [theme.accentPrimary, theme.accentSecondary], startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(Color.white.opacity(0.15))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    
                    Button {
                        Haptics.impact(.light)
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(theme.accentPrimary)
                    }
                }
                .padding(.vertical, 8)
            } else {
                Button {
                    guard let product = selectedProduct else { return }
                    isBusy = true
                    Task {
                        await pro.purchase(product)
                        isBusy = false
                        if pro.isPro {
                            await checkSubscriptionStatus()
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        if isBusy {
                            ProgressView().tint(.black)
                        }
                        Text(isBusy ? "Processing..." : "Start Free Trial")
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
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: theme.accentPrimary.opacity(0.4), radius: 12, y: 4)
                }
                .disabled(isBusy || selectedProduct == nil)
                .opacity(selectedProduct == nil ? 0.6 : 1)
                
                Text("Cancel anytime. No commitment.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            if let msg = pro.lastErrorMessage {
                Text(msg)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Footer
    
    private var footer: some View {
        VStack(spacing: 16) {
            Button("Restore Purchases") {
                Haptics.impact(.light)
                Task {
                    await pro.restorePurchases()
                    await checkSubscriptionStatus()
                }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: 16) {
                Link("Privacy", destination: URL(string: "https://rajannagar.github.io/FocusFlow/privacy.html")!)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                
                Text("•")
                    .foregroundColor(.white.opacity(0.2))
                
                Link("Terms", destination: URL(string: "https://rajannagar.github.io/FocusFlow/terms.html")!)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    PaywallView()
        .environmentObject(ProEntitlementManager())
}
