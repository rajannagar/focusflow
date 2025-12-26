import SwiftUI

struct SetNewPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appSettings = AppSettings.shared

    let accessToken: String
    let onFinished: () -> Void

    @State private var password: String = ""
    @State private var confirm: String = ""
    @State private var isLoading: Bool = false
    @State private var error: String?
    @State private var success: String?

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
                        onFinished()
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
                    Text("Set a new password")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Choose a strong password to secure your FocusFlow account.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.72))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.top, 4)

                VStack(spacing: 14) {
                    secureField(label: "NEW PASSWORD", text: $password)
                    secureField(label: "CONFIRM PASSWORD", text: $confirm)
                }
                .padding(.horizontal, 22)
                .padding(.top, 4)

                if let error {
                    Text(error)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.horizontal, 22)
                }

                if let success {
                    Text(success)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 22)
                }

                Button {
                    submit()
                } label: {
                    if isLoading {
                        ProgressView().tint(.black)
                    } else {
                        Text("Update password")
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
                .disabled(isDisabled)

                Spacer(minLength: 0)
            }
        }
    }

    private var isDisabled: Bool {
        isLoading ||
        password.count < 6 ||
        confirm.count < 6 ||
        password != confirm
    }

    private func submit() {
        error = nil
        success = nil

        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = confirm.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 6 else {
            error = "Password must be at least 6 characters."
            return
        }

        guard trimmed == trimmedConfirm else {
            error = "Passwords don’t match."
            return
        }

        isLoading = true
        Task {
            do {
                try await SupabaseAuthAPI.shared.updatePassword(accessToken: accessToken, newPassword: trimmed)
                await MainActor.run {
                    isLoading = false
                    success = "Password updated. Please log in with your new password."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        onFinished()
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let message: String
                    if let e = error as? SupabaseAuthAPIError {
                        switch e {
                        case .badURL:
                            message = "Invalid server configuration."
                        case .missingTokens:
                            message = "Unexpected response. Please try again."
                        case .badResponse(_, let body):
                            message = body.isEmpty ? "Couldn’t update password. Please try again." : body
                        }
                    } else {
                        message = error.localizedDescription.isEmpty
                        ? "Couldn’t update password. Please try again."
                        : error.localizedDescription
                    }
                    self.error = message
                }
            }
        }
    }

    private func secureField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.65))

            SecureField("", text: text)
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
    }
}
