import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';

/// Preflight video checker - validates video BEFORE full analysis
///
/// Checks for common issues:
/// - Multi-person detected
/// - Body frequently out of frame
/// - Too short / insufficient kick cycles
/// - Video likely not DNF (wrong discipline)
class VideoPreflightChecker {
  /// Run preflight checks on extracted poses
  ///
  /// Returns map with warnings and shouldProceed flag
  Map<String, dynamic> checkVideo(List<Pose> poses) {
    final warnings = <String>[];
    final criticalIssues = <String>[];

    if (poses.isEmpty) {
      criticalIssues.add('No person detected in video');
      return {
        'warnings': warnings,
        'criticalIssues': criticalIssues,
        'shouldProceed': false,
        'canOverride': false,
      };
    }

    // Check 1: Video too short
    final durationSeconds = poses.length / 5.0; // Assuming 5 fps
    if (durationSeconds < 3.0) {
      criticalIssues.add(
        'Video too short (${durationSeconds.toStringAsFixed(1)}s). '
        'Need at least 3 seconds of swimming.'
      );
    } else if (durationSeconds < 8.0) {
      warnings.add(
        'Video is short (${durationSeconds.toStringAsFixed(1)}s). '
        'Recommended: 8-15 seconds for best results.'
      );
    }

    // Check 2: Multi-person detection
    final multiPersonFrames = _detectMultiPerson(poses);
    if (multiPersonFrames > poses.length * 0.3) {
      warnings.add(
        'Multiple people detected in ${((multiPersonFrames / poses.length) * 100).toStringAsFixed(0)}% of frames. '
        'Analysis works best with one person only.'
      );
    }

    // Check 3: Body frequently out of frame
    final outOfFrameCount = _detectOutOfFrame(poses);
    if (outOfFrameCount > poses.length * 0.5) {
      criticalIssues.add(
        'Body out of frame in ${((outOfFrameCount / poses.length) * 100).toStringAsFixed(0)}% of frames. '
        'Ensure full body is visible throughout.'
      );
    } else if (outOfFrameCount > poses.length * 0.2) {
      warnings.add(
        'Body partially out of frame in some sections. '
        'Keep full body visible for better analysis.'
      );
    }

    // Check 4: Insufficient kick cycles
    final kickCycles = _estimateKickCycles(poses);
    if (kickCycles < 2) {
      warnings.add(
        'Only ${kickCycles} kick cycle(s) detected. '
        'Recommended: at least 3 cycles for reliable analysis.'
      );
    }

    // Check 5: Quick classification check (DNF vs DYN/DYNB)
    final likelyDiscipline = _quickClassify(poses);
    if (likelyDiscipline != 'DNF' && likelyDiscipline != 'UNKNOWN') {
      warnings.add(
        'Video looks like $likelyDiscipline, not DNF. '
        'Analysis may not be accurate.'
      );
    }

    // Determine if we should proceed
    final shouldProceed = criticalIssues.isEmpty;
    final canOverride = criticalIssues.length <= 1; // Allow override for 1 critical issue

    return {
      'warnings': warnings,
      'criticalIssues': criticalIssues,
      'shouldProceed': shouldProceed,
      'canOverride': canOverride,
      'metadata': {
        'durationSeconds': durationSeconds,
        'multiPersonFrames': multiPersonFrames,
        'outOfFrameCount': outOfFrameCount,
        'kickCycles': kickCycles,
        'likelyDiscipline': likelyDiscipline,
      },
    };
  }

  /// Detect frames with multiple people
  int _detectMultiPerson(List<Pose> poses) {
    // Simple heuristic: if too many landmarks detected, likely multiple people
    // ML Kit Pose Detection should only detect one person, but may pick up
    // multiple if they're close together

    int multiPersonCount = 0;

    for (final pose in poses) {
      // Check for duplicate or conflicting landmarks
      // If we have multiple shoulders at very different positions, suspect multi-person
      final landmarks = pose.landmarks.values.toList();

      // Count landmarks with high confidence
      final highConfidenceLandmarks = landmarks.where(
        (l) => l.likelihood > 0.7
      ).length;

      // Too many high-confidence landmarks may indicate multiple people
      if (highConfidenceLandmarks > 25) {
        multiPersonCount++;
      }
    }

    return multiPersonCount;
  }

  /// Detect frames where body is significantly out of frame
  int _detectOutOfFrame(List<Pose> poses) {
    int outOfFrameCount = 0;

    for (final pose in poses) {
      // Check if key landmarks are missing or have low confidence
      final keyLandmarks = [
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.rightHip,
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.rightKnee,
      ];

      int missingCount = 0;
      for (final type in keyLandmarks) {
        final landmark = pose.landmarks[type];
        if (landmark == null || landmark.likelihood < 0.3) {
          missingCount++;
        }
      }

      // If more than half of key landmarks are missing, consider out of frame
      if (missingCount > keyLandmarks.length / 2) {
        outOfFrameCount++;
      }
    }

    return outOfFrameCount;
  }

  /// Estimate number of kick cycles
  int _estimateKickCycles(List<Pose> poses) {
    // Analyze knee angle variation to detect kick cycles
    final kneeAngles = <double>[];

    for (final pose in poses) {
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
      final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
      final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

      if (leftHip != null && leftKnee != null && leftAnkle != null) {
        final angle = _calculateAngle(
          leftHip.x, leftHip.y,
          leftKnee.x, leftKnee.y,
          leftAnkle.x, leftAnkle.y,
        );
        kneeAngles.add(angle);
      }
    }

    if (kneeAngles.length < 5) return 0;

    // Simple peak detection to count cycles
    int peaks = 0;
    for (int i = 2; i < kneeAngles.length - 2; i++) {
      if (kneeAngles[i] > kneeAngles[i - 1] &&
          kneeAngles[i] > kneeAngles[i + 1] &&
          kneeAngles[i] > 100) { // Threshold for flexed knee
        peaks++;
      }
    }

    return (peaks / 2).round(); // Each kick cycle has ~2 peaks
  }

  /// Quick classification to detect wrong discipline
  String _quickClassify(List<Pose> poses) {
    if (poses.length < 10) return 'UNKNOWN';

    // Simple heuristic based on leg position
    int extendedLegFrames = 0;
    int flexedLegFrames = 0;

    for (final pose in poses) {
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
      final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
      final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

      if (leftHip != null && leftKnee != null && leftAnkle != null) {
        final angle = _calculateAngle(
          leftHip.x, leftHip.y,
          leftKnee.x, leftKnee.y,
          leftAnkle.x, leftAnkle.y,
        );

        if (angle > 150) {
          extendedLegFrames++;
        } else if (angle < 120) {
          flexedLegFrames++;
        }
      }
    }

    // DYN/DYNB tend to have more extended leg positions (fins)
    // DNF has more flexed positions (breaststroke kick)
    final extendedRatio = extendedLegFrames / poses.length;
    final flexedRatio = flexedLegFrames / poses.length;

    if (extendedRatio > 0.6) {
      return 'DYN/DYNB'; // Likely finning
    } else if (flexedRatio > 0.4) {
      return 'DNF'; // Likely breaststroke
    }

    return 'UNKNOWN';
  }

  /// Calculate angle between three points
  double _calculateAngle(double x1, double y1, double x2, double y2, double x3, double y3) {
    final vector1 = [x1 - x2, y1 - y2];
    final vector2 = [x3 - x2, y3 - y2];

    final dotProduct = vector1[0] * vector2[0] + vector1[1] * vector2[1];
    final magnitude1 = sqrt(vector1[0] * vector1[0] + vector1[1] * vector1[1]);
    final magnitude2 = sqrt(vector2[0] * vector2[0] + vector2[1] * vector2[1]);

    if (magnitude1 == 0 || magnitude2 == 0) return 0;

    final cosAngle = dotProduct / (magnitude1 * magnitude2);
    final angle = acos(cosAngle.clamp(-1.0, 1.0)) * (180 / pi);

    return angle;
  }
}
