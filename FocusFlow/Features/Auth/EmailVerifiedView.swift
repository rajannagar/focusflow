//
//  EmailVerifiedView.swift
//  FocusFlow
//
//  Success screen shown after email verification via deep link.
//  User must sign in after verification.
//

import SwiftUI

struct EmailVerifiedView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appSettings = AppSettings.shared
    
    let onContinue: () -> Void
    
    @State private var checkmarkScale: CGFloat = 0.5
    @State private var checkmarkOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    
    var body: some View {
        let theme = appSettings.selectedTheme
        
        ZStack {
            PremiumAppBackground(theme: theme, showParticles: true, particleCount: 20)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Success checkmark
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(checkmarkScale)
                .opacity(checkmarkOpacity)
                
                // Success text
                VStack(spacing: 12) {
                    Text("Email Verified!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Your account is ready. Sign in to start your focus journey.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .opacity(textOpacity)
                
                Spacer()
                
                // Sign In button
                VStack(spacing: 16) {
                    Button {
                        Haptics.impact(.medium)
                        // Dismiss this view and open login sheet
                        onContinue()
                        // Post notification to open email login sheet
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(
                                name: Notification.Name("FocusFlow.openEmailLogin"),
                                object: nil
                            )
                        }
                    } label: {
                        Text("Sign In")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: theme.accentPrimary.opacity(0.4), radius: 16, y: 8)
                    }
                    
                    // Not now option - just goes to auth landing
                    Button {
                        Haptics.impact(.light)
                        onContinue()
                    } label: {
                        Text("Not now")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(buttonOpacity)
            }
        }
        .onAppear {
            animateIn()
        }
    }
    
    private func animateIn() {
        // Checkmark bounces in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
            checkmarkScale = 1.0
            checkmarkOpacity = 1.0
        }
        
        // Text fades in
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            textOpacity = 1.0
        }
        
        // Button fades in
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            buttonOpacity = 1.0
        }
        
        // Haptic feedback for success
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            Haptics.notification(.success)
        }
    }
}

#Preview {
    EmailVerifiedView {
        print("Continue tapped")
    }
}

