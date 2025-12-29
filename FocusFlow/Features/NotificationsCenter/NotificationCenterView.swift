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

            VStack(spacing: 0) {
                header(accentPrimary: accentPrimary, accentSecondary: accentSecondary)
                    .padding(.horizontal, 18)
                    .padding(.top, 8) // Reduced padding, safe area will add more
                    .padding(.bottom, 14)

                if manager.notifications.isEmpty {
                    emptyState(accentPrimary: accentPrimary)
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                } else {
                    // ✅ Native List with swipe actions (Apple-grade)
                    notificationsList(accentPrimary: accentPrimary, accentSecondary: accentSecondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onAppear { iconPulse = true }
        .alert("Clear all notifications?", isPresented: $showingClearAllConfirm) {
            Button("Clear All", role: .destructive) {
                Haptics.impact(.medium)
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
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentPrimary, accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(iconPulse ? 1.06 : 0.94)
                        .animation(
                            .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                            value: iconPulse
                        )

                    Text("Notifications")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("Your recent focus events & nudges")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            HStack(spacing: 8) {
                if !manager.notifications.isEmpty {
                    // Mark all read button
                    Button {
                        Haptics.impact(.light)
                        withAnimation { manager.markAllAsRead() }
                    } label: {
                        Image(systemName: "checklist")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    // Clear all button
                    Button {
                        Haptics.impact(.light)
                        showingClearAllConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                // Close button
                Button {
                    Haptics.impact(.light)
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Notifications List (Native Swipe Actions)

    private func notificationsList(
        accentPrimary: Color,
        accentSecondary: Color
    ) -> some View {
        List {
            ForEach(manager.notifications) { notification in
                notificationRow(
                    notification,
                    accentPrimary: accentPrimary,
                    accentSecondary: accentSecondary
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
                // ✅ Swipe LEFT to delete (trailing)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Haptics.impact(.medium)
                        withAnimation {
                            manager.delete(notification)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
                // ✅ Swipe RIGHT to toggle read/unread (leading)
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    if notification.isRead {
                        Button {
                            Haptics.impact(.light)
                            withAnimation {
                                manager.markAsUnread(notification)
                            }
                        } label: {
                            Label("Unread", systemImage: "envelope.badge.fill")
                        }
                        .tint(accentSecondary)
                    } else {
                        Button {
                            Haptics.impact(.light)
                            withAnimation {
                                manager.markAsRead(notification)
                            }
                        } label: {
                            Label("Read", systemImage: "envelope.open.fill")
                        }
                        .tint(accentPrimary)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }

    // MARK: - Empty State

    private func emptyState(accentPrimary: Color) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accentPrimary.opacity(0.12))
                    .frame(width: 72, height: 72)
                
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 28))
                    .foregroundColor(accentPrimary.opacity(0.8))
            }

            VStack(spacing: 6) {
                Text("You're all caught up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text("As you complete sessions, hit milestones\nand build streaks, they'll show up here.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 60)
    }

    // MARK: - Notification Row

    private func notificationRow(
        _ notification: FocusNotification,
        accentPrimary: Color,
        accentSecondary: Color
    ) -> some View {
        let isRead = notification.isRead

        let iconColor: Color = {
            switch notification.kind {
            case .sessionCompleted: return accentPrimary
            case .taskCompleted:    return accentSecondary
            case .streak:           return accentSecondary
            case .levelUp:          return accentPrimary
            case .badgeUnlocked:    return accentPrimary
            case .goalUpdated:      return accentSecondary
            case .dailyRecap:       return .purple
            case .general:          return accentSecondary
            }
        }()

        let titleColor: Color = isRead ? .white.opacity(0.65) : .white
        let bodyColor: Color = isRead ? .white.opacity(0.45) : .white.opacity(0.75)
        let timeColor: Color = isRead ? .white.opacity(0.35) : .white.opacity(0.55)
        let iconOpacity: Double = isRead ? 0.5 : 0.85

        // Refined card styling (matches app theme)
        let cardBackgroundOpacity: Double = isRead ? 0.03 : 0.05
        let strokeOpacity: Double = isRead ? 0.06 : 0.08

        return HStack(alignment: .top, spacing: 12) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 38, height: 38)

                Image(systemName: notification.iconName)
                    .foregroundColor(iconColor.opacity(iconOpacity))
                    .font(.system(size: 15, weight: .medium))
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .center, spacing: 6) {
                    Text(notification.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(titleColor)
                        .lineLimit(2)

                    // Unread indicator dot
                    if !isRead {
                        Circle()
                            .fill(accentPrimary)
                            .frame(width: 7, height: 7)
                    }

                    Spacer()

                    Text(notification.relativeDateString)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(timeColor)
                }

                Text(notification.body)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(bodyColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
            }
            
            // Chevron for navigable notifications
            if manager.destination(for: notification.kind) != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.top, 4)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(cardBackgroundOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.impact(.light)
            
            // Check if this notification type has a destination
            let hasDestination = manager.destination(for: notification.kind) != nil
            
            if hasDestination {
                // Dismiss sheet and navigate
                dismiss()
                manager.handleTap(on: notification)
            } else {
                // Just mark as read
                if !notification.isRead {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        manager.markAsRead(notification)
                    }
                }
            }
        }
    }
}

#Preview {
    NotificationCenterView()
}
