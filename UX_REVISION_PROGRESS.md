# UX Revision Progress - Indoor AI (DNF-only) MVP

## 📅 Status: Phase 1 Complete (Core Leveling Flow)

**Date:** 2026-02-09
**Goal:** Implement video-based leveling WITHOUT forcing upload on first launch

---

## ✅ Phase 1: Core Leveling System (COMPLETE)

### Implemented Features

#### 1. 5-Tier Leveling System ✅
**Files:**
- `lib/utils/level_calculator.dart` (NEW)
- `lib/models/user_profile.dart` (UPDATED)

**Features:**
- **Provisional Level (1-5)** - Based ONLY on PB distance
  ```
  L1: < 25m (Beginner)
  L2: 25-49m (Developing)
  L3: 50-74m (Intermediate)
  L4: 75-99m (Advanced)
  L5: ≥ 100m (Elite)
  ```

- **Official Level (1-5)** - Based on PB + Technique modifier
  ```
  Technique Score:
  - ≥80: +1 level
  - 55-79: +0 level
  - <55: -1 level

  Requirements:
  - Confidence ≥ 0.60
  - Classification == 'DNF'
  - Technique score available
  ```

- **Helper Functions:**
  - `calculateProvisionalLevel(pbMeters)` → int (1-5)
  - `calculateOfficialLevel(...)` → int? (nullable)
  - `getLevelName(level)` → String
  - `getLevelDescription(level)` → String
  - `getPBRangeForLevel(level)` → String
  - `canAssignOfficialLevel(...)` → bool
  - `getOfficialLevelNotAssignedReasons(...)` → List<String>

#### 2. Updated UserProfile Model ✅
**File:** `lib/models/user_profile.dart`

**New Fields:**
```dart
@HiveField(9)
int? provisionalLevel; // 1-5, PB-based

@HiveField(10)
int? officialLevel; // 1-5, PB+technique, video-based, nullable
```

**Status:**
- Hive type adapter regenerated ✅
- Backward compatible with existing `diverLevel` field ✅

#### 3. Provisional Level Screen ✅
**File:** `lib/features/dynamic_training/screens/provisional_level_screen.dart` (NEW)

**UI Components:**
- Level display with circular badge (1-5)
- Level name (Beginner/Developing/Intermediate/Advanced/Elite)
- PB info ("Based on your Xm PB")
- PB range for level ("25-49m")
- "Unlock More" info card explaining video benefits:
  - Official Level (PB + Technique)
  - Detailed technique feedback
  - Personalized drill recommendations
  - Stroke-by-stroke analysis
- Primary CTA: "Start DNF Level Test (Video)" → DNFVideoUploadScreen
- Secondary CTA: "Not now" → Home screen

**User Experience:**
- Instant value: User gets provisional level immediately after PB input
- No forced video upload
- Clear value proposition for video upload

#### 4. Updated PB Input Flow ✅
**File:** `lib/features/dynamic_training/screens/dnf_pb_input_screen.dart`

**Changes:**
- Calculate provisional level using `LevelCalculator`
- Save provisionalLevel to UserProfile
- Navigate to `ProvisionalLevelScreen` (NOT directly to video upload)
- "Skip for now" → Return to home (NOT to video upload)
- Console log: `[DNF PB] Saved: 50m, Provisional level: 3`

**Flow:**
```
OLD: PB Input → Video Upload (forced)
NEW: PB Input → Provisional Level Screen → Video Upload (optional)
```

---

## 🚧 Phase 2: Professional Results & Safety (IN PROGRESS)

### Task #4: Preflight Video Checks ⏳
**Status:** Pending
**Priority:** High
**Files to create:**
- `lib/services/video_preflight_checker.dart`

**Requirements:**
- Run checks BEFORE analysis
- Show warnings dialog:
  - Multi-person detected
  - Body frequently out of frame
  - Too short / insufficient kick cycles
  - Video likely not DNF (DYN/DYNB/other)
- Allow "Proceed anyway" button
- Block analysis if critical issues

### Task #5: Enhanced Results Screen ⏳
**Status:** Pending
**Priority:** High
**File to update:**
- `lib/features/analysis/screens/analysis_result_screen.dart`

**Requirements:**
- Confidence badge (0-100%) with "Why?" expandable
- Classification display (DNF / Not DNF / Unrelated)
- Official Level display (only if eligible)
- Scoring rules:
  - Confidence < 0.35: No technique score, "Not available" + reasons
  - Confidence 0.35-0.59: Primary metrics only, cautious language
  - Confidence ≥ 0.60: Full score + official level + drills
- "Not available" sections with reasons
- Evidence timestamps

### Task #6: DNF Classification ⏳
**Status:** Pending
**Priority:** High
**Files to create:**
- `lib/services/video_classifier.dart`

**Requirements:**
- Detect DNF vs DYN (fins present)
- Detect DNF vs DYNB (bi-fins arm movement)
- Detect DNF vs OTHER
- Return classification string
- Show warning if not DNF: "This video looks like DYN/DYNB. DNF analysis is not applicable."

### Task #7: Level-Based Drill System ⏳
**Status:** Pending
**Priority:** Medium
**Files to create:**
- `lib/services/drill_recommender.dart`

**Requirements:**
- Vary drills by Official/Provisional level (1-5)
- If official not assigned OR confidence <0.60:
  - Show generic drills + capture improvement tips
- If official assigned:
  - 4-8 drills (2 per top issue + 1 foundation)
- Each drill must include:
  - Goal
  - Setup
  - Reps/sets/rest
  - Key cues
  - Common mistakes
  - Progression/regression

### Task #8: Video Upload Screen Copy ⏳
**Status:** Pending
**Priority:** Low
**File to update:**
- `lib/features/dynamic_training/screens/dnf_video_upload_screen.dart`

**Requirements:**
- Add copy: "Video is analyzed on-device. Nothing is uploaded to a server."
- Add copy: "If measurement is not possible, we will not score it and we will tell you why."
- Add "Capture tips" expandable section

---

## 📊 Implementation Progress

| Phase | Tasks | Status |
|-------|-------|--------|
| Phase 1: Core Leveling | 3/3 | ✅ Complete |
| Phase 2: Professional Results | 0/5 | 🚧 In Progress |
| **Total** | **3/8** | **37.5%** |

---

## 🎯 Acceptance Criteria Status

- [x] App does NOT force video upload on first launch
- [x] PB input immediately yields Provisional Level
- [x] DNF Level Test (video) is the primary CTA to unlock Official Level
- [ ] DYN/DYNB shown as Coming soon and truly not tappable (Already done in previous MVP)
- [ ] No pre-upload movement categories; single upload flow (Already done)
- [ ] Results never lie: measurable-only, confidence-gated, not-available explained (Pending)
- [ ] Official Level assignment is confidence-gated and DNF-only (System ready, needs results UI)
- [ ] Drill list changes by level and issues (Pending)

---

## 🧪 Testing Phase 1

### Manual Test Steps

1. **Fresh Start:**
   - App launches with clean state
   - Complete onboarding (5 steps)
   - Navigate to home screen

2. **PB Input → Provisional Level:**
   - Tap "Dynamic No Fins" tile
   - Enter PB (e.g., 50m)
   - Tap "Continue"
   - **Verify:** Provisional Level screen shows:
     - Level 3 (Intermediate)
     - "Based on your 50m PB"
     - "50-74m" range
     - Unlock More info card
     - Two CTAs (Video test + Not now)

3. **Level Calculation:**
   - Test different PBs:
     - 20m → Level 1 (Beginner, <25m)
     - 35m → Level 2 (Developing, 25-49m)
     - 60m → Level 3 (Intermediate, 50-74m)
     - 85m → Level 4 (Advanced, 75-99m)
     - 120m → Level 5 (Elite, ≥100m)

4. **Navigation Flows:**
   - "Not now" → Should return to home
   - "Start DNF Level Test" → Should go to video upload screen
   - Back button from Provisional → Should go to PB input
   - "Skip for now" on PB input → Should go to home

### Console Verification

Look for:
```
[DNF PB] Saved: 50m, Provisional level: 3
```

---

## 📁 New Files Created

1. `lib/utils/level_calculator.dart` (175 lines)
2. `lib/features/dynamic_training/screens/provisional_level_screen.dart` (285 lines)

## 📝 Modified Files

1. `lib/models/user_profile.dart` (+4 fields, +2 copyWith params)
2. `lib/features/dynamic_training/screens/dnf_pb_input_screen.dart` (navigation + level logic)

---

## 🚀 Next Steps

### Immediate (High Priority):
1. ✅ Complete Phase 1 (DONE)
2. Implement Preflight Checks (Task #4)
3. Enhance Results Screen (Task #5)
4. Implement Classification (Task #6)

### Soon (Medium Priority):
5. Level-Based Drills (Task #7)
6. Update Upload Screen Copy (Task #8)

### Testing:
7. Manual test on simulator
8. Screenshot capture for documentation
9. Integration test with real video

---

## 💡 Key Design Decisions

1. **Why Provisional + Official?**
   - Immediate value (provisional) prevents drop-off
   - Official level creates motivation for video upload
   - Clear upgrade path

2. **Why 5 tiers instead of 4?**
   - More granular progression
   - Better matches typical pool distance milestones
   - Aligns with spec requirements

3. **Why nullable officialLevel?**
   - Not all users will upload video
   - Confidence gating means not all videos qualify
   - Explicit null = "not assigned yet" vs 0 = invalid

4. **Why keep legacy diverLevel?**
   - Backward compatibility with existing code
   - Gradual migration path
   - Fallback for features not yet updated

---

**Status:** Phase 1 shipped, Phase 2 in progress. App is running on simulator ready for testing.
