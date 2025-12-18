import SwiftUI

struct EmailAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appSettings = AppSettings.shared

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoginMode: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        let theme = appSettings.selectedTheme

        ZStack {
            LinearGradient(
                colors: theme.backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)

                Text(isLoginMode ? "Log in with email" : "Create account")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                Text("Use your email to sign in and keep your focus data synced.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )

                    VStack(spacing: 16) {

                        if !isLoginMode {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Full name")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))

                                TextField("Your name", text: $fullName)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .padding(10)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))

                            TextField("you@example.com", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))

                            SecureField("Minimum 6 characters", text: $password)
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(.red.opacity(0.9))
                                .multilineTextAlignment(.leading)
                        }

                        Button(action: submit) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            } else {
                                Text(isLoginMode ? "Log in" : "Create account")
                                    .font(.system(size: 15, weight: .semibold))
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                        }
                        .disabled(isPrimaryButtonDisabled)
                        .background(Color.white.opacity(isLoading ? 0.12 : 0.2))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(.top, 4)

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isLoginMode.toggle()
                                errorMessage = nil
                            }
                        } label: {
                            Text(isLoginMode ? "Need an account? Sign up instead" : "Already have an account? Log in instead")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 4)
                    }
                    .padding(18)
                }
                .padding(.horizontal, 24)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(Color.white.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.bottom, 20)
            }
        }
    }

    private var isPrimaryButtonDisabled: Bool {
        if isLoading { return true }
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
        if password.isEmpty { return true }

        if !isLoginMode && fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }

        return false
    }

    private func submit() {
        errorMessage = nil
        isLoading = true
        Task { await submitAsync() }
    }

    private func submitAsync() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let result: AuthAPISessionResult

            if isLoginMode {
                result = try await AuthAPI.shared.loginWithEmailSession(
                    email: trimmedEmail,
                    password: password
                )
            } else {
                result = try await AuthAPI.shared.signUpWithEmailSession(
                    email: trimmedEmail,
                    password: password
                )
            }

            let user = result.user
            let bestEmail = user.email ?? trimmedEmail

            // ✅ Signup confirm-email flow: no token returned => don't log in yet
            if isLoginMode == false && (result.accessToken == nil || result.accessToken?.isEmpty == true) {
                // If your backend allows profile upsert without a user token, you can omit this.
                // But since your UserProfileAPI now expects accessToken, we CAN’T call it here safely.
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Account created. Please check your email to confirm, then log in."
                    isLoginMode = true
                }
                return
            }

            // Login requires access token
            guard let accessToken = result.accessToken, !accessToken.isEmpty else {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Login succeeded but no access token was returned."
                }
                return
            }

            // ✅ Ensure user_profiles exists/updated (now passes accessToken)
            do {
                if isLoginMode {
                    _ = try await UserProfileAPI.shared.upsertProfile(
                        for: user.id,
                        fullName: nil,
                        displayName: nil,
                        email: bestEmail,
                        accessToken: accessToken
                    )
                } else {
                    _ = try await UserProfileAPI.shared.upsertProfile(
                        for: user.id,
                        fullName: trimmedName,
                        displayName: trimmedName,
                        email: bestEmail,
                        accessToken: accessToken
                    )
                }
            } catch {
                print("Email auth: failed to upsert profile:", error)
            }

            await MainActor.run {
                AuthManager.shared.completeLogin(
                    userId: user.id,
                    email: bestEmail,
                    isGuest: false,
                    accessToken: accessToken,
                    refreshToken: result.refreshToken
                )
                isLoading = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                isLoading = false
                if let apiError = error as? AuthAPIError {
                    errorMessage = apiError.localizedDescription
                } else {
                    errorMessage = error.localizedDescription.isEmpty
                        ? "Something went wrong. Please try again."
                        : error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    EmailAuthView()
        .environmentObject(AppSettings.shared)
}
