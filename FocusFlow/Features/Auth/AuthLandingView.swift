import SwiftUI
import AuthenticationServices
import CryptoKit
import Supabase
import Auth

struct AuthLandingView: View {
    @ObservedObject private var appSettings = AppSettings.shared

    // Use a route-based cover to avoid SwiftUI caching the previous mode
    private enum EmailSheetRoute: Identifiable {
        case login
        case signup

        var id: Int { self == .login ? 1 : 2 }

        var mode: EmailAuthMode {
            switch self {
            case .login: return .login
            case .signup: return .signup
            }
        }
    }

    @State private var emailSheet: EmailSheetRoute?
    @State private var errorMessage: String?

    // Apple nonce support (required for native Sign in with Apple → Supabase)
    @State private var currentNonce: String?

    var body: some View {
        let theme = appSettings.selectedTheme

        ZStack {
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

                // MARK: - Actions
                VStack(spacing: 12) {

                    // Apple (NATIVE → Supabase signInWithIdToken)
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

                    // Google (Supabase OAuth)
                    Button {
                        Haptics.impact(.light)
                        Task { await signInWithGoogle() }
                    } label: {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Text("G")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(.black)
                                )

                            Text("Continue with Google")
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

                    // Email
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

                    if let errorMessage {
                        Text(errorMessage)
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
        .fullScreenCover(item: $emailSheet) { route in
            EmailAuthView(mode: route.mode)
        }
    }

    // MARK: - Apple (Native)
    private func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        errorMessage = nil

        // Generate + store nonce
        let nonce = Self.randomNonceString()
        currentNonce = nonce

        // Apple requires SHA256(nonce) in the request
        request.nonce = Self.sha256(nonce)

        request.requestedScopes = [.fullName, .email]
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            print("Apple sign in failed:", error)
            errorMessage = "Sign in with Apple failed. Please try again."

        case .success(let authResult):
            guard let credential = authResult.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Missing Apple credentials."
                return
            }

            guard let nonce = currentNonce else {
                errorMessage = "Missing nonce. Please try again."
                return
            }

            guard let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  !idToken.isEmpty
            else {
                errorMessage = "Missing Apple identity token."
                return
            }

            // Create Supabase session using Apple ID token + nonce
            Task { await signInWithAppleIdToken(idToken: idToken, nonce: nonce) }
        }
    }

    @MainActor
    private func signInWithAppleIdToken(idToken: String, nonce: String) async {
        errorMessage = nil
        do {
            let session = try await SupabaseClientProvider.shared.client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )

            // ✅ Force app state update immediately (don’t rely only on the bridge)
            AuthManager.shared.completeLogin(
                userId: session.user.id,
                email: session.user.email,
                isGuest: false,
                accessToken: session.accessToken,
                refreshToken: session.refreshToken
            )

        } catch {
            print("Supabase Apple sign-in failed:", error)
            errorMessage = error.localizedDescription.isEmpty
                ? "Apple sign-in failed. Please try again."
                : error.localizedDescription
        }
    }

    // MARK: - Google OAuth (Supabase)
    @MainActor
    private func signInWithGoogle() async {
        errorMessage = nil
        do {
            let redirect = SupabaseClientProvider.shared.redirectURL

            _ = try await SupabaseClientProvider.shared.client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: redirect
            )

            // Supabase opens Safari; returning to app is handled by:
            // FocusFlowApp.onOpenURL -> auth.session(from:)

        } catch {
            print("Google OAuth failed:", error)
            errorMessage = error.localizedDescription.isEmpty
                ? "Google sign-in failed. Please try again."
                : error.localizedDescription
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

    // MARK: - Nonce helpers (Apple requirement)
    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(status)")
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    AuthLandingView()
}
