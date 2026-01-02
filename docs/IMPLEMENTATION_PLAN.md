# FocusFlow Launch Implementation Plan
**Created:** January 2, 2026  
**Status:** Ready to Execute  
**Estimated Time:** 5-7 days

---

## 📋 Priority Legend

| Priority | Label | Description |
|----------|-------|-------------|
| 🔴 P1 | **CRITICAL** | Launch blocker - must fix before release |
| 🟡 P2 | **HIGH** | Should fix before release |
| 🟢 P3 | **MEDIUM** | Nice to have before release |

---

## 🔴 PRIORITY 1: CRITICAL (Days 1-4)

### P1-0: Update PaywallView.swift
**File:** `FocusFlow/StoreKit/PaywallView.swift`  
**Effort:** 1.5 hours  
**Why:** PaywallView must show correct features & support contextual triggers

**Current Issues:**
- Feature list is generic, doesn't match new Free vs Pro matrix
- No contextual support (same view for all triggers)
- Missing key Pro features (Cloud Sync, Widgets, Live Activity, Journey)

**Changes Required:**

1. **Add PaywallContext enum:**
```swift
enum PaywallContext: String, Identifiable {
    case general
    case sound, theme, ambiance, preset
    case task, reminder
    case history, xpLevels, journey
    case widget, liveActivity
    case externalMusic, cloudSync
    
    var id: String { rawValue }
    
    var headline: String {
        switch self {
        case .general: return "Unlock your full potential"
        case .sound: return "Unlock All Focus Sounds"
        case .theme: return "Unlock All Themes"
        case .ambiance: return "Unlock All Ambient Backgrounds"
        case .preset: return "Create Unlimited Presets"
        case .task: return "Unlock Unlimited Tasks"
        case .reminder: return "Unlock Unlimited Reminders"
        case .history: return "View Your Complete History"
        case .xpLevels: return "Track Your Progress with XP"
        case .journey: return "Discover Your Focus Journey"
        case .widget: return "Unlock Interactive Widgets"
        case .liveActivity: return "Focus from Dynamic Island"
        case .externalMusic: return "Connect Your Music Apps"
        case .cloudSync: return "Sync Across All Devices"
        }
    }
    
    var highlightedFeatureIcon: String {
        switch self {
        case .sound: return "speaker.wave.3.fill"
        case .theme: return "paintpalette.fill"
        case .ambiance: return "sparkles"
        case .preset: return "slider.horizontal.3"
        case .task: return "checklist"
        case .reminder: return "bell.fill"
        case .history: return "calendar"
        case .xpLevels: return "trophy.fill"
        case .journey: return "map.fill"
        case .widget: return "square.grid.2x2.fill"
        case .liveActivity: return "iphone.badge.play"
        case .externalMusic: return "music.note"
        case .cloudSync: return "icloud.fill"
        default: return "crown.fill"
        }
    }
}
```

2. **Add context parameter:**
```swift
struct PaywallView: View {
    var context: PaywallContext = .general
    // ...
}
```

3. **Update proIcon to show contextual headline:**
```swift
Text(context.headline)
    .font(.system(size: 15, weight: .medium))
    .foregroundColor(.white.opacity(0.6))
```

4. **Update featuresSection with complete feature list:**
```swift
private var featuresSection: some View {
    VStack(spacing: 12) {
        featureRow(icon: "speaker.wave.3.fill", title: "11 Focus Sounds", description: "Full ambient sound library")
        featureRow(icon: "sparkles", title: "14 Ambient Backgrounds", description: "Aurora, Rain, Ocean & more")
        featureRow(icon: "paintpalette.fill", title: "10 Themes", description: "Personalize your experience")
        featureRow(icon: "slider.horizontal.3", title: "Unlimited Presets", description: "Create & edit focus modes")
        featureRow(icon: "checklist", title: "Unlimited Tasks", description: "No limits on your to-do list")
        featureRow(icon: "calendar", title: "Full History", description: "View all your past sessions")
        featureRow(icon: "trophy.fill", title: "XP & 50 Levels", description: "Track progress & achievements")
        featureRow(icon: "map.fill", title: "Journey View", description: "Daily & weekly insights")
        featureRow(icon: "square.grid.2x2.fill", title: "All Widgets", description: "Interactive home screen controls")
        featureRow(icon: "iphone.badge.play", title: "Live Activity", description: "Timer in Dynamic Island")
        featureRow(icon: "music.note", title: "Music Apps", description: "Spotify, Apple Music & more")
        featureRow(icon: "icloud.fill", title: "Cloud Sync", description: "Sync across all your devices")
    }
    // ...
}
```

5. **Add notification for showing paywall from anywhere:**
```swift
// In NotificationCenterManager or extension:
extension Notification.Name {
    static let showPaywall = Notification.Name("FocusFlow.showPaywall")
}

// Usage from gated features:
NotificationCenter.default.post(
    name: .showPaywall, 
    object: nil, 
    userInfo: ["context": PaywallContext.sound.rawValue]
)
```

---

### P1-1: Create ProGatingHelper.swift
**File:** `FocusFlow/Core/Utilities/ProGatingHelper.swift` (NEW)  
**Effort:** 1 hour  
**Why:** Centralized gating logic prevents inconsistencies

```swift
// Create new file with:
// - isPro check
// - canUseCloudSync (isPro + isSignedIn)
// - syncStatus enum (active, needsSignIn, needsUpgrade)
// - Free tier limits (themes, sounds, ambiance sets)
// - Feature check methods
```

**Free Tier Limits:**
- Themes: Forest, Neon (2)
- Sounds: Light Rain, Fireplace, Soft Ambience (3)
- Ambiance: Minimal, Stars, Forest (3)
- Tasks: 3 active max
- Reminders: 1 max
- History: 3 days
- Presets: View/use 3 defaults, no create/edit

---

### P1-2: Wire Guest → Account Migration
**File:** `FocusFlow/App/ContentView.swift`  
**Effort:** 30 minutes  
**Why:** Prevents data loss when users sign in from guest mode

**Changes:**
1. Add `@State private var showMigrationSheet = false`
2. Add `.onChange(of: authManager.state)` handler
3. Check `GuestMigrationManager.shared.hasGuestData()`
4. Show `DataMigrationSheet` when conditions met

**Test:**
- Start as guest → Create task/session → Sign in → Migration sheet appears

---

### P1-3: Remove DebugLogView
**File:** `FocusFlow/Features/Focus/DebugLogView.swift`  
**Effort:** 5 minutes  
**Why:** Dead code, potential App Store rejection

**Options:**
- A: Delete file entirely
- B: Wrap in `#if DEBUG ... #endif`

---

### P1-4: Gate Cloud Sync
**File:** `FocusFlow/Infrastructure/Cloud/SyncCoordinator.swift`  
**Effort:** 30 minutes  
**Why:** Cloud sync is highest-value Pro feature

**Changes in `startAllEngines(userId:)`:**
```swift
private func startAllEngines(userId: UUID) {
    // ✅ Check Pro + SignedIn
    guard ProGatingHelper.shared.canUseCloudSync else {
        #if DEBUG
        print("[SyncCoordinator] Sync disabled - requires Pro + SignedIn")
        #endif
        return
    }
    
    // ... existing code
}
```

**Also update:**
- `handleAuthStateChange()` - Check Pro before starting
- Add observer for Pro status changes

---

### P1-5: Gate Themes (2 Free)
**File:** `FocusFlow/Features/Profile/ProfileView.swift`  
**Effort:** 1 hour  
**Why:** Themes are highly visible upgrade trigger

**Free Themes:** Forest, Neon  
**Pro Themes:** Peach, Cyber, Ocean, Sunrise, Amber, Mint, Royal, Slate

**Changes:**
- Show lock icon on Pro themes
- Tapping locked theme shows PaywallView
- Prevent theme change if not Pro

---

### P1-6: Gate Sounds (3 Free)
**File:** `FocusFlow/Features/Focus/FocusSoundPicker.swift`  
**Effort:** 1 hour  
**Why:** Users encounter sounds first session

**Free Sounds:** 
- light-rain-ambient
- fireplace  
- soft-ambience

**Changes:**
- Show lock icon on Pro sounds
- Allow preview but not selection
- Tapping locked sound shows PaywallView

---

### P1-7: Gate Ambiance (3 Free)
**File:** `FocusFlow/Features/Focus/AmbientBackgrounds.swift`  
**Effort:** 1 hour  
**Why:** Visual backgrounds are strong upgrade trigger

**Free Ambiance:** Minimal, Stars, Forest  
**Pro Ambiance:** Aurora, Rain, Fireplace, Ocean, Gradient, Snow, Underwater, Clouds, Sakura, Lightning, Lava

**Changes:**
- Show lock icon on Pro modes in AmbientPickerSheet
- Prevent selection if not Pro
- Show PaywallView on tap

---

### P1-8: Gate Presets (No Create/Edit)
**Files:** 
- `FocusFlow/Features/Presets/FocusPresetStore.swift`
- `FocusFlow/Features/Presets/FocusPresetManagerView.swift`
- `FocusFlow/Features/Presets/FocusPresetEditorView.swift`

**Effort:** 1 hour  
**Why:** Custom presets are power user feature

**Free:** Can view and USE first 3 default presets (Deep Work, Study, Writing)  
**Pro:** 4th default (Reading) + unlimited custom + edit

**Changes:**
- Hide "+" button for free users
- Show "Pro" badge on Reading preset
- Block edit button for free users
- Show PaywallView when blocked action attempted

---

### P1-9: Gate Tasks (3 Max Active)
**Files:**
- `FocusFlow/Features/Tasks/TasksStore.swift`
- `FocusFlow/Features/Tasks/TasksView.swift`

**Effort:** 1 hour  
**Why:** Power users hit this limit quickly

**Changes in TasksStore:**
```swift
func upsert(_ task: FFTaskItem) {
    let isNewTask = !tasks.contains(where: { $0.id == task.id })
    
    if isNewTask && !ProGatingHelper.shared.isPro {
        let activeTasks = tasks.filter { !isCompleted(taskId: $0.id, on: Date()) }
        if activeTasks.count >= 3 {
            // Post notification to show paywall
            NotificationCenter.default.post(name: .showPaywall, object: nil, 
                userInfo: ["context": "task_limit"])
            return
        }
    }
    // ... existing code
}
```

**Changes in TasksView:**
- Show "3/3 tasks" counter for free users
- Show upgrade prompt when limit reached

---

### P1-10: Gate Task Reminders (1 Max)
**File:** `FocusFlow/Features/Tasks/TaskReminderScheduler.swift`  
**Effort:** 30 minutes  
**Why:** Limits encourage upgrade

**Changes:**
- Count tasks with reminders
- Block adding reminder if count >= 1 and not Pro
- Show message "Upgrade for unlimited reminders"

---

### P1-11: Gate Progress History (3 Days)
**File:** `FocusFlow/Features/Progress/ProgressViewV2.swift`  
**Effort:** 1 hour  
**Why:** Historical data is valuable to committed users

**Changes:**
- Filter sessions to last 3 days for free users
- Show "View full history with Pro" message
- Add blur/overlay on older days
- Tapping locked history shows PaywallView

---

### P1-12: Gate XP/Levels (Pro Only)
**File:** `FocusFlow/Features/Profile/ProfileView.swift`  
**Effort:** 45 minutes  
**Why:** Gamification is Pro perk

**Changes:**
- Hide XP bar for free users
- Hide level indicator
- Hide achievements section
- Show "Unlock XP & Levels with Pro" teaser card

---

### P1-13: Gate Journey View (Pro Only)
**Files:**
- `FocusFlow/Features/Profile/ProfileView.swift`
- `FocusFlow/Features/Journey/JourneyView.swift`

**Effort:** 30 minutes  
**Why:** Deep analytics is Pro feature

**Changes:**
- Hide Journey navigation for free users
- Or show locked state with Pro teaser
- If accessed directly, redirect to paywall

---

### P1-14: Gate Widgets
**Files:**
- `FocusFlow/Shared/WidgetDataManager.swift`
- `FocusFlowWidgets/FocusFlowWidget.swift`

**Effort:** 1 hour  
**Why:** Interactive widgets are Pro perk

**Free:** Small widget, view-only (shows progress, no controls)  
**Pro:** All sizes, full interactivity

**Changes:**
- Don't sync preset data for free users
- Don't sync control state for free users
- Widget shows "Upgrade for controls" for free users

---

### P1-15: Gate Live Activity (Pro Only)
**File:** `FocusFlow/Shared/FocusLiveActivityManager.swift`  
**Effort:** 30 minutes  
**Why:** Live Activity is premium feature

**Changes:**
```swift
func startActivity(...) {
    guard ProGatingHelper.shared.isPro else {
        #if DEBUG
        print("[LiveActivity] Disabled - requires Pro")
        #endif
        return
    }
    // ... existing code
}
```

---

### P1-16: Gate External Music Apps (Pro Only)
**File:** `FocusFlow/Features/Focus/ExternalMusicLauncher.swift`  
**Effort:** 30 minutes  
**Why:** Integration is Pro perk

**Changes:**
```swift
static func openSelectedApp(_ app: AppSettings.ExternalMusicApp) {
    guard ProGatingHelper.shared.isPro else {
        // Show paywall instead
        NotificationCenter.default.post(name: .showPaywall, object: nil,
            userInfo: ["context": "external_music"])
        return
    }
    // ... existing code
}
```

Also hide external music option in FocusSoundPicker for free users.

---

## 🟡 PRIORITY 2: HIGH (Days 5-6)

### P2-1: Sync Status UI in ProfileView
**File:** `FocusFlow/Features/Profile/ProfileView.swift`  
**Effort:** 1 hour

**Show different states:**
| State | UI |
|-------|-----|
| Pro + SignedIn | "☁️ Cloud Sync: Active" + Sync Now button |
| Pro + Guest | "☁️ Sign in to sync" + Sign In button |
| Free + SignedIn | "☁️ Upgrade for sync" + Upgrade button |
| Free + Guest | "☁️ Upgrade for sync" + Upgrade button |

---

### P2-2: PaywallContext for Contextual Prompts
**File:** `FocusFlow/StoreKit/PaywallView.swift`  
**Effort:** 45 minutes

**Add context parameter:**
```swift
enum PaywallContext: String {
    case general, sound, theme, ambiance, preset, task, reminder
    case history, xpJourney, widget, liveActivity, externalMusic, cloudSync
    
    var headline: String {
        switch self {
        case .sound: return "Unlock All Focus Sounds"
        case .theme: return "Unlock All Themes"
        case .task: return "Unlock Unlimited Tasks"
        case .cloudSync: return "Sync Across All Devices"
        // ... etc
        }
    }
}
```

---

### P2-3: Multi-Device Sync Testing
**Effort:** 2-3 hours

**Test Matrix:**
| Scenario | Device A | Device B | Expected |
|----------|----------|----------|----------|
| Offline edit | Edit task offline | - | Queues, syncs when online |
| Simultaneous | Edit task | Edit same task | Last-write-wins |
| Delete conflict | Delete task | Edit same task | Delete wins |
| Session sync | Complete session | - | Appears on B |
| Preset sync | Create preset | - | Appears on B |

---

### P2-4: Test All 4 User States
**Effort:** 1-2 hours

**Test each combination:**
- [ ] Guest + Free: All limits enforced, no sync
- [ ] Guest + Pro: All features except sync
- [ ] SignedIn + Free: All limits enforced, no sync
- [ ] SignedIn + Pro: All features including sync

---

## 🟢 PRIORITY 3: MEDIUM (Days 7+)

### P3-1: Empty States & First-Run Guidance
**Effort:** 1 day

- Add engaging empty state in Tasks tab
- Add empty state in Progress tab
- Add "Tap the orb to begin" hint
- Add celebration on first completed session

---

### P3-2: Accessibility Pass
**Effort:** 1-2 days

- Add `.accessibilityLabel()` to custom controls
- Add `.accessibilityHint()` for complex interactions
- Test with VoiceOver
- Verify Dynamic Type support

---

### P3-3: App Store Assets
**Effort:** 1 day

- [ ] Screenshots (6.7", 6.5", 5.5")
- [ ] App preview video (optional)
- [ ] Description highlighting Pro features
- [ ] Keywords
- [ ] Privacy policy URL
- [ ] Support URL

---

### P3-4: TestFlight Beta
**Effort:** 1 week

- [ ] Build for TestFlight
- [ ] Invite 5+ beta testers
- [ ] Collect feedback for 1 week
- [ ] Fix reported issues

---

## 📅 Execution Timeline

| Day | Focus | Tasks |
|-----|-------|-------|
| **1** | Foundation | P1-0 (PaywallView), P1-1 (ProGatingHelper), P1-2 (Migration), P1-3 (DebugLogView) |
| **2** | Content Gates | P1-5 (Themes), P1-6 (Sounds), P1-7 (Ambiance) |
| **3** | Feature Gates | P1-4 (Sync), P1-8 (Presets), P1-9 (Tasks), P1-10 (Reminders) |
| **4** | Platform Gates | P1-11 (History), P1-12 (XP), P1-13 (Journey), P1-14-16 (Widget/LA/Music) |
| **5** | High Priority | P2-1 (Sync UI), P2-2 (PaywallContext) |
| **6** | Testing | P2-3 (Sync test), P2-4 (State test) |
| **7+** | Polish | P3-1 through P3-4 |

---

## ✅ Definition of Done

**Each gate must:**
- [ ] Check Pro status correctly
- [ ] Show appropriate lock UI
- [ ] Trigger PaywallView when blocked
- [ ] Not crash when limit reached
- [ ] Work in all 4 user states

**Before release:**
- [ ] All P1 tasks complete
- [ ] All P2 tasks complete
- [ ] No crashes in 24-hour test
- [ ] TestFlight feedback addressed

---

## 🚀 Ready to Start

Begin with: **P1-1: Create ProGatingHelper.swift**

This establishes the foundation for all other gates.

