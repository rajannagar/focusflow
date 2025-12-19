import SwiftUI
import StoreKit

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

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var pro: ProEntitlementManager
    @ObservedObject private var appSettings = AppSettings.shared

    @State private var selectedID: String = ProEntitlementManager.yearlyID
    @State private var isBusy = false
    @State private var iconPulse = false

    private var theme: AppTheme { appSettings.selectedTheme }

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
            let accentPrimary = theme.accentPrimary
            let accentSecondary = theme.accentSecondary

            ZStack {
                // Background gradient (matches app)
                LinearGradient(
                    gradient: Gradient(colors: theme.backgroundColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Blurred halos
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
                    VStack(spacing: 16) {
                        header

                        planTabs

                        planDetailsCard

                        featuresCard

                        ctaCard

                        footer
                            .padding(.top, 4)

                        Spacer(minLength: 18)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
            }
        }
        .onAppear { iconPulse = true }
        .task {
            if pro.products.isEmpty { await pro.loadProducts() }
            await pro.refreshEntitlement()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image("Focusflow_Logo")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                    .scaleEffect(iconPulse ? 1.06 : 0.94)
                    .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: iconPulse)

                VStack(alignment: .leading, spacing: 4) {
                    Text("FocusFlow Pro")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)

                    Text("3-day free trial • Cancel anytime")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.80))
                }
            }

            Spacer()

            Button {
                Haptics.impact(.light)
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .imageScale(.medium)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.14))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Plan Tabs (Premium segmented)

    private var planTabs: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose a plan")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.90))

                HStack(spacing: 10) {
                    tabButton(
                        title: "Yearly",
                        badge: "Best value",
                        isSelected: isYearlySelected
                    ) {
                        Haptics.impact(.light)
                        selectedID = ProEntitlementManager.yearlyID
                    }

                    tabButton(
                        title: "Monthly",
                        badge: "Popular",
                        isSelected: !isYearlySelected
                    ) {
                        Haptics.impact(.light)
                        selectedID = ProEntitlementManager.monthlyID
                    }
                }
            }
        }
    }

    private func tabButton(title: String, badge: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .black : .white.opacity(0.85))

                    Text(badge)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isSelected ? .black.opacity(0.75) : .white.opacity(0.55))
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .black.opacity(0.75) : .white.opacity(0.25))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        isSelected
                        ? LinearGradient(gradient: Gradient(colors: [theme.accentPrimary, theme.accentSecondary]),
                                         startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.10), Color.white.opacity(0.06)]),
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(isSelected ? 0.08 : 0.14), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Plan Details (Pricing)

    private var planDetailsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Plan details")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.90))

                    Spacer()

                    Text(priceLine(for: selectedProduct))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.92))
                }

                Text(subPriceLine(for: selectedProduct))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.70))
                    .fixedSize(horizontal: false, vertical: true)

                Divider().background(Color.white.opacity(0.16))

                VStack(alignment: .leading, spacing: 8) {
                    bullet("3-day free trial (then renews automatically)")
                    bullet("Cancel anytime in Apple ID settings")
                    if let savings = savingsLine() {
                        bullet(savings)
                    }
                }
            }
        }
    }

    private func priceLine(for product: Product?) -> String {
        guard let product else { return "Loading…" }
        let period = periodShort(product)
        return "\(product.displayPrice) / \(period)"
    }

    private func subPriceLine(for product: Product?) -> String {
        guard let product else {
            return "If this never loads: set the StoreKit Configuration in your Scheme or sign into a Sandbox Apple ID on device."
        }

        // Nice yearly-per-month helper
        if product.id == ProEntitlementManager.yearlyID,
           let yearly = yearlyProduct,
           let perMonth = yearlyEquivalentPerMonth(yearly) {
            return "Billed yearly • ≈ \(perMonth) / month"
        }

        return "Billed \(billingWord(product)) • Renews automatically"
    }

    private func billingWord(_ product: Product) -> String {
        guard let p = product.subscription?.subscriptionPeriod else { return "periodically" }
        switch p.unit {
        case .day: return "daily"
        case .week: return "weekly"
        case .month: return "monthly"
        case .year: return "yearly"
        @unknown default: return "periodically"
        }
    }

    private func periodShort(_ product: Product) -> String {
        guard let p = product.subscription?.subscriptionPeriod else { return "period" }
        switch p.unit {
        case .day: return p.value == 1 ? "day" : "\(p.value) days"
        case .week: return p.value == 1 ? "week" : "\(p.value) weeks"
        case .month: return p.value == 1 ? "month" : "\(p.value) months"
        case .year: return p.value == 1 ? "year" : "\(p.value) years"
        @unknown default: return "period"
        }
    }

    private func yearlyEquivalentPerMonth(_ yearly: Product) -> String? {
        // This is approximate; displayPrice is localized string, so we don’t parse it.
        // We’ll show a friendly hint only if we can compute from decimals is NOT possible here.
        // So instead: return nil. (Keeps it premium & avoids wrong math.)
        return nil
    }

    private func savingsLine() -> String? {
        // If both products are loaded, we can display a simple “Best value” note without risky currency parsing.
        if monthlyProduct != nil && yearlyProduct != nil && isYearlySelected {
            return "Best value compared to monthly"
        }
        return nil
    }

    // MARK: - Features (clean + compact)

    private var featuresCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("What you get")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.90))
                    Spacer()
                }

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Free includes")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                        feature("Focus timer")
                        feature("Limited sounds (first 3 + silent)")
                        feature("Up to 2 habits")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Pro unlocks")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                        feature("Create & edit focus presets")
                        feature("Full sound library")
                        feature("Unlimited habits")
                        feature("Stats dashboard")
                        feature("Levels & achievements")
                        feature("Themes")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - CTA

    private var ctaCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                if pro.isPro {
                    Button {
                        Haptics.impact(.light)
                        dismiss()
                    } label: {
                        Text("You’re on Pro ✓")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)

                } else {
                    Button {
                        guard let product = selectedProduct else { return }
                        isBusy = true
                        Task {
                            await pro.purchase(product)
                            isBusy = false
                            if pro.isPro { dismiss() }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if isBusy { ProgressView().tint(.black) }
                            Text(isBusy ? "Processing…" : "Start free trial")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [theme.accentPrimary, theme.accentSecondary]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(radius: 12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isBusy || selectedProduct == nil)
                    .opacity((selectedProduct == nil) ? 0.6 : 1.0)

                    if let msg = pro.lastErrorMessage {
                        Text(msg)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 14) {
            Button("Restore") {
                Haptics.impact(.light)
                Task { await pro.restorePurchases() }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white.opacity(0.85))

            Button("Manage") {
                Haptics.impact(.light)
                Task { await pro.openManageSubscriptions() }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white.opacity(0.85))

            Spacer()

            Link("Privacy", destination: URL(string: "https://rajannagar.github.io/FocusFlow/privacy.html")!)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(.horizontal, 4)
    }

    // MARK: - UI Helpers

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(theme.accentPrimary.opacity(0.95))
                .padding(.top, 1)

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.86))
        }
    }

    private func feature(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(theme.accentPrimary.opacity(0.95))
                .padding(.top, 1)

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.86))
        }
    }
}
