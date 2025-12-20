import SwiftUI
import AuthenticationServices

struct AuthLandingView: View {
    // Use a route-based sheet to avoid SwiftUI caching the previous mode
    private enum EmailSheetRoute: Identifiable {
        case login
        case signup

        var id: Int {
            switch self {
            case .login: return 1
            case .signup: return 2
            }
        }

        var mode: EmailAuthMode {
            switch self {
            case .login: return .login
            case .signup: return .signup
            }
        }
    }

    @State private var emailSheet: EmailSheetRoute?
    @State private var appleErrorMessage: String?

    var body: some View {
        ZStack {
            // MARK: - Animated Background
            AnimatedThemeBackgroundView()

            VStack(spacing: 28) {

                // MARK: - Skip (Guest)
                HStack {
                    Spacer()
                    Button("Skip") {
                        continueAsGuest()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
                }
                .padding(.top, 12)
                .padding(.trailing, 20)

                Spacer()

                // MARK: - Brand
                VStack(spacing: 16) {
                    Image("Focusflow_Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)

                    Text("FocusFlow")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.white)

                    Text("A calmer way to plan, focus, and track your progress across all your devices.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }

                Spacer()

                // MARK: - Auth Actions
                VStack(spacing: 14) {

                    SignInWithAppleButton(
                        .signIn,
                        onRequest: configureAppleRequest,
                        onCompletion: handleAppleCompletion
                    )
                    .frame(height: 52)
                    .signInWithAppleButtonStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    Button {
                        emailSheet = .signup
                    } label: {
                        Text("Continue with email")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color.white.opacity(0.12))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.white.opacity(0.7))

                        Button("Log in") {
                            emailSheet = .login
                        }
                        .underline()
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    }
                    .font(.system(size: 13))

                    if let appleErrorMessage {
                        Text(appleErrorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 36)
            }
        }
        .sheet(item: $emailSheet) { route in
            EmailAuthView(mode: route.mode)
        }
    }

    // MARK: - Apple Auth
    private func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            print("Apple sign in failed:", error)
            appleErrorMessage = "Sign in with Apple failed. Please try again."

        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                appleErrorMessage = "Missing Apple credentials."
                return
            }

            let userIdentifier = credential.user
            let emailFromApple = credential.email

            let fullName: String? = {
                guard let nameComponents = credential.fullName else { return nil }
                let given = nameComponents.givenName?.trimmingCharacters(in: .whitespacesAndNewlines)
                let family = nameComponents.familyName?.trimmingCharacters(in: .whitespacesAndNewlines)
                let parts = [given, family].compactMap { $0 }.filter { !$0.isEmpty }
                return parts.isEmpty ? nil : parts.joined(separator: " ")
            }()

            let idTokenString: String? = {
                guard let tokenData = credential.identityToken else { return nil }
                return String(data: tokenData, encoding: .utf8)
            }()

            Task {
                do {
                    let apiResult = try await AuthAPI.shared.loginWithAppleSession(
                        userIdentifier: userIdentifier,
                        idToken: idTokenString,
                        email: emailFromApple
                    )

                    let user = apiResult.user
                    let bestEmail = user.email ?? emailFromApple

                    guard let accessToken = apiResult.accessToken, !accessToken.isEmpty else {
                        await MainActor.run {
                            appleErrorMessage = "Apple sign-in succeeded but no access token was returned."
                        }
                        return
                    }

                    // Ensure user profile exists / updated
                    do {
                        _ = try await UserProfileAPI.shared.upsertProfile(
                            for: user.id,
                            fullName: fullName,
                            displayName: fullName,
                            email: bestEmail,
                            accessToken: accessToken
                        )
                    } catch {
                        print("Apple login: failed to upsert profile:", error)
                    }

                    await MainActor.run {
                        AuthManager.shared.completeLogin(
                            userId: user.id,
                            email: bestEmail,
                            isGuest: false,
                            accessToken: accessToken,
                            refreshToken: apiResult.refreshToken
                        )
                        appleErrorMessage = nil
                    }
                } catch {
                    await MainActor.run {
                        if let apiError = error as? AuthAPIError {
                            appleErrorMessage = apiError.localizedDescription
                        } else {
                            appleErrorMessage = error.localizedDescription.isEmpty
                                ? "Apple sign-in failed. Please try again."
                                : error.localizedDescription
                        }
                        print("Apple login API error:", error)
                    }
                }
            }
        }
    }

    // MARK: - Guest
    private func continueAsGuest() {
        AuthManager.shared.completeLogin(
            userId: UUID(),
            email: nil,
            isGuest: true
        )
    }
}

#Preview {
    AuthLandingView()
}
