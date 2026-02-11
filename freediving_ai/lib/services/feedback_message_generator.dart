import '../models/component_result.dart';

/// Generates user-facing feedback messages with measurement basis.
///
/// Feedback messages include:
/// - Technical assessment of the component
/// - Score/performance level
/// - Measurement basis (time ranges, confidence, duration)
/// - Actionable recommendations
///
/// Example:
/// "Your streamline shows good form with a score of 75/100.
///  Based on 3.2s of clear video (frames 2.0-5.2s, 85% confidence),
///  we observed consistent body alignment. Focus on tightening your core
///  for even better results."
class FeedbackMessageGenerator {
  /// Generate feedback message for a component result.
  ///
  /// Returns null if component is not measurable or has no feedback to provide.
  static String? generateFeedback({
    required ComponentResult component,
    bool includeMeasurementBasis = true,
    bool includeRecommendation = true,
  }) {
    // Skip if not measurable
    if (!component.isMeasurable) {
      return null;
    }

    final buffer = StringBuffer();

    // 1. Component name and status
    final componentName = _getComponentDisplayName(component.componentId);
    buffer.write('Your $componentName ');

    // 2. Performance assessment
    buffer.write(_getPerformanceAssessment(component));

    // 3. Score (if available)
    if (component.score != null) {
      buffer.write(' with a score of ${component.score!.toStringAsFixed(0)}/100');
    }
    buffer.write('. ');

    // 4. Measurement basis (if requested and available)
    if (includeMeasurementBasis) {
      final basis = _formatMeasurementBasis(component);
      if (basis != null) {
        buffer.write(basis);
        buffer.write(' ');
      }
    }

    // 5. Specific observations
    final observations = _getComponentObservations(component);
    if (observations != null) {
      buffer.write(observations);
      buffer.write(' ');
    }

    // 6. Recommendation (if requested)
    if (includeRecommendation) {
      final recommendation = _getRecommendation(component);
      if (recommendation != null) {
        buffer.write(recommendation);
      }
    }

    return buffer.toString().trim();
  }

  /// Generate a compact feedback message (without measurement basis).
  static String? generateCompactFeedback({
    required ComponentResult component,
  }) {
    return generateFeedback(
      component: component,
      includeMeasurementBasis: false,
      includeRecommendation: true,
    );
  }

  /// Generate measurement basis string.
  ///
  /// Examples:
  /// - "Based on 3s of clear video across 2 segments"
  /// - "Based on 5s of video (medium visibility)"
  /// - "Based on limited data (1s, 48% confidence)"
  static String? _formatMeasurementBasis(ComponentResult component) {
    if (component.measurementBasis.isEmpty) return null;

    // Otherwise, construct from time ranges and confidence
    final totalDuration = component.timeRanges.fold<double>(
      0.0,
      (sum, range) => sum + range.duration,
    );

    if (totalDuration == 0.0 && component.rawConfidence == 0.0) {
      return null;
    }

    final buffer = StringBuffer();
    buffer.write('Based on ');

    if (totalDuration > 0.0) {
      // Round duration to whole seconds for cleaner display
      final roundedDuration = totalDuration.round();
      buffer.write('${roundedDuration}s of ');

      // Qualify video quality based on confidence
      if (component.confidenceLevel == ConfidenceLevel.high) {
        buffer.write('clear video');
      } else if (component.confidenceLevel == ConfidenceLevel.medium) {
        buffer.write('video');
      } else {
        buffer.write('limited video');
      }

      // Add segment count if multiple
      if (component.timeRanges.length > 1) {
        buffer.write(' across ${component.timeRanges.length} segments');
      }

      // Add visibility note for medium/low confidence
      if (component.confidenceLevel == ConfidenceLevel.medium) {
        buffer.write(' (medium visibility)');
      } else if (component.confidenceLevel == ConfidenceLevel.low) {
        buffer.write(' (${(component.rawConfidence * 100).round()}% confidence)');
      }
    } else {
      // No time ranges, just confidence
      buffer.write('${(component.rawConfidence * 100).round()}% confidence measurement');
    }

    buffer.write('.');
    return buffer.toString();
  }

  /// Get component display name.
  static String _getComponentDisplayName(String componentId) {
    switch (componentId) {
      case 'streamline':
        return 'streamline';
      case 'kick':
        return 'kick technique';
      case 'arm':
        return 'arm stroke';
      case 'glide':
        return 'glide efficiency';
      case 'start':
        return 'start/push-off';
      case 'turn':
        return 'turn execution';
      default:
        return componentId;
    }
  }

  /// Get performance assessment based on score and status.
  static String _getPerformanceAssessment(ComponentResult component) {
    final score = component.score ?? 50.0;

    // Status-specific qualifiers
    if (component.status == ComponentStatus.partial) {
      if (score >= 70) {
        return 'shows promising form';
      } else if (score >= 50) {
        return 'shows developing technique';
      } else {
        return 'shows early-stage technique';
      }
    }

    // Score-based assessment for confirmed status
    if (score >= 90) {
      return 'demonstrates excellent form';
    } else if (score >= 80) {
      return 'shows strong technique';
    } else if (score >= 70) {
      return 'shows good form';
    } else if (score >= 60) {
      return 'shows solid fundamentals';
    } else if (score >= 50) {
      return 'shows developing form';
    } else {
      return 'needs improvement';
    }
  }

  /// Get component-specific observations from subMetrics.
  static String? _getComponentObservations(ComponentResult component) {
    final subMetrics = component.subMetrics;
    if (subMetrics == null || subMetrics.isEmpty) return null;

    final componentId = component.componentId;

    switch (componentId) {
      case 'streamline':
        return _getStreamlineObservations(subMetrics);
      case 'kick':
        return _getKickObservations(subMetrics);
      case 'arm':
        return _getArmObservations(subMetrics);
      case 'glide':
        return _getGlideObservations(subMetrics);
      case 'start':
        return _getStartObservations(subMetrics);
      case 'turn':
        return _getTurnObservations(subMetrics);
      default:
        return null;
    }
  }

  static String? _getStreamlineObservations(Map<String, dynamic> metrics) {
    final bodyAlignment = metrics['bodyAlignment'] as double?;
    final armPosition = metrics['armPosition'] as double?;

    if (bodyAlignment == null && armPosition == null) return null;

    final observations = <String>[];

    if (bodyAlignment != null) {
      if (bodyAlignment >= 0.85) {
        observations.add('excellent body alignment');
      } else if (bodyAlignment >= 0.70) {
        observations.add('good body alignment');
      } else {
        observations.add('body alignment could be improved');
      }
    }

    if (armPosition != null) {
      if (armPosition >= 0.85) {
        observations.add('arms well-positioned');
      } else if (armPosition >= 0.70) {
        observations.add('decent arm position');
      } else {
        observations.add('arms need better positioning');
      }
    }

    return observations.isEmpty ? null : 'We observed ${observations.join(' and ')}.';
  }

  static String? _getKickObservations(Map<String, dynamic> metrics) {
    final symmetry = metrics['symmetry'] as double?;
    final power = metrics['power'] as double?;

    if (symmetry == null && power == null) return null;

    final observations = <String>[];

    if (symmetry != null) {
      if (symmetry >= 0.85) {
        observations.add('symmetric kick motion');
      } else if (symmetry >= 0.70) {
        observations.add('mostly symmetric kicks');
      } else {
        observations.add('asymmetric kick motion');
      }
    }

    if (power != null) {
      if (power >= 0.85) {
        observations.add('strong kick power');
      } else if (power >= 0.70) {
        observations.add('moderate kick power');
      } else {
        observations.add('kicks lack power');
      }
    }

    return observations.isEmpty ? null : 'We observed ${observations.join(' with ')}.';
  }

  static String? _getArmObservations(Map<String, dynamic> metrics) {
    final sweepWidth = metrics['sweepWidth'] as double?;
    final timing = metrics['timing'] as double?;

    if (sweepWidth == null && timing == null) return null;

    final observations = <String>[];

    if (sweepWidth != null) {
      if (sweepWidth >= 0.85) {
        observations.add('optimal sweep width');
      } else if (sweepWidth >= 0.70) {
        observations.add('good sweep width');
      } else {
        observations.add('narrow sweep width');
      }
    }

    if (timing != null) {
      if (timing >= 0.85) {
        observations.add('excellent timing');
      } else if (timing >= 0.70) {
        observations.add('decent timing');
      } else {
        observations.add('timing needs work');
      }
    }

    return observations.isEmpty ? null : 'We observed ${observations.join(' and ')}.';
  }

  static String? _getGlideObservations(Map<String, dynamic> metrics) {
    final avgDuration = metrics['avgGlideDuration'] as double?;
    final intervalCount = metrics['intervalCount'] as int?;

    if (avgDuration == null && intervalCount == null) return null;

    final parts = <String>[];

    if (intervalCount != null && intervalCount > 0) {
      parts.add('detected $intervalCount glide ${intervalCount == 1 ? 'interval' : 'intervals'}');
    }

    if (avgDuration != null && avgDuration > 0) {
      parts.add('averaging ${avgDuration.toStringAsFixed(1)}s each');
    }

    return parts.isEmpty ? null : 'We ${parts.join(' ')}.';
  }

  static String? _getStartObservations(Map<String, dynamic> metrics) {
    final pushOffPower = metrics['pushOffPower'] as double?;

    if (pushOffPower == null) return null;

    if (pushOffPower >= 0.85) {
      return 'We observed powerful wall push-offs.';
    } else if (pushOffPower >= 0.70) {
      return 'We observed moderate push-off power.';
    } else {
      return 'We observed weak push-offs from the wall.';
    }
  }

  static String? _getTurnObservations(Map<String, dynamic> metrics) {
    final rotation = metrics['rotationSpeed'] as double?;
    final streamlineAfter = metrics['streamlineAfter'] as double?;

    if (rotation == null && streamlineAfter == null) return null;

    final observations = <String>[];

    if (rotation != null) {
      if (rotation >= 0.85) {
        observations.add('quick rotation');
      } else if (rotation >= 0.70) {
        observations.add('decent rotation speed');
      } else {
        observations.add('slow rotation');
      }
    }

    if (streamlineAfter != null) {
      if (streamlineAfter >= 0.85) {
        observations.add('excellent post-turn streamline');
      } else if (streamlineAfter >= 0.70) {
        observations.add('good post-turn streamline');
      } else {
        observations.add('weak post-turn streamline');
      }
    }

    return observations.isEmpty ? null : 'We observed ${observations.join(' and ')}.';
  }

  /// Get actionable recommendation based on score and component.
  static String? _getRecommendation(ComponentResult component) {
    final score = component.score ?? 50.0;

    // High scores get encouragement + refinement advice
    if (score >= 80) {
      return _getAdvancedRecommendation(component.componentId);
    }

    // Medium scores get specific improvement advice
    if (score >= 60) {
      return _getMediumRecommendation(component.componentId);
    }

    // Low scores get fundamental advice
    return _getFundamentalRecommendation(component.componentId);
  }

  static String _getAdvancedRecommendation(String componentId) {
    switch (componentId) {
      case 'streamline':
        return 'Excellent work! Focus on maintaining this form under fatigue and during transitions.';
      case 'kick':
        return 'Strong kicks! Work on maintaining this power throughout longer sets.';
      case 'arm':
        return 'Great arm stroke! Focus on consistency and efficiency at race pace.';
      case 'glide':
        return 'Impressive glide! Challenge yourself to increase the distance per stroke even further.';
      case 'start':
        return 'Powerful push-offs! Maintain this explosive start even when fatigued.';
      case 'turn':
        return 'Solid turns! Focus on maintaining speed through the turn transition.';
      default:
        return 'Keep up the excellent form!';
    }
  }

  static String _getMediumRecommendation(String componentId) {
    switch (componentId) {
      case 'streamline':
        return 'Focus on tightening your core and keeping arms pressed to ears for better alignment.';
      case 'kick':
        return 'Work on increasing kick power while maintaining symmetry. Try resistance drills.';
      case 'arm':
        return 'Focus on widening your sweep and keeping elbows high throughout the stroke.';
      case 'glide':
        return 'Maximize your glide by holding streamline longer and reducing kick frequency.';
      case 'start':
        return 'Focus on planting feet higher on the wall and driving through the streamline.';
      case 'turn':
        return 'Practice tighter tucks and quicker rotations to maintain momentum through turns.';
      default:
        return 'Focus on technique consistency to improve further.';
    }
  }

  static String _getFundamentalRecommendation(String componentId) {
    switch (componentId) {
      case 'streamline':
        return 'Practice streamline holds against the wall daily. Focus on squeezing your head between your arms.';
      case 'kick':
        return 'Work on slow-motion kicks to perfect form. Focus on foot position and ankle flexibility.';
      case 'arm':
        return 'Isolate your arm stroke with a pull buoy. Focus on the catch and pull path.';
      case 'glide':
        return 'Practice 1-kick + maximum glide drills. Focus on holding streamline throughout the glide.';
      case 'start':
        return 'Practice explosive push-offs with streamline hold. Focus on power and body position.';
      case 'turn':
        return 'Break down the turn into steps: approach, touch, tuck, rotate, push. Master each phase.';
      default:
        return 'Focus on fundamentals and consistent practice to build a strong foundation.';
    }
  }

  /// Generate technical details citation for debug/advanced view.
  ///
  /// Example: "Segments: 2.0-5.2s, 7.8-9.5s | Total: 6.2s | Confidence: 85%"
  static String generateTechnicalDetails(ComponentResult component) {
    if (component.timeRanges.isEmpty) {
      return 'Full travel phase | Confidence: ${(component.rawConfidence * 100).round()}%';
    }

    final buffer = StringBuffer();
    buffer.write('Segments: ');

    if (component.timeRanges.length <= 5) {
      final ranges = component.timeRanges.map(
        (r) => '${r.startSec.toStringAsFixed(1)}-${r.endSec.toStringAsFixed(1)}s',
      ).join(', ');
      buffer.write(ranges);
    } else {
      // Too many segments, just show count
      final first3 = component.timeRanges.take(3).map(
        (r) => '${r.startSec.toStringAsFixed(1)}-${r.endSec.toStringAsFixed(1)}s',
      ).join(', ');
      buffer.write('$first3, ... (${component.timeRanges.length} total)');
    }

    final totalDuration = component.timeRanges.fold<double>(0.0, (s, r) => s + r.duration);
    buffer.write(' | Total: ${totalDuration.toStringAsFixed(1)}s');
    buffer.write(' | Confidence: ${(component.rawConfidence * 100).round()}%');

    return buffer.toString();
  }
}
