import SwiftUI

enum EmailAuthMode {
    case login
    case signup
}

struct EmailAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appSettings = AppSettings.shared

    let mode: EmailAuthMode
    @State private var isLoginMode: Bool

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false

    @State private var errorMessage: String?
    @State private var successMessage: String?

    // Reset Password
    @State private var showingResetSheet: Bool = false

    init(mode: EmailAuthMode = .signup) {
        self.mode = mode
        _isLoginMode = State(initialValue: mode == .login)
    }

    var body: some View {
        let theme = appSettings.selectedTheme

        ZStack {
            PremiumAppBackground(theme: theme, showParticles: true, particleCount: 16)
                .ignoresSafeArea()

            VStack(spacing: 16) {

                // MARK: - Top bar
                HStack {
                    Button {
                        Haptics.impact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.top, 14)
                .padding(.horizontal, 22)

                // MARK: - Header (left aligned)
                VStack(alignment: .leading, spacing: 10) {
                    Text(isLoginMode ? "Sign in to FocusFlow" : "Create your FocusFlow account")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(isLoginMode ? "Pick up right where you left off." : "Start your calm, focused workflow.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.72))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.top, 4)

                // MARK: - Inputs
                VStack(spacing: 14) {
                    if !isLoginMode {
                        inputField(label: "FULL NAME", text: $fullName)
                    }
                    inputField(label: "EMAIL", text: $email, keyboard: .emailAddress)
                    secureInputField(label: "PASSWORD", text: $password)
                }
                .padding(.horizontal, 22)
                .padding(.top, 4)

                // MARK: - Messages
                if let successMessage {
                    Text(successMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 22)
                        .padding(.top, 2)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.horizontal, 22)
                        .padding(.top, 2)
                }

                // MARK: - Primary action (Paywall-style)
                Button(action: submit) {
                    if isLoading {
                        ProgressView().tint(.black)
                    } else {
                        Text(isLoginMode ? "Login" : "Create account")
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
                .padding(.top, 6)
                .disabled(isPrimaryDisabled)

                // MARK: - Secondary actions
                VStack(spacing: 12) {

                    if isLoginMode {
                        Button {
                            Haptics.impact(.light)
                            successMessage = nil
                            errorMessage = nil
                            showingResetSheet = true
                        } label: {
                            Text("Reset password")
                                .underline()
                                .foregroundColor(.white.opacity(0.85))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        Haptics.impact(.light)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isLoginMode.toggle()
                            errorMessage = nil
                            successMessage = nil
                        }
                    } label: {
                        Text(isLoginMode ? "Create new account" : "Already have an account? Log in")
                            .underline()
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)

                Spacer(minLength: 0)
            }
        }
        // ✅ full screen reset flow
        .fullScreenCover(isPresented: $showingResetSheet) {
            ResetPasswordSheet(
                initialEmail: email,
                onSent: { message in
                    successMessage = message
                    errorMessage = nil
                    isLoginMode = true
                },
                onError: { message in
                    successMessage = nil
                    errorMessage = message
                }
            )
        }
    }

    // MARK: - State
    private var isPrimaryDisabled: Bool {
        isLoading ||
        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        password.isEmpty ||
        (!isLoginMode && fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    // MARK: - Actions
    private func submit() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        Task { await submitAsync() }
    }

    private func submitAsync() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let result: AuthAPISessionResult =
                isLoginMode
                ? try await AuthAPI.shared.loginWithEmailSession(email: trimmedEmail, password: password)
                : try await AuthAPI.shared.signUpWithEmailSession(email: trimmedEmail, password: password)

            // Signup confirm-email flow
            guard let accessToken = result.accessToken, !accessToken.isEmpty else {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Account created. Check your email to confirm, then log in."
                    successMessage = nil
                    isLoginMode = true
                }
                return
            }

            await MainActor.run {
                AuthManager.shared.completeLogin(
                    userId: result.user.id,
                    email: result.user.email ?? trimmedEmail,
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
                successMessage = nil
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

    // MARK: - UI Components
    private func fieldContainer<Content: View>(_ content: () -> Content) -> some View {
        content()
            .padding(14)
            .background(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func inputField(
        label: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.65))

            fieldContainer {
                TextField("", text: text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundColor(.white)
                    .tint(.white)
            }
        }
    }

    private func secureInputField(
        label: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.65))

            fieldContainer {
                SecureField("", text: text)
                    .foregroundColor(.white)
                    .tint(.white)
            }
        }
    }
}

// ---------------------------------------------------------
// MARK: - ResetPasswordSheet (full screen + premium bg)
// ---------------------------------------------------------

private struct ResetPasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appSettings = AppSettings.shared

    let initialEmail: String
    let onSent: (String) -> Void
    let onError: (String) -> Void

    @State private var email: String
    @State private var isSending: Bool = false
    @State private var localError: String?

    init(
        initialEmail: String,
        onSent: @escaping (String) -> Void,
        onError: @escaping (String) -> Void
    ) {
        self.initialEmail = initialEmail
        self.onSent = onSent
        self.onError = onError
        _email = State(initialValue: initialEmail)
    }

    var body: some View {
        let theme = appSettings.selectedTheme

        ZStack {
            PremiumAppBackground(theme: theme, showParticles: true, particleCount: 14)
                .ignoresSafeArea()

            VStack(spacing: 16) {

                // Top bar
                HStack {
                    Button {
                        Haptics.impact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.top, 14)
                .padding(.horizontal, 22)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Reset your password")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("We’ll email you a secure link to set a new password.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.72))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.top, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text("EMAIL")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))

                    TextField("", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
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
                .padding(.horizontal, 22)
                .padding(.top, 4)

                if let localError {
                    Text(localError)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.horizontal, 22)
                }

                Button {
                    send()
                } label: {
                    if isSending {
                        ProgressView().tint(.black)
                    } else {
                        Text("Send reset link")
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
                .disabled(isSending || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer(minLength: 0)
            }
        }
    }

    private func send() {
        localError = nil
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            localError = "Please enter your email."
            return
        }

        isSending = true
        Task {
            do {
                try await SupabaseAuthAPI.shared.sendPasswordReset(email: trimmed)
                await MainActor.run {
                    isSending = false
                    onSent("Password reset email sent. Check your inbox.")
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    let message: String
                    if let e = error as? SupabaseAuthAPIError {
                        switch e {
                        case .badURL:
                            message = "Invalid server configuration."
                        case .missingTokens:
                            message = "Unexpected response. Please try again."
                        case .badResponse(_, let body):
                            message = body.isEmpty ? "Couldn’t send reset email. Please try again." : body
                        }
                    } else {
                        message = error.localizedDescription.isEmpty
                        ? "Couldn’t send reset email. Please try again."
                        : error.localizedDescription
                    }
                    localError = message
                    onError(message)
                }
            }
        }
    }
}
