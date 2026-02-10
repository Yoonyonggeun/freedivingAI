# Simulator Testing Guide - DNF MVP Flow

## Current Status

✅ **App is running** on iPhone SE (3rd generation) simulator
✅ **Home screen displays correctly** with new Indoor Pool Disciplines layout

## Screenshot Evidence

### Home Screen (Current)
- ✅ "Indoor Pool Disciplines" section visible
- ✅ DNF tile is active (blue, no lock icon)
- ✅ DYN tile is disabled (dimmed, lock icon, "SOON" badge)
- ✅ DYNB tile is disabled (dimmed, lock icon, "SOON" badge)
- ✅ "Other Features" section shows Static Training and Training History

## Manual Test Steps

### Test 1: DNF Tile Navigation ✅ READY TO TEST
**Steps:**
1. Click on "Dynamic No Fins" tile on the home screen
2. **Expected:** Navigate to DNF Personal Best Input screen
3. **Verify:**
   - Screen title shows "DNF Personal Best"
   - Header text: "What's your current DNF distance?"
   - Subtitle: "This helps us calibrate analysis for your level"
   - DNF Distance input field with "m" suffix
   - Pool Length dropdown (25m/50m)
   - "Skip for now" button
   - "Continue" button

### Test 2: DYN/DYNB Disabled Tiles ✅ READY TO TEST
**Steps:**
1. Try clicking on "Dynamic with Fins" tile
2. Try clicking on "Dynamic Bi-Fins" tile
3. **Expected:** No navigation occurs
4. **Verify:** App stays on home screen

### Test 3: PB Input - Skip Flow
**Steps:**
1. Navigate to DNF PB Input screen (from Test 1)
2. Click "Skip for now" button
3. **Expected:** Navigate to DNF Video Upload screen
4. **Verify:**
   - Screen title shows "Upload DNF Video"
   - "Capture Requirements" header visible
   - Video Guidelines section with 5 requirements:
     - Side or rear-diagonal view
     - Full body visible throughout
     - 8-15 seconds of continuous swimming
     - Good lighting and water clarity
     - Include at least one complete stroke cycle
   - "Choose from Gallery" button

### Test 4: PB Input - Save Flow
**Steps:**
1. Navigate to DNF PB Input screen
2. Tap on the text field
3. Enter "50" (or any number)
4. Optionally change pool length dropdown
5. Click "Continue" button
6. **Expected:**
   - Loading indicator briefly appears
   - Navigate to DNF Video Upload screen
   - Console log shows: `[DNF PB] Saved: 50m, Assigned level: intermediate`
7. **Verify:**
   - Check Flutter console for level assignment log
   - 25m pool thresholds:
     - <25m → beginner
     - 25-49m → intermediate
     - 50-99m → advanced
     - ≥100m → elite
   - 50m pool thresholds:
     - <50m → beginner
     - 50-99m → intermediate
     - 100-149m → advanced
     - ≥150m → elite

### Test 5: Video Upload Screen
**Steps:**
1. Navigate to DNF Video Upload screen
2. **Verify UI:**
   - Requirements card displays all 5 DNF guidelines
   - Blue "Choose from Gallery" button present
   - Each requirement has check icon
3. Click "Choose from Gallery"
4. **Expected:** File picker opens
5. **Note:** Cannot fully test analysis without actual video

### Test 6: Back Navigation
**Steps:**
1. From DNF Video Upload screen → Back button
2. **Expected:** Return to PB Input screen
3. From PB Input screen → Back button
4. **Expected:** Return to Home screen

### Test 7: Level Assignment Logic (Console Verification)
**Test Cases:**
1. Enter PB: 20m, Pool: 25m
   - **Expected log:** `Assigned level: beginner`
2. Enter PB: 50m, Pool: 25m
   - **Expected log:** `Assigned level: intermediate`
3. Enter PB: 100m, Pool: 25m
   - **Expected log:** `Assigned level: advanced`
4. Enter PB: 150m, Pool: 25m
   - **Expected log:** `Assigned level: elite`

### Test 8: Profile Integration (Advanced)
**Steps:**
1. After entering PB and continuing, navigate to Home
2. Go to Profile screen
3. **Expected:** PB should be saved in profile data
4. **Verify:** Check Hive database or profile display

## How to Monitor Console Output

While app is running, watch the terminal output:
```bash
# In the terminal where flutter run is active
# Look for logs like:
flutter: [DNF PB] Saved: 50m, Assigned level: intermediate
```

## Test Results Template

Copy this template to record your test results:

```
## Test Session: [Date/Time]

### Test 1: DNF Tile Navigation
- [ ] PASS / [ ] FAIL
- Notes: _______________________

### Test 2: DYN/DYNB Disabled
- [ ] PASS / [ ] FAIL
- Notes: _______________________

### Test 3: PB Skip Flow
- [ ] PASS / [ ] FAIL
- Notes: _______________________

### Test 4: PB Save Flow
- [ ] PASS / [ ] FAIL
- Notes: _______________________
- Console log: _______________________

### Test 5: Video Upload UI
- [ ] PASS / [ ] FAIL
- Notes: _______________________

### Test 6: Back Navigation
- [ ] PASS / [ ] FAIL
- Notes: _______________________

### Test 7: Level Assignment
- 20m/25m pool: _____ (expected: beginner)
- 50m/25m pool: _____ (expected: intermediate)
- 100m/25m pool: _____ (expected: advanced)
- 150m/25m pool: _____ (expected: elite)

## Issues Found:
1. _______________________
2. _______________________

## Screenshots Taken:
- Home screen: ✅
- PB Input screen: [ ]
- Video Upload screen: [ ]
- Results screen (if tested with video): [ ]
```

## Quick Navigation Commands

If you need to restart or hot reload:
```bash
# In the terminal where flutter run is active:
r    # Hot reload (preserves state)
R    # Hot restart (fresh state)
q    # Quit app
```

## Current App State

- **Device:** iPhone SE (3rd generation) (F04FD780-369C-4CAC-91ED-F2B0D57DD8B3)
- **Mode:** Debug
- **Status:** ✅ Running
- **Current Screen:** Home (Indoor Pool Disciplines visible)

---

**Next Step:** Manually tap the "Dynamic No Fins" tile in the simulator to proceed with testing!
