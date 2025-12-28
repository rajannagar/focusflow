//
//  AuthLandingView.swift
//  FocusFlow
//
//  Redesigned auth landing with native Google Sign-In (no supabase.co popup).
//

import SwiftUI
import AuthenticationServices
import CryptoKit
import Security
import Supabase
import Auth
import GoogleSignIn

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

    // Retain Apple sign-in objects (ASAuthorizationController delegate is weak)
    @State private var appleSignInDelegate: AppleSignInDelegate?
    @State private var applePresentationProvider: ApplePresentationContextProvider?

    // UI state
    @State private var isSigningInApple = false
    @State private var isSigningInGoogle = false
    @State private var errorMessage: String?
    
    // Animation states
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    
    // MARK: - Google Client ID
    private let googleClientID = "292865907704-5a9pqe1fs8722g24936rk6humi4gkpn0.apps.googleusercontent.com"

    var body: some View {
        let theme = appSettings.selectedTheme

        ZStack {
            // Premium background
            PremiumAppBackground(theme: theme, showParticles: true, particleCount: 18)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                
                Spacer()
                
                // MARK: - Logo & Branding (Center)
                VStack(spacing: 20) {
                    // App Logo
                    Image("Focusflow_Logo")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 110, height: 110)
                        .shadow(color: theme.accentPrimary.opacity(0.4), radius: 30, x: 0, y: 10)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    // App Name
                    Text("FocusFlow")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(logoOpacity)
                    
                    // Tagline
                    VStack(spacing: 8) {
                        Text("Your focus journey")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("starts here")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .opacity(textOpacity)
                }
                
                Spacer()
                
                // MARK: - Auth Buttons (Bottom)
                VStack(spacing: 14) {
                    
                    // Apple Sign In
                    Button {
                        Haptics.impact(.medium)
                        startSignInWithApple()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 18, weight: .semibold))
                            Text(isSigningInApple ? "Signing in..." : "Continue with Apple")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.white.opacity(0.1), radius: 10, y: 4)
                    }
                    .disabled(isSigningInApple || isSigningInGoogle)
                    
                    // Google Sign In (Native SDK)
                    Button {
                        Haptics.impact(.medium)
                        startSignInWithGoogle()
                    } label: {
                        HStack(spacing: 12) {
                            // Google "G" logo
                            Image("google_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text(isSigningInGoogle ? "Signing in..." : "Continue with Google")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(isSigningInApple || isSigningInGoogle)
                    
                    // Email Sign In
                    Button {
                        Haptics.impact(.light)
                        emailSheetRoute = .signup
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Continue with Email")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(isSigningInApple || isSigningInGoogle)
                    
                    // Divider
                    HStack(spacing: 16) {
                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 1)
                        
                        Text("or")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 4)
                    
                    // Guest Mode
                    Button {
                        Haptics.impact(.light)
                        continueAsGuest()
                    } label: {
                        Text("Continue as Guest")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSigningInApple || isSigningInGoogle)
                    
                    // Error Message
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    
                    // Existing Account Link
                    Button {
                        Haptics.impact(.light)
                        emailSheetRoute = .login
                    } label: {
                        Text("Already have an account? ")
                            .foregroundColor(.white.opacity(0.5))
                        +
                        Text("Log in")
                            .foregroundColor(theme.accentPrimary)
                            .fontWeight(.semibold)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                .opacity(buttonsOpacity)
            }
        }
        .onAppear {
            animateIn()
        }
        .fullScreenCover(item: $emailSheetRoute) { route in
            EmailAuthView(mode: route.mode)
        }
    }
    
    // MARK: - Animations
    
    private func animateIn() {
        // Logo animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Text animation
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            textOpacity = 1.0
        }
        
        // Buttons animation
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            buttonsOpacity = 1.0
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

        // IMPORTANT: `ASAuthorizationController.delegate` is weak.
        // Keep these objects alive until the callback fires.
        let delegate = AppleSignInDelegate { result in
            DispatchQueue.main.async {
                self.isSigningInApple = false
                self.appleSignInDelegate = nil
                self.applePresentationProvider = nil
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

        let presenter = ApplePresentationContextProvider()

        self.appleSignInDelegate = delegate
        self.applePresentationProvider = presenter

        controller.delegate = delegate
        controller.presentationContextProvider = presenter
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
        
        // Capture name from Apple (only available on FIRST sign-in)
        var fullName: String? = nil
        if let nameComponents = credential.fullName {
            let firstName = nameComponents.givenName ?? ""
            let lastName = nameComponents.familyName ?? ""
            let name = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
            if !name.isEmpty {
                fullName = name
            }
        }

        Task { await signInWithAppleIdToken(idToken: idToken, nonce: nonce, fullName: fullName) }
    }

    @MainActor
    private func signInWithAppleIdToken(idToken: String, nonce: String, fullName: String?) async {
        errorMessage = nil
        do {
            let session = try await SupabaseManager.shared.client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )

            AppSettings.shared.accountEmail = session.user.email
            
            // Save name if provided and not already set
            if let name = fullName, !name.isEmpty {
                if AppSettings.shared.displayName.isEmpty {
                    AppSettings.shared.displayName = name
                }
            }
            
            AuthManagerV2.shared.upgradeFromGuest()
            
            #if DEBUG
            print("[AuthLandingView] Apple sign-in successful: \(session.user.email ?? "no email"), name: \(fullName ?? "not provided")")
            #endif

        } catch {
            print("Supabase Apple sign-in failed:", error)
            errorMessage = error.localizedDescription.isEmpty
                ? "Apple sign-in failed. Please try again."
                : error.localizedDescription
        }
    }

    // MARK: - Google Sign In (Native SDK)
    
    private func startSignInWithGoogle() {
        errorMessage = nil
        isSigningInGoogle = true
        
        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to get root view controller."
            isSigningInGoogle = false
            return
        }
        
        // Configure Google Sign-In
        let config = GIDConfiguration(clientID: googleClientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start the sign-in flow
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            Task { @MainActor in
                await handleGoogleSignInResult(result: result, error: error)
            }
        }
    }
    
    @MainActor
    private func handleGoogleSignInResult(result: GIDSignInResult?, error: Error?) async {
        defer { isSigningInGoogle = false }
        
        if let error = error {
            // User cancelled - don't show error
            if (error as NSError).code == GIDSignInError.canceled.rawValue {
                return
            }
            print("Google Sign-In error:", error)
            errorMessage = "Google sign-in failed. Please try again."
            return
        }
        
        guard let result = result else {
            errorMessage = "Google sign-in failed. No result returned."
            return
        }
        
        guard let idToken = result.user.idToken?.tokenString else {
            errorMessage = "Missing Google ID token."
            return
        }
        
        // Get access token for Supabase
        let accessToken = result.user.accessToken.tokenString
        
        // Capture name from Google profile
        let googleName = result.user.profile?.name
        let googleGivenName = result.user.profile?.givenName
        let displayName = googleName ?? googleGivenName
        
        // Sign in to Supabase with Google ID token
        do {
            let session = try await SupabaseManager.shared.client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .google,
                    idToken: idToken,
                    accessToken: accessToken
                )
            )
            
            AppSettings.shared.accountEmail = session.user.email
            
            // Save name if provided and not already set
            if let name = displayName, !name.isEmpty {
                if AppSettings.shared.displayName.isEmpty {
                    AppSettings.shared.displayName = name
                }
            }
            
            AuthManagerV2.shared.upgradeFromGuest()
            
            #if DEBUG
            print("[AuthLandingView] Google sign-in successful: \(session.user.email ?? "no email"), name: \(displayName ?? "not provided")")
            #endif
            
        } catch {
            print("Supabase Google sign-in failed:", error)
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
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

// MARK: - Preview

#Preview {
    AuthLandingView()
}
