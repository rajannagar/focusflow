import SwiftUI
import AuthenticationServices

struct AuthLandingView: View {
    @ObservedObject private var appSettings = AppSettings.shared

    // Use a route-based cover to avoid SwiftUI caching the previous mode
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
        let theme = appSettings.selectedTheme

        ZStack {
            // ✅ Match Profile / Progress / Paywall
            PremiumAppBackground(theme: theme, showParticles: true, particleCount: 18)
                .ignoresSafeArea()

            VStack(spacing: 22) {

                // MARK: - Top bar
                HStack {
                    Spacer()

                    Button {
                        Haptics.impact(.light)
                        continueAsGuest()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 14)
                .padding(.horizontal, 22)

                Spacer()

                // MARK: - Brand
                VStack(spacing: 14) {
                    Image("Focusflow_Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 76, height: 76)
                        .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 8)

                    Text("FocusFlow")
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("A calmer way to plan, focus, and track progress.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 34)
                }

                Spacer()

                // MARK: - Auth Actions (Paywall-style)
                VStack(spacing: 12) {

                    // Primary: Apple
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: configureAppleRequest,
                        onCompletion: handleAppleCompletion
                    )
                    .frame(height: 54)
                    .signInWithAppleButtonStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.22), radius: 18, x: 0, y: 12)

                    // Secondary: Email (glass)
                    Button {
                        Haptics.impact(.light)
                        emailSheet = .signup
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                                .imageScale(.small)
                                .foregroundColor(.white.opacity(0.90))

                            Text("Continue with email")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .imageScale(.small)
                                .foregroundColor(.white.opacity(0.55))
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(Color.white.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.16), radius: 14, x: 0, y: 10)
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 6) {
                        Text("Already have an account?")
                            .foregroundColor(.white.opacity(0.65))

                        Button {
                            Haptics.impact(.light)
                            emailSheet = .login
                        } label: {
                            Text("Log in")
                                .underline()
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.system(size: 13, weight: .medium))

                    if let appleErrorMessage {
                        Text(appleErrorMessage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 28)
            }
        }
        // ✅ Full-page email auth (better for your premium theme)
        .fullScreenCover(item: $emailSheet) { route in
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
