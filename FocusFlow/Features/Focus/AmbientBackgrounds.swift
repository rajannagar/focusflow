import SwiftUI

// MARK: - Ambient Mode Enum

enum AmbientMode: String, CaseIterable, Identifiable, Codable {
    case minimal = "Minimal"
    case aurora = "Aurora"
    case rain = "Rain"
    case fireplace = "Fireplace"
    case ocean = "Ocean"
    case forest = "Forest"
    case stars = "Stars"
    case gradientFlow = "Gradient Flow"
    case snow = "Snow"
    case underwater = "Underwater"
    case clouds = "Clouds"
    case sakura = "Sakura"
    case lightning = "Lightning"
    case lavaLamp = "Lava Lamp"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .minimal: return "circle.grid.2x2"
        case .aurora: return "wind"
        case .rain: return "cloud.rain"
        case .fireplace: return "flame"
        case .ocean: return "water.waves"
        case .forest: return "leaf"
        case .stars: return "sparkles"
        case .gradientFlow: return "circle.hexagongrid"
        case .snow: return "snowflake"
        case .underwater: return "bubble.left.and.bubble.right"
        case .clouds: return "cloud"
        case .sakura: return "camera.macro"
        case .lightning: return "bolt"
        case .lavaLamp: return "oval"
        }
    }
    
    var description: String {
        switch self {
        case .minimal: return "Clean & focused"
        case .aurora: return "Northern lights"
        case .rain: return "Calming rainfall"
        case .fireplace: return "Warm & cozy"
        case .ocean: return "Gentle waves"
        case .forest: return "Nature vibes"
        case .stars: return "Cosmic calm"
        case .gradientFlow: return "Flowing colors"
        case .snow: return "Winter serenity"
        case .underwater: return "Deep sea calm"
        case .clouds: return "Dreamy skies"
        case .sakura: return "Cherry blossoms"
        case .lightning: return "Electric energy"
        case .lavaLamp: return "Retro flow"
        }
    }
}

// MARK: - Ambient Background View

struct AmbientBackground: View {
    let mode: AmbientMode
    let theme: AppTheme
    let isActive: Bool // Whether timer is running
    var intensity: Double = 0.7 // 0.0 to 1.0
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.08),
                    Color(red: 0.08, green: 0.08, blue: 0.10),
                    Color(red: 0.05, green: 0.05, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Ambient layer
            switch mode {
            case .minimal:
                MinimalAmbient(theme: theme, isActive: isActive, intensity: intensity)
            case .aurora:
                AuroraAmbient(theme: theme, isActive: isActive, intensity: intensity)
            case .rain:
                RainAmbient(theme: theme, isActive: isActive, intensity: intensity)
            case .fireplace:
                FireplaceAmbient(theme: theme, isActive: isActive, intensity: intensity)
            case .ocean:
                OceanAmbient(theme: theme, isActive: isActive, intensity: intensity)
            case .forest:
                ForestAmbient(theme: theme, isActive: isActive, intensity: intensity)
            case .stars:
                StarsAmbient(theme: theme, isActive: isActive, intensity: intensity)
            case .gradientFlow:
                GradientFlowAmbient(theme: theme, isActive: isActive, intensity: intensity)
            case .snow:
                SnowAmbient(theme: theme, isActive: isActive, intensity: intensity)
            case .underwater:
                UnderwaterAmbient(theme: theme, isActive: isActive, intensity: intensity)
            case .clouds:
                CloudsAmbient(theme: theme, isActive: isActive, intensity: intensity)
            case .sakura:
                SakuraAmbient(theme: theme, isActive: isActive, intensity: intensity)
            case .lightning:
                LightningAmbient(theme: theme, isActive: isActive, intensity: intensity)
            case .lavaLamp:
                LavaLampAmbient(theme: theme, isActive: isActive, intensity: intensity)
            }
            
            // Vignette overlay
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.black.opacity(0.3)
                ]),
                center: .center,
                startRadius: 200,
                endRadius: 500
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Minimal Ambient (Default)

private struct MinimalAmbient: View {
    let theme: AppTheme
    let isActive: Bool
    let intensity: Double
    
    var body: some View {
        ZStack {
            // Subtle glow orbs
            FloatingGlowOrbs(theme: theme, count: 3, opacity: (isActive ? 0.15 : 0.08) * intensity)
            
            // Subtle particles
            if isActive {
                ParticleField(theme: theme, count: Int(12 * intensity), opacity: 0.3 * intensity)
            }
        }
    }
}

// MARK: - Aurora Ambient

private struct AuroraAmbient: View {
    let theme: AppTheme
    let isActive: Bool
    let intensity: Double
    
    @State private var phase: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            Canvas { context, size in
                // Draw multiple aurora bands
                for i in 0..<4 {
                    let yOffset = size.height * (0.2 + CGFloat(i) * 0.15)
                    let amplitude = size.height * 0.08 * intensity
                    let frequency = 0.003 + Double(i) * 0.001
                    let speed = (0.3 + Double(i) * 0.1) * intensity
                    
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: yOffset))
                    
                    for x in stride(from: 0, to: size.width, by: 2) {
                        let y = yOffset + sin(x * frequency + time * speed) * amplitude
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                    path.addLine(to: CGPoint(x: 0, y: size.height))
                    path.closeSubpath()
                    
                    let baseOpacity = isActive ? 0.3 : 0.15
                    let gradient = Gradient(colors: [
                        theme.accentPrimary.opacity(baseOpacity * intensity),
                        theme.accentSecondary.opacity((baseOpacity * 0.66) * intensity),
                        Color.clear
                    ])
                    
                    context.fill(
                        path,
                        with: .linearGradient(
                            gradient,
                            startPoint: CGPoint(x: size.width / 2, y: yOffset - amplitude),
                            endPoint: CGPoint(x: size.width / 2, y: size.height)
                        )
                    )
                }
            }
            .blur(radius: 30)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Rain Ambient

private struct RainAmbient: View {
    let theme: AppTheme
    let isActive: Bool
    let intensity: Double
    
    var body: some View {
        ZStack {
            TimelineView(.animation(minimumInterval: 1/30)) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let dropCount = Int((isActive ? 80 : 40) * intensity)
                    
                    for i in 0..<dropCount {
                        let seed = Double(i) * 127.1
                        let x = (sin(seed) * 0.5 + 0.5) * size.width
                        let speed = 200 + (cos(seed * 2.3) * 0.5 + 0.5) * 150
                        let length = 15 + (sin(seed * 3.7) * 0.5 + 0.5) * 20
                        let y = ((time * speed + seed * 50).truncatingRemainder(dividingBy: Double(size.height + length))) - length
                        
                        let opacity = (isActive ? 0.4 : 0.2) * intensity
                        
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x, y: y + length))
                        
                        context.stroke(
                            path,
                            with: .color(Color.white.opacity(opacity)),
                            lineWidth: 1
                        )
                    }
                }
            }
            .ignoresSafeArea()
            
            // Subtle mist at bottom
            LinearGradient(
                colors: [
                    Color.clear,
                    theme.accentPrimary.opacity((isActive ? 0.1 : 0.05) * intensity)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
            .blur(radius: 30)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea()
        }
    }
}

// MARK: - Fireplace Ambient

private struct FireplaceAmbient: View {
    let theme: AppTheme
    let isActive: Bool
    let intensity: Double
    
    var body: some View {
        ZStack {
            // Warm glow from bottom
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let flicker = (sin(time * 3) * 0.1 + sin(time * 7) * 0.05 + sin(time * 11) * 0.03) * intensity
                
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.orange.opacity((isActive ? (0.35 + flicker) : 0.15) * intensity),
                        Color.red.opacity((isActive ? (0.2 + flicker * 0.5) : 0.08) * intensity),
                        Color.clear
                    ]),
                    center: .bottom,
                    startRadius: 0,
                    endRadius: 500
                )
                .ignoresSafeArea()
            }
            
            // Floating embers
            if isActive {
                EmberParticles(count: Int(20 * intensity), intensity: intensity)
            }
        }
    }
}

private struct EmberParticles: View {
    let count: Int
    let intensity: Double
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            Canvas { context, size in
                for i in 0..<count {
                    let seed = Double(i) * 73.7
                    let x = size.width * 0.3 + (sin(seed) * 0.5 + 0.5) * size.width * 0.4
                    let baseY = size.height
                    let speed = 30 + (cos(seed * 2.1) * 0.5 + 0.5) * 40
                    let wobble = sin(time * 2 + seed) * 20
                    
                    let y = baseY - ((time * speed + seed * 20).truncatingRemainder(dividingBy: Double(size.height * 0.7)))
                    let progress = 1 - (baseY - y) / (size.height * 0.7)
                    let opacity = 0.8 * progress * intensity
                    let radius = 2 + (1 - progress) * 3
                    
                    let rect = CGRect(x: x + wobble - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(Color.orange.opacity(opacity))
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Ocean Ambient

private struct OceanAmbient: View {
    let theme: AppTheme
    let isActive: Bool
    let intensity: Double
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            ZStack {
                // Multiple wave layers
                ForEach(0..<3, id: \.self) { layer in
                    WaveLayer(
                        time: time,
                        layer: layer,
                        color: layer == 0 ? theme.accentPrimary : theme.accentSecondary,
                        isActive: isActive,
                        intensity: intensity
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct WaveLayer: View {
    let time: TimeInterval
    let layer: Int
    let color: Color
    let isActive: Bool
    let intensity: Double
    
    var body: some View {
        Canvas { context, size in
            let yBase = size.height * (0.65 + CGFloat(layer) * 0.1)
            let amplitude = size.height * (isActive ? 0.03 : 0.015) * intensity
            let frequency = 0.008 - Double(layer) * 0.002
            let speed = (0.5 + Double(layer) * 0.2) * intensity
            let opacity = (isActive ? (0.25 - Double(layer) * 0.05) : (0.12 - Double(layer) * 0.03)) * intensity
            
            var path = Path()
            path.move(to: CGPoint(x: 0, y: size.height))
            
            for x in stride(from: 0, to: size.width + 1, by: 2) {
                let y = yBase + sin(x * frequency + time * speed) * amplitude
                    + sin(x * frequency * 2 + time * speed * 1.5) * amplitude * 0.5
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()
            
            context.fill(path, with: .color(color.opacity(opacity)))
        }
        .blur(radius: CGFloat(layer) * 5 + 5)
    }
}

// MARK: - Forest Ambient

private struct ForestAmbient: View {
    let theme: AppTheme
    let isActive: Bool
    let intensity: Double
    
    var body: some View {
        ZStack {
            // Soft green underglow
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity((isActive ? 0.15 : 0.08) * intensity),
                    Color.clear
                ]),
                center: .bottom,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            // Fireflies / floating particles
            FireflyParticles(theme: theme, count: Int((isActive ? 25 : 10) * intensity), intensity: intensity)
            
            // Subtle light rays from top
            LightRays(theme: theme, isActive: isActive, intensity: intensity)
        }
    }
}

private struct FireflyParticles: View {
    let theme: AppTheme
    let count: Int
    let intensity: Double
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            Canvas { context, size in
                for i in 0..<count {
                    let seed = Double(i) * 47.3
                    let baseX = (sin(seed) * 0.5 + 0.5) * size.width
                    let baseY = (cos(seed * 1.3) * 0.5 + 0.5) * size.height
                    
                    let wobbleX = sin(time * 0.5 + seed) * 30
                    let wobbleY = cos(time * 0.7 + seed * 1.1) * 20
                    
                    let x = baseX + wobbleX
                    let y = baseY + wobbleY
                    
                    let pulse = (sin(time * 2 + seed * 2) * 0.5 + 0.5)
                    let opacity = (0.3 + pulse * 0.5) * intensity
                    let radius = 2 + pulse * 2
                    
                    // Glow
                    let glowRect = CGRect(x: x - 8, y: y - 8, width: 16, height: 16)
                    context.fill(
                        Path(ellipseIn: glowRect),
                        with: .color(Color.yellow.opacity(opacity * 0.3))
                    )
                    
                    // Core
                    let coreRect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.fill(
                        Path(ellipseIn: coreRect),
                        with: .color(Color.yellow.opacity(opacity))
                    )
                }
            }
            .blur(radius: 1)
        }
        .ignoresSafeArea()
    }
}

private struct LightRays: View {
    let theme: AppTheme
    let isActive: Bool
    let intensity: Double
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/10)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            Canvas { context, size in
                for i in 0..<5 {
                    let seed = Double(i) * 31.7
                    let x = size.width * (0.2 + CGFloat(i) * 0.15)
                    let sway = sin(time * 0.2 + seed) * 20
                    
                    let opacity = (isActive ? 0.08 : 0.04) * intensity
                    
                    var path = Path()
                    path.move(to: CGPoint(x: x + sway, y: 0))
                    path.addLine(to: CGPoint(x: x - 30 + sway, y: size.height * 0.6))
                    path.addLine(to: CGPoint(x: x + 30 + sway, y: size.height * 0.6))
                    path.closeSubpath()
                    
                    context.fill(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color.white.opacity(opacity),
                                Color.clear
                            ]),
                            startPoint: CGPoint(x: x, y: 0),
                            endPoint: CGPoint(x: x, y: size.height * 0.6)
                        )
                    )
                }
            }
            .blur(radius: 20)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Stars Ambient

private struct StarsAmbient: View {
    let theme: AppTheme
    let isActive: Bool
    let intensity: Double
    
    var body: some View {
        ZStack {
            // Starfield
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                Canvas { context, size in
                    let starCount = Int((isActive ? 100 : 60) * intensity)
                    
                    for i in 0..<starCount {
                        let seed = Double(i) * 17.31
                        let x = (sin(seed * 1.1) * 0.5 + 0.5) * size.width
                        let y = (cos(seed * 1.7) * 0.5 + 0.5) * size.height
                        
                        let twinkleSpeed = 1 + (sin(seed * 2.3) * 0.5 + 0.5) * 2
                        let twinkle = sin(time * twinkleSpeed + seed) * 0.5 + 0.5
                        
                        let baseOpacity = isActive ? 0.6 : 0.3
                        let opacity = baseOpacity * (0.3 + twinkle * 0.7) * intensity
                        let radius = 1 + twinkle * 1.5
                        
                        let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(Color.white.opacity(opacity))
                        )
                    }
                }
            }
            
            // Shooting stars (occasional)
            if isActive && intensity > 0.3 {
                ShootingStars(theme: theme, intensity: intensity)
            }
            
            // Nebula glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            theme.accentPrimary.opacity((isActive ? 0.15 : 0.08) * intensity),
                            theme.accentSecondary.opacity((isActive ? 0.1 : 0.05) * intensity),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 50,
                        endRadius: 300
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: 100, y: -150)
                .blur(radius: 40)
        }
        .ignoresSafeArea()
    }
}

private struct ShootingStars: View {
    let theme: AppTheme
    let intensity: Double
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            Canvas { context, size in
                // Only show shooting star occasionally
                let cycle = time.truncatingRemainder(dividingBy: 8)
                guard cycle < 1 else { return }
                
                let progress = cycle
                let startX = size.width * 0.8
                let startY = size.height * 0.1
                let endX = size.width * 0.2
                let endY = size.height * 0.4
                
                let currentX = startX + (endX - startX) * progress
                let currentY = startY + (endY - startY) * progress
                
                let tailLength: CGFloat = 80
                let tailX = currentX + tailLength * 0.6
                let tailY = currentY - tailLength * 0.3
                
                var path = Path()
                path.move(to: CGPoint(x: tailX, y: tailY))
                path.addLine(to: CGPoint(x: currentX, y: currentY))
                
                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [Color.clear, Color.white.opacity(0.8 * intensity)]),
                        startPoint: CGPoint(x: tailX, y: tailY),
                        endPoint: CGPoint(x: currentX, y: currentY)
                    ),
                    lineWidth: 2
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Gradient Flow Ambient

private struct GradientFlowAmbient: View {
    let theme: AppTheme
    let isActive: Bool
    let intensity: Double
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            Canvas { context, size in
                // Multiple flowing gradient blobs
                let blobCount = 4
                
                for i in 0..<blobCount {
                    let seed = Double(i) * 57.3
                    let speed = (isActive ? 0.3 : 0.15) * intensity
                    
                    let centerX = size.width * (0.3 + sin(time * speed + seed) * 0.4)
                    let centerY = size.height * (0.3 + cos(time * speed * 0.7 + seed * 1.3) * 0.4)
                    let radius = size.width * (0.3 + sin(time * speed * 0.5 + seed * 2) * 0.1)
                    
                    let color = i % 2 == 0 ? theme.accentPrimary : theme.accentSecondary
                    let opacity = (isActive ? 0.25 : 0.12) * intensity
                    
                    let rect = CGRect(
                        x: centerX - radius,
                        y: centerY - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .radialGradient(
                            Gradient(colors: [color.opacity(opacity), Color.clear]),
                            center: CGPoint(x: centerX, y: centerY),
                            startRadius: 0,
                            endRadius: radius
                        )
                    )
                }
            }
            .blur(radius: 60)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Snow Ambient

private struct SnowAmbient: View {
    let theme: AppTheme
    let isActive: Bool
    let intensity: Double
    
    var body: some View {
        ZStack {
            // Cool blue tint at top
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.08 * intensity),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
            
            // Snowflakes
            TimelineView(.animation(minimumInterval: 1/30)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                Canvas { context, size in
                    let flakeCount = Int((isActive ? 60 : 30) * intensity)
                    
                    for i in 0..<flakeCount {
                        let seed = Double(i) * 89.3
                        let x = (sin(seed) * 0.5 + 0.5) * size.width + sin(time * 0.5 + seed) * 30
                        let speed = 40 + (cos(seed * 2.1) * 0.5 + 0.5) * 30
                        let y = ((time * speed + seed * 40).truncatingRemainder(dividingBy: Double(size.height + 20))) - 10
                        
                        let sizeVariation = 2 + (sin(seed * 3.7) * 0.5 + 0.5) * 4
                        let opacity = (0.3 + (cos(seed * 1.3) * 0.5 + 0.5) * 0.5) * intensity
                        
                        let rect = CGRect(x: x - sizeVariation/2, y: y - sizeVariation/2, width: sizeVariation, height: sizeVariation)
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(Color.white.opacity(opacity))
                        )
                    }
                }
            }
            .ignoresSafeArea()
            
            // Ground fog
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.05 * intensity)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 300)
            .blur(radius: 40)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea()
        }
    }
}

// MARK: - Underwater Ambient

private struct UnderwaterAmbient: View {
    let theme: AppTheme
    let isActive: Bool
    let intensity: Double
    
    var body: some View {
        ZStack {
            // Deep blue gradient
            LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.1, blue: 0.2).opacity(0.5 * intensity),
                    Color(red: 0.0, green: 0.15, blue: 0.25).opacity(0.3 * intensity)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Light rays from surface
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                Canvas { context, size in
                    for i in 0..<6 {
                        let seed = Double(i) * 41.7
                        let baseX = size.width * (0.1 + CGFloat(i) * 0.15)
                        let sway = sin(time * 0.3 + seed) * 30
                        
                        let opacity = (isActive ? 0.12 : 0.06) * intensity
                        let width: CGFloat = 40 + sin(time * 0.5 + seed) * 10
                        
                        var path = Path()
                        path.move(to: CGPoint(x: baseX + sway - width/2, y: 0))
                        path.addLine(to: CGPoint(x: baseX + sway + width/2, y: 0))
                        path.addLine(to: CGPoint(x: baseX + sway * 2 + width, y: size.height))
                        path.addLine(to: CGPoint(x: baseX + sway * 2 - width, y: size.height))
                        path.closeSubpath()
                        
                        context.fill(
                            path,
                            with: .linearGradient(
                                Gradient(colors: [
                                    Color.cyan.opacity(opacity),
                                    Color.clear
                                ]),
                                startPoint: CGPoint(x: baseX, y: 0),
                                endPoint: CGPoint(x: baseX, y: size.height * 0.8)
                            )
                        )
                    }
                }
                .blur(radius: 20)
            }
            .ignoresSafeArea()
            
            // Bubbles
            BubbleParticles(count: Int((isActive ? 25 : 12) * intensity), intensity: intensity)
        }
    }
}

private struct BubbleParticles: View {
    let count: Int
    let intensity: Double
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            Canvas { context, size in
                for i in 0..<count {
                    let seed = Double(i) * 67.9
                    let x = (sin(seed) * 0.5 + 0.5) * size.width + sin(time * 0.8 + seed) * 20
                    let speed = 25 + (cos(seed * 1.7) * 0.5 + 0.5) * 20
                    let y = size.height - ((time * speed + seed * 30).truncatingRemainder(dividingBy: Double(size.height + 30)))
                    
                    let radius = 3 + (sin(seed * 2.3) * 0.5 + 0.5) * 8
                    let opacity = (0.2 + (cos(seed) * 0.5 + 0.5) * 0.3) * intensity
                    
                    // Bubble outline
                    let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.stroke(
                        Path(ellipseIn: rect),
                        with: .color(Color.white.opacity(opacity)),
                        lineWidth: 1
                    )
                    
                    // Highlight
                    let highlightRect = CGRect(x: x - radius * 0.3, y: y - radius * 0.5, width: radius * 0.4, height: radius * 0.3)
                    context.fill(
                        Path(ellipseIn: highlightRect),
                        with: .color(Color.white.opacity(opacity * 0.8))
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Clouds Ambient

private struct CloudsAmbient: View {
    let theme: AppTheme
    let isActive: Bool
    let intensity: Double
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/20)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            ZStack {
                // Multiple cloud layers
                ForEach(0..<5, id: \.self) { layer in
                    CloudLayer(time: time, layer: layer, isActive: isActive, intensity: intensity)
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct CloudLayer: View {
    let time: TimeInterval
    let layer: Int
    let isActive: Bool
    let intensity: Double
    
    var body: some View {
        Canvas { context, size in
            let seed = Double(layer) * 123.4
            let speed = (0.02 + Double(layer) * 0.008) * (isActive ? 1.0 : 0.5)
            let yBase = size.height * (0.15 + CGFloat(layer) * 0.15)
            let scale = 1.0 - Double(layer) * 0.1
            
            // Draw cloud blobs
            for i in 0..<3 {
                let cloudSeed = seed + Double(i) * 45.6
                let xOffset = ((time * speed * 100 + cloudSeed * 50).truncatingRemainder(dividingBy: Double(size.width + 300))) - 150
                let yOffset = yBase + sin(time * 0.2 + cloudSeed) * 20
                
                let cloudWidth = (120 + sin(cloudSeed) * 40) * scale
                let cloudHeight = (60 + cos(cloudSeed) * 20) * scale
                let opacity = (0.08 - Double(layer) * 0.012) * intensity
                
                // Main cloud body
                let mainRect = CGRect(x: xOffset, y: yOffset, width: cloudWidth, height: cloudHeight)
                context.fill(
                    Path(ellipseIn: mainRect),
                    with: .color(Color.white.opacity(opacity))
                )
                
                // Cloud puffs
                let puff1 = CGRect(x: xOffset - cloudWidth * 0.2, y: yOffset + cloudHeight * 0.2, width: cloudWidth * 0.6, height: cloudHeight * 0.8)
                context.fill(Path(ellipseIn: puff1), with: .color(Color.white.opacity(opacity * 0.8)))
                
                let puff2 = CGRect(x: xOffset + cloudWidth * 0.5, y: yOffset + cloudHeight * 0.1, width: cloudWidth * 0.5, height: cloudHeight * 0.7)
                context.fill(Path(ellipseIn: puff2), with: .color(Color.white.opacity(opacity * 0.8)))
            }
        }
        .blur(radius: CGFloat(10 + layer * 5))
    }
}

// MARK: - Sakura (Cherry Blossom) Ambient

private struct SakuraAmbient: View {
    let theme: AppTheme
    let isActive: Bool
    let intensity: Double
    
    var body: some View {
        ZStack {
            // Soft pink glow
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.pink.opacity(0.1 * intensity),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            // Falling petals
            TimelineView(.animation(minimumInterval: 1/30)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                Canvas { context, size in
                    let petalCount = Int((isActive ? 40 : 20) * intensity)
                    
                    for i in 0..<petalCount {
                        let seed = Double(i) * 53.7
                        let startX = (sin(seed) * 0.5 + 0.5) * size.width
                        let speed = 35 + (cos(seed * 2.1) * 0.5 + 0.5) * 25
                        
                        // Swaying motion
                        let sway = sin(time * 1.5 + seed) * 40 + sin(time * 0.7 + seed * 2) * 20
                        let x = startX + sway
                        let y = ((time * speed + seed * 30).truncatingRemainder(dividingBy: Double(size.height + 30))) - 15
                        
                        // Rotation
                        let rotation = time * 2 + seed
                        
                        let petalSize = 6 + (sin(seed * 3.1) * 0.5 + 0.5) * 6
                        let opacity = (0.4 + (cos(seed) * 0.5 + 0.5) * 0.4) * intensity
                        
                        // Draw petal (ellipse rotated)
                        context.translateBy(x: x, y: y)
                        context.rotate(by: .radians(rotation))
                        
                        let petalRect = CGRect(x: -petalSize/2, y: -petalSize/4, width: petalSize, height: petalSize/2)
                        context.fill(
                            Path(ellipseIn: petalRect),
                            with: .color(Color.pink.opacity(opacity))
                        )
                        
                        context.rotate(by: .radians(-rotation))
                        context.translateBy(x: -x, y: -y)
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Lightning Ambient

private struct LightningAmbient: View {
    let theme: AppTheme
    let isActive: Bool
    let intensity: Double
    
    @State private var flashOpacity: Double = 0
    @State private var lastFlashTime: Date = Date()
    
    var body: some View {
        ZStack {
            // Dark stormy base
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15).opacity(0.5 * intensity),
                    Color(red: 0.05, green: 0.05, blue: 0.1).opacity(0.3 * intensity)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Storm clouds
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                Canvas { context, size in
                    for i in 0..<4 {
                        let seed = Double(i) * 67.3
                        let x = size.width * (0.2 + CGFloat(i) * 0.2) + sin(time * 0.1 + seed) * 30
                        let y = size.height * 0.15 + sin(time * 0.15 + seed) * 10
                        let cloudSize = size.width * 0.4
                        
                        let rect = CGRect(x: x - cloudSize/2, y: y - cloudSize/4, width: cloudSize, height: cloudSize/2)
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(Color.gray.opacity(0.15 * intensity))
                        )
                    }
                }
                .blur(radius: 40)
            }
            .ignoresSafeArea()
            
            // Lightning flash overlay
            Rectangle()
                .fill(Color.white.opacity(flashOpacity))
                .ignoresSafeArea()
            
            // Lightning bolts
            if isActive {
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    
                    Canvas { context, size in
                        // Random lightning every few seconds
                        let cycle = time.truncatingRemainder(dividingBy: 4)
                        guard cycle < 0.3 else { return }
                        
                        let seed = floor(time / 4) * 123.456
                        let startX = size.width * (0.3 + (sin(seed) * 0.5 + 0.5) * 0.4)
                        
                        drawLightningBolt(context: context, startX: startX, startY: 0, size: size, seed: seed, intensity: intensity)
                    }
                }
                .ignoresSafeArea()
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                startLightningFlashes()
            }
        }
        .onAppear {
            if isActive {
                startLightningFlashes()
            }
        }
    }
    
    private func startLightningFlashes() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...6), repeats: true) { _ in
            guard isActive else { return }
            withAnimation(.easeIn(duration: 0.05)) {
                flashOpacity = 0.3 * intensity
            }
            withAnimation(.easeOut(duration: 0.2).delay(0.05)) {
                flashOpacity = 0
            }
        }
    }
    
    private func drawLightningBolt(context: GraphicsContext, startX: CGFloat, startY: CGFloat, size: CGSize, seed: Double, intensity: Double) {
        var path = Path()
        path.move(to: CGPoint(x: startX, y: startY))
        
        var currentX = startX
        var currentY = startY
        let segments = 8
        let segmentHeight = size.height * 0.5 / CGFloat(segments)
        
        for i in 0..<segments {
            let jitter = (sin(seed + Double(i) * 17.3) * 0.5 + 0.5) * 40 - 20
            currentX += jitter
            currentY += segmentHeight
            path.addLine(to: CGPoint(x: currentX, y: currentY))
        }
        
        // Glow
        context.stroke(
            path,
            with: .color(Color.white.opacity(0.8 * intensity)),
            lineWidth: 4
        )
        context.stroke(
            path,
            with: .color(Color.cyan.opacity(0.5 * intensity)),
            lineWidth: 8
        )
    }
}

// MARK: - Lava Lamp Ambient

private struct LavaLampAmbient: View {
    let theme: AppTheme
    let isActive: Bool
    let intensity: Double
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            Canvas { context, size in
                let blobCount = 5
                
                for i in 0..<blobCount {
                    let seed = Double(i) * 97.3
                    let speed = (isActive ? 0.15 : 0.08) * intensity
                    
                    // Slow vertical movement with slight horizontal sway
                    let baseY = (time * speed * 50 + seed * 100).truncatingRemainder(dividingBy: Double(size.height + 200)) - 100
                    let sway = sin(time * 0.3 + seed) * 50
                    let x = size.width * (0.3 + (sin(seed) * 0.5 + 0.5) * 0.4) + sway
                    let y = size.height - baseY
                    
                    // Morphing blob shape
                    let baseRadius = size.width * 0.15
                    let morph1 = sin(time * 0.5 + seed) * 0.3
                    let morph2 = cos(time * 0.7 + seed * 1.5) * 0.2
                    let radiusX = baseRadius * (1 + morph1)
                    let radiusY = baseRadius * (1 + morph2)
                    
                    let color = i % 2 == 0 ? theme.accentPrimary : theme.accentSecondary
                    let opacity = (isActive ? 0.4 : 0.2) * intensity
                    
                    let rect = CGRect(x: x - radiusX, y: y - radiusY, width: radiusX * 2, height: radiusY * 2)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .radialGradient(
                            Gradient(colors: [
                                color.opacity(opacity),
                                color.opacity(opacity * 0.5),
                                Color.clear
                            ]),
                            center: CGPoint(x: x, y: y),
                            startRadius: 0,
                            endRadius: max(radiusX, radiusY)
                        )
                    )
                }
            }
            .blur(radius: 30)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Helper Components

private struct FloatingGlowOrbs: View {
    let theme: AppTheme
    let count: Int
    let opacity: Double
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/20)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            Canvas { context, size in
                for i in 0..<count {
                    let seed = Double(i) * 123.456
                    let baseX = (sin(seed) * 0.5 + 0.5) * size.width
                    let baseY = (cos(seed * 1.5) * 0.5 + 0.5) * size.height
                    
                    let moveX = sin(time * 0.1 + seed) * 50
                    let moveY = cos(time * 0.15 + seed * 1.2) * 30
                    
                    let x = baseX + moveX
                    let y = baseY + moveY
                    let radius = size.width * (0.2 + sin(seed * 2) * 0.1)
                    
                    let color = i % 2 == 0 ? theme.accentPrimary : theme.accentSecondary
                    
                    let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .radialGradient(
                            Gradient(colors: [color.opacity(opacity), Color.clear]),
                            center: CGPoint(x: x, y: y),
                            startRadius: 0,
                            endRadius: radius
                        )
                    )
                }
            }
            .blur(radius: 50)
        }
        .ignoresSafeArea()
    }
}

private struct ParticleField: View {
    let theme: AppTheme
    let count: Int
    let opacity: Double
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/20)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            Canvas { context, size in
                for i in 0..<count {
                    let seed = Double(i) * 789.123
                    let x = (sin(seed) * 0.5 + 0.5) * size.width
                    let speed = 15 + (cos(seed * 2) * 0.5 + 0.5) * 10
                    let y = size.height - ((time * speed + seed * 30).truncatingRemainder(dividingBy: Double(size.height)))
                    
                    let particleOpacity = opacity * (0.5 + sin(time + seed) * 0.5)
                    let radius: CGFloat = 1.5
                    
                    let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(theme.accentPrimary.opacity(particleOpacity))
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Ambient Picker Sheet

struct AmbientPickerSheet: View {
    let theme: AppTheme
    @Binding var selectedMode: AmbientMode
    @Binding var intensity: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Preview background
            AmbientBackground(mode: selectedMode, theme: theme, isActive: true, intensity: intensity)
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 44, height: 4)
                        .padding(.top, 12)
                    
                    Text("Ambience")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Choose your focus atmosphere")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 16)
                
                // Intensity Slider
                VStack(spacing: 10) {
                    HStack {
                        Text("INTENSITY")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1)
                        
                        Spacer()
                        
                        Text("\(Int(intensity * 100))%")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "circle.dotted")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                        
                        CustomSlider(value: $intensity, theme: theme)
                        
                        Image(systemName: "circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(theme.accentPrimary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Mode Grid
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(AmbientMode.allCases) { mode in
                            AmbientModeCard(
                                mode: mode,
                                theme: theme,
                                isSelected: selectedMode == mode,
                                onTap: {
                                    Haptics.impact(.light)
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedMode = mode
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                
                Spacer()
                
                // Done button
                Button {
                    Haptics.impact(.medium)
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .bold))
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
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
    }
}

// MARK: - Custom Slider

private struct CustomSlider: View {
    @Binding var value: Double
    let theme: AppTheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 6)
                
                // Filled track
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * value, height: 6)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: theme.accentPrimary.opacity(0.3), radius: 6, x: 0, y: 2)
                    .offset(x: (geometry.size.width - 22) * value)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newValue = gesture.location.x / geometry.size.width
                                value = min(max(newValue, 0.1), 1.0) // Min 10%
                                Haptics.impact(.light)
                            }
                    )
            }
        }
        .frame(height: 22)
    }
}

private struct AmbientModeCard: View {
    let mode: AmbientMode
    let theme: AppTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(colors: [theme.accentPrimary, theme.accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: mode.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .black : .white.opacity(0.8))
                }
                
                VStack(spacing: 2) {
                    Text(mode.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(mode.description)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.12 : 0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                isSelected
                                    ? LinearGradient(colors: [theme.accentPrimary, theme.accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(color: isSelected ? theme.accentPrimary.opacity(0.2) : .clear, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AmbientBackground(mode: .aurora, theme: AppSettings.shared.profileTheme, isActive: true)
        
        VStack {
            Text("Focus Mode")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
        }
    }
}
