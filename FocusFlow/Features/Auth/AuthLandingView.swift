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

    @State private var emailSheetRoute: EmailSheetRoute? = nil

    // Apple sign-in nonce (required for Supabase / Apple OIDC)
    @State private var currentNonce: String?

    // UI state
    @State private var isSigningInApple = false
    @State private var isSigningInGoogle = false
    @State private var errorMessage: String?

    var body: some View {
        let theme = appSettings.selectedTheme

        ZStack {
            PremiumAppBackground(theme: theme, showParticles: true, particleCount: 18)
                .ignoresSafeArea()

            VStack(spacing: 18) {

                Spacer(minLength: 28)

                VStack(spacing: 10) {
                    Text("Welcome to FocusFlow")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Sign in to sync your presets, progress, and tasks across devices.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 22)
                }

                VStack(spacing: 12) {

                    // Apple
                    Button {
                        Haptics.impact(.medium)
                        startSignInWithApple()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 16, weight: .semibold))
                            Text(isSigningInApple ? "Signing in..." : "Continue with Apple")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(Color.white.opacity(0.95))
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .disabled(isSigningInApple || isSigningInGoogle)

                    // Google
                    Button {
                        Haptics.impact(.medium)
                        Task { await signInWithGoogle() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "globe")
                                .font(.system(size: 16, weight: .semibold))
                            Text(isSigningInGoogle ? "Opening Google..." : "Continue with Google")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(Color.white.opacity(0.10))
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.16), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .disabled(isSigningInApple || isSigningInGoogle)

                    // Email
                    Button {
                        Haptics.impact(.light)
                        emailSheetRoute = .signup
                    } label: {
                        Text("Continue with Email")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .disabled(isSigningInApple || isSigningInGoogle)

                    // Guest
                    Button {
                        Haptics.impact(.light)
                        continueAsGuest()
                    } label: {
                        Text("Continue as Guest")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                            .padding(.top, 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSigningInApple || isSigningInGoogle)
                }
                .padding(.horizontal, 22)
                .padding(.top, 10)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 22)
                        .padding(.top, 4)
                }

                Spacer(minLength: 18)

                // Footer: toggle to login
                Button {
                    Haptics.impact(.light)
                    emailSheetRoute = .login
                } label: {
                    Text("Already have an account? Log in")
                        .underline()
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 18)
            }
        }
        .fullScreenCover(item: $emailSheetRoute) { route in
            EmailAuthView(mode: route.mode)
        }
    }

    // MARK: - Apple Sign In (ASAuthorizationController)

    private func startSignInWithApple() {
        errorMessage = nil
        isSigningInApple = true

        let nonce = Self.randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = AppleSignInDelegate { result in
            DispatchQueue.main.async {
                self.isSigningInApple = false
            }

            switch result {
            case .success(let appleCredential):
                handleAppleCredential(appleCredential)
            case .failure(let error):
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription.isEmpty
                        ? "Apple sign-in failed. Please try again."
                        : error.localizedDescription
                }
            }
        }
        controller.presentationContextProvider = ApplePresentationContextProvider()
        controller.performRequests()
    }

    private func handleAppleCredential(_ credential: ASAuthorizationAppleIDCredential) {
        guard let nonce = currentNonce else {
            errorMessage = "Invalid sign-in state. Please try again."
            return
        }

        guard let identityToken = credential.identityToken,
              let idToken = String(data: identityToken, encoding: .utf8) else {
            errorMessage = "Missing Apple identity token."
            return
        }

        Task { await signInWithAppleIdToken(idToken: idToken, nonce: nonce) }
    }

    @MainActor
    private func signInWithAppleIdToken(idToken: String, nonce: String) async {
        errorMessage = nil
        do {
            let session = try await SupabaseManager.shared.client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )

            // ✅ Supabase session is now active. AuthManagerV2 + AppSettings will react automatically
            // via auth state changes (namespace + sync engines). We optionally persist the email for UI.
            AppSettings.shared.accountEmail = session.user.email
            AuthManagerV2.shared.upgradeFromGuest()

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
        isSigningInGoogle = true
        defer { isSigningInGoogle = false }

        do {
            _ = try await SupabaseManager.shared.client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: SupabaseManager.redirectURL
            )

            // Supabase opens Safari; returning to app is handled by:
            // FocusFlowApp.onOpenURL -> client.auth.session(from:)
            AuthManagerV2.shared.upgradeFromGuest()

        } catch {
            print("Google OAuth failed:", error)
            errorMessage = error.localizedDescription.isEmpty
                ? "Google sign-in failed. Please try again."
                : error.localizedDescription
        }
    }

    // MARK: - Guest

    private func continueAsGuest() {
        AuthManagerV2.shared.continueAsGuest()
    }

    // MARK: - Nonce helpers (Apple requirement)

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if status != errSecSuccess { fatalError("Unable to generate nonce.") }
                return random
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
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Apple Sign In Delegates

private final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    typealias Completion = (Result<ASAuthorizationAppleIDCredential, Error>) -> Void
    private let completion: Completion

    init(completion: @escaping Completion) {
        self.completion = completion
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            completion(.success(credential))
        } else {
            completion(.failure(NSError(domain: "AppleSignIn", code: -1)))
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
}

private final class ApplePresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Best-effort window
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}
