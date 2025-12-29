# FocusFlow App Audit - Issues Found

## 🔴 CRITICAL UI ISSUES

### 1. Badge Detail Sheet - Close Button Cut Off
**Location:** `ProfileView.swift` lines 1205-1303
**Issue:** 
- Close button (X) at top right is cut off when badge detail sheet opens
- Sheet uses `.presentationDetents([.medium])` which may not provide enough space
- Two `Spacer()` elements at bottom (lines 1298-1299) push content up, potentially cutting off top button
- Button has `.padding(.top, 16)` but no safe area padding

**Fix Needed:**
- Add safe area padding to top HStack
- Consider using `.presentationDetents([.medium, .large])` for flexibility
- Remove one of the Spacers or use fixed spacing
- Ensure close button is always visible with proper safe area handling

---

### 2. Sheet Presentation Detents - Inconsistent Sizing
**Locations:** Multiple files
**Issues:**
- Many sheets use fixed detents (`.medium`, `.height(520)`, `.fraction(0.52)`) that may not work on all device sizes
- Some sheets don't allow resizing (only one detent)
- Badge sheet: `.presentationDetents([.medium])` - fixed, no flexibility
- Progress sheets: Multiple fixed heights (480, 520)
- Task sheets: Mix of fixed heights and fractions

**Recommendation:**
- Use multiple detents where appropriate: `[.medium, .large]`
- Test on different iPhone sizes (SE, Pro Max)
- Consider using `.fraction()` with safe minimums

---

### 3. Safe Area Handling Inconsistencies
**Locations:** Multiple views
**Issues:**
- Some views use `.ignoresSafeArea()` everywhere
- Some use `.ignoresSafeArea(edges: .bottom)` 
- Some don't handle safe areas at all
- Badge detail sheet doesn't account for safe area at top

**Files Affected:**
- `ProfileView.swift` - BadgeDetailSheet
- `FocusSoundPicker.swift` - Multiple ScrollViews
- `FocusPresetEditorView.swift` - ScrollView
- `NotificationCenterView.swift` - List

---

## 🟠 FLOW & UX ISSUES

### 4. Onboarding - Auth Buttons Don't Actually Auth
**Location:** `OnboardingView.swift` lines 186-197
**Issue:**
- On final onboarding page, auth provider buttons (Apple, Google, Email) only call `manager.completeOnboarding()`
- They don't actually trigger authentication
- User expects to sign in but just completes onboarding as guest
- Comment says "Auth will be handled after onboarding" but it's not clear to user

**Fix Needed:**
- Either trigger actual auth flow from these buttons
- Or change button text to "Continue to sign in" or similar
- Or remove these buttons and just have "Start Focusing" button

---

### 5. Email Auth - Signup Success Flow Confusing
**Location:** `EmailAuthView.swift` lines 217-232
**Issue:**
- When signup succeeds but email confirmation is required, shows error message: "Account created. Check your email to confirm, then log in."
- This is shown as an `errorMessage` (red text) even though it's actually success
- User might think something went wrong
- Automatically switches to login mode but message is confusing

**Fix Needed:**
- Show as success message (green/white) not error
- Better messaging: "Account created! Please check your email to confirm your account."
- Maybe add a "Resend confirmation" button

---

### 6. Email Auth - No Loading State on Buttons
**Location:** `EmailAuthView.swift` lines 109-134
**Issue:**
- Primary button shows `ProgressView()` when loading, but button itself doesn't show disabled state clearly
- Secondary buttons (Reset password, Toggle login/signup) don't show any loading states
- User can tap multiple times during async operations

**Fix Needed:**
- Add visual disabled state to all buttons during loading
- Prevent multiple taps
- Show loading indicator on secondary actions if needed

---

### 7. Sync Errors Not Visible to Users
**Location:** `SyncCoordinator.swift` lines 137-144
**Issue:**
- Sync errors are logged to console but never shown to users
- `syncError` is published but no UI displays it
- Users have no way to know if sync failed
- No retry mechanism visible in UI

**Fix Needed:**
- Add sync status indicator in Profile or Settings
- Show sync errors in a banner or alert
- Add manual "Sync Now" button with status
- Show last sync time to users

---

### 8. Task Editor - No Validation Feedback
**Location:** `TasksView.swift` - TaskEditorSheet
**Issue:**
- Save button is disabled when title is empty (line 1414)
- But no visual feedback explaining WHY it's disabled
- User might not understand why they can't save

**Fix Needed:**
- Add placeholder text hint: "Task title is required"
- Show error message if user tries to save empty task
- Better visual indication of required fields

---

### 9. Focus Timer - Early End Logic Not Clear
**Location:** `FocusTimerViewModel.swift` lines 265-282
**Issue:**
- Complex logic for when early-ended sessions are logged
- Rules: >= 60s AND (>= 5 min OR >= 40% completion)
- User has no way to know if their session will count
- No UI feedback about whether session will be logged

**Fix Needed:**
- Show indicator when session meets minimum requirements
- Display "This session will count" or "Session too short" message
- Maybe show progress toward minimum threshold

---

## 🟡 STATE MANAGEMENT ISSUES

### 10. Auth State Transitions - Race Conditions Possible
**Location:** `AuthManagerV2.swift`, `SyncCoordinator.swift`
**Issue:**
- Multiple async operations happening during auth state changes
- Sync coordinator starts/stops engines based on auth state
- No clear ordering guarantees
- Could lead to sync starting before auth is fully ready

**Fix Needed:**
- Add proper state machine with clear transitions
- Ensure sync only starts after auth is fully initialized
- Add guards against race conditions

---

### 11. Tasks Store - Auth State Switching
**Location:** `TasksStore.swift` lines 164-179
**Issue:**
- When auth state changes, tasks are immediately switched
- No confirmation or warning to user
- Guest tasks might be lost if user signs in (though code tries to preserve)
- No visual feedback during state switch

**Fix Needed:**
- Show loading indicator during auth state switch
- Warn user if they're about to lose data
- Better handling of guest → signed in transition

---

### 12. Progress Store - Namespace Switching
**Location:** `ProgressStore.swift` lines 67-85
**Issue:**
- Similar to TasksStore - immediate switch on auth change
- Guest data is preserved but user might not understand
- No UI feedback during switch

---

## 🟢 MISSING FEATURES / EDGE CASES

### 13. No Offline Mode Indication
**Issue:**
- App doesn't show when offline
- Sync might fail silently
- No way to know if data is synced or local-only

**Fix Needed:**
- Add network status indicator
- Show "Offline" badge when no connection
- Queue sync operations when offline

---

### 14. No Data Export/Backup
**Issue:**
- Users can't export their data
- No way to backup before reset
- Reset confirmation requires typing "RESET" but no backup option

**Fix Needed:**
- Add export functionality (JSON/CSV)
- Offer backup before reset
- Maybe add iCloud backup option

---

### 15. Reset All Data - No Undo
**Location:** `ProfileView.swift` lines 1342-1350
**Issue:**
- Reset requires typing "RESET" but action is permanent
- No way to undo
- No backup created before reset

**Fix Needed:**
- Add confirmation dialog with warning
- Offer to create backup before reset
- Maybe add 7-day undo window (store backup temporarily)

---

### 16. Task Completion - No Undo
**Location:** `TasksStore.swift` lines 118-136
**Issue:**
- Tapping task toggles completion
- No way to undo accidental completion
- No confirmation for important tasks

**Fix Needed:**
- Add swipe to undo (show snackbar)
- Maybe add confirmation for recurring tasks
- Long-press to see completion history

---

### 17. Focus Session - No Pause Reason Tracking
**Location:** `FocusTimerViewModel.swift`
**Issue:**
- Can pause session but no way to track why
- No analytics on pause frequency
- No way to mark session as "interrupted" vs "planned break"

**Fix Needed:**
- Optional pause reason selection
- Track pause patterns
- Maybe add "planned break" vs "interruption" distinction

---

### 18. Preset Editor - Sound Selection Not Clear
**Location:** `FocusPresetEditorView.swift` lines 532-543
**Issue:**
- When sound picker closes, selection is applied from `appSettings`
- But preset editor might have different state
- User might not understand which sound is selected for preset vs app

**Fix Needed:**
- Show current preset sound selection clearly
- Separate preset sound from app-wide sound
- Better visual indication of what's being edited

---

## 🔵 UI INCONSISTENCIES

### 19. Button Styles Inconsistent
**Locations:** Multiple files
**Issues:**
- Some buttons use `.buttonStyle(.plain)`
- Some use custom styles
- Close buttons have different sizes and styles across sheets
- Primary action buttons have different corner radii (16, 20, 24)

**Fix Needed:**
- Standardize button styles
- Create reusable button components
- Consistent sizing and spacing

---

### 20. Sheet Headers Inconsistent
**Locations:** Multiple sheet views
**Issues:**
- Some sheets have close button on left
- Some on right
- Some have title, some don't
- Different padding values

**Fix Needed:**
- Standardize sheet header layout
- Consistent close button placement (top right)
- Consistent title styling

---

### 21. Color Opacity Values Inconsistent
**Locations:** Throughout app
**Issues:**
- White opacity: 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.85, 0.9
- No clear system for opacity levels
- Hard to maintain consistency

**Fix Needed:**
- Create opacity constants
- Define semantic opacity levels (subtle, medium, strong)
- Use consistent values

---

### 22. Padding Values Inconsistent
**Locations:** Throughout app
**Issues:**
- Padding: 8, 10, 12, 14, 16, 18, 20, 22, 24
- No clear spacing system
- Hard to maintain visual rhythm

**Fix Needed:**
- Create spacing constants
- Use 4pt or 8pt grid system
- Standardize padding values

---

## 🟣 ACCESSIBILITY ISSUES

### 23. No VoiceOver Labels
**Issue:**
- Many buttons and icons lack accessibility labels
- Images don't have descriptions
- Badge icons not described

**Fix Needed:**
- Add `.accessibilityLabel()` to all interactive elements
- Add `.accessibilityHint()` for complex actions
- Test with VoiceOver

---

### 24. Color Contrast Issues
**Issue:**
- White text on light backgrounds might not meet WCAG standards
- Some opacity values too low for readability
- Badge colors might not have enough contrast

**Fix Needed:**
- Test color contrast ratios
- Ensure minimum 4.5:1 for text
- Adjust opacity values for better readability

---

### 25. Dynamic Type Not Supported
**Issue:**
- Text sizes are fixed
- Doesn't respect user's text size preferences
- Hard to read for users who need larger text

**Fix Needed:**
- Use `.font(.system(size:style:))` with text styles
- Test with different Dynamic Type sizes
- Ensure layouts adapt to larger text

---

## 🔴 BUGS & ERRORS

### 26. GeometryReader in Badge Progress Bar
**Location:** `ProfileView.swift` lines 1272-1280
**Issue:**
- `GeometryReader` used for progress bar but might cause layout issues
- No minimum width constraint
- Could cause layout warnings

**Fix Needed:**
- Use fixed width or better layout approach
- Test on different screen sizes
- Consider using `Capsule()` shape with frame

---

### 27. Timer Restoration - Edge Cases
**Location:** `FocusTimerViewModel.swift` lines 360-411
**Issue:**
- Complex restoration logic
- Multiple edge cases (paused, running, completed)
- Could restore incorrectly if app killed at wrong time

**Fix Needed:**
- Add more validation
- Handle edge cases explicitly
- Test app kill scenarios

---

### 28. Task Sort Index - Potential Duplicates
**Location:** `TasksStore.swift` lines 75-92
**Issue:**
- Sort index reassignment might create duplicates
- No validation that indices are unique
- Could cause sorting issues

**Fix Needed:**
- Add validation for unique sort indices
- Better sorting algorithm
- Test with many tasks

---

## 📝 SUMMARY BY PRIORITY

### Must Fix Before Launch:
1. Badge Detail Sheet - Close Button Cut Off (#1)
2. Onboarding Auth Buttons Don't Work (#4)
3. Sync Errors Not Visible (#7)
4. No Offline Indication (#13)

### Should Fix Soon:
5. Email Auth Flow Confusion (#5)
6. Sheet Sizing Issues (#2)
7. Safe Area Inconsistencies (#3)
8. Reset Data No Undo (#15)

### Nice to Have:
9. All other UI inconsistencies
10. Accessibility improvements
11. Better error handling
12. Data export feature

---

## 🎯 RECOMMENDED FIX ORDER

1. **Badge Detail Sheet** - Quick fix, high visibility
2. **Onboarding Auth Flow** - Core user experience
3. **Sync Status UI** - Important for cloud users
4. **Sheet Sizing** - Affects many screens
5. **Safe Area Handling** - Prevents cut-off issues
6. **Email Auth Messaging** - Reduces confusion
7. **UI Consistency** - Polish and professionalism
8. **Accessibility** - Important for all users

---

*Generated: Comprehensive app audit*
*Total Issues Found: 28*
*Critical: 4 | High: 8 | Medium: 10 | Low: 6*

