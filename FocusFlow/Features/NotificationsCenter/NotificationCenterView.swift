import SwiftUI

struct NotificationCenterView: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var manager = NotificationCenterManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showingClearAllConfirm = false
    @State private var iconPulse = false

    var body: some View {
        let theme = appSettings.profileTheme
        let accentPrimary = theme.accentPrimary
        let accentSecondary = theme.accentSecondary

        ZStack {
            // ✅ PremiumAppBackground (same as Profile/Progress/FocusView)
            PremiumAppBackground(theme: theme, showParticles: true, particleCount: 16)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                header(accentPrimary: accentPrimary, accentSecondary: accentSecondary)
                    .padding(.horizontal, 18)
                    .padding(.top, 18)

                if manager.notifications.isEmpty {
                    emptyState
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                } else {
                    // ✅ Scroll all the way down, no bottom padding
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(manager.notifications) { notification in
                                notificationRow(
                                    notification,
                                    accentPrimary: accentPrimary,
                                    accentSecondary: accentSecondary
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    simpleTap()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        manager.markAsRead(notification)
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        simpleTap()
                                        withAnimation {
                                            manager.delete(notification)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    if notification.isRead {
                                        Button {
                                            simpleTap()
                                            withAnimation {
                                                manager.markAsUnread(notification)
                                            }
                                        } label: {
                                            Label("Mark Unread", systemImage: "circle.fill")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 6)
                        .padding(.bottom, 0) // ✅ no bottom padding
                    }
                    .ignoresSafeArea(edges: .bottom) // ✅ extend to bottom
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onAppear { iconPulse = true }
        .alert("Clear all notifications?", isPresented: $showingClearAllConfirm) {
            Button("Clear all", role: .destructive) {
                simpleTap()
                withAnimation { manager.clearAll() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove all notifications from your focus history.")
        }
        // ✅ Full-page sheet
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
        .presentationCornerRadius(32)
    }

    // MARK: - Header

    private func header(
        accentPrimary: Color,
        accentSecondary: Color
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "bell.badge.fill")
                        .imageScale(.medium)
                        .foregroundColor(.white.opacity(0.9))
                        .scaleEffect(iconPulse ? 1.06 : 0.94)
                        .animation(
                            .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                            value: iconPulse
                        )

                    Text("Notifications")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("Your recent focus events & nudges.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.62))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            HStack(spacing: 8) {
                if !manager.notifications.isEmpty {
                    Button {
                        simpleTap()
                        withAnimation { manager.markAllAsRead() }
                    } label: {
                        Image(systemName: "checklist")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.10))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Button {
                        simpleTap()
                        showingClearAllConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.10))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    simpleTap()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(width: 64, height: 64)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
                .overlay(
                    Image(systemName: "bell.slash.fill")
                        .imageScale(.large)
                        .foregroundColor(.white.opacity(0.9))
                )

            Text("You’re all caught up")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text("As you complete sessions, hit milestones and build streaks, they’ll show up here.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.62))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 44)
    }

    // MARK: - Row

    private func notificationRow(
        _ notification: FocusNotification,
        accentPrimary: Color,
        accentSecondary: Color
    ) -> some View {
        let isRead = notification.isRead

        let baseColor: Color = {
            switch notification.kind {
            case .sessionCompleted: return accentPrimary
            case .streak:          return accentSecondary
            case .habit:           return accentPrimary
            case .general:         return accentSecondary
            }
        }()

        let titleColor: Color = isRead ? .white.opacity(0.78) : .white
        let bodyColor: Color = isRead ? .white.opacity(0.60) : .white.opacity(0.92)
        let timeColor: Color = isRead ? .white.opacity(0.45) : .white.opacity(0.70)
        let iconOpacity: Double = isRead ? 0.65 : 1.0

        // Match new theme (less milky)
        let cardBackgroundOpacity: Double = isRead ? 0.04 : 0.06
        let strokeOpacity: Double = isRead ? 0.08 : 0.10

        return HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(baseColor.opacity(0.16))
                    .frame(width: 34, height: 34)

                Image(systemName: notification.iconName)
                    .foregroundColor(baseColor.opacity(iconOpacity))
                    .imageScale(.medium)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 6) {
                    Text(notification.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(titleColor)
                        .lineLimit(2)

                    if !isRead {
                        Circle()
                            .fill(accentPrimary)
                            .frame(width: 6, height: 6)
                    }

                    Spacer()

                    Text(notification.relativeDateString)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(timeColor)
                }

                Text(notification.body)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(bodyColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(cardBackgroundOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
                )
        )
    }

    // MARK: - Haptics

    private func simpleTap() {
        Haptics.impact(.medium)
    }
}

#Preview {
    NotificationCenterView()
}
