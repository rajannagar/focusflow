import SwiftUI

// =========================================================
// MARK: - Premium App Background
// =========================================================
// A beautiful, consistent background used across all views
// Features: Multi-layer gradients, floating particles, subtle glow orbs

struct PremiumAppBackground: View {
    let theme: AppTheme
    var showParticles: Bool = true
    var particleCount: Int = 15
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base layer - deep dark with slight color
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.06, blue: 0.09),
                        Color(red: 0.04, green: 0.04, blue: 0.07),
                        Color(red: 0.02, green: 0.02, blue: 0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Mesh-like gradient overlay for depth
                MeshGradientLayer(theme: theme, size: geo.size)
                
                // Floating glow orbs
                GlowOrbsLayer(theme: theme, size: geo.size)
                
                // Particle field
                if showParticles {
                    ParticleFieldView(theme: theme, count: particleCount)
                }
                
                // Subtle noise texture overlay
                NoiseTextureOverlay()
                
                // Top vignette for depth
                VignetteOverlay()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Mesh Gradient Layer

private struct MeshGradientLayer: View {
    let theme: AppTheme
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Primary accent glow - top left
            RadialGradient(
                colors: [
                    theme.accentPrimary.opacity(0.12),
                    theme.accentPrimary.opacity(0.05),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: size.width * 0.8
            )
            
            // Secondary accent glow - bottom right
            RadialGradient(
                colors: [
                    theme.accentSecondary.opacity(0.10),
                    theme.accentSecondary.opacity(0.03),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: size.width * 0.9
            )
            
            // Center subtle highlight
            RadialGradient(
                colors: [
                    Color.white.opacity(0.02),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: size.width * 0.5
            )
        }
    }
}

// MARK: - Glow Orbs Layer

private struct GlowOrbsLayer: View {
    let theme: AppTheme
    let size: CGSize
    
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Large primary orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            theme.accentPrimary.opacity(0.20),
                            theme.accentPrimary.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .blur(radius: 60)
                .offset(
                    x: -size.width * 0.3 + (animate ? 20 : 0),
                    y: -size.height * 0.25 + (animate ? 15 : 0)
                )
            
            // Medium secondary orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            theme.accentSecondary.opacity(0.15),
                            theme.accentSecondary.opacity(0.03),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .offset(
                    x: size.width * 0.35 + (animate ? -15 : 0),
                    y: size.height * 0.3 + (animate ? -20 : 0)
                )
            
            // Small accent orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            theme.accentPrimary.opacity(0.12),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 40)
                .offset(
                    x: size.width * 0.2 + (animate ? 10 : 0),
                    y: -size.height * 0.35 + (animate ? 10 : 0)
                )
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                animate = true
            }
        }
    }
}

// MARK: - Particle Field

private struct ParticleFieldView: View {
    let theme: AppTheme
    let count: Int
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<count, id: \.self) { index in
                    ParticleDot(
                        theme: theme,
                        index: index,
                        bounds: geo.size
                    )
                }
            }
        }
    }
}

private struct ParticleDot: View {
    let theme: AppTheme
    let index: Int
    let bounds: CGSize
    
    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 0
    @State private var scale: Double = 1
    
    private var size: CGFloat {
        CGFloat.random(in: 2...4)
    }
    
    private var color: Color {
        [theme.accentPrimary, theme.accentSecondary, .white][index % 3]
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .opacity(opacity * 0.6)
            .scaleEffect(scale)
            .blur(radius: 0.5)
            .position(position)
            .onAppear {
                // Random starting position
                position = CGPoint(
                    x: CGFloat.random(in: 0...bounds.width),
                    y: CGFloat.random(in: 0...bounds.height)
                )
                
                // Animate with random duration and delay
                let duration = Double.random(in: 4...8)
                let delay = Double.random(in: 0...3)
                
                withAnimation(
                    .easeInOut(duration: 2)
                    .delay(delay)
                ) {
                    opacity = Double.random(in: 0.3...0.8)
                }
                
                // Floating animation
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    position = CGPoint(
                        x: position.x + CGFloat.random(in: -30...30),
                        y: position.y + CGFloat.random(in: -40...40)
                    )
                    scale = Double.random(in: 0.8...1.2)
                }
            }
    }
}

// MARK: - Noise Texture Overlay

private struct NoiseTextureOverlay: View {
    var body: some View {
        Canvas { context, size in
            // Create subtle noise pattern
            for _ in 0..<1500 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let opacity = Double.random(in: 0.01...0.03)
                
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(Color.white.opacity(opacity))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Vignette Overlay

private struct VignetteOverlay: View {
    var body: some View {
        ZStack {
            // Top edge darkening
            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .frame(height: 200)
            .frame(maxHeight: .infinity, alignment: .top)
            
            // Bottom edge darkening
            LinearGradient(
                colors: [
                    Color.black.opacity(0.4),
                    Color.clear
                ],
                startPoint: .bottom,
                endPoint: .center
            )
            .frame(height: 250)
            .frame(maxHeight: .infinity, alignment: .bottom)
            
            // Corner vignettes
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.15)],
                center: .center,
                startRadius: 200,
                endRadius: 600
            )
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Glass Card Style (Updated)

struct PremiumCard<Content: View>: View {
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 16
    var backgroundOpacity: Double = 0.06
    var borderOpacity: Double = 0.08
    let content: () -> Content
    
    var body: some View {
        content()
            .padding(padding)
            .background(
                ZStack {
                    // Frosted glass effect
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(backgroundOpacity))
                    
                    // Inner glow at top
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(borderOpacity * 1.5),
                                Color.white.opacity(borderOpacity * 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Section Header Style

struct PremiumSectionHeader: View {
    let title: String
    var showInfo: Bool = false
    var onInfoTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            if showInfo, let onInfoTap {
                Button {
                    Haptics.impact(.light)
                    onInfoTap()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        PremiumAppBackground(theme: AppSettings.shared.profileTheme)
        
        VStack(spacing: 20) {
            PremiumCard {
                VStack(alignment: .leading, spacing: 8) {
                    PremiumSectionHeader(title: "EXAMPLE CARD", showInfo: true)
                    Text("Beautiful glass card")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("With frosted glass effect")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
