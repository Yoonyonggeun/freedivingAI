# Quick Start Guide - Static Training Templates

## What's New?

Your FreeDiving AI app now has a **Template-Based Static Training System** with:
- ✅ Create up to 2 reusable training templates
- ✅ Custom per-round hold and rest times (1-10 rounds)
- ✅ Audio alerts for phase transitions
- ✅ Haptic feedback (vibrations)
- ✅ Visual countdown warnings
- ✅ Accurate pause time tracking
- ✅ Proper incomplete session handling

---

## Installation Steps

### 1. Install Dependencies
```bash
cd freediving_ai
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Add Audio Files (Recommended)

Download these 4 free sound effects and place them in `freediving_ai/assets/sounds/`:

**Required Files**:
- `hold_start.mp3` - Single beep (hold begins)
- `hold_end.mp3` - Double beep (hold ends)
- `rest_start.mp3` - Soft tone (rest begins)
- `training_complete.mp3` - Success chime (training done)

**Free Sources**:
- https://freesound.org/ (search "beep short")
- https://mixkit.co/free-sound-effects/beep/
- Or use any royalty-free beeps (max 3 seconds each)

**Skip Audio?** App works without audio files (haptic-only mode).

### 3. Run the App
```bash
flutter run
```

---

## How to Use

### Create Your First Template

1. **Open App** → Tap "Static Training" tile on home screen
2. **Create Template** → Tap the blue "Create Template" button
3. **Enter Details**:
   - Template Name: "Morning Routine" (or any name)
   - Number of Rounds: 5
4. **Configure Each Round**:
   - Round 1: Hold 30s, Rest 60s
   - Round 2: Hold 40s, Rest 55s
   - Round 3: Hold 50s, Rest 50s
   - Round 4: Hold 60s, Rest 45s
   - Round 5: Hold 70s (no rest - last round)
5. **Save** → Tap "Save Template"
6. **Done!** Your template is now in the list

### Start Training

1. **Select Template** → Tap "START" button on your template
2. **Begin** → Tap the play button (⯈)
3. **Listen/Feel**:
   - 🔊 Hold start sound + vibration
   - 🟡 Orange glow at 10 seconds remaining
   - 📳 Triple vibration at 3 seconds remaining
   - 🔊 Hold end sound + rest start sound
4. **Features**:
   - **Pause**: Tap pause button (⏸) anytime
   - **Skip Hold**: Tap checkmark (✓) to end hold early
   - **Quit**: Pause → Tap stop (⏹) → Progress saved as incomplete

### Edit a Template

1. **Template List** → Tap "EDIT" button
2. **Modify** → Change name, rounds, or times
3. **Save** → Tap "Save Template"

### Delete a Template

1. **Template List** → Tap trash icon (🗑)
2. **Confirm** → Tap "Delete"
3. **Note**: Can create new template after deletion

---

## Features Explained

### Template Limit (2 Max)
- Only 2 templates can exist at once
- Delete one to create another
- Prevents clutter and encourages intentional design

### Per-Round Configuration
- Each round has its own hold and rest time
- Allows progressive training (increasing difficulty)
- Or recovery training (decreasing difficulty)

### Smart Pause Tracking
- Paused time doesn't count toward hold duration
- Example: 60s hold, pause 10s, resume → still need 60s total hold
- Accurate performance tracking

### Incomplete Sessions
- Quit mid-training? Progress is saved
- Session marked as "incomplete"
- Records how many rounds you completed
- Useful for analyzing patterns

### Audio Feedback
- Plays at phase transitions (hold → rest → hold)
- Completion sound when all rounds done
- Works without headphones (uses device speaker)
- Gracefully degrades if sound files missing

### Haptic Feedback
- Vibrations at every phase change
- Triple vibration at 3-second countdown
- Works on physical devices only (not simulator)
- Helps during eyes-closed breath holds

### Visual Warnings
- 10 seconds remaining: Orange glow around timer
- Prevents surprise when time runs out
- Combines with haptic countdown

---

## Troubleshooting

### "Template limit reached (2/2)"
**Solution**: Delete one template to create a new one.

### No Sound Playing
**Possible Causes**:
1. Audio files not added to `assets/sounds/` folder
2. Device volume is muted
3. File names don't match exactly (case-sensitive)

**Solution**: Add audio files or use haptic-only mode.

### No Haptic Feedback
**Possible Causes**:
1. Running in iOS Simulator (haptics don't work there)
2. Device has vibration disabled in settings

**Solution**: Test on physical device with vibration enabled.

### Timer Doesn't Auto-Advance
**Possible Cause**: Timer reached 0:00 during hold phase.

**Expected Behavior**: Should auto-advance to rest (or next round).

**If Not Working**: Check console for errors.

### Template Not Saving
**Possible Cause**: Template name is empty or validation failed.

**Solution**:
- Enter a name (required)
- Rounds: 1-10
- Hold/Rest times: 10-600 seconds

---

## Sample Templates

### Beginner CO2 Table
```
Name: "Beginner CO2"
Rounds: 5
Round 1: Hold 30s, Rest 60s
Round 2: Hold 30s, Rest 55s
Round 3: Hold 30s, Rest 50s
Round 4: Hold 30s, Rest 45s
Round 5: Hold 30s
Total: 3:40
```

### Intermediate O2 Table
```
Name: "O2 Progressive"
Rounds: 6
Round 1: Hold 45s, Rest 90s
Round 2: Hold 60s, Rest 90s
Round 3: Hold 75s, Rest 90s
Round 4: Hold 90s, Rest 90s
Round 5: Hold 105s, Rest 90s
Round 6: Hold 120s
Total: 14:15
```

### Advanced Mixed Table
```
Name: "Peak Performance"
Rounds: 8
Round 1: Hold 60s, Rest 120s
Round 2: Hold 75s, Rest 110s
Round 3: Hold 90s, Rest 100s
Round 4: Hold 105s, Rest 90s
Round 5: Hold 120s, Rest 80s
Round 6: Hold 120s, Rest 70s
Round 7: Hold 120s, Rest 60s
Round 8: Hold 120s
Total: 21:00
```

---

## Tips for Best Results

1. **Test Audio First**:
   - Create a short 2-round template
   - Run through once to verify sounds work
   - Adjust device volume if needed

2. **Progressive Overload**:
   - Start with easier templates
   - Gradually increase hold times or decrease rest times
   - Create new template each week with +5-10s progression

3. **Use Pause Wisely**:
   - Only for emergencies (coughing, phone call)
   - Paused time doesn't count, but breaks flow
   - Better to quit and restart if needed

4. **Track Progress**:
   - Check training history after each session
   - Compare completed vs. incomplete sessions
   - Adjust template difficulty based on completion rate

5. **Eyes-Closed Training**:
   - Haptic feedback lets you train with eyes closed
   - Triple vibration warns of imminent hold end
   - Completion vibration confirms session done

---

## Next Steps

1. ✅ **Create Templates**: Make your first training template
2. ✅ **Add Sounds**: Download and add audio files (optional)
3. ✅ **Test Training**: Run through a full session
4. ✅ **Check History**: View your session in training history
5. ✅ **Iterate**: Adjust template based on performance

---

## Need Help?

- **Implementation Details**: See `IMPLEMENTATION_SUMMARY.md`
- **Audio Files Guide**: See `freediving_ai/assets/sounds/README.md`
- **Code Reference**: All files have inline comments

---

**Ready to dive in!** 🌊

Start by creating your first template and experiencing the new audio/haptic feedback system.
