import SwiftUI

struct FocusFlowLaunchView: View {
    @ObservedObject private var appSettings = AppSettings.shared

    // Background + glow
    @State private var bgOpacity: Double = 0.0
    @State private var glowOpacity: Double = 0.0
    @State private var glowScale: CGFloat = 0.92

    // Brand (logo + name)
    @State private var brandOpacity: Double = 0.0
    @State private var brandScale: CGFloat = 0.97

    // Bottom tagline
    @State private var subtitleOpacity: Double = 0.0
    @State private var subtitleOffset: CGFloat = 14

    var body: some View {
        let theme = appSettings.selectedTheme
        let accentPrimary = theme.accentPrimary
        let accentSecondary = theme.accentSecondary

        GeometryReader { geo in
            ZStack {
                // MARK: - Background
                LinearGradient(
                    colors: theme.backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(bgOpacity)
                .ignoresSafeArea()

                // MARK: - Ambient glow (same vibe as auth)
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                accentPrimary.opacity(0.55),
                                accentSecondary.opacity(0.0)
                            ]),
                            center: .top,
                            startRadius: 0,
                            endRadius: 320
                        )
                    )
                    .scaleEffect(glowScale)
                    .opacity(glowOpacity)
                    .blur(radius: 70)
                    .offset(y: -140)

                // MARK: - Brand block (logo + name only)
                VStack(spacing: 14) {
                    Image("Focusflow_Logo")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 72, height: 72)

                    Text("FocusFlow")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.white)
                }
                .opacity(brandOpacity)
                .scaleEffect(brandScale)
                // 🔑 Place it higher to match AuthLandingView feel
                // Tune this fraction if you want it a tiny bit higher/lower.
                .position(x: geo.size.width * 0.5, y: geo.size.height * 0.37)

                // MARK: - Bottom tagline (short + simple)
                VStack {
                    Spacer()

                    Text("A calmer way to get serious work done.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.72))
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
        withAnimation(.easeInOut(duration: 0.5)) {
            bgOpacity = 1.0
        }

        withAnimation(.easeInOut(duration: 0.9).delay(0.1)) {
            glowOpacity = 1.0
            glowScale = 1.05
        }

        withAnimation(.spring(response: 0.8, dampingFraction: 0.85).delay(0.25)) {
            brandOpacity = 1.0
            brandScale = 1.0
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.7)) {
            subtitleOpacity = 1.0
            subtitleOffset = 0
        }
    }
}
