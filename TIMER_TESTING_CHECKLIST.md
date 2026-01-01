# Timer Testing Checklist

## 🎯 Critical Tests (Do These First)

### 1. **Basic Timer Functionality**
- [ ] Start a 5-minute timer - does it count down correctly?
- [ ] Pause the timer - does it stop immediately?
- [ ] Resume the timer - does it continue from where it paused?
- [ ] Let timer complete - does it show completion overlay?
- [ ] Check progress bar - does it fill smoothly?

### 2. **Timer Accuracy (Most Important!)**
- [ ] Start a 10-minute timer
- [ ] Let it run for 2-3 minutes
- [ ] Check if the displayed time matches actual elapsed time
- [ ] Pause and resume multiple times - does time stay accurate?
- [ ] Let it run to completion - does it finish at exactly 0:00?

### 3. **False Session Logging (The Bug You Found)**
- [ ] Start a 20-minute timer
- [ ] Immediately pause it (before any time passes)
- [ ] Reset it
- [ ] Check your progress - **should NOT show a 20-min session logged**
- [ ] Start timer, pause after 30 seconds, reset - should NOT log
- [ ] Start timer, pause after 2 minutes, reset - should NOT log (less than 5 min)
- [ ] Start timer, run for 6 minutes, then reset - **should log 6 minutes** (meets 5-min rule)

### 4. **Pause/Resume Accuracy**
- [ ] Start a 10-minute timer
- [ ] Let it run to 8:30 remaining
- [ ] Pause it
- [ ] Wait 30 seconds
- [ ] Resume - should still show 8:30 (time doesn't pass while paused)
- [ ] Let it run - should continue counting down smoothly

### 5. **Background/Foreground Behavior**
- [ ] Start a 5-minute timer
- [ ] Background the app (home button/swipe up)
- [ ] Wait 1-2 minutes
- [ ] Return to app - does timer show correct remaining time?
- [ ] Check if it's still running or paused correctly

### 6. **App Kill/Restore (Critical!)**
- [ ] Start a 10-minute timer
- [ ] Let it run for 2 minutes
- [ ] **Force kill the app** (swipe up in app switcher)
- [ ] Wait 1 minute
- [ ] Reopen the app
- [ ] Timer should restore and show ~7 minutes remaining
- [ ] Should continue running from where it left off

### 7. **Timer Completion While Backgrounded**
- [ ] Start a 2-minute timer
- [ ] Background the app immediately
- [ ] Wait 2+ minutes
- [ ] Return to app
- [ ] Should show completion overlay
- [ ] Check progress - should show 2 minutes logged

### 8. **Dynamic Island / Live Activity**
- [ ] Start a timer
- [ ] Check Dynamic Island - does it show the timer?
- [ ] Tap pause in Dynamic Island - does timer pause in app?
- [ ] Tap play in Dynamic Island - does timer resume in app?
- [ ] Check Lock Screen - does Live Activity show correct time?
- [ ] Background app - does Dynamic Island update correctly?

### 9. **Rapid State Changes (Stress Test)**
- [ ] Start timer
- [ ] Rapidly pause/resume 5-10 times
- [ ] Does timer stay accurate?
- [ ] Does it crash or freeze?
- [ ] Check for any duplicate session logs

### 10. **Duration Changes**
- [ ] Start a 25-minute timer
- [ ] While running, tap "Length" button
- [ ] Change to 10 minutes
- [ ] Should reset to idle (not log false session)
- [ ] Start new 10-minute timer - does it work correctly?

### 11. **Multiple Sessions in a Row**
- [ ] Complete a 5-minute session
- [ ] Start another 5-minute session immediately
- [ ] Complete it
- [ ] Check progress - should show 2 separate 5-minute sessions
- [ ] Not one 10-minute session

### 12. **Edge Cases**
- [ ] Start timer, immediately pause, then reset - should NOT log
- [ ] Start timer, change duration while paused - should reset cleanly
- [ ] Start timer, kill app while paused, restore - should restore paused state
- [ ] Start timer, let it complete, then start again - should work normally

---

## 🔍 What to Watch For

### ✅ **Good Signs:**
- Timer counts down smoothly, no jumps
- Time displayed matches actual elapsed time
- Pause/resume works instantly and accurately
- No false session logs in progress
- Dynamic Island controls work
- App restores timer state correctly after kill

### ❌ **Red Flags (Report These):**
- Timer drifts (shows wrong time after running)
- Time jumps when pausing/resuming
- False session logs appear
- Timer doesn't restore after app kill
- Dynamic Island doesn't respond
- App crashes during rapid pause/resume
- Progress bar doesn't match timer

---

## 📊 Quick Test Scenarios

### Scenario 1: "The Quick Test"
1. Start 5-min timer
2. Let run 1 minute
3. Pause
4. Resume
5. Let complete
6. ✅ Should log exactly 5 minutes

### Scenario 2: "The False Log Test" (Your Original Bug)
1. Start 20-min timer
2. Immediately pause
3. Reset
4. ✅ Should NOT log anything

### Scenario 3: "The Background Test"
1. Start 3-min timer
2. Background app
3. Wait 3+ minutes
4. Return to app
5. ✅ Should show completion, log 3 minutes

### Scenario 4: "The Kill Test"
1. Start 10-min timer
2. Let run 2 minutes
3. Force kill app
4. Wait 1 minute
5. Reopen app
6. ✅ Should show ~7 minutes remaining

---

## 🐛 If You Find Issues

Note down:
1. **What you were doing** (step-by-step)
2. **What happened** (actual behavior)
3. **What should have happened** (expected behavior)
4. **Screenshot** if possible
5. **Time/date** it occurred

This will help me fix any remaining bugs quickly!

---

## ✅ Success Criteria

Your timer is working perfectly if:
- ✅ No false session logs
- ✅ Timer stays accurate over long periods
- ✅ Pause/resume works perfectly
- ✅ App restore works after kill
- ✅ Dynamic Island controls work
- ✅ No crashes or freezes
- ✅ Progress bar matches timer

Good luck testing! 🚀


