import SwiftUI

struct SetNewPasswordView: View {
    @Environment(\.dismiss) private var dismiss

    let accessToken: String
    let onFinished: () -> Void

    @State private var password: String = ""
    @State private var confirm: String = ""
    @State private var isLoading: Bool = false
    @State private var error: String?
    @State private var success: String?

    var body: some View {
        ZStack {
            AnimatedThemeBackgroundView()

            VStack(spacing: 22) {
                Capsule()
                    .fill(Color.white.opacity(0.30))
                    .frame(width: 40, height: 4)
                    .padding(.top, 10)

                VStack(spacing: 10) {
                    Text("Set a new password")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Choose a strong password to secure your FocusFlow account.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                VStack(spacing: 16) {
                    secureField(label: "NEW PASSWORD", text: $password)
                    secureField(label: "CONFIRM PASSWORD", text: $confirm)
                }
                .padding(.horizontal, 28)

                if let error {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.horizontal, 28)
                }

                if let success {
                    Text(success)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 28)
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
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.white)
                .foregroundColor(.black)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 28)
                .disabled(isDisabled)

                Button("Cancel") {
                    onFinished()
                    dismiss()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
                .padding(.bottom, 20)

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
                    // Close after a short beat
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
                        message = error.localizedDescription.isEmpty ? "Couldn’t update password. Please try again." : error.localizedDescription
                    }
                    self.error = message
                }
            }
        }
    }

    private func secureField(label: String, text: Binding<String>) -> some View {
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
