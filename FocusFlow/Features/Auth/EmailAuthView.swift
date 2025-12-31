import SwiftUI
import Supabase

enum EmailAuthMode {
    case login
    case signup
}

struct EmailAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var authManager = AuthManagerV2.shared

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

    // ✅ Single source of truth (replaces SupabaseClientProvider)
    private var supabase: SupabaseClient {
        SupabaseManager.shared.client
    }

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

                // Header
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

                // Inputs
                VStack(spacing: 14) {
                    if !isLoginMode {
                        inputField(label: "FULL NAME", text: $fullName)
                    }
                    inputField(label: "EMAIL", text: $email, keyboard: .emailAddress)
                    secureInputField(label: "PASSWORD", text: $password)
                }
                .padding(.horizontal, 22)
                .padding(.top, 4)

                // Messages
                if let successMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        
                        Text(successMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 2)
                }

                if let errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.9))
                        
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 2)
                }

                // Primary action
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

                // Secondary actions
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
        // ✅ Dismiss when user becomes signed in (e.g., after email confirmation deep link)
        .onChange(of: authManager.state) { oldState, newState in
            if case .signedIn = newState {
                dismiss()
            }
        }
        // ✅ Also listen for auth completed notification (from deep link handler)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FocusFlow.authCompleted"))) { _ in
            dismiss()
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
            if isLoginMode {
                let session = try await supabase.auth.signIn(email: trimmedEmail, password: password)

                await MainActor.run {
                    // Set email from session
                    AppSettings.shared.accountEmail = session.user.email
                    isLoading = false
                    dismiss()
                }
            } else {
                let trimmedFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
                
                #if DEBUG
                print("[Signup] Creating account for: \(trimmedEmail)")
                #endif
                
                let session = try await supabase.auth.signUp(email: trimmedEmail, password: password)

                // If confirmations are ON, Supabase may not create a session immediately.
                let hasSession = (try? await supabase.auth.session) != nil
                
                #if DEBUG
                print("[Signup] Account created, hasSession: \(hasSession)")
                #endif

                await MainActor.run {
                    isLoading = false
                    if hasSession {
                        // Set email from session
                        AppSettings.shared.accountEmail = session.user.email
                        // Set display name from full name if provided and not already set
                        if !trimmedFullName.isEmpty {
                            if AppSettings.shared.displayName.isEmpty || AppSettings.shared.displayName == "You" {
                                AppSettings.shared.displayName = trimmedFullName
                            }
                        }
                        dismiss()
                    } else {
                        // Email confirmation required
                        // ✅ Set pending flow AFTER signup succeeds so deep link handler knows what to show
                        PasswordRecoveryManager.shared.setPendingSignup()
                        successMessage = "Account created! Check your email to verify your account."
                        errorMessage = nil
                        // Switch to login mode so user can sign in after confirming
                        isLoginMode = true
                        // Clear password so it's not visible
                        password = ""
                    }
                }
            }
        } catch {
            #if DEBUG
            print("[Signup] Error: \(error)")
            print("[Signup] Error description: \(error.localizedDescription)")
            #endif
            
            await MainActor.run {
                isLoading = false
                successMessage = nil
                // Clear any pending flow on error
                PasswordRecoveryManager.shared.clearPendingFlow()
                errorMessage = error.localizedDescription.isEmpty
                ? "Something went wrong. Please try again."
                : error.localizedDescription
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

    // ✅ Single source of truth (replaces SupabaseClientProvider)
    private var supabase: SupabaseClient {
        SupabaseManager.shared.client
    }

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
        
        #if DEBUG
        print("[ResetPassword] Sending reset email to: \(trimmed)")
        #endif
        
        Task {
            do {
                // ✅ Use the SAME redirect URL as OAuth so onOpenURL + SupabaseManager can handle it.
                try await supabase.auth.resetPasswordForEmail(
                    trimmed,
                    redirectTo: SupabaseManager.redirectURL
                )
                
                #if DEBUG
                print("[ResetPassword] Reset email sent successfully")
                #endif
                
                // ✅ Set pending flow AFTER success so it's only set when request is processed
                await MainActor.run {
                    PasswordRecoveryManager.shared.setPendingPasswordReset()
                    isSending = false
                    // Ambiguous message for security - doesn't reveal if account exists
                    onSent("If an account exists with this email, you'll receive a reset link shortly.")
                    dismiss()
                }
            } catch {
                #if DEBUG
                print("[ResetPassword] Error sending reset email: \(error)")
                print("[ResetPassword] Error description: \(error.localizedDescription)")
                #endif
                
                await MainActor.run {
                    isSending = false
                    // Clear pending flow on error
                    PasswordRecoveryManager.shared.clearPendingFlow()
                    let message = error.localizedDescription.isEmpty
                    ? "Couldn't send reset email. Please try again."
                    : error.localizedDescription
                    localError = message
                    onError(message)
                }
            }
        }
    }
}
