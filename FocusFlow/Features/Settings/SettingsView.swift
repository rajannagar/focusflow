// =========================================================
// SettingsView.swift
// =========================================================

import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var tasksStore = TasksStore.shared
    @ObservedObject private var syncCoordinator = SyncCoordinator.shared
    @ObservedObject private var authManager = AuthManagerV2.shared
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @EnvironmentObject private var pro: ProEntitlementManager
    @ObservedObject private var appSettings = AppSettings.shared

    @State private var showingReset = false
    @State private var resetText = ""
    @State private var showingPaywall = false
    @State private var paywallContext: PaywallContext = .general
    @State private var showingNotificationSettings = false
    @State private var showingRestore = false
    @State private var resetError: String?
    @State private var isCreatingBackup = false
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    @State private var showingDeleteAccount = false
    @ObservedObject private var backupManager = DataBackupManager.shared
    @State private var isSigningOut = false
    @State private var isExportingData = false

    private var theme: AppTheme { appSettings.profileTheme }

    var body: some View {
        ZStack {
            PremiumAppBackground(theme: theme, showParticles: false)
            
            VStack(spacing: 0) {
                header
                settingsContent
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingReset) {
            ResetConfirmationSheet(
                resetText: $resetText,
                isCreatingBackup: $isCreatingBackup,
                resetError: $resetError,
                backupManager: backupManager,
                onBackupAndReset: {
                    Task {
                        await performResetWithBackup()
                    }
                },
                onResetWithoutBackup: {
                    performReset()
                },
                onCancel: {
                    resetText = ""
                    resetError = nil
                    showingReset = false
                }
            )
        }
        .alert("Restore Backup", isPresented: $showingRestore) {
            Button("Cancel", role: .cancel) { }
            Button("Restore", role: .destructive) {
                Task {
                    await restoreBackup()
                }
            }
        } message: {
            if let age = backupManager.backupAgeString() {
                Text("This will replace all current data with the backup from \(age). Current data will be lost.")
            } else {
                Text("This will replace all current data with the backup. Current data will be lost.")
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(context: paywallContext).environmentObject(pro)
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
                    .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showingDeleteAccount) {
            DeleteAccountConfirmationSheet(
                onDelete: {
                    Task {
                        await deleteAccount()
                    }
                },
                onCancel: {
                    showingDeleteAccount = false
                }
            )
        }
    }
    
    private func deleteAccount() async {
        do {
            try await authManager.deleteAccount()
            Haptics.impact(.heavy)
            // Navigation will handle dismissal automatically after account deletion
        } catch {
            resetError = error.localizedDescription
        }
    }

    // MARK: - Header
    
    private var header: some View {
        HStack {
            Button {
                Haptics.impact(.light)
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text("Settings")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Invisible spacer to balance the back button
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                Text("Back")
                    .font(.system(size: 16, weight: .medium))
            }
            .opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    private var settingsContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                themeSection
                feedbackSection
                notificationsSection
                subscriptionSection
                // ✅ Sync section only shown for signed-in users
                // Guest mode is local-only, so sync doesn't apply
                if authManager.state.isSignedIn {
                    syncSection
                }
                dataSection
                if authManager.state.isSignedIn {
                    accountSection
                }
                aboutSection
            }
            .padding(20)
        }
    }
    
    private var accountSection: some View {
        SettingsSectionView(title: "ACCOUNT") {
            VStack(spacing: 12) {
                // Account info
                if let email = AppSettings.shared.accountEmail, !email.isEmpty {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 14))
                                .foregroundColor(theme.accentPrimary.opacity(0.8))
                            Text(email)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Sign Out Button
                Button {
                    Haptics.impact(.medium)
                    signOut()
                } label: {
                    HStack {
                        HStack(spacing: 8) {
                            if isSigningOut {
                                ProgressView()
                                    .tint(.white.opacity(0.7))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Text("Sign Out")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                    }
                }
                .disabled(isSigningOut)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Delete Account Button
                Button {
                    Haptics.impact(.light)
                    showingDeleteAccount = true
                } label: {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.minus")
                                .font(.system(size: 14))
                                .foregroundColor(.red.opacity(0.9))
                            Text("Delete Account")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red.opacity(0.9))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red.opacity(0.5))
                    }
                }
            }
        }
    }
    
    private func signOut() {
        guard !isSigningOut else { return }
        isSigningOut = true
        Task {
            await authManager.signOut()
            await MainActor.run {
                isSigningOut = false
                // Navigation will handle dismissal automatically after sign out
            }
        }
    }

    private var themeSection: some View {
        SettingsSectionView(title: "THEME") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(AppTheme.allCases) { t in
                        themeButton(for: t)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
        }
    }

    private func themeButton(for t: AppTheme) -> some View {
        let isLocked = ProGatingHelper.shared.isThemeLocked(t)
        let isSelected = settings.profileTheme == t
        
        return Button {
            Haptics.impact(.light)
            if isLocked {
                paywallContext = .theme
                showingPaywall = true
            } else {
                settings.setThemeWithSync(t)
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [t.accentPrimary, t.accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                                .frame(width: 48, height: 48)
                        )
                        .scaleEffect(isSelected ? 1.0 : 0.92)
                        .animation(.easeInOut(duration: 0.15), value: isSelected)
                    
                    // Premium lock overlay
                    if isLocked {
                        ZStack {
                            // Gradient overlay
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.black.opacity(0.6),
                                            Color.black.opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                            
                            // PRO badge
                            VStack(spacing: 2) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text("PRO")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.white)
                                    .tracking(0.5)
                            }
                        }
                    }
                }

                Text(t.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(t.displayName) theme\(isSelected ? ", selected" : "")\(isLocked ? ", requires Pro upgrade" : "")")
        .accessibilityHint(isLocked ? "Upgrade to Pro to use this theme" : (isSelected ? "Currently active theme" : "Tap to apply this theme"))
    }

    private var feedbackSection: some View {
        SettingsSectionView(title: "PREFERENCES") {
            Toggle("Focus Sounds", isOn: $settings.soundEnabled).tint(theme.accentPrimary)
            Toggle("Haptics", isOn: $settings.hapticsEnabled).tint(theme.accentPrimary)
        }
    }

    private var notificationsSection: some View {
        SettingsSectionView(title: "NOTIFICATIONS") {
            Button {
                Haptics.impact(.light)
                showingNotificationSettings = true
            } label: {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 14))
                            .foregroundColor(theme.accentPrimary)

                        Text("Manage Notifications")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
    }

    private var subscriptionSection: some View {
        SettingsSectionView(title: "SUBSCRIPTION") {
            Button { showingPaywall = true } label: {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill").foregroundColor(.yellow)
                        Text("FocusFlow Pro")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text(pro.isPro ? "Active" : "Subscribe")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(pro.isPro ? .green : theme.accentPrimary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
    }

    private var syncSection: some View {
        SettingsSectionView(title: "SYNC") {
            VStack(spacing: 12) {
                // ✅ Only show sync section for SignedIn users (not guests)
                // Guest mode is local-only by design, so sync doesn't apply
                // Show different states based on Pro status for signed-in users
                let syncStatus = ProGatingHelper.shared.cloudSyncStatus
                
                switch syncStatus {
                case .active:
                    // Pro + SignedIn: Show active sync status
                    syncActiveView
                    
                case .needsUpgrade:
                    // Free + SignedIn: Show upgrade prompt
                    syncNeedsUpgradeView
                    
                case .needsSignIn:
                    // Note: This case won't appear since sync section only shows for SignedIn users
                    // Guest mode is local-only by design, so sync section is hidden for guests
                    // Fallback to upgrade view (shouldn't happen)
                    syncNeedsUpgradeView
                }
            }
        }
    }
    
    // MARK: - Sync Status Views
    
    private var syncActiveView: some View {
        VStack(spacing: 12) {
            // Network status indicator
            if networkMonitor.isOffline {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                    
                    Text("Offline - No internet connection")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red.opacity(0.9))
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
            }
            
            // Sync status
            HStack {
                HStack(spacing: 8) {
                    if syncCoordinator.isSyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(theme.accentPrimary)
                    } else if syncCoordinator.syncError != nil {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                    } else {
                        Image(systemName: "checkmark.icloud.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                    }
                    
                    Text("☁️ Cloud Sync: Active")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            
            // Error message if present
            if let error = syncCoordinator.syncError {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange.opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(networkMonitor.isOffline ? "Sync requires internet connection" : error.localizedDescription)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        if networkMonitor.isOffline {
                            Text("Connect to Wi-Fi or cellular data to sync")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
            }
            
            // Sync Now button
            Button {
                Haptics.impact(.medium)
                Task {
                    await syncCoordinator.syncNow()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Sync Now")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(syncCoordinator.isSyncing || networkMonitor.isOffline)
            .opacity((syncCoordinator.isSyncing || networkMonitor.isOffline) ? 0.6 : 1.0)
        }
    }
    
    private var syncNeedsSignInView: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                    
                    Text("☁️ Sign in to sync")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            
            Button {
                Haptics.impact(.medium)
                authManager.exitGuest()
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle.fill.badge.checkmark")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Sign In")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
    
    private var syncNeedsUpgradeView: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "icloud.slash")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Text("☁️ Upgrade for sync")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            
            Button {
                Haptics.impact(.medium)
                showingPaywall = true
                paywallContext = .cloudSync
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Upgrade")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
    
    private var dataSection: some View {
        SettingsSectionView(title: "DATA") {
            // Export My Data (GDPR)
            Button { exportMyData() } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Export My Data")
                            .foregroundColor(.white)
                            .font(.system(size: 15, weight: .medium))
                        Text("Download all your data as JSON")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 12, weight: .regular))
                    }
                    Spacer()
                    if isExportingData {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white.opacity(0.6))
                    } else {
                        Image(systemName: "arrow.down.doc.fill")
                            .foregroundColor(theme.accentPrimary.opacity(0.8))
                    }
                }
            }
            .disabled(isExportingData)
            
            if backupManager.hasBackup {
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.vertical, 4)
                
                Button { showingRestore = true } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Restore Backup")
                                .foregroundColor(.white)
                                .font(.system(size: 15, weight: .medium))
                            if let age = backupManager.backupAgeString() {
                                Text(age)
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.system(size: 12, weight: .regular))
                            }
                        }
                        Spacer()
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(.green.opacity(0.8))
                    }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, 4)
            
            Button { showingReset = true } label: {
                HStack {
                    Text("Reset All Data").foregroundColor(.red)
                    Spacer()
                    Image(systemName: "exclamationmark.triangle").foregroundColor(.red.opacity(0.6))
                }
            }
        }
    }
    
    private func exportMyData() {
        isExportingData = true
        
        Task {
            do {
                // Create fresh backup with all current data
                try backupManager.createBackup()
                let url = try backupManager.getBackupFileURL()
                
                await MainActor.run {
                    isExportingData = false
                    shareURL = url
                    showingShareSheet = true
                }
            } catch {
                await MainActor.run {
                    isExportingData = false
                    resetError = "Failed to export data: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Reset & Restore Functions
    
    private func performResetWithBackup() async {
        isCreatingBackup = true
        resetError = nil
        
        do {
            // Create backup before reset
            try backupManager.createBackup()
            
            // Small delay to show backup message
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Perform reset
            performReset()
            
            resetText = ""
            isCreatingBackup = false
            showingReset = false
        } catch {
            resetError = "Failed to create backup: \(error.localizedDescription)"
            isCreatingBackup = false
        }
    }
    
    private func performReset() {
        Haptics.impact(.medium)
        progressStore.clearAll()
        tasksStore.clearAll()
        // Clear goal history
        UserDefaults.standard.removeObject(forKey: "focusflow.pv2.dailyGoalHistory.v1")
        AppSyncManager.shared.forceRefresh()
        resetText = ""
        showingReset = false
    }
    
    private func restoreBackup() async {
        do {
            try backupManager.restoreBackup()
            Haptics.impact(.medium)
            showingRestore = false
        } catch {
            resetError = "Failed to restore: \(error.localizedDescription)"
            // Show error in an alert
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showingRestore = false
            }
        }
    }
    
    private func shareBackup() {
        Haptics.impact(.light)
        do {
            let url = try backupManager.getBackupFileURL()
            shareURL = url
            showingShareSheet = true
        } catch {
            resetError = "Failed to access backup: \(error.localizedDescription)"
        }
    }

    private var aboutSection: some View {
        SettingsSectionView(title: "ABOUT") {
            Link(destination: URL(string: "https://rajannagar.github.io/FocusFlow/privacy.html")!) {
                HStack {
                    Text("Privacy Policy").foregroundColor(.white)
                    Spacer()
                    Image(systemName: "arrow.up.right").foregroundColor(.white.opacity(0.3))
                }
            }
            Link(destination: URL(string: "https://rajannagar.github.io/FocusFlow/terms.html")!) {
                HStack {
                    Text("Terms of Service").foregroundColor(.white)
                    Spacer()
                    Image(systemName: "arrow.up.right").foregroundColor(.white.opacity(0.3))
                }
            }
            
            // Version info
            HStack {
                Text("Version")
                    .foregroundColor(.white)
                Spacer()
                Text(appVersion)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
    
    /// App version from Info.plist
    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Settings Section View

struct SettingsSectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)

            VStack(spacing: 12) {
                content()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(12)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Reset Confirmation Sheet

struct ResetConfirmationSheet: View {
    @Binding var resetText: String
    @Binding var isCreatingBackup: Bool
    @Binding var resetError: String?
    @ObservedObject var backupManager: DataBackupManager
    let onBackupAndReset: () -> Void
    let onResetWithoutBackup: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    private let theme = AppSettings.shared.profileTheme
    private var isResetEnabled: Bool {
        resetText.uppercased() == "RESET"
    }
    
    var body: some View {
        ZStack {
            PremiumAppBackground(theme: theme, showParticles: false)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button {
                        Haptics.impact(.light)
                        onCancel()
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
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Warning Icon
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(.red.opacity(0.9))
                        }
                        .padding(.top, 8)
                        
                        // Title
                        Text("Reset All Data")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Warning Message
                        VStack(alignment: .leading, spacing: 12) {
                            Text("This will PERMANENTLY delete:")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                DataLossRow(icon: "flame.fill", text: "All focus sessions")
                                DataLossRow(icon: "checkmark.circle.fill", text: "All tasks and completions")
                                DataLossRow(icon: "scope", text: "All goals and progress")
                                DataLossRow(icon: "xmark.circle.fill", text: "This action CANNOT be undone")
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Backup Info or Tip
                        if isCreatingBackup {
                            HStack(spacing: 12) {
                                ProgressView()
                                    .tint(.blue)
                                Text("Creating backup...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue.opacity(0.9))
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                        } else if backupManager.hasBackup {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green.opacity(0.9))
                                    .font(.system(size: 16))
                                VStack(alignment: .leading, spacing: 2) {
                                    if let age = backupManager.backupAgeString() {
                                        Text(age)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    if let daysLeft = backupManager.daysUntilExpiration() {
                                        Text("Restore available for \(daysLeft) more days")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                        } else {
                            HStack(spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow.opacity(0.9))
                                    .font(.system(size: 16))
                                Text("Tip: Use 'Backup & Reset' to create a backup first (7-day restore window)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.yellow.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                        }
                        
                        // Error Message
                        if let error = resetError {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red.opacity(0.9))
                                    .font(.system(size: 16))
                                Text(error)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.red.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                        }
                        
                        // Confirmation Text Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type RESET to confirm")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextField("", text: $resetText)
                                .focused($isTextFieldFocused)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isResetEnabled ? Color.red.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1.5)
                                )
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        isTextFieldFocused = true
                                    }
                                }
                        }
                        .padding(.horizontal, 20)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            // Backup & Reset Button
                            Button {
                                Haptics.impact(.medium)
                                onBackupAndReset()
                            } label: {
                                HStack {
                                    if isCreatingBackup {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "square.and.arrow.down.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    Text(isCreatingBackup ? "Creating Backup..." : "Backup & Reset")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: isResetEnabled && !isCreatingBackup ? [Color.blue, Color.blue.opacity(0.8)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(!isResetEnabled || isCreatingBackup)
                            
                            // Reset Without Backup Button
                            Button {
                                Haptics.impact(.medium)
                                onResetWithoutBackup()
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Reset Without Backup")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: isResetEnabled ? [Color.red.opacity(0.8), Color.red.opacity(0.6)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(!isResetEnabled)
                            
                            // Cancel Button
                            Button {
                                Haptics.impact(.light)
                                onCancel()
                                dismiss()
                            } label: {
                                Text("Cancel")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Delete Account Confirmation Sheet

struct DeleteAccountConfirmationSheet: View {
    let onDelete: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var confirmText = ""
    @State private var isDeleting = false
    @State private var deleteError: String?
    @FocusState private var isTextFieldFocused: Bool
    
    private let theme = AppSettings.shared.profileTheme
    private var isDeleteEnabled: Bool {
        confirmText.uppercased() == "DELETE"
    }
    
    var body: some View {
        ZStack {
            PremiumAppBackground(theme: theme, showParticles: false)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button {
                        Haptics.impact(.light)
                        onCancel()
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
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Warning Icon
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "person.crop.circle.badge.xmark")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(.red.opacity(0.9))
                        }
                        .padding(.top, 8)
                        
                        // Title
                        Text("Delete Account")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Warning Message
                        VStack(alignment: .leading, spacing: 12) {
                            Text("This will PERMANENTLY delete:")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                DataLossRow(icon: "person.circle.fill", text: "Your FocusFlow account")
                                DataLossRow(icon: "flame.fill", text: "All focus sessions & stats")
                                DataLossRow(icon: "checkmark.circle.fill", text: "All tasks and completions")
                                DataLossRow(icon: "slider.horizontal.3", text: "All presets and settings")
                                DataLossRow(icon: "icloud.slash.fill", text: "All cloud synced data")
                                DataLossRow(icon: "xmark.circle.fill", text: "This action CANNOT be undone")
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Pro subscription warning
                        HStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow.opacity(0.9))
                                .font(.system(size: 16))
                            Text("If you have an active Pro subscription, you'll need to cancel it separately in your Apple ID settings.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.yellow.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                        
                        // Error Message
                        if let error = deleteError {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red.opacity(0.9))
                                    .font(.system(size: 16))
                                Text(error)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.red.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                        }
                        
                        // Confirmation Text Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type DELETE to confirm")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextField("", text: $confirmText)
                                .focused($isTextFieldFocused)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isDeleteEnabled ? Color.red.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1.5)
                                )
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        isTextFieldFocused = true
                                    }
                                }
                        }
                        .padding(.horizontal, 20)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            // Delete Account Button
                            Button {
                                Haptics.impact(.heavy)
                                isDeleting = true
                                onDelete()
                            } label: {
                                HStack {
                                    if isDeleting {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    Text(isDeleting ? "Deleting Account..." : "Delete My Account")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: isDeleteEnabled && !isDeleting ? [Color.red.opacity(0.9), Color.red.opacity(0.7)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(!isDeleteEnabled || isDeleting)
                            
                            // Cancel Button
                            Button {
                                Haptics.impact(.light)
                                onCancel()
                                dismiss()
                            } label: {
                                Text("Cancel")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Data Loss Row

struct DataLossRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.red.opacity(0.8))
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

