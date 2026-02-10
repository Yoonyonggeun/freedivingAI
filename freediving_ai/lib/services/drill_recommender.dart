/// Level-based drill recommendation system
///
/// Provides personalized drills based on:
/// - Official/Provisional level (1-5)
/// - Detected technique issues
/// - Analysis confidence
class DrillRecommender {
  /// Get drill recommendations
  ///
  /// Returns list of drill strings with full details
  static List<String> getDrills({
    int? officialLevel,
    int? provisionalLevel,
    double confidence = 0.0,
    List<String> topIssues = const [],
    String? analysisMode,
  }) {
    // Quick Feedback mode → generic safe drills (3-5)
    if (analysisMode == 'QUICK_FEEDBACK') {
      return _getQuickFeedbackDrills(provisionalLevel ?? 1);
    }

    // Level Test mode → issue-based + level-based (4-8)
    if (analysisMode == 'LEVEL_TEST' && officialLevel != null) {
      return _getLevelSpecificDrills(officialLevel, topIssues);
    }

    // Legacy fallback
    if (officialLevel == null || confidence < 0.60) {
      return _getGenericDrillsWithCaptureTips(provisionalLevel ?? 1);
    }

    return _getLevelSpecificDrills(officialLevel, topIssues);
  }

  /// Quick Feedback drills (3-5 safe generic drills, no capture tips)
  static List<String> _getQuickFeedbackDrills(int provisionalLevel) {
    final drills = <String>[];

    drills.add(_getFoundationDrill(provisionalLevel));

    switch (provisionalLevel) {
      case 1:
      case 2:
        drills.addAll([
          'Drill: Streamline hold - Hold streamline position against wall for 10 seconds, 3 sets.',
          'Drill: Wall push-off practice - Push off wall in streamline, glide as far as possible, 10 reps.',
          'Drill: Single kick + glide - 25m, 4 reps. Focus on kick power and glide length.',
        ]);
        break;
      case 3:
      case 4:
        drills.addAll([
          'Drill: Streamline + 5 kicks - Push off wall, hold streamline, then 5 controlled kicks, 4 x 50m.',
          'Drill: Kick tempo variation - Alternate 25m slow kicks with 25m normal tempo, 4 sets.',
          'Drill: Distance per stroke challenge - Minimize kicks per 25m, 6 reps.',
        ]);
        break;
      default:
        drills.addAll([
          'Drill: Race pace intervals - 50m at race pace, 6 reps, 90s rest.',
          'Drill: Variable tempo training - Mix slow and fast 25m segments, 6 x 75m.',
          'Drill: Technique under fatigue - 3 x 100m maintaining perfect form.',
        ]);
    }

    return drills.take(5).toList();
  }

  /// Generic drills + capture improvement tips (for low confidence or no official level)
  static List<String> _getGenericDrillsWithCaptureTips(int provisionalLevel) {
    final drills = <String>[];

    // Basic drills for the level
    switch (provisionalLevel) {
      case 1: // Beginner
        drills.addAll([
          'Drill: Streamline hold - Hold streamline position against wall for 10 seconds, 3 sets. Focus on keeping arms straight and tight to ears.',
          'Drill: Wall push-off practice - Push off wall in streamline, glide as far as possible, 10 reps. Count glide distance each time.',
        ]);
        break;
      case 2: // Developing
        drills.addAll([
          'Drill: Streamline + 3 kicks - Push off wall, hold streamline for 2-3 seconds, then 3 slow breaststroke kicks, 4 x 25m.',
          'Drill: Kick timing practice - Focus on pause after each kick, feel water pressure on chest, 4 x 25m.',
        ]);
        break;
      case 3: // Intermediate
        drills.addAll([
          'Drill: Streamline + 5 kicks - Push off wall, hold streamline, then 5 controlled kicks with extended glide, 4 x 50m.',
          'Drill: Kick tempo variation - Alternate 25m slow kicks (emphasis on glide) with 25m normal tempo, 4 sets.',
        ]);
        break;
      case 4: // Advanced
        drills.addAll([
          'Drill: Turn + sprint intervals - Practice turn execution followed by 15m sprint, 8 sets with 45s rest.',
          'Drill: Variable tempo training - Mix slow (glide-focused) and fast (power-focused) 25m segments, 6 x 75m.',
        ]);
        break;
      case 5: // Elite
        drills.addAll([
          'Drill: Competition pace simulation - Full pool length at race pace, focus on maintaining technique, 3 reps with 2min rest.',
          'Drill: Power undulation with resistance - Use resistance band, practice explosive kicks, 6 x 25m.',
        ]);
        break;
    }

    // Add capture improvement tips
    drills.addAll([
      'Capture Tip: Film from side angle for best body visibility',
      'Capture Tip: Ensure full body is in frame throughout the swim',
      'Capture Tip: Film at least 8-15 seconds of continuous swimming',
      'Capture Tip: Include at least 3 complete kick cycles',
    ]);

    return drills;
  }

  /// Level-specific drills based on detected issues
  static List<String> _getLevelSpecificDrills(int level, List<String> topIssues) {
    final drills = <String>[];

    // Foundation drill for the level (always included)
    drills.add(_getFoundationDrill(level));

    // Add 2 drills per top issue (max 3 issues = 6 drills)
    final issuesToAddress = topIssues.take(3).toList();

    for (final issue in issuesToAddress) {
      drills.addAll(_getDrillsForIssue(issue, level));
    }

    // Ensure we have at least 4 drills
    if (drills.length < 4) {
      drills.addAll(_getSupplementaryDrills(level).take(4 - drills.length));
    }

    return drills.take(8).toList(); // Max 8 drills
  }

  /// Foundation drill for each level
  static String _getFoundationDrill(int level) {
    switch (level) {
      case 1:
        return 'Foundation: Streamline hold (10s, 3 sets) - Build core strength and body awareness. '
            'Setup: Against wall, arms overhead, hands stacked, squeeze ears with biceps. '
            'Key cue: Feel tension from fingertips to toes. '
            'Common mistake: Arching back or letting arms drift apart.';

      case 2:
        return 'Foundation: Streamline + 3 kicks (4 x 25m, 30s rest) - Develop kick-glide rhythm. '
            'Setup: Push off wall in streamline, 3 controlled breaststroke kicks. '
            'Key cues: Point toes on recovery, feel water pressure on chest during glide. '
            'Progression: Increase to 5 kicks. Regression: 2 kicks only.';

      case 3:
        return 'Foundation: Full stroke technique (4 x 50m, 45s rest) - Refine complete DNF motion. '
            'Setup: Focus on one technique element per length (streamline, kick, glide, rhythm). '
            'Key cues: Maintain horizontal body position, maximize glide between kicks. '
            'Progression: Add 25m to distance. Regression: Reduce to 25m segments.';

      case 4:
        return 'Foundation: Turn practice with glide (10 turns, 30s rest) - Master efficient turns. '
            'Setup: Approach wall at swimming pace, execute turn, hold streamline 3-5s. '
            'Key cues: Tight tuck, quick rotation, explosive push-off, immediate streamline. '
            'Progression: Add sprint after turn. Regression: Slow approach.';

      case 5:
        return 'Foundation: Race pace simulation (3 x full pool, 2min rest) - Competition readiness. '
            'Setup: Swim at target competition pace, focus on technique under fatigue. '
            'Key cues: Maintain form throughout, control breathing, efficient turns. '
            'Progression: Increase to 5 reps. Regression: Reduce to half pool.';

      default:
        return _getFoundationDrill(1);
    }
  }

  /// Get drills for specific technique issues
  static List<String> _getDrillsForIssue(String issue, int level) {
    final drills = <String>[];

    if (issue.toLowerCase().contains('streamline') ||
        issue.toLowerCase().contains('body position')) {
      drills.addAll([
        'Streamline refinement: Underwater streamline hold (15s, 4 sets) - Push off wall, hold perfect streamline underwater. '
            'Goal: Improve body alignment and reduce drag. '
            'Key cues: Squeeze head between arms, lock elbows, point toes. '
            'Progression: Add slow kicks while maintaining streamline.',

        'Body position drill: Superman glide (4 x 25m) - Push off, arms at sides, focus on horizontal body position. '
            'Goal: Develop core strength and body awareness. '
            'Key cues: Keep chest down, hips up, look at bottom of pool. '
            'Regression: Use kickboard under chest for support.',
      ]);
    }

    if (issue.toLowerCase().contains('kick') ||
        issue.toLowerCase().contains('leg')) {
      drills.addAll([
        'Kick technique drill: Slow-motion kicks (4 x 25m) - Execute each kick in slow motion, focus on form. '
            'Goal: Perfect kick mechanics and muscle memory. '
            'Key cues: Wide knees, feet together on recovery, explosive snap. '
            'Common mistakes: Rushing recovery, not flexing ankles.',

        'Kick power drill: Resistance kicks (6 x 15m) - Use drag shorts or resistance band. '
            'Goal: Build kick strength and power. '
            'Sets: 6 reps, 45s rest between. '
            'Progression: Increase resistance. Regression: Remove resistance, focus on form.',
      ]);
    }

    if (issue.toLowerCase().contains('glide') ||
        issue.toLowerCase().contains('efficiency')) {
      drills.addAll([
        'Glide extension drill: 1 kick + maximum glide (4 x 50m) - One powerful kick, glide until almost stopped. '
            'Goal: Maximize distance per kick. '
            'Key cues: Hold streamline during entire glide, feel deceleration. '
            'Progression: Count strokes per length, try to reduce.',

        'Efficiency drill: Stroke count challenge (4 x 25m) - Minimize number of kicks per length. '
            'Goal: Improve kick power and glide. '
            'Setup: Count kicks, try to beat your record each set. '
            'Progression: Increase distance to 50m.',
      ]);
    }

    if (issue.toLowerCase().contains('rhythm') ||
        issue.toLowerCase().contains('tempo') ||
        issue.toLowerCase().contains('timing')) {
      drills.addAll([
        'Rhythm drill: Metronome kicks (4 x 50m) - Use poolside timer or count in head (e.g., 1-2-3 glide, kick). '
            'Goal: Develop consistent kick rhythm. '
            'Key cues: Same tempo throughout, don\'t rush when tired. '
            'Progression: Vary tempo (slow vs fast sets).',

        'Tempo variation drill: Pyramid tempo (1 x continuous) - 25m slow, 25m medium, 25m fast, 25m medium, 25m slow. '
            'Goal: Control tempo at different speeds while maintaining form. '
            'Rest: 15s between segments. '
            'Progression: Add more segments.',
      ]);
    }

    if (issue.toLowerCase().contains('turn')) {
      drills.addAll([
        'Turn technique drill: Wall touch turns (10 reps) - Approach wall, two-hand touch, tuck, pivot, push. '
            'Goal: Master efficient turn mechanics. '
            'Key cues: Tight tuck, quick rotation, plant feet high on wall. '
            'Common mistakes: Slow rotation, feet too low, weak push-off.',

        'Turn to streamline drill: Turn + 5m sprint (8 sets, 30s rest) - Execute turn, explosive push-off, maintain speed 5m. '
            'Goal: Maximize turn efficiency and maintain momentum. '
            'Progression: Extend sprint to 10m.',
      ]);
    }

    // If no specific drills matched, return supplementary drills
    if (drills.isEmpty) {
      return _getSupplementaryDrills(level).take(2).toList();
    }

    return drills.take(2).toList(); // 2 drills per issue
  }

  /// Supplementary drills (when not enough issue-specific drills)
  static List<String> _getSupplementaryDrills(int level) {
    if (level <= 2) {
      return [
        'Wall push-off practice: 10 reps - Perfect streamline, powerful push, maximum glide distance.',
        'Vertical kick practice: 30s intervals, 4 sets - Develops kick power and endurance.',
        'Balance drill: One-arm streamline (4 x 25m each arm) - Improves body rotation control.',
      ];
    } else if (level <= 4) {
      return [
        'Hypoxic training: 25m breathless intervals (6 reps, 60s rest) - Builds CO2 tolerance.',
        'Speed variation: 25m sprint / 25m easy (8 x 50m) - Develops pace control.',
        'Underwater streamline: 15m max distance (5 reps) - Perfects streamline under pressure.',
      ];
    } else {
      return [
        'Race pace intervals: 50m at race pace (6 reps, 90s rest) - Competition simulation.',
        'VO2 max sets: 25m sprints (12 reps, 30s rest) - Maximum aerobic capacity.',
        'Technique under fatigue: 3 x 100m maintaining perfect form - Mental toughness.',
      ];
    }
  }
}
