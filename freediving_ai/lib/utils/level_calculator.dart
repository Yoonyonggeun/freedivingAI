/// Level calculation utilities for DNF Indoor AI MVP
///
/// Implements 5-tier leveling system:
/// - Provisional Level: Based only on PB distance
/// - Official Level: Based on PB + Technique modifier (video-based)

class LevelCalculator {
  /// Calculate provisional level from PB distance (1-5)
  ///
  /// Tiers:
  /// - L1: < 25m
  /// - L2: 25-49m
  /// - L3: 50-74m
  /// - L4: 75-99m
  /// - L5: >= 100m
  static int calculateProvisionalLevel(double pbMeters) {
    if (pbMeters < 25) return 1;
    if (pbMeters < 50) return 2;
    if (pbMeters < 75) return 3;
    if (pbMeters < 100) return 4;
    return 5;
  }

  /// Calculate official level from provisional level + technique score
  ///
  /// Technique modifier:
  /// - >= 80: +1 level
  /// - 55-79: +0 level
  /// - < 55: -1 level
  ///
  /// Result is clamped to [1..5]
  ///
  /// Returns null if:
  /// - confidence < 0.60
  /// - classification != DNF
  /// - techniqueScore is null
  static int? calculateOfficialLevel({
    required int provisionalLevel,
    required double? techniqueScore,
    required double confidence,
    required String classification,
    bool levelTestEligible = true,
  }) {
    // Gate official level assignment
    if (!levelTestEligible ||
        confidence < 0.60 ||
        classification != 'DNF' ||
        techniqueScore == null) {
      return null;
    }

    // Apply technique modifier
    int modifier = 0;
    if (techniqueScore >= 80) {
      modifier = 1;
    } else if (techniqueScore < 55) {
      modifier = -1;
    }

    // Clamp to [1..5]
    final officialLevel = provisionalLevel + modifier;
    return officialLevel.clamp(1, 5);
  }

  /// Get level name for display
  static String getLevelName(int level) {
    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Developing';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Elite';
      default:
        return 'Unknown';
    }
  }

  /// Get level description
  static String getLevelDescription(int level, {bool isProvisional = false}) {
    final prefix = isProvisional ? 'Provisional' : 'Official';
    final name = getLevelName(level);

    switch (level) {
      case 1:
        return '$prefix Level 1 ($name): Building foundation, focus on basics';
      case 2:
        return '$prefix Level 2 ($name): Developing skills, improving consistency';
      case 3:
        return '$prefix Level 3 ($name): Solid technique, ready for longer distances';
      case 4:
        return '$prefix Level 4 ($name): Advanced skills, competition-ready technique';
      case 5:
        return '$prefix Level 5 ($name): Elite performance, mastery of DNF';
      default:
        return 'Unknown level';
    }
  }

  /// Get PB range for a given level
  static String getPBRangeForLevel(int level) {
    switch (level) {
      case 1:
        return '< 25m';
      case 2:
        return '25-49m';
      case 3:
        return '50-74m';
      case 4:
        return '75-99m';
      case 5:
        return '≥ 100m';
      default:
        return 'Unknown';
    }
  }

  /// Check if official level can be assigned
  static bool canAssignOfficialLevel({
    required double confidence,
    required String classification,
    required double? techniqueScore,
    bool levelTestEligible = true,
  }) {
    return levelTestEligible &&
           confidence >= 0.60 &&
           classification == 'DNF' &&
           techniqueScore != null;
  }

  /// Get reasons why official level was not assigned
  static List<String> getOfficialLevelNotAssignedReasons({
    required double confidence,
    required String classification,
    required double? techniqueScore,
    bool levelTestEligible = true,
    List<String> failedRequirements = const [],
  }) {
    final reasons = <String>[];

    if (!levelTestEligible) {
      reasons.add('Level test requirements not met');
      reasons.addAll(failedRequirements);
    }

    if (confidence < 0.60) {
      reasons.add('Analysis confidence too low (${(confidence * 100).toStringAsFixed(0)}%, need >= 60%)');
    }

    if (classification != 'DNF') {
      reasons.add('Video classified as $classification, not DNF');
    }

    if (techniqueScore == null) {
      reasons.add('Technique score not available');
    }

    return reasons;
  }
}
