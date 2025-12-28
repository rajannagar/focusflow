//
//  OnboardingManager.swift
//  FocusFlow
//
//  Manages onboarding state and user preferences during onboarding.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Onboarding Data

struct OnboardingData {
    var displayName: String = ""
    var dailyGoalMinutes: Int = 60
    var selectedTheme: AppTheme = .forest
}

// MARK: - Onboarding Manager

@MainActor
final class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    // MARK: - Keys
    
    private enum Keys {
        static let hasCompletedOnboarding = "ff_hasCompletedOnboarding"
        static let onboardingVersion = "ff_onboardingVersion"
    }
    
    /// Current onboarding version - increment to show onboarding again for major updates
    private let currentOnboardingVersion = 1
    
    // MARK: - Published State
    
    @Published var hasCompletedOnboarding: Bool = false
    @Published var currentPage: Int = 0
    @Published var onboardingData = OnboardingData()
    
    // MARK: - Constants
    
    let totalPages = 6
    
    // MARK: - Goal Options
    
    let goalOptions: [Int] = [15, 30, 45, 60, 90, 120]
    
    // MARK: - Init
    
    private init() {
        loadOnboardingState()
    }
    
    // MARK: - State Management
    
    private func loadOnboardingState() {
        let defaults = UserDefaults.standard
        
        // Check if onboarding was completed
        let completed = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        let savedVersion = defaults.integer(forKey: Keys.onboardingVersion)
        
        // Show onboarding if never completed OR if we have a new version
        if completed && savedVersion >= currentOnboardingVersion {
            hasCompletedOnboarding = true
        } else {
            hasCompletedOnboarding = false
        }
        
        // Load default theme from AppSettings if available
        onboardingData.selectedTheme = AppSettings.shared.selectedTheme
    }
    
    // MARK: - Navigation
    
    func nextPage() {
        if currentPage < totalPages - 1 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentPage += 1
            }
            Haptics.impact(.light)
        }
    }
    
    func previousPage() {
        if currentPage > 0 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentPage -= 1
            }
            Haptics.impact(.light)
        }
    }
    
    func goToPage(_ page: Int) {
        guard page >= 0 && page < totalPages else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentPage = page
        }
        Haptics.impact(.light)
    }
    
    // MARK: - Theme Selection
    
    func selectTheme(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.5)) {
            onboardingData.selectedTheme = theme
        }
        Haptics.impact(.medium)
    }
    
    // MARK: - Goal Selection
    
    func selectGoal(_ minutes: Int) {
        onboardingData.dailyGoalMinutes = minutes
        Haptics.impact(.light)
    }
    
    // MARK: - Completion
    
    func completeOnboarding() {
        // Save user preferences to AppSettings
        let settings = AppSettings.shared
        
        // Save display name if provided
        let trimmedName = onboardingData.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            settings.displayName = trimmedName
        }
        
        // Save theme
        settings.selectedTheme = onboardingData.selectedTheme
        settings.profileTheme = onboardingData.selectedTheme
        
        // Save daily goal
        settings.dailyGoalMinutes = onboardingData.dailyGoalMinutes
        
        // Mark onboarding as completed
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: Keys.hasCompletedOnboarding)
        defaults.set(currentOnboardingVersion, forKey: Keys.onboardingVersion)
        
        // Update state
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
        
        Haptics.notification(.success)
        
        #if DEBUG
        print("[OnboardingManager] Onboarding completed!")
        print("  - Name: \(trimmedName.isEmpty ? "(default)" : trimmedName)")
        print("  - Theme: \(onboardingData.selectedTheme.displayName)")
        print("  - Goal: \(onboardingData.dailyGoalMinutes) minutes")
        #endif
    }
    
    func skipOnboarding() {
        // Mark as completed without saving preferences
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: Keys.hasCompletedOnboarding)
        defaults.set(currentOnboardingVersion, forKey: Keys.onboardingVersion)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
        
        Haptics.impact(.light)
        
        #if DEBUG
        print("[OnboardingManager] Onboarding skipped")
        #endif
    }
    
    // MARK: - Reset (for testing)
    
    #if DEBUG
    func resetOnboarding() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Keys.hasCompletedOnboarding)
        defaults.removeObject(forKey: Keys.onboardingVersion)
        
        hasCompletedOnboarding = false
        currentPage = 0
        onboardingData = OnboardingData()
        
        print("[OnboardingManager] Onboarding reset for testing")
    }
    #endif
}
