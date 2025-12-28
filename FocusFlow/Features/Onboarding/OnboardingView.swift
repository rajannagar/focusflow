//
//  OnboardingView.swift
//  FocusFlow
//
//  Main onboarding container with page navigation and controls.
//

import SwiftUI
import UserNotifications

// MARK: - Main Onboarding View

struct OnboardingView: View {
    @StateObject private var manager = OnboardingManager.shared
    @State private var dragOffset: CGFloat = 0
    
    // Notification permission request helper
    private func requestNotificationPermission(completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                UserDefaults.standard.set(true, forKey: "ff_hasRequestedNotificationPermission")
                
                if granted {
                    Haptics.notification(.success)
                } else {
                    Haptics.notification(.warning)
                }
                
                #if DEBUG
                print("[Onboarding] Notification permission: \(granted ? "granted" : "denied")")
                #endif
                
                completion()
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Dynamic background based on selected theme
            PremiumAppBackground(theme: manager.onboardingData.selectedTheme)
                .ignoresSafeArea()
            
            // Floating particles
            FloatingParticlesView(theme: manager.onboardingData.selectedTheme)
                .ignoresSafeArea()
                .opacity(0.6)
            
            VStack(spacing: 0) {
                // Skip button (top right)
                HStack {
                    Spacer()
                    
                    if manager.currentPage < manager.totalPages - 1 {
                        Button(action: {
                            manager.skipOnboarding()
                        }) {
                            Text("Skip")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(height: 44)
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                // Page content
                TabView(selection: $manager.currentPage) {
                    OnboardingWelcomePage(theme: manager.onboardingData.selectedTheme)
                        .tag(0)
                    
                    OnboardingFocusPage(theme: manager.onboardingData.selectedTheme)
                        .tag(1)
                    
                    OnboardingHabitsPage(theme: manager.onboardingData.selectedTheme)
                        .tag(2)
                    
                    OnboardingPersonalizePage(
                        theme: manager.onboardingData.selectedTheme,
                        manager: manager
                    )
                    .tag(3)
                    
                    OnboardingNotificationsPage(
                        theme: manager.onboardingData.selectedTheme,
                        manager: manager
                    )
                    .tag(4)
                    
                    OnboardingReadyPage(
                        theme: manager.onboardingData.selectedTheme,
                        displayName: manager.onboardingData.displayName
                    )
                    .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: manager.currentPage)
                
                // Bottom controls
                VStack(spacing: 20) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<manager.totalPages, id: \.self) { index in
                            Capsule()
                                .fill(index == manager.currentPage
                                      ? manager.onboardingData.selectedTheme.accentPrimary
                                      : Color.white.opacity(0.2))
                                .frame(
                                    width: index == manager.currentPage ? 24 : 8,
                                    height: 8
                                )
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: manager.currentPage)
                        }
                    }
                    
                    // Action button
                    if manager.currentPage < manager.totalPages - 1 {
                        // Notification permission page - special button
                        if manager.currentPage == 4 {
                            VStack(spacing: 12) {
                                OnboardingButton(
                                    title: "Enable Notifications",
                                    theme: manager.onboardingData.selectedTheme,
                                    isPrimary: true
                                ) {
                                    requestNotificationPermission {
                                        // Move to next page after permission dialog
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            manager.nextPage()
                                        }
                                    }
                                }
                                
                                Button(action: {
                                    Haptics.impact(.light)
                                    manager.nextPage()
                                }) {
                                    Text("Maybe Later")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            // Continue button for other pages
                            OnboardingButton(
                                title: manager.currentPage == 0 ? "Get Started" : "Continue",
                                theme: manager.onboardingData.selectedTheme
                            ) {
                                manager.nextPage()
                            }
                        }
                    } else {
                        // Final page - Complete button + Auth options
                        VStack(spacing: 16) {
                            OnboardingButton(
                                title: "Start Focusing",
                                theme: manager.onboardingData.selectedTheme,
                                isPrimary: true
                            ) {
                                manager.completeOnboarding()
                            }
                            
                            // Divider
                            HStack(spacing: 12) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 1)
                                
                                Text("or sign in to sync")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.4))
                                
                                Rectangle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 20)
                            
                            // Auth provider buttons
                            HStack(spacing: 12) {
                                AuthProviderButton(provider: .apple) {
                                    manager.completeOnboarding()
                                    // Auth will be handled after onboarding
                                }
                                
                                AuthProviderButton(provider: .google) {
                                    manager.completeOnboarding()
                                }
                                
                                AuthProviderButton(provider: .email) {
                                    manager.completeOnboarding()
                                }
                            }
                            
                            // Guest option
                            Button(action: {
                                manager.completeOnboarding()
                            }) {
                                Text("Continue as guest")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Onboarding Button

private struct OnboardingButton: View {
    let title: String
    let theme: AppTheme
    var isPrimary: Bool = true
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(isPrimary ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Group {
                        if isPrimary {
                            LinearGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color.white.opacity(0.1)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(isPrimary ? 0 : 0.1), lineWidth: 1)
                )
                .shadow(color: isPrimary ? theme.accentPrimary.opacity(0.4) : .clear, radius: 12, y: 4)
                .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
    }
}

// MARK: - Auth Provider Button

private enum AuthProvider {
    case apple, google, email
    
    var iconName: String {
        switch self {
        case .apple: return "apple.logo"
        case .google: return "g.circle.fill"
        case .email: return "envelope.fill"
        }
    }
    
    var label: String {
        switch self {
        case .apple: return "Apple"
        case .google: return "Google"
        case .email: return "Email"
        }
    }
}

private struct AuthProviderButton: View {
    let provider: AuthProvider
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: provider.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                
                Text(provider.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(width: 80, height: 64)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Floating Particles View

private struct FloatingParticlesView: View {
    let theme: AppTheme
    
    @State private var particles: [FloatingParticle] = []
    private let particleCount = 15
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .blur(radius: particle.size / 4)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geo.size)
                startAnimation(in: geo.size)
            }
            .onChange(of: theme) { _, _ in
                updateParticleColors()
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<particleCount).map { i in
            FloatingParticle(
                id: i,
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 4...12),
                opacity: Double.random(in: 0.1...0.3),
                color: [theme.accentPrimary, theme.accentSecondary, .white].randomElement()!.opacity(0.6)
            )
        }
    }
    
    private func updateParticleColors() {
        for i in particles.indices {
            particles[i].color = [theme.accentPrimary, theme.accentSecondary, .white].randomElement()!.opacity(0.6)
        }
    }
    
    private func startAnimation(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            for i in particles.indices {
                withAnimation(.easeInOut(duration: Double.random(in: 3...6))) {
                    particles[i].position = CGPoint(
                        x: CGFloat.random(in: 0...size.width),
                        y: CGFloat.random(in: 0...size.height)
                    )
                    particles[i].opacity = Double.random(in: 0.1...0.3)
                }
            }
        }
    }
}

private struct FloatingParticle: Identifiable {
    let id: Int
    var position: CGPoint
    let size: CGFloat
    var opacity: Double
    var color: Color
}

// MARK: - Press Events Modifier

private struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

private extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
