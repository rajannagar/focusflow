import SwiftUI

struct FocusFlowLaunchView: View {
    @ObservedObject private var appSettings = AppSettings.shared

    // MARK: - Animation state
    @State private var brandOpacity: Double = 0.0
    @State private var brandScale: CGFloat = 0.96
    @State private var brandOffset: CGFloat = 10

    @State private var subtitleOpacity: Double = 0.0
    @State private var subtitleOffset: CGFloat = 14

    @State private var glowOpacity: Double = 0.0
    @State private var glowScale: CGFloat = 0.92

    var body: some View {
        let theme = appSettings.selectedTheme

        GeometryReader { geo in
            ZStack {
                // ✅ Same background system as Profile / Progress / Paywall
                PremiumAppBackground(
                    theme: theme,
                    showParticles: true,
                    particleCount: 16
                )
                .ignoresSafeArea()

                // Subtle branded halo (kept minimal so it still "belongs" to PremiumAppBackground)
                Circle()
                    .fill(theme.accentPrimary.opacity(0.22))
                    .blur(radius: 80)
                    .frame(width: geo.size.width * 0.95, height: geo.size.width * 0.95)
                    .scaleEffect(glowScale)
                    .opacity(glowOpacity)
                    .offset(x: -geo.size.width * 0.25, y: -geo.size.height * 0.35)

                Circle()
                    .fill(theme.accentSecondary.opacity(0.16))
                    .blur(radius: 90)
                    .frame(width: geo.size.width * 0.95, height: geo.size.width * 0.95)
                    .scaleEffect(glowScale)
                    .opacity(glowOpacity)
                    .offset(x: geo.size.width * 0.28, y: geo.size.height * 0.40)

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: geo.size.height * 0.22)

                    // MARK: - Brand block
                    VStack(spacing: 12) {
                        Image("Focusflow_Logo")
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(width: 76, height: 76)
                            .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 8)

                        Text("FocusFlow")
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
                    }
                    .opacity(brandOpacity)
                    .scaleEffect(brandScale)
                    .offset(y: brandOffset)

                    Spacer()

                    // MARK: - Tagline
                    Text("A calmer way to get serious work done.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.70))
                        .opacity(subtitleOpacity)
                        .offset(y: subtitleOffset)
                        .padding(.bottom, 28)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)
            }
            .onAppear { runAnimation() }
        }
    }

    private func runAnimation() {
        // Background already exists (PremiumAppBackground), so just animate overlays + content.
        withAnimation(.easeInOut(duration: 0.9).delay(0.05)) {
            glowOpacity = 1.0
            glowScale = 1.05
        }

        withAnimation(.spring(response: 0.8, dampingFraction: 0.85).delay(0.15)) {
            brandOpacity = 1.0
            brandScale = 1.0
            brandOffset = 0
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.55)) {
            subtitleOpacity = 1.0
            subtitleOffset = 0
        }
    }
}
