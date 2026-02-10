# DNF Video Analysis - Quick Start Guide

## Installation (5 minutes)

### 1. Install Dependencies

```bash
cd freediving_ai
flutter pub get
```

### 2. Verify Installation

Run this test to ensure FFmpeg is working:

```bash
flutter run
# In app, navigate to video upload
# Select any short video clip
# Check logs for "Executing FFmpeg" message
```

## First Analysis (3 steps)

### Step 1: Record DNF Clip

**Requirements:**
- Duration: 8-15 seconds minimum
- Angle: Side view of swimmer
- Visibility: Clear water, good lighting
- Frame: Full body visible
- Format: .mp4 or .mov

**Best practices:**
- Mount camera on pool deck (stable position)
- Swimmer fills 60-80% of frame
- Avoid reflections on water surface
- Record continuous swimming (not just one kick)

### Step 2: Upload & Analyze

```dart
// In your Flutter app
await analysisProvider.analyzeVideo(
  videoPath: selectedVideoPath,
  discipline: 'DNF',  // ← Important!
  category: 'full_clip',
  profile: userProfile,
);
```

### Step 3: View Results

Results appear in 7-15 seconds with:
- **Overall Score**: 0-100 based on valid metrics
- **Timeline**: Visual breakdown of START/TRAVEL/TURN + motions
- **Coaching**: Specific improvements with drill recommendations
- **Warnings**: If data quality insufficient

## Expected Log Output (Success)

```
[VideoAnalysis] Starting frame extraction
[VideoFrameExtractor] Extracted 47 frames
[VideoAnalysis] Pose detection complete: 43 poses
[VideoAnalysis] Valid frame rate: 91.5%
[DNFAnalyzer] START not detected: video begins mid-movement
[VideoAnalysis] Using DNF Full Analyzer
Analysis complete: Overall score 73.5
```

## Expected Log Output (Warning)

```
[VideoAnalysis] Valid frame rate: 34.2% (16/47)
[VideoAnalysis] WARNING: Low valid frame rate
[DNFAnalyzer] Insufficient kick cycles (2/3)
Coaching: "Insufficient data - record longer clip with better visibility"
```

## Interpreting Results

### High Confidence (Score Reliable)

```json
{
  "overallScore": 76.3,
  "categoryScores": {
    "streamline": 82.1,  // Confidence: 0.85
    "kick": 74.2,        // Confidence: 0.85, Cycles: 5
    "glide": 72.5        // Confidence: 0.70
  },
  "coaching": {
    "strengths": ["Excellent streamline position"],
    "improvements": ["Work on leg symmetry"],
    "drills": ["Breaststroke kick on back drill"],
    "warnings": []  // Empty = good data quality
  }
}
```

### Low Confidence (Need Better Video)

```json
{
  "overallScore": 50.0,
  "categoryScores": {},  // Empty = no valid metrics
  "coaching": {
    "strengths": [],
    "improvements": [],
    "drills": [],
    "warnings": [
      "Too few frames (18). Minimum 20 frames required.",
      "Insufficient kick cycles (1/3)"
    ]
  }
}
```

## Common Issues & Quick Fixes

| Issue | Fix |
|-------|-----|
| "FFmpeg execution failed" | Update `ffmpeg_kit_flutter` package |
| Valid frame rate < 50% | Record in better lighting, side angle |
| "Insufficient kick cycles" | Record longer clip (10-15s minimum) |
| Scores all 0.0 | Check `discipline == 'DNF'` in code |
| Analysis takes > 20s | Reduce fps to 3 or scale to 480p |

## Performance Tuning

Edit `video_analysis_provider.dart` line ~380:

```dart
// Current (balanced)
final framePaths = await _frameExtractor.extractFrames(
  videoPath,
  fps: 5,       // ← Reduce to 3 if slow
  scale: '720:-2',  // ← Change to '480:-2' if memory issues
  quality: 4,   // ← Reduce to 2 if pose detection fails
);
```

## Next Steps

1. **Test with 3-5 different clips** to understand quality requirements
2. **Review DNF_IMPLEMENTATION_GUIDE.md** for detailed architecture
3. **Check dnf_drills.json** for full drill database
4. **Monitor logs** during analysis to diagnose issues

## Support

If analysis consistently fails or produces incorrect results:

1. Check logs for specific error messages
2. Verify video meets requirements (see Step 1 above)
3. Test with sample video from repository
4. File issue with:
   - Video specs (duration, resolution, format)
   - Full log output
   - Screenshot of result

---

**Quick Start Version**: v1.0
**Last Updated**: 2026-02-06
