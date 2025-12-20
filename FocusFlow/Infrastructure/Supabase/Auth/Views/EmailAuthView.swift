import SwiftUI

enum EmailAuthMode {
    case login
    case signup
}

struct EmailAuthView: View {
    @Environment(\.dismiss) private var dismiss

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
        ZStack {
            AnimatedThemeBackgroundView()

            VStack(spacing: 28) {

                // MARK: - Header (LEFT-ALIGNED)
                VStack(alignment: .leading, spacing: 10) {
                    Text(isLoginMode ? "Sign in to FocusFlow" : "Create your FocusFlow account")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)

                    Text(
                        isLoginMode
                        ? "Ready to start where you left off?"
                        : "Start your calm, focused workflow."
                    )
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 40)
                .padding(.horizontal, 28)

                // MARK: - Input Fields
                VStack(spacing: 18) {
                    if !isLoginMode {
                        inputField(label: "FULL NAME", text: $fullName)
                    }

                    inputField(label: "EMAIL", text: $email, keyboard: .emailAddress)
                    secureInputField(label: "PASSWORD", text: $password)
                }
                .padding(.horizontal, 28)

                // MARK: - Messages
                if let successMessage {
                    Text(successMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 28)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.horizontal, 28)
                }

                // MARK: - Primary Action
                Button(action: submit) {
                    if isLoading {
                        ProgressView().tint(.black)
                    } else {
                        Text(isLoginMode ? "Login" : "Create account")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.white)
                .foregroundColor(.black)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 28)
                .disabled(isPrimaryDisabled)

                // MARK: - Secondary Actions (CENTERED)
                VStack(spacing: 12) {

                    if isLoginMode {
                        Button("Reset password") {
                            // Opens a sheet and pre-fills the current email if any
                            successMessage = nil
                            errorMessage = nil
                            showingResetSheet = true
                        }
                        .underline()
                        .foregroundColor(.white.opacity(0.85))
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isLoginMode.toggle()
                            errorMessage = nil
                            successMessage = nil
                        }
                    } label: {
                        Text(
                            isLoginMode
                            ? "Create new account"
                            : "Already have an account? Log in"
                        )
                        .underline()
                        .foregroundColor(.white)
                    }
                }
                .font(.system(size: 14))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

                Spacer()

                // MARK: - Close
                Button("Close") {
                    dismiss()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showingResetSheet) {
            ResetPasswordSheet(
                initialEmail: email,
                onSent: { message in
                    // Show success inline and keep user in login mode
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
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)

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

            // Optional: keep your existing profile upsert behavior if you want it here.
            // (Your prior version had it; leaving it out avoids errors if profile API changes.)

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
    private func inputField(
        label: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            TextField("", text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(14)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundColor(.white)
        }
    }

    private func secureInputField(
        label: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            SecureField("", text: text)
                .padding(14)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundColor(.white)
        }
    }
}

// ---------------------------------------------------------
// MARK: - ResetPasswordSheet
// Premium + consistent with your animated background
// ---------------------------------------------------------

private struct ResetPasswordSheet: View {
    @Environment(\.dismiss) private var dismiss

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
        ZStack {
            AnimatedThemeBackgroundView()

            VStack(spacing: 22) {
                Capsule()
                    .fill(Color.white.opacity(0.30))
                    .frame(width: 40, height: 4)
                    .padding(.top, 10)

                VStack(spacing: 10) {
                    Text("Reset your password")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)

                    Text("We’ll email you a secure link to set a new password.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("EMAIL")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    TextField("", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 28)

                if let localError {
                    Text(localError)
                        .font(.system(size: 13))
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.horizontal, 28)
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
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.white)
                .foregroundColor(.black)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 28)
                .disabled(isSending || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
                .padding(.bottom, 20)

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
                        message = error.localizedDescription.isEmpty ? "Couldn’t send reset email. Please try again." : error.localizedDescription
                    }
                    localError = message
                    onError(message)
                }
            }
        }
    }
}
