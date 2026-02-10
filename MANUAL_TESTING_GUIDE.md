# Manual Testing Guide - Real Video Analysis

## Prerequisites

- iOS Simulator or physical device
- Well-lit environment for recording
- Side view camera angle (profile view)

## Test Procedure

### Step 1: Build and Run the App

```bash
cd freediving_ai
flutter run
```

Wait for the app to launch successfully.

---

### Step 2: Navigate to Dynamic Training

1. Open the app
2. Tap on **Dynamic Training** from the main menu
3. You should see the video guide/recording screen

---

### Step 3: Record Test Videos

Record 3 different test videos to cover all categories:

#### Test Video 1: Streamline (5-10 seconds)
1. Select **Discipline**: DYN
2. Select **Category**: Streamline
3. Tap **Record**
4. Simulate swimming:
   - Lie horizontally (or simulate swimming motion)
   - Keep arms extended forward
   - Keep legs together
   - Maintain steady position
5. Stop recording after 5-10 seconds
6. Tap **Analyze**

**Expected Output**:
```
Overall Score: 50-90/100 (depends on form)
Category Scores:
  - body_alignment: 60-90
  - head_position: 60-90
  - arm_position: 50-80
  - leg_position: 60-90

Strengths: 2-3 items
Improvements: 2-3 items
```

**Check V2 Data** (if accessible in debug):
```dart
final result = Hive.box<AnalysisResult>('analysisResults').getAt(0);
print(result.poseData); // Should show v2Data with version 2.0
```

#### Test Video 2: Finning (3-5 seconds)
1. Select **Category**: Finning
2. Record video with kicking motion:
   - Move legs up and down rhythmically
   - 3-5 kicks total
   - Keep hips relatively stable
3. Tap **Analyze**

**Expected Output**:
```
Overall Score: 40-80/100

Key Metric to Check:
  - kick_frequency: Should show actual detected kicks/min
  - NOT a hardcoded value like 50 or 60
```

**Validation**:
- Count the actual kicks in your video
- Calculate: (kicks / duration_in_seconds) * 60 = expected kicks/min
- Compare with reported B-1 value in V2 data

#### Test Video 3: Short Video (<2 seconds)
1. Record a very short video (1-2 seconds)
2. Tap **Analyze**

**Expected Output**:
```
Overall Score: 40-60/100
Confidence: <0.8 (should be lower)

Improvements should include:
  - "Record longer video (5+ seconds) with clear side view"
  OR similar guidance about video quality
```

---

### Step 4: Inspect V2 Data (Advanced)

If you have access to Dart DevTools or can add debug logging:

```dart
// In video_analysis_provider.dart after analysis completes:
print('=== V2 DATA ===');
final v2Data = analysisData['v2Data'];
print('Version: ${v2Data['version']}');
print('Confidence: ${v2Data['overallConfidence']}');
print('Phases: ${v2Data['phases']}');
print('Metrics:');
v2Data['metrics'].forEach((key, value) {
  print('  $key: value=${value['value']}, score=${value['score']}, conf=${value['confidence']}');
});
```

**Expected Console Output**:
```
=== V2 DATA ===
Version: 2.0
Confidence: 0.6-0.9
Phases: [{phase: START, ...}, {phase: TRAVEL, ...}]
Metrics:
  A-1: value=5.2, score=85.0, conf=0.9
  A-2: value=0.15, score=72.0, conf=0.85
  ...
```

---

### Step 5: Verify Key Features

#### 5.1 Normalization Test
1. Record same motion from 2 different distances:
   - **Test A**: Camera 1 meter away
   - **Test B**: Camera 2 meters away
2. Compare overall scores

**Expected**: Scores within ±15 points

#### 5.2 Edge Cases

Test these scenarios:

| Scenario | Action | Expected Behavior |
|----------|--------|-------------------|
| **Empty analysis** | Skip recording, try to analyze | Graceful error or default scores |
| **Very short video** | Record <1 second | Low confidence, helpful message |
| **Poor lighting** | Record in dim light | Lower confidence, may work |
| **Wrong angle** | Record from above/below | Lower scores, may warn |
| **Multiple analyses** | Analyze 3-5 videos in a row | No crashes, consistent results |

---

### Step 6: Check Results Display

Verify the UI displays correctly:

- [ ] Overall score shows (0-100)
- [ ] All category scores show
- [ ] Strengths list is populated (not empty)
- [ ] Improvements list is populated
- [ ] No error messages or crashes
- [ ] Results can be saved and viewed later

---

### Step 7: Performance Check

Monitor during analysis:

- [ ] Analysis completes in <2 seconds
- [ ] No app freezing or lag
- [ ] Memory usage stable
- [ ] Can analyze multiple videos without issues

---

## Validation Checklist

### Functional Requirements ✅

- [ ] App launches without errors
- [ ] Can record videos
- [ ] Analysis completes successfully
- [ ] Results display in UI
- [ ] Can switch between categories
- [ ] Can view past analyses

### V2 Service Requirements ✅

- [ ] Normalized metrics (test at different distances)
- [ ] Phase detection working (check v2Data)
- [ ] All metrics calculated (A-1 to A-6, B-1/B-3/B-4, D-2/D-4)
- [ ] Kick frequency NOT hardcoded (matches actual kicks)
- [ ] Confidence scoring working (high for good video, low for short)
- [ ] Backward compatible (UI works as before)

### Quality Requirements ✅

- [ ] No crashes or errors
- [ ] Fast analysis (<2s)
- [ ] Helpful feedback messages
- [ ] Scores seem reasonable
- [ ] Edge cases handled gracefully

---

## Troubleshooting

### Issue: Analysis Returns Default Scores (50/50/50)

**Possible Causes**:
- ML Kit not detecting poses (video quality issue)
- All frames filtered out (shoulder width < 10px)
- Empty poses list

**Debug**:
```dart
// Check pose detection:
print('Detected ${poses.length} poses');
print('First pose landmarks: ${poses.first.landmarks.length}');
```

### Issue: Low Scores Across All Metrics

**Possible Causes**:
- Poor video quality
- Wrong camera angle
- Fast movements (motion blur)

**Solution**: Record with:
- Good lighting
- Side view (profile)
- Slow, steady movements
- Camera stable (not shaking)

### Issue: Confidence Always Low

**Possible Causes**:
- Short videos (<3 seconds)
- Poor landmark detection
- Missing critical landmarks

**Debug**:
```dart
// Check v2 confidence breakdown:
final v2Data = result.poseData;
print('Landmark confidence: ${frameConfidences}');
print('Frame count: ${v2Data['metadata']['frameCount']}');
```

---

## Success Criteria

Consider testing successful if:

1. ✅ Can record and analyze videos without crashes
2. ✅ Scores vary based on actual form (not always same)
3. ✅ Kick frequency matches actual counted kicks (±10%)
4. ✅ Different distances give similar scores (±15 points)
5. ✅ Short videos handled gracefully (no crashes)
6. ✅ Feedback messages are helpful and accurate
7. ✅ V2 data accessible in poseData field

---

## Report Findings

After testing, document:

1. **Test Videos**: Number of videos tested, durations
2. **Results**: Sample scores and feedback
3. **Issues Found**: Any crashes, errors, or unexpected behavior
4. **V2 Data Quality**: Confidence levels, metric values
5. **Normalization**: Score differences at different distances
6. **Recommendations**: Any improvements or adjustments needed

---

## Example Test Report Template

```markdown
## Manual Test Report

**Date**: _______
**Tester**: _______
**Device**: _______

### Test Results

| Test | Status | Notes |
|------|--------|-------|
| Streamline video | ✅/❌ | Score: ___, Confidence: ___ |
| Finning video | ✅/❌ | Kicks detected: ___ |
| Short video | ✅/❌ | Handled gracefully: Yes/No |
| Normalization | ✅/❌ | Score diff: ___ points |
| Edge cases | ✅/❌ | Any crashes: Yes/No |

### V2 Data Sample
```
Version: ___
Confidence: ___
Phases: ___
Metrics: ___
```

### Issues Found
1. ___
2. ___

### Recommendations
1. ___
2. ___

### Approval
- [ ] Ready for production
- [ ] Needs fixes (list above)
```

---

## Next Steps After Manual Testing

1. **If all tests pass**: Deploy to production
2. **If issues found**:
   - Document issues
   - Fix critical bugs
   - Re-test
3. **Production monitoring**:
   - Track analysis success rate
   - Monitor confidence levels
   - Gather user feedback

---

**Testing Status**: ⏳ Pending Manual Testing
**Automated Tests**: ✅ All Passed (27/27)
**Ready for**: Manual Testing with Real Videos
