import SwiftUI
import Supabase
import Auth

struct SetNewPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appSettings = AppSettings.shared

    let onFinished: () -> Void

    @State private var password: String = ""
    @State private var confirm: String = ""
    @State private var isLoading: Bool = false
    @State private var error: String?
    @State private var showSuccess: Bool = false

    var body: some View {
        let theme = appSettings.selectedTheme

        ZStack {
            PremiumAppBackground(theme: theme, showParticles: true, particleCount: 14)
                .ignoresSafeArea()

            if showSuccess {
                successView(theme: theme)
            } else {
                formView(theme: theme)
            }
        }
    }
    
    // MARK: - Form View
    
    private func formView(theme: AppTheme) -> some View {
        VStack(spacing: 16) {
            
            // Header with cancel option
            HStack {
                Spacer()
                
                Button {
                    Haptics.impact(.light)
                    cancelAndSignOut()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 16)
            .padding(.horizontal, 22)

            VStack(alignment: .leading, spacing: 10) {
                Text("Set a new password")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("Choose a strong password to secure your FocusFlow account.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.72))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.top, 4)

            VStack(spacing: 14) {
                secureField(label: "NEW PASSWORD", text: $password)
                secureField(label: "CONFIRM PASSWORD", text: $confirm)
            }
            .padding(.horizontal, 22)
            .padding(.top, 4)

            if let error {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.9))
                    Text(error)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red.opacity(0.9))
                }
                .padding(.horizontal, 22)
            }

            Button {
                submit()
            } label: {
                if isLoading {
                    ProgressView().tint(.black)
                } else {
                    Text("Update Password")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [theme.accentPrimary, theme.accentSecondary]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.black)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.22), radius: 18, x: 0, y: 12)
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .disabled(isDisabled)

            Spacer(minLength: 0)
        }
    }
    
    // MARK: - Success View
    
    private func successView(theme: AppTheme) -> some View {
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
            
            // Success text
            VStack(spacing: 12) {
                Text("Password Updated!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Your password has been changed successfully. You can now sign in with your new password.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Continue button
            VStack(spacing: 16) {
                Button {
                    Haptics.impact(.medium)
                    // Sign out so user can sign in with new password
                    Task {
                        await AuthManagerV2.shared.signOut()
                        onFinished()
                        dismiss()
                        // Post notification to open email login sheet
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(
                                name: Notification.Name("FocusFlow.openEmailLogin"),
                                object: nil
                            )
                        }
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
                    Task {
                        await AuthManagerV2.shared.signOut()
                        onFinished()
                        dismiss()
                    }
                } label: {
                    Text("Not now")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            Haptics.notification(.success)
        }
    }

    private var isDisabled: Bool {
        isLoading ||
        password.trimmingCharacters(in: .whitespacesAndNewlines).count < 6 ||
        confirm.trimmingCharacters(in: .whitespacesAndNewlines).count < 6 ||
        password.trimmingCharacters(in: .whitespacesAndNewlines) != confirm.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func submit() {
        error = nil

        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = confirm.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 6 else {
            error = "Password must be at least 6 characters."
            return
        }

        guard trimmed == trimmedConfirm else {
            error = "Passwords don't match."
            return
        }

        isLoading = true

        Task {
            do {
                // Requires that the recovery deep link has already established a session.
                _ = try await SupabaseManager.shared.auth.update(
                    user: UserAttributes(password: trimmed)
                )

                await MainActor.run {
                    isLoading = false
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSuccess = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    self.error = error.localizedDescription.isEmpty
                        ? "Couldn't update password. Please try again."
                        : error.localizedDescription
                }
            }
        }
    }
    
    /// Cancel the password reset flow - signs out and returns to login
    private func cancelAndSignOut() {
        Task {
            await AuthManagerV2.shared.signOut()
            await MainActor.run {
                onFinished()
                dismiss()
            }
        }
    }

    private func secureField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.65))

            SecureField("", text: text)
                .padding(14)
                .background(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundColor(.white)
                .tint(.white)
        }
    }
}
