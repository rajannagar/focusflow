//
//  OnboardingPageViews.swift
//  FocusFlow
//
//  Individual onboarding page views with animations.
//

import SwiftUI
import Combine
import UserNotifications

// MARK: - Page 1: Welcome

struct OnboardingWelcomePage: View {
    let theme: AppTheme
    
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var taglineOffset: CGFloat = 20
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo
            VStack(spacing: 16) {
                Image("Focusflow_Logo")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .shadow(color: theme.accentPrimary.opacity(0.4), radius: 30, x: 0, y: 10)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                Text("FocusFlow")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(logoOpacity)
            }
            
            Spacer()
                .frame(height: 40)
            
            // Tagline
            VStack(spacing: 12) {
                Text("A calmer way to get")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("serious work done")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .opacity(taglineOpacity)
            .offset(y: taglineOffset)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            animateIn()
        }
    }
    
    private func animateIn() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
            taglineOpacity = 1.0
            taglineOffset = 0
        }
    }
}

// MARK: - Page 2: Focus Sessions

struct OnboardingFocusPage: View {
    let theme: AppTheme
    
    @State private var ringProgress: CGFloat = 0
    @State private var timerOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var displayTime: Int = 1500 // 25:00 in seconds
    
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Animated Focus Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 180, height: 180)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                
                // Glow effect
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(theme.accentPrimary.opacity(0.4), lineWidth: 16)
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 12)
                
                // Timer display
                VStack(spacing: 4) {
                    Text(formatTime(displayTime))
                        .font(.system(size: 42, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text("Deep Focus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .opacity(timerOpacity)
            }
            
            Spacer()
                .frame(height: 50)
            
            // Description
            VStack(spacing: 12) {
                Text("Deep Focus Sessions")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Distraction-free focus time with\nambient sounds & gentle reminders")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(textOpacity)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            animateIn()
        }
        .onReceive(timer) { _ in
            updateTimer()
        }
    }
    
    private func animateIn() {
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            timerOpacity = 1.0
        }
        
        withAnimation(.easeInOut(duration: 2.5).delay(0.3)) {
            ringProgress = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            textOpacity = 1.0
        }
    }
    
    private func updateTimer() {
        if ringProgress > 0 && ringProgress < 1 {
            let remaining = Int(1500.0 * (1.0 - Double(ringProgress)))
            displayTime = max(0, remaining)
        } else if ringProgress >= 1 {
            displayTime = 0
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Page 3: Build Habits

struct OnboardingHabitsPage: View {
    let theme: AppTheme
    
    @State private var weekDotsVisible: [Bool] = Array(repeating: false, count: 7)
    @State private var streakCount: Int = 0
    @State private var xpProgress: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var levelOpacity: Double = 0
    
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]
    private let activeDays = [true, true, true, true, true, false, false]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Week visualization
            HStack(spacing: 16) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 8) {
                        Text(weekDays[index])
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Circle()
                            .fill(activeDays[index] ? theme.accentPrimary : Color.white.opacity(0.1))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(index == 4 ? Color.white.opacity(0.6) : Color.clear, lineWidth: 2)
                            )
                            .scaleEffect(weekDotsVisible[index] ? 1.0 : 0.5)
                            .opacity(weekDotsVisible[index] ? 1.0 : 0.0)
                    }
                }
            }
            
            Spacer()
                .frame(height: 30)
            
            // Streak display
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                
                Text("\(streakCount) Day Streak")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.orange.opacity(0.15))
            .clipShape(Capsule())
            
            Spacer()
                .frame(height: 30)
            
            // XP/Level Card
            VStack(spacing: 12) {
                // XP Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * xpProgress)
                        
                        // Shimmer effect
                        if xpProgress > 0 {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.3), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * xpProgress)
                        }
                    }
                }
                .frame(height: 12)
                .frame(maxWidth: 260)
                
                HStack {
                    Text("Level 7")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.accentPrimary)
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("Focused")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(levelOpacity)
            
            Spacer()
                .frame(height: 40)
            
            // Description
            VStack(spacing: 12) {
                Text("Track Your Journey")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Build streaks, earn XP, unlock\nachievements & watch yourself grow")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(textOpacity)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            animateIn()
        }
    }
    
    private func animateIn() {
        // Animate week dots sequentially
        for i in 0..<7 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(i) * 0.1)) {
                weekDotsVisible[i] = true
            }
        }
        
        // Animate streak counter
        withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
            streakCount = 5
        }
        
        // Animate XP bar
        withAnimation(.easeInOut(duration: 1.2).delay(1.0)) {
            xpProgress = 0.75
            levelOpacity = 1.0
        }
        
        // Show text
        withAnimation(.easeOut(duration: 0.5).delay(1.4)) {
            textOpacity = 1.0
        }
    }
}

// MARK: - Page 4: Personalize

struct OnboardingPersonalizePage: View {
    let theme: AppTheme
    @ObservedObject var manager: OnboardingManager
    
    @State private var contentOpacity: Double = 0
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 20)
            
            // Title
            VStack(spacing: 8) {
                Text("Make it yours")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Personalize your experience")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .opacity(contentOpacity)
            
            Spacer()
                .frame(height: 36)
            
            // Name input
            VStack(alignment: .leading, spacing: 10) {
                Text("WHAT SHOULD WE CALL YOU?")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.2)
                
                TextField("Your name", text: $manager.onboardingData.displayName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .padding(16)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .tint(manager.onboardingData.selectedTheme.accentPrimary)
                    .focused($isNameFocused)
            }
            .padding(.horizontal, 24)
            .opacity(contentOpacity)
            
            Spacer()
                .frame(height: 28)
            
            // Daily goal selector
            VStack(alignment: .leading, spacing: 12) {
                Text("DAILY FOCUS GOAL")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.2)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(manager.goalOptions, id: \.self) { minutes in
                            GoalOptionButton(
                                minutes: minutes,
                                isSelected: manager.onboardingData.dailyGoalMinutes == minutes,
                                theme: manager.onboardingData.selectedTheme
                            ) {
                                manager.selectGoal(minutes)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 24)
            .opacity(contentOpacity)
            
            Spacer()
                .frame(height: 28)
            
            // Theme selector
            VStack(alignment: .leading, spacing: 12) {
                Text("PICK YOUR VIBE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.2)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(AppTheme.allCases) { appTheme in
                        ThemeOptionButton(
                            theme: appTheme,
                            isSelected: manager.onboardingData.selectedTheme == appTheme
                        ) {
                            manager.selectTheme(appTheme)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .opacity(contentOpacity)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                contentOpacity = 1.0
            }
        }
        .onTapGesture {
            isNameFocused = false
        }
    }
}

// MARK: - Goal Option Button

private struct GoalOptionButton: View {
    let minutes: Int
    let isSelected: Bool
    let theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(minutes)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .black : .white)
                
                Text("min")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .black.opacity(0.6) : .white.opacity(0.5))
            }
            .frame(width: 54, height: 54)
            .background(
                isSelected
                    ? AnyShapeStyle(LinearGradient(colors: [theme.accentPrimary, theme.accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                    : AnyShapeStyle(Color.white.opacity(0.08))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Theme Option Button

private struct ThemeOptionButton: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    if isSelected {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .shadow(color: isSelected ? theme.accentPrimary.opacity(0.5) : .clear, radius: 8)
                
                Text(theme.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                    .lineLimit(1)
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Page 5: Notifications Permission

struct OnboardingNotificationsPage: View {
    let theme: AppTheme
    @ObservedObject var manager: OnboardingManager
    
    @State private var contentOpacity: Double = 0
    @State private var bellScale: CGFloat = 0.5
    @State private var bellRotation: Double = 0
    @State private var hasRequestedPermission: Bool = false
    @State private var permissionGranted: Bool? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Bell Icon with animation
            ZStack {
                // Glow rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(theme.accentPrimary.opacity(0.15 - Double(i) * 0.04), lineWidth: 2)
                        .frame(width: CGFloat(120 + i * 40), height: CGFloat(120 + i * 40))
                        .scaleEffect(bellScale)
                }
                
                // Bell background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.accentPrimary.opacity(0.2), theme.accentSecondary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(bellScale)
                
                // Bell icon
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(bellRotation))
                    .scaleEffect(bellScale)
            }
            .opacity(contentOpacity)
            
            Spacer()
                .frame(height: 40)
            
            // Title & Description
            VStack(spacing: 16) {
                Text("Stay on Track")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Get gentle reminders to help you\nbuild your focus habit")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(contentOpacity)
            
            Spacer()
                .frame(height: 32)
            
            // Feature list
            VStack(spacing: 16) {
                NotificationFeatureRow(
                    icon: "clock.fill",
                    title: "Daily Reminders",
                    description: "Start your focus sessions on time",
                    theme: theme
                )
                
                NotificationFeatureRow(
                    icon: "flame.fill",
                    title: "Streak Alerts",
                    description: "Don't lose your progress",
                    theme: theme
                )
                
                NotificationFeatureRow(
                    icon: "checkmark.circle.fill",
                    title: "Task Reminders",
                    description: "Never miss a deadline",
                    theme: theme
                )
            }
            .padding(.horizontal, 32)
            .opacity(contentOpacity)
            
            Spacer()
                .frame(height: 32)
            
            // Permission status indicator
            if let granted = permissionGranted {
                HStack(spacing: 8) {
                    Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(granted ? .green : .orange)
                    
                    Text(granted ? "Notifications enabled!" : "You can enable later in Settings")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(granted ? .green : .white.opacity(0.5))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Color.white.opacity(0.05))
                .clipShape(Capsule())
                .transition(.scale.combined(with: .opacity))
            }
            
            Spacer()
            Spacer()
        }
        .onAppear {
            animateIn()
        }
    }
    
    private func animateIn() {
        // Content fade in
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            contentOpacity = 1.0
        }
        
        // Bell scale in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
            bellScale = 1.0
        }
        
        // Bell wiggle animation
        withAnimation(.easeInOut(duration: 0.15).delay(0.7)) {
            bellRotation = 15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            withAnimation(.easeInOut(duration: 0.15)) {
                bellRotation = -15
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.15)) {
                bellRotation = 10
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            withAnimation(.easeInOut(duration: 0.15)) {
                bellRotation = 0
            }
        }
    }
    
    func requestNotificationPermission() {
        guard !hasRequestedPermission else { return }
        hasRequestedPermission = true
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.permissionGranted = granted
                }
                
                // Save permission state
                UserDefaults.standard.set(true, forKey: "ff_hasRequestedNotificationPermission")
                
                if granted {
                    Haptics.notification(.success)
                } else {
                    Haptics.notification(.warning)
                }
                
                #if DEBUG
                print("[Onboarding] Notification permission: \(granted ? "granted" : "denied")")
                #endif
            }
        }
    }
}

// MARK: - Notification Feature Row

private struct NotificationFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let theme: AppTheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(theme.accentPrimary.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.accentPrimary)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
    }
}

// MARK: - Page 6: Ready

struct OnboardingReadyPage: View {
    let theme: AppTheme
    let displayName: String
    
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    @State private var showConfetti: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Success checkmark
            ZStack {
                // Glow rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(theme.accentPrimary.opacity(0.1 - Double(i) * 0.03), lineWidth: 2)
                        .frame(width: CGFloat(100 + i * 30), height: CGFloat(100 + i * 30))
                        .scaleEffect(checkmarkScale)
                        .opacity(checkmarkOpacity)
                }
                
                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: theme.accentPrimary.opacity(0.5), radius: 20)
                    .scaleEffect(checkmarkScale)
                    .opacity(checkmarkOpacity)
                
                // Checkmark
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(checkmarkScale)
                    .opacity(checkmarkOpacity)
            }
            
            // Confetti particles
            if showConfetti {
                ConfettiView(theme: theme)
                    .frame(height: 100)
            }
            
            Spacer()
                .frame(height: 40)
            
            // Personalized message
            VStack(spacing: 12) {
                Text(greetingText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Your focus journey begins now.\nLet's make today count.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(textOpacity)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            animateIn()
        }
    }
    
    private var greetingText: String {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            return "You're all set!"
        } else {
            return "You're all set, \(name)!"
        }
    }
    
    private func animateIn() {
        // Checkmark animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            checkmarkScale = 1.0
            checkmarkOpacity = 1.0
        }
        
        // Show confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showConfetti = true
        }
        
        // Text animation
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            textOpacity = 1.0
        }
        
        // Buttons animation
        withAnimation(.easeOut(duration: 0.5).delay(0.9)) {
            buttonsOpacity = 1.0
        }
    }
}

// MARK: - Confetti View

private struct ConfettiView: View {
    let theme: AppTheme
    
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geo.size)
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        let colors: [Color] = [
            theme.accentPrimary,
            theme.accentSecondary,
            .white,
            .yellow,
            .orange
        ]
        
        for i in 0..<20 {
            let particle = ConfettiParticle(
                id: i,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...8),
                position: CGPoint(
                    x: size.width / 2 + CGFloat.random(in: -20...20),
                    y: size.height / 2
                ),
                opacity: 1.0
            )
            particles.append(particle)
            
            // Animate particle
            withAnimation(.easeOut(duration: Double.random(in: 0.8...1.5)).delay(Double(i) * 0.02)) {
                particles[i].position = CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: -50...size.height)
                )
                particles[i].opacity = 0
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

// MARK: - Preview

#Preview {
    ZStack {
        PremiumAppBackground(theme: .forest)
        OnboardingWelcomePage(theme: .forest)
    }
}
