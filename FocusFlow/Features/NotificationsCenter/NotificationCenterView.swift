import SwiftUI

struct NotificationCenterView: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var manager = NotificationCenterManager.shared

    @State private var showingClearAllConfirm = false
    @State private var iconPulse = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let theme = appSettings.selectedTheme
            let accentPrimary = theme.accentPrimary
            let accentSecondary = theme.accentSecondary

            ZStack {
                // Background gradient – match Focus / Habits / Stats / Profile
                LinearGradient(
                    gradient: Gradient(colors: theme.backgroundColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Soft halo blobs
                Circle()
                    .fill(accentPrimary.opacity(0.5))
                    .blur(radius: 90)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: -size.width * 0.45, y: -size.height * 0.55)

                Circle()
                    .fill(accentSecondary.opacity(0.35))
                    .blur(radius: 100)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: size.width * 0.45, y: size.height * 0.5)

                VStack(spacing: 16) {
                    header(accentPrimary: accentPrimary, accentSecondary: accentSecondary)
                        .padding(.horizontal, 22)
                        .padding(.top, 18)

                    if manager.notifications.isEmpty {
                        emptyState
                            .padding(.horizontal, 22)
                            .padding(.top, 8)
                    } else {
                        // Main list
                        List {
                            ForEach(manager.notifications) { notification in
                                notificationRow(
                                    notification,
                                    accentPrimary: accentPrimary,
                                    accentSecondary: accentSecondary
                                )
                                .listRowInsets(
                                    EdgeInsets(top: 4, leading: 22, bottom: 12, trailing: 22)
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .onTapGesture {
                                    simpleTap()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        manager.markAsRead(notification)
                                    }
                                }
                                // Swipe LEFT → delete
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        simpleTap()
                                        withAnimation {
                                            manager.delete(notification)
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                                // Swipe RIGHT → mark unread
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    if notification.isRead {
                                        Button {
                                            simpleTap()
                                            withAnimation {
                                                manager.markAsUnread(notification)
                                            }
                                        } label: {
                                            Image(systemName: "circle.fill")
                                        }
                                        .tint(accentPrimary)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }

                    Spacer(minLength: 24)
                }
            }
            .onAppear {
                iconPulse = true
            }
        }
        .alert("Clear all notifications?", isPresented: $showingClearAllConfirm) {
            Button("Clear all", role: .destructive) {
                simpleTap()
                withAnimation {
                    manager.clearAll()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove all notifications from your focus history.")
        }
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
                            .easeInOut(duration: 2.4)
                                .repeatForever(autoreverses: true),
                            value: iconPulse
                        )

                    Text("Notifications")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("Your recent focus events & nudges.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }

            Spacer()

            if !manager.notifications.isEmpty {
                HStack(spacing: 8) {
                    Button {
                        simpleTap()
                        withAnimation {
                            manager.markAllAsRead()
                        }
                    } label: {
                        Text("Mark all read")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.16))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        simpleTap()
                        showingClearAllConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .imageScale(.small)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(accentSecondary.opacity(0.30))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "bell.slash.fill")
                        .imageScale(.large)
                        .foregroundColor(.white)
                )

            Text("You’re all caught up")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text("As you complete sessions, hit milestones and build streaks, they’ll show up here.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 40)
    }

    // MARK: - Row

    private func notificationRow(
        _ notification: FocusNotification,
        accentPrimary: Color,
        accentSecondary: Color
    ) -> some View {
        let isRead = notification.isRead

        // Theme-driven accent per type
        let baseColor: Color = {
            switch notification.kind {
            case .sessionCompleted: return accentPrimary
            case .streak:          return accentSecondary
            case .habit:           return accentPrimary
            case .general:         return accentSecondary
            }
        }()

        // Read vs unread styling
        let titleColor: Color = isRead ? .white.opacity(0.75) : .white
        let bodyColor: Color = isRead ? .white.opacity(0.6) : .white.opacity(0.92)
        let timeColor: Color = isRead ? .white.opacity(0.45) : .white.opacity(0.75)
        let iconOpacity: Double = isRead ? 0.6 : 1.0
        let cardBackgroundOpacity: Double = isRead ? 0.10 : 0.22
        let strokeOpacity: Double = isRead ? 0.06 : 0.14

        return HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(baseColor.opacity(0.20))
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
                    .font(.system(size: 13))
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
