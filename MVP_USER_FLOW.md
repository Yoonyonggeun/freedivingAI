# Indoor AI MVP - User Flow Guide

## Visual Flow Diagram

```
┌─────────────────────────────────────┐
│        HOME SCREEN                  │
│                                     │
│  Indoor Pool Disciplines            │
│  ┌───────────────────────────────┐ │
│  │ 🏊 Dynamic No Fins            │ │ ◄─── ACTIVE (Blue)
│  │ Start DNF analysis            │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 🏊 Dynamic with Fins    🔒    │ │ ◄─── DISABLED (Dimmed)
│  │ Coming soon            [SOON] │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 🏊 Dynamic Bi-Fins      🔒    │ │ ◄─── DISABLED (Dimmed)
│  │ Coming soon            [SOON] │ │
│  └───────────────────────────────┘ │
│                                     │
│  Other Features                     │
│  ┌──────────┬──────────┬─────────┐ │
│  │ Static   │ History  │ Profile │ │
│  │ Training │          │         │ │
│  └──────────┴──────────┴─────────┘ │
└─────────────────────────────────────┘
           │
           │ [Tap DNF]
           ▼
┌─────────────────────────────────────┐
│   DNF PERSONAL BEST INPUT           │
│                                     │
│  What's your current DNF distance?  │
│  This helps us calibrate analysis   │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 🏊 DNF Distance               │ │
│  │                               │ │
│  │ ┌─────────────────┐           │ │
│  │ │ 50            m │           │ │
│  │ └─────────────────┘           │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ Pool Length         [25m ▼]   │ │
│  └───────────────────────────────┘ │
│                                     │
│  [Skip for now]      [Continue]    │
└─────────────────────────────────────┘
           │
           │ [Continue/Skip]
           ▼
┌─────────────────────────────────────┐
│   UPLOAD DNF VIDEO                  │
│                                     │
│  Capture Requirements               │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 📹 Video Guidelines           │ │
│  │                               │ │
│  │ ✓ Side or rear-diagonal view  │ │
│  │ ✓ Full body visible           │ │
│  │ ✓ 8-15 seconds continuous     │ │
│  │ ✓ Good lighting/clarity       │ │
│  │ ✓ At least one stroke cycle  │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │   📷 Choose from Gallery      │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
           │
           │ [Choose video]
           ▼
┌─────────────────────────────────────┐
│   ANALYZING VIDEO                   │
│                                     │
│         ⭕ 73%                      │
│                                     │
│      Analyzing Video                │
│           73%                       │
└─────────────────────────────────────┘
           │
           │ [Analysis complete]
           ▼
┌─────────────────────────────────────┐
│   ANALYSIS RESULTS                  │
│                                     │
│  ┌───────────────────────────────┐ │
│  │       Overall Score           │ │
│  │                               │ │
│  │          ⭕ 78               │ │
│  │           Good                │ │
│  │                               │ │
│  │      DNF - Full Clip          │ │
│  └───────────────────────────────┘ │
│                                     │
│    ┌─────────────────────────┐     │
│    │ ✓ High Confidence       │     │ ◄─── NEW
│    └─────────────────────────┘     │
│                                     │
│  What We Measured                   │ ◄─── NEW
│  ┌───────────────────────────────┐ │
│  │ ✓ Streamline         78%      │ │
│  │ ✓ Body Position      82%      │ │
│  │ ✓ Kick Technique     75%      │ │
│  └───────────────────────────────┘ │
│                                     │
│  What We Could NOT Measure          │ ◄─── NEW
│  ┌───────────────────────────────┐ │
│  │ ℹ️ Insufficient frames for    │ │
│  │   turn analysis               │ │
│  └───────────────────────────────┘ │
│                                     │
│  Detailed Scores                    │
│  [Score bars...]                    │
│                                     │
│  Strengths                          │
│  • Strong kick technique            │
│                                     │
│  Areas for Improvement              │
│  • Improve streamline position      │
│                                     │
│  Recommended Drills                 │ ◄─── Level-appropriate
│  • Streamline + 3 kicks (50m)       │
│                                     │
│  ✓ Automatically Saved to History   │
│  [Analyze Another Video]            │
└─────────────────────────────────────┘
```

## Key Features

### 1. Discipline Selection (Home Screen)
- **DNF**: Fully functional, direct flow to analysis
- **DYN/DYNB**: Clearly marked as "Coming soon"
- **Visual distinction**: Disabled tiles are dimmed with lock icon

### 2. PB Input (Optional but Recommended)
- Collects DNF Personal Best for level calibration
- Auto-assigns training level (beginner/intermediate/advanced/elite)
- Skippable if user doesn't know their PB
- Pool length context (25m/50m) for accurate level assignment

### 3. Video Upload
- Clear filming requirements
- No confusing category selection
- DNF-specific guidelines

### 4. Enhanced Results
- **Confidence Badge**: Shows how reliable the analysis is
- **Measured vs Unmeasured**: Honest about what AI could/couldn't analyze
- **Level-Appropriate Drills**: Based on PB input

## User Benefits

✅ **Faster onboarding**: 3 taps to start analysis (vs 5+ in old flow)
✅ **Clear expectations**: "Coming soon" instead of broken features
✅ **Honest feedback**: Shows what couldn't be measured
✅ **Personalized coaching**: Level-appropriate drills based on PB
✅ **Trust building**: Confidence indicator builds user trust

## Developer Benefits

✅ **Reduced scope**: Ship DNF first, validate market
✅ **Cleaner codebase**: No confusing multi-discipline logic in MVP
✅ **Easier testing**: Single discipline = focused QA
✅ **Future-ready**: DYN/DYNB can use same pattern when ready

## Comparison: Old vs New Flow

### Old Flow (General Video Analysis)
```
Home → Video Analysis → Select Discipline (DNF/DYN/DYNB/...)
  → Select Category (6 options) → Upload → Results
```
**Problems:**
- 5+ taps to start
- Category selection confusing for beginners
- DYN/DYNB appear functional but aren't ready
- Generic results without context

### New Flow (DNF MVP)
```
Home → DNF → PB Input (optional) → Upload → Results
```
**Benefits:**
- 3 taps to start (2 if skip PB)
- No category confusion (DNF uses full clip)
- DYN/DYNB clearly "Coming soon"
- Personalized results with confidence

---

**Ready for:** User testing, screenshot creation, app store submission
