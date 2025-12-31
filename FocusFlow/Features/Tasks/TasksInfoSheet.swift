import SwiftUI

// =========================================================
// MARK: - Tasks Info Sheet (Premium themed)
// =========================================================

struct TasksInfoSheet: View {
    let theme: AppTheme

    @Environment(\.dismiss) private var dismiss
    @State private var appearAnimation = false

    private var details: [(String, String, String)] {
        [
            ("checkmark.circle.fill",
             "Complete Tasks",
             "Tap the circle next to any task to mark it complete. Completed tasks move to the bottom of your list."),

            ("clock.fill",
             "Duration & Focus",
             "Set a duration for your task. Tasks with duration can be converted to focus presets — tap the timer icon when editing."),

            ("bell.fill",
             "Reminders",
             "Set a reminder time and we'll notify you before your task is due. Great for time-sensitive items."),

            ("repeat",
             "Recurring Tasks",
             "Make tasks repeat daily, weekly, or on specific days. Perfect for habits and routines you want to build."),

            ("calendar",
             "Date Navigation",
             "Swipe through dates at the top, or tap the calendar icon to jump to any date. Plan ahead or review past days."),

            ("trash.fill",
             "Delete Tasks",
             "Swipe left on a task to delete. For recurring tasks, choose to delete just one occurrence or the entire series.")
        ]
    }

    var body: some View {
        ZStack {
            PremiumAppBackground(theme: theme, particleCount: 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.10))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    VStack(spacing: 18) {
                        ZStack {
                            Circle()
                                .fill(theme.accentPrimary.opacity(0.20))
                                .frame(width: 120, height: 120)
                                .blur(radius: 30)
                                .scaleEffect(appearAnimation ? 1.18 : 0.82)

                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            theme.accentPrimary.opacity(0.30),
                                            theme.accentSecondary.opacity(0.12)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)

                            Image(systemName: "checklist")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(theme.accentPrimary)
                                .scaleEffect(appearAnimation ? 1.0 : 0.6)
                        }
                        .padding(.top, 18)

                        Text("How Tasks Work")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 18)

                        Text("Plan your day with tasks, set reminders, and track your progress.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.62))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 18)
                    }
                    .padding(.bottom, 26)

                    VStack(spacing: 12) {
                        ForEach(Array(details.enumerated()), id: \.offset) { index, item in
                            TasksInfoDetailCard(
                                icon: item.0,
                                title: item.1,
                                text: item.2,
                                iconColor: theme.accentPrimary
                            )
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 24)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.82)
                                    .delay(Double(index) * 0.06 + 0.22),
                                value: appearAnimation
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    Button {
                        Haptics.impact(.light)
                        dismiss()
                    } label: {
                        Text("Got it")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: theme.accentPrimary.opacity(0.35), radius: 16, y: 8)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.top, 26)
                    .padding(.bottom, 40)
                    .opacity(appearAnimation ? 1 : 0)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.72)) {
                appearAnimation = true
            }
        }
        .colorScheme(.dark)
    }
}

private struct TasksInfoDetailCard: View {
    let icon: String
    let title: String
    let text: String
    let iconColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor.opacity(0.85))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)

                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

