import SwiftUI
import AuthenticationServices

struct AuthLandingView: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @State private var showingEmailSheet = false
    @State private var appleErrorMessage: String?

    var body: some View {
        let theme = appSettings.selectedTheme
        let accentPrimary = theme.accentPrimary
        let accentSecondary = theme.accentSecondary

        ZStack {
            LinearGradient(
                colors: theme.backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            accentPrimary.opacity(0.55),
                            accentSecondary.opacity(0.0)
                        ]),
                        center: .top,
                        startRadius: 0,
                        endRadius: 320
                    )
                )
                .blur(radius: 70)
                .offset(y: -140)

            VStack(spacing: 28) {
                Spacer().frame(height: 40)

                VStack(spacing: 10) {
                    Text("Welcome to")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    Text("FocusFlow")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)

                    Text("A calmer way to plan, focus, and track your progress across all your devices.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 22)

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Today’s focus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))

                            Spacer()

                            Text("On track")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.10))
                                .clipShape(Capsule())
                                .foregroundColor(.white.opacity(0.9))
                        }

                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [accentPrimary, accentSecondary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Image(systemName: "timer")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 56, height: 56)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Deep work session")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)

                                Text("25 min • Writing sprint")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.white.opacity(0.75))
                            }

                            Spacer()
                        }

                        Divider().background(Color.white.opacity(0.1))

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Streak")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("5 days")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            Spacer()

                            VStack(alignment: .leading, spacing: 2) {
                                Text("This week")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("6h 40m focused")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Sync")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("Across devices")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(18)
                }
                .padding(.horizontal, 28)

                Spacer()

                VStack(spacing: 10) {
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: configureAppleRequest,
                        onCompletion: handleAppleCompletion
                    )
                    .frame(height: 52)
                    .signInWithAppleButtonStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal, 24)

                    Button {
                        showingEmailSheet = true
                    } label: {
                        Text("Continue with email")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color.white.opacity(0.10))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 24)

                    Button(action: continueAsGuest) {
                        Text("Skip for now")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                    }

                    if let appleErrorMessage {
                        Text(appleErrorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 2)
                    }

                    Text("Create an account or sign in to keep your focus sessions, habits, and stats synced.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showingEmailSheet) {
            EmailAuthView()
        }
    }

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

                    // ✅ If your UserProfileAPI requires accessToken, we need it here.
                    guard let accessToken = apiResult.accessToken, !accessToken.isEmpty else {
                        await MainActor.run {
                            appleErrorMessage = "Apple sign-in succeeded but no access token was returned."
                        }
                        return
                    }

                    // ✅ Update/ensure profile row (now passes accessToken)
                    if let fullName, !fullName.isEmpty {
                        do {
                            _ = try await UserProfileAPI.shared.upsertProfile(
                                for: user.id,
                                fullName: fullName,
                                displayName: fullName,
                                email: bestEmail,
                                accessToken: accessToken
                            )
                        } catch {
                            print("Apple login: failed to upsert profile name/email:", error)
                        }
                    } else if let bestEmail {
                        do {
                            _ = try await UserProfileAPI.shared.upsertProfile(
                                for: user.id,
                                fullName: nil,
                                displayName: nil,
                                email: bestEmail,
                                accessToken: accessToken
                            )
                        } catch {
                            print("Apple login: failed to upsert email-only profile:", error)
                        }
                    } else {
                        // still ensure row exists
                        do {
                            _ = try await UserProfileAPI.shared.upsertProfile(
                                for: user.id,
                                fullName: nil,
                                displayName: nil,
                                email: nil,
                                accessToken: accessToken
                            )
                        } catch {
                            print("Apple login: failed to ensure empty profile:", error)
                        }
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
                            appleErrorMessage = error.localizedDescription
                        }
                        print("Apple login API error:", error)
                    }
                }
            }
        }
    }

    private func continueAsGuest() {
        let guestId = UUID()
        AuthManager.shared.completeLogin(userId: guestId, email: nil, isGuest: true)
    }
}

#Preview {
    AuthLandingView()
}
