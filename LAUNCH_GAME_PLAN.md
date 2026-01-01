# FocusFlow Launch Game Plan
**Version:** 1.0  
**Date:** December 29, 2024  
**Status:** Ready for Review

---

## Executive Summary

This plan addresses **critical blockers**, **App Store readiness**, and **quality improvements** to get FocusFlow ready for launch. The audit findings are accurate—we have a solid foundation but need to complete key features and polish before submission.

**Estimated Timeline:** 3-4 weeks to launch-ready state

---

## 🚨 CRITICAL BLOCKERS (Week 1 - Must Fix)

### 1. Wire Guest → Account Migration ⚠️ **HIGHEST PRIORITY**

**Status:** `DataMigrationSheet` exists but is never shown  
**Impact:** Users who start as guest and then sign in will lose their data  
**Risk:** Data loss = 1-star reviews

**Implementation:**
- [ ] Add migration check in `ContentView` when auth state changes from `.guest` to `.signedIn`
- [ ] Show `DataMigrationSheet` immediately after successful sign-in if guest data exists
- [ ] Test flow: Guest creates data → Sign in → Migration sheet appears → Data migrates
- [ ] Handle edge case: User dismisses migration sheet (should still allow sign-in)

**Files to modify:**
- `FocusFlow/App/ContentView.swift` - Add migration trigger
- `FocusFlow/Features/Auth/DataMigrationSheet.swift` - Already complete, just needs wiring

**Code location:**
```swift
// In ContentView, after auth state changes to .signedIn:
.onChange(of: authManager.state) { oldState, newState in
    if case .guest = oldState,
       case .signedIn = newState,
       GuestMigrationManager.shared.hasGuestData() {
        // Show migration sheet
    }
}
```

---

### 2. Implement Real Pro Gating ⚠️ **CRITICAL FOR MONETIZATION**

**Status:** `ProEntitlementManager` exists, but almost nothing is gated  
**Impact:** No revenue = no sustainable business  
**Risk:** Users won't upgrade if everything is free

**Implementation Plan:**

#### 2a. Cloud Sync Gating (Highest Value)
- [ ] Modify `SyncCoordinator.startAllEngines()` to check `ProEntitlementManager.shared.isPro`
- [ ] Only start sync engines if user is Pro OR guest (guest = local-only, no sync)
- [ ] Show "Upgrade to Pro for cloud sync" message in Profile when signed in but not Pro
- [ ] Disable sync queue processing for non-Pro users

**Files:**
- `FocusFlow/Infrastructure/Cloud/SyncCoordinator.swift`
- `FocusFlow/Features/Profile/ProfileView.swift` (add sync status with upgrade prompt)

#### 2b. Preset Limits
- [ ] Add preset limit check in `FocusPresetStore.upsert()`
- [ ] Free: Max 3 custom presets (exclude default presets)
- [ ] Pro: Unlimited
- [ ] Show upgrade prompt when limit reached

**Files:**
- `FocusFlow/Features/Presets/FocusPresetStore.swift`
- `FocusFlow/Features/Presets/FocusPresetEditorView.swift` (show limit message)

#### 2c. Theme Limits
- [ ] Check Pro status in theme picker
- [ ] Free: 2-3 themes available
- [ ] Pro: All themes
- [ ] Show lock icon on Pro themes

**Files:**
- `FocusFlow/Features/Profile/ProfileView.swift` (theme selection)
- `FocusFlow/Core/AppSettings/AppSettings.swift` (theme enum)

#### 2d. Widgets & Live Activities
- [ ] Gate widget updates behind Pro check
- [ ] Free: Widget shows basic info (read-only)
- [ ] Pro: Full widget + Live Activity controls
- [ ] Show upgrade prompt when non-Pro user tries to use widget controls

**Files:**
- `FocusFlow/Shared/WidgetDataManager.swift`
- `FocusFlow/Features/Focus/FocusLiveActivityManager.swift`
- `FocusFlowWidgets/FocusFlowWidget.swift`

#### 2e. Journey/Deep History
- [ ] Limit Progress view history to last 7 days for free users
- [ ] Pro: Full history
- [ ] Show "View full history with Pro" message

**Files:**
- `FocusFlow/Features/Progress/ProgressViewV2.swift`
- `FocusFlow/Features/Journey/Journeyview.swift`

**Pro Gating Helper:**
Create a reusable view modifier:
```swift
extension View {
    func requiresPro(showPaywall: Binding<Bool>) -> some View {
        // Check ProEntitlementManager and show paywall if needed
    }
}
```

---

### 3. Remove Dead Code ⚠️ **APP STORE CLEANUP**

**Status:** Unused surfaces exist but aren't referenced  
**Impact:** Confusion, potential crashes if accidentally accessed  
**Risk:** App Store rejection if debug code is visible

**Tasks:**
- [ ] Remove or hide `DebugLogView.swift` (not referenced anywhere)
- [ ] If keeping for development, wrap in `#if DEBUG` or remove from production builds
- [ ] Search for any other unused views/components

**Files:**
- `FocusFlow/Features/Focus/DebugLogView.swift` - Remove or conditionally compile

---

### 4. Sync Multi-Device Testing ⚠️ **CRITICAL FOR RELIABILITY**

**Status:** Sync is implemented but needs stress testing  
**Impact:** Data loss/corruption if sync fails  
**Risk:** User frustration, support burden

**Test Checklist:**
- [ ] Two devices, same account, offline edits → sync when online
- [ ] Edit same task on two devices simultaneously
- [ ] Complete task on device A, delete on device B → conflict resolution
- [ ] Create preset on device A, delete on device B → conflict resolution
- [ ] Sign out on device A, sign in on device B → data persists
- [ ] Network interruption during sync → queue processes correctly

**Documentation:**
- [ ] Create `SYNC_TESTING_CHECKLIST.md` with test scenarios
- [ ] Document expected behavior for conflicts

---

## 🎨 POLISH & UX (Week 2)

### 5. Refactor Mega-Views (Technical Debt)

**Status:** 4 files are 1500+ lines (hard to maintain)  
**Impact:** Slower development, harder to polish, potential bugs  
**Risk:** Technical debt compounds over time

**Priority Order:**
1. **ProfileView.swift** (3131 lines) - Highest priority
2. **ProgressViewV2.swift** (1978 lines)
3. **TasksView.swift** (1954 lines)
4. **FocusView.swift** (1774 lines)

**Refactoring Strategy:**
- Extract sections into separate `View` components
- Move business logic to `ViewModel` classes
- Create reusable UI components (cards, headers, buttons)

**Example Structure:**
```
ProfileView.swift (main coordinator, ~200 lines)
├── ProfileHeaderView.swift
├── ProfileStatsView.swift
├── ProfileSettingsSheet.swift
├── ProfileUpgradeCard.swift
└── ProfileViewModel.swift (business logic)
```

**Files to create:**
- `FocusFlow/Features/Profile/ProfileHeaderView.swift`
- `FocusFlow/Features/Profile/ProfileStatsView.swift`
- `FocusFlow/Features/Profile/ProfileSettingsSheet.swift`
- `FocusFlow/Features/Profile/ProfileViewModel.swift`
- Similar structure for other mega-views

**Note:** This is a **polish task**, not a blocker. Can be done incrementally.

---

### 6. Empty States & First-Run Experience

**Status:** Basic empty states exist but could be more engaging  
**Impact:** User confusion, lower engagement  
**Risk:** Users don't understand how to use the app

**Tasks:**
- [ ] Add "First session" guidance after onboarding
- [ ] Improve empty state in Tasks tab (no tasks today)
- [ ] Improve empty state in Progress tab (no sessions yet)
- [ ] Add subtle coach marks for key actions (start focus, create task)
- [ ] Add "Quick Start" button in empty states

**Files:**
- `FocusFlow/Features/Tasks/TasksView.swift` - Empty state
- `FocusFlow/Features/Progress/ProgressViewV2.swift` - Empty state
- `FocusFlow/Features/Focus/FocusView.swift` - First session guidance

---

### 7. Accessibility & Typography Consistency

**Status:** Basic accessibility but needs improvement  
**Impact:** App Store requirements, user inclusivity  
**Risk:** App Store rejection if accessibility is poor

**Tasks:**
- [ ] Add VoiceOver labels to all custom controls
- [ ] Test Dynamic Type support (all text should scale)
- [ ] Check color contrast ratios (WCAG AA minimum)
- [ ] Standardize typography scale (one font system)
- [ ] Add accessibility hints for complex interactions

**Files:**
- All view files - Add `.accessibilityLabel()` and `.accessibilityHint()`
- `FocusFlow/Core/UI/` - Create typography system

---

### 8. Haptics & Feedback Consistency

**Status:** Haptics exist but inconsistent  
**Impact:** User experience polish  
**Risk:** Feels unpolished

**Tasks:**
- [ ] Standardize haptic feedback:
  - Start/Stop focus: `.medium`
  - Complete task: `.light`
  - Error: `.error`
  - Success: `.success`
- [ ] Add haptics to all primary actions
- [ ] Test haptic timing (not too delayed)

**Files:**
- `FocusFlow/Core/Utilities/Haptics.swift` - Already exists, ensure consistent usage
- All view files - Add haptics to button actions

---

## 🧪 TESTING & QUALITY (Week 3)

### 9. Unit Tests for Critical Logic

**Status:** No unit tests currently  
**Impact:** Confidence in edge cases, regression prevention  
**Risk:** Bugs slip through to production

**Priority Tests:**
- [ ] Task repeat/schedule logic (`TaskModels.swift`)
- [ ] Sync merge logic (`TasksSyncEngine.swift`, `SessionsSyncEngine.swift`)
- [ ] Streak calculation (`ProgressStore.swift`)
- [ ] Goal minutes calculation
- [ ] Preset limit enforcement

**Files to create:**
- `FocusFlowTests/` directory (if not exists)
- `TaskRepeatLogicTests.swift`
- `SyncMergeTests.swift`
- `ProgressCalculationTests.swift`

---

### 10. Integration Testing

**Status:** Manual testing only  
**Impact:** Catch integration issues before launch  
**Risk:** Broken flows in production

**Test Scenarios:**
- [ ] Complete onboarding → Create account → First focus session
- [ ] Guest mode → Create data → Sign in → Migration
- [ ] Free user → Hit preset limit → Upgrade → Create preset
- [ ] Two devices → Sync → Verify data consistency
- [ ] Network offline → Make changes → Come online → Sync

---

### 11. Performance Optimization

**Status:** Needs profiling  
**Impact:** Smooth user experience  
**Risk:** Laggy UI, battery drain

**Tasks:**
- [ ] Profile app with Instruments (Time Profiler, Allocations)
- [ ] Optimize heavy backgrounds in ScrollViews (precompute gradients)
- [ ] Reduce SwiftUI view complexity (break down mega-views)
- [ ] Test on older devices (iPhone 12, iPhone 11)
- [ ] Check memory usage (should stay under 100MB for typical use)

---

## 📱 APP STORE READINESS (Week 4)

### 12. App Store Assets

**Status:** Need to prepare  
**Impact:** App Store listing quality  
**Risk:** Lower conversion if assets are poor

**Tasks:**
- [ ] App screenshots (all required sizes)
- [ ] App preview video (optional but recommended)
- [ ] App description (highlight Pro features)
- [ ] Keywords optimization
- [ ] Privacy policy URL (already have `docs/privacy.html`)
- [ ] Support URL

---

### 13. App Store Metadata

**Status:** Need to finalize  
**Impact:** Discoverability and conversion  
**Risk:** Poor discoverability

**Tasks:**
- [ ] App name: "FocusFlow" (or final name)
- [ ] Subtitle: "Focus Timer + Tasks + Progress"
- [ ] Description: Highlight premium design, Live Activities, cloud sync
- [ ] What's New: Launch notes
- [ ] Promotional text (if applicable)
- [ ] Category: Productivity
- [ ] Age rating: 4+ (no objectionable content)

---

### 14. Privacy & Permissions

**Status:** Mostly complete, needs verification  
**Impact:** App Store compliance  
**Risk:** Rejection if privacy info is incorrect

**Tasks:**
- [ ] Verify privacy policy matches actual data collection
- [ ] Document all data collected (Supabase, analytics if any)
- [ ] Ensure notification permission request is clear
- [ ] Test permission denial flows (app should still work)

**Files:**
- `docs/privacy.html` - Verify accuracy
- `FocusFlow/Info.plist` - Check permission descriptions

---

### 15. Final Pre-Launch Checklist

**Status:** To be completed  
**Impact:** Launch quality  
**Risk:** Launch issues if skipped

**Checklist:**
- [ ] All critical blockers resolved
- [ ] Pro gating fully implemented and tested
- [ ] Migration flow tested end-to-end
- [ ] Sync tested on multiple devices
- [ ] No crashes in 24-hour test session
- [ ] App Store assets ready
- [ ] Privacy policy live
- [ ] TestFlight build tested by 5+ beta testers
- [ ] App Store Connect submission ready
- [ ] Marketing materials ready (if applicable)

---

## 📊 PRIORITIZATION MATRIX

### Must Have (Launch Blockers)
1. ✅ Guest → Account Migration
2. ✅ Pro Gating (Cloud Sync + Presets + Themes)
3. ✅ Remove Dead Code
4. ✅ Sync Multi-Device Testing

### Should Have (Quality)
5. Empty States & First-Run Experience
6. Accessibility Pass
7. Unit Tests (Critical Logic)
8. Performance Optimization

### Nice to Have (Post-Launch)
9. Mega-View Refactoring (can be incremental)
10. Advanced Analytics
11. More Widget Variants
12. Calendar Integration

---

## 🎯 SUCCESS METRICS

**Launch Readiness Criteria:**
- [ ] Zero critical bugs
- [ ] Pro gating fully functional
- [ ] Migration flow works 100% of the time
- [ ] Sync works reliably across devices
- [ ] App Store assets complete
- [ ] TestFlight feedback positive (4+ stars)

**Post-Launch Metrics to Track:**
- Conversion rate (Free → Pro)
- Daily active users
- Session completion rate
- Sync reliability (error rate)
- Crash rate (target: <0.1%)

---

## 📅 SUGGESTED TIMELINE

### Week 1: Critical Blockers
- **Days 1-2:** Wire migration flow + test
- **Days 3-5:** Implement Pro gating (all 5 areas)
- **Day 6:** Remove dead code
- **Day 7:** Sync multi-device testing

### Week 2: Polish
- **Days 1-2:** Empty states & first-run
- **Days 3-4:** Accessibility pass
- **Day 5:** Haptics consistency
- **Days 6-7:** Start mega-view refactoring (ProfileView)

### Week 3: Testing
- **Days 1-3:** Unit tests
- **Days 4-5:** Integration testing
- **Days 6-7:** Performance optimization

### Week 4: App Store Prep
- **Days 1-2:** App Store assets
- **Days 3-4:** Metadata & privacy
- **Days 5-6:** Final testing & TestFlight
- **Day 7:** Submit to App Store

---

## 🔧 IMPLEMENTATION NOTES

### Pro Gating Implementation Pattern

```swift
// Example: Preset limit check
func upsert(_ preset: FocusPreset) {
    // Check if adding new preset (not updating existing)
    let isNewPreset = !presets.contains(where: { $0.id == preset.id })
    
    if isNewPreset {
        let customPresets = presets.filter { !$0.isDefault }
        let isPro = ProEntitlementManager.shared.isPro
        
        if !isPro && customPresets.count >= 3 {
            // Show upgrade prompt
            NotificationCenter.default.post(
                name: .showPaywall,
                object: nil,
                userInfo: ["reason": "preset_limit"]
            )
            return
        }
    }
    
    // Continue with upsert...
}
```

### Migration Trigger Pattern

```swift
// In ContentView
.onChange(of: authManager.state) { oldState, newState in
    if case .guest = oldState,
       case .signedIn(let userId) = newState {
        
        // Check if guest has data
        if GuestMigrationManager.shared.hasGuestData() {
            // Show migration sheet
            showMigrationSheet = true
        }
    }
}
.sheet(isPresented: $showMigrationSheet) {
    DataMigrationSheet(theme: AppSettings.shared.theme)
}
```

---

## 🚀 POST-LAUNCH ROADMAP (Future Enhancements)

### Phase 2 (Month 2-3)
- Smart insights ("You focus best at 9am")
- Calendar integration
- Export/Import (CSV)
- Shareable progress cards

### Phase 3 (Month 4-6)
- iPad optimization
- Apple Watch app
- Siri Shortcuts
- Widget variants (more sizes)

---

## 📝 NOTES & ASSUMPTIONS

**Assumptions:**
- Supabase backend is production-ready
- StoreKit configuration is set up correctly
- App Store Connect account is ready

**Risks:**
- Sync complexity may have edge cases we haven't discovered
- Pro gating needs careful UX to not feel restrictive
- Migration flow is critical - must work perfectly

**Dependencies:**
- Supabase tables and RLS policies must be correct
- StoreKit products must be configured in App Store Connect
- Privacy policy must be hosted and accessible

---

## ✅ REVIEW CHECKLIST

Before starting implementation, review:
- [ ] This plan aligns with your vision
- [ ] Timeline is realistic for your schedule
- [ ] Pro feature set is appropriate
- [ ] Migration flow UX is acceptable
- [ ] All priorities are correct

**Next Steps:**
1. Review this plan
2. Adjust priorities if needed
3. Start with Week 1 tasks
4. Track progress in project management tool (or markdown checklist)

---

**Questions or concerns?** Flag any items that need clarification before starting implementation.

