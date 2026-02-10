import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';

/// Classifies freediving videos into DNF, DYN, DYNB, or OTHER
///
/// Uses pose-based motion signatures with body-axis relative coordinates
/// to be invariant to camera rotation. Features:
/// - Breaststroke kick signature detection (ankle separation periodicity)
/// - Cross-discipline penalties (e.g., breaststroke kick penalizes DYNB)
/// - Rule trace output for debug reports
class VideoClassifier {
  /// Classify a sequence of poses
  ///
  /// Returns classification result with confidence, feature values, and rule trace
  Map<String, dynamic> classify(List<Pose> poses) {
    if (poses.isEmpty) {
      return {
        'classification': 'OTHER',
        'confidence': 0.0,
        'reason': 'No pose data available',
        'scores': {'DNF': 0.0, 'DYN': 0.0, 'DYNB': 0.0},
        'featureValues': <String, dynamic>{},
        'ruleTrace': <Map<String, dynamic>>[],
      };
    }

    // Extract motion features using body-axis coordinates
    final features = _extractMotionFeatures(poses);

    // Run classification logic — collect rule traces
    final dnfTrace = <Map<String, dynamic>>[];
    final dynTrace = <Map<String, dynamic>>[];
    final dynbTrace = <Map<String, dynamic>>[];

    final dnfScore = _scoreDNF(features, dnfTrace);
    final dynScore = _scoreDYN(features, dynTrace);
    final dynbScore = _scoreDYNB(features, dynbTrace);

    // Determine winner
    final allScores = [dnfScore, dynScore, dynbScore]..sort((a, b) => b.compareTo(a));
    final maxScore = allScores[0];
    final secondHighestScore = allScores[1];
    final scoreDelta = maxScore - secondHighestScore;

    String classification;
    double confidence;
    String reason;
    bool isInconclusive = false;
    List<String> conflictReasons = [];
    List<String> captureGuidance = [];

    if (maxScore < 0.3) {
      classification = 'OTHER';
      confidence = 0.0;
      reason = 'Motion pattern does not match any freediving discipline';
    } else if (scoreDelta < 0.15 && maxScore >= 0.3) {
      // Scores too close — inconclusive
      isInconclusive = true;

      // Still assign best-guess classification
      if (dnfScore == maxScore) {
        classification = 'DNF';
      } else if (dynScore == maxScore) {
        classification = 'DYN';
      } else {
        classification = 'DYNB';
      }
      confidence = maxScore;
      reason = 'Classification uncertain — top disciplines score within ${(scoreDelta * 100).toStringAsFixed(0)}% of each other';

      // Build conflict reasons
      final scoreMap = {'DNF': dnfScore, 'DYN': dynScore, 'DYNB': dynbScore};
      final sorted = scoreMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      conflictReasons = [
        '${sorted[0].key} (${(sorted[0].value * 100).toStringAsFixed(0)}%) vs '
            '${sorted[1].key} (${(sorted[1].value * 100).toStringAsFixed(0)}%)',
        'Score gap: ${(scoreDelta * 100).toStringAsFixed(0)}% (needs ≥15% for confident classification)',
      ];

      // Generate filming tips
      captureGuidance = [
        'Film from a side angle to show kick pattern clearly',
        'Ensure full body (head to toes) is visible',
        'Record at least 3 complete kick/stroke cycles',
        'Avoid filming multiple swimmers in the same frame',
      ];
    } else if (dnfScore == maxScore) {
      classification = 'DNF';
      confidence = dnfScore;
      reason = 'Breaststroke kick signature detected, arm strokes present, no fins';
    } else if (dynScore == maxScore) {
      classification = 'DYN';
      confidence = dynScore;
      reason = 'Fins detected (extended legs, minimal ankle flexion)';
    } else {
      classification = 'DYNB';
      confidence = dynbScore;
      reason = 'Bi-fins movement detected (body wave, symmetric arms)';
    }

    // Build combined rule trace (top 3 contributing features across all)
    final allTraces = <Map<String, dynamic>>[];
    if (classification == 'DNF') allTraces.addAll(dnfTrace);
    if (classification == 'DYN') allTraces.addAll(dynTrace);
    if (classification == 'DYNB') allTraces.addAll(dynbTrace);
    // Sort by absolute contribution
    allTraces.sort((a, b) =>
        (b['contribution'] as double).abs().compareTo((a['contribution'] as double).abs()));
    final topTrace = allTraces.take(3).map((t) => {
      'feature': t['feature'],
      'value': t['value'],
      'effect': '${t['contribution'] > 0 ? "+" : ""}${(t['contribution'] as double).toStringAsFixed(2)} to $classification',
    }).toList();

    // DYNB uncertain classification flag
    bool uncertainClassification = false;
    if (classification == 'DYNB' && confidence < 0.5) {
      uncertainClassification = true;
      reason = 'Fins status uncertain — motion pattern ambiguous';
    }

    // Build DYNB feature breakdown for debug
    final bodyWave = features['bodyWave'] as double;
    final armMovement = features['armMovement'] as double;
    final armSymmetry = features['armSymmetry'] as double;
    final legFlexionVal = features['legFlexion'] as double;
    final breaststrokeKick = features['breaststrokeKickSignature'] as double;

    final dynbFeatureBreakdown = <String, dynamic>{
      'bodyWave': {
        'value': bodyWave,
        'threshold': 0.6,
        'met': bodyWave > 0.6,
        'contribution': bodyWave > 0.6 ? 0.30 : 0.0,
      },
      'armMovementNoBreaststroke': {
        'value': armMovement,
        'threshold': 0.4,
        'breaststrokeKick': breaststrokeKick,
        'met': armMovement > 0.4 && breaststrokeKick < 0.3,
        'contribution': (armMovement > 0.4 && breaststrokeKick < 0.3) ? 0.25 : 0.0,
      },
      'armSymmetry': {
        'value': armSymmetry,
        'threshold': 0.6,
        'met': armSymmetry > 0.6,
        'contribution': armSymmetry > 0.6 ? 0.20 : 0.0,
      },
      'legFlexion': {
        'value': legFlexionVal,
        'threshold': 0.4,
        'met': legFlexionVal < 0.4,
        'contribution': legFlexionVal < 0.4 ? 0.15 : 0.0,
      },
      'breaststrokePenalty': {
        'value': breaststrokeKick,
        'threshold': 0.5,
        'met': breaststrokeKick > 0.5,
        'contribution': breaststrokeKick > 0.5 ? -0.30 : 0.0,
      },
    };

    return {
      'classification': classification,
      'confidence': confidence,
      'reason': reason,
      'scores': {
        'DNF': dnfScore,
        'DYN': dynScore,
        'DYNB': dynbScore,
      },
      'featureValues': features,
      'ruleTrace': topTrace,
      'uncertainClassification': uncertainClassification,
      'isInconclusive': isInconclusive,
      'scoreDelta': scoreDelta,
      'conflictReasons': conflictReasons,
      'captureGuidance': captureGuidance,
      'dynbFeatureBreakdown': dynbFeatureBreakdown,
    };
  }

  /// Extract motion features from poses using body-axis relative coordinates
  Map<String, dynamic> _extractMotionFeatures(List<Pose> poses) {
    final legFlexion = _analyzeLegFlexion(poses);
    final legSymmetry = _analyzeLegSymmetry(poses);
    final ankleFlexion = _analyzeAnkleFlexion(poses);
    final armMovement = _analyzeArmMovement(poses);
    final armSymmetry = _analyzeArmSymmetry(poses);
    final bodyAngle = _analyzeBodyAngle(poses);
    final bodyWave = _analyzeBodyWave(poses);
    final breaststrokeKickSignature = _analyzeBreaststrokeKickSignature(poses);

    return {
      'legFlexion': legFlexion,
      'legSymmetry': legSymmetry,
      'ankleFlexion': ankleFlexion,
      'armMovement': armMovement,
      'armSymmetry': armSymmetry,
      'bodyAngle': bodyAngle,
      'bodyWave': bodyWave,
      'breaststrokeKickSignature': breaststrokeKickSignature,
    };
  }

  // =========================================================================
  // Scoring — DNF
  // =========================================================================

  /// Score for DNF (breaststroke-like, no fins, arm strokes present)
  ///
  /// Key insight: Real DNF has significant arm strokes AND breaststroke kicks.
  /// The combination of arm strokes + breaststroke kick is the primary DNF indicator.
  double _scoreDNF(Map<String, dynamic> features, List<Map<String, dynamic>> trace) {
    double score = 0.0;

    final breaststrokeKick = features['breaststrokeKickSignature'] as double;
    final legSymmetry = features['legSymmetry'] as double;
    final ankleFlexion = features['ankleFlexion'] as double;
    final armMovement = features['armMovement'] as double;

    // Primary indicator: breaststroke kick signature
    if (breaststrokeKick > 0.4) {
      final contrib = 0.35;
      score += contrib;
      trace.add({'feature': 'breaststrokeKickSignature', 'value': breaststrokeKick, 'contribution': contrib});
    }

    // Symmetric leg movement (both legs move together in breaststroke)
    if (legSymmetry > 0.7) {
      final contrib = 0.20;
      score += contrib;
      trace.add({'feature': 'legSymmetry', 'value': legSymmetry, 'contribution': contrib});
    }

    // Arm stroke + breaststroke kick combo = strong DNF signal
    if (armMovement > 0.3 && breaststrokeKick > 0.3) {
      final contrib = 0.25;
      score += contrib;
      trace.add({'feature': 'armStrokeWithKick', 'value': (armMovement + breaststrokeKick) / 2, 'contribution': contrib});
    }

    // High ankle flexion (no fins = bare feet flex naturally)
    if (ankleFlexion > 0.5) {
      final contrib = 0.20;
      score += contrib;
      trace.add({'feature': 'ankleFlexion', 'value': ankleFlexion, 'contribution': contrib});
    }

    return score.clamp(0.0, 1.0);
  }

  // =========================================================================
  // Scoring — DYN
  // =========================================================================

  /// Score for DYN (mono-fin, extended legs, minimal arm movement)
  double _scoreDYN(Map<String, dynamic> features, List<Map<String, dynamic>> trace) {
    double score = 0.0;

    final legFlexion = features['legFlexion'] as double;
    final legSymmetry = features['legSymmetry'] as double;
    final ankleFlexion = features['ankleFlexion'] as double;
    final armMovement = features['armMovement'] as double;
    final breaststrokeKick = features['breaststrokeKickSignature'] as double;

    // Low leg flexion (fins keep legs straighter)
    if (legFlexion < 0.4) {
      final contrib = 0.3;
      score += contrib;
      trace.add({'feature': 'legFlexion', 'value': legFlexion, 'contribution': contrib});
    }

    // Asymmetric leg movement (mono-fin alternating kick)
    if (legSymmetry < 0.5) {
      final contrib = 0.2;
      score += contrib;
      trace.add({'feature': 'legSymmetry', 'value': legSymmetry, 'contribution': contrib});
    }

    // Low ankle flexion (fins extend feet)
    if (ankleFlexion < 0.3) {
      final contrib = 0.3;
      score += contrib;
      trace.add({'feature': 'ankleFlexion', 'value': ankleFlexion, 'contribution': contrib});
    }

    // Minimal arm movement (arms at sides or in streamline)
    if (armMovement < 0.3) {
      final contrib = 0.2;
      score += contrib;
      trace.add({'feature': 'armMovement', 'value': armMovement, 'contribution': contrib});
    }

    // Penalty: breaststroke kick should not appear in DYN
    if (breaststrokeKick > 0.5) {
      final penalty = -0.25;
      score += penalty;
      trace.add({'feature': 'breaststrokeKickSignature', 'value': breaststrokeKick, 'contribution': penalty});
    }

    return score.clamp(0.0, 1.0);
  }

  // =========================================================================
  // Scoring — DYNB
  // =========================================================================

  /// Score for DYNB (bi-fins, body wave, arm movement without breaststroke kick)
  ///
  /// Key fix: Penalize DYNB when breaststroke kick is detected (= DNF, not DYNB).
  /// Also penalize when arm strokes are present (arm strokes = probably DNF).
  double _scoreDYNB(Map<String, dynamic> features, List<Map<String, dynamic>> trace) {
    double score = 0.0;

    final bodyWave = features['bodyWave'] as double;
    final armMovement = features['armMovement'] as double;
    final armSymmetry = features['armSymmetry'] as double;
    final legFlexion = features['legFlexion'] as double;
    final breaststrokeKick = features['breaststrokeKickSignature'] as double;

    // High body wave (dolphin kick pattern)
    if (bodyWave > 0.6) {
      final contrib = 0.30;
      score += contrib;
      trace.add({'feature': 'bodyWave', 'value': bodyWave, 'contribution': contrib});
    }

    // Arm movement WITHOUT breaststroke kick (dolphin-style arm use)
    if (armMovement > 0.4 && breaststrokeKick < 0.3) {
      final contrib = 0.25;
      score += contrib;
      trace.add({'feature': 'armMovementNoBreaststroke', 'value': armMovement, 'contribution': contrib});
    }

    // Symmetric arm movement
    if (armSymmetry > 0.6) {
      final contrib = 0.20;
      score += contrib;
      trace.add({'feature': 'armSymmetry', 'value': armSymmetry, 'contribution': contrib});
    }

    // Low leg flexion (similar to DYN)
    if (legFlexion < 0.4) {
      final contrib = 0.15;
      score += contrib;
      trace.add({'feature': 'legFlexion', 'value': legFlexion, 'contribution': contrib});
    }

    // PENALTY: Breaststroke kick detected = NOT DYNB
    if (breaststrokeKick > 0.5) {
      final penalty = -0.30;
      score += penalty;
      trace.add({'feature': 'breaststrokeKickSignature', 'value': breaststrokeKick, 'contribution': penalty});
    }

    // PENALTY: Arm strokes present = probably DNF, not DYNB
    if (armMovement > 0.5 && breaststrokeKick > 0.3) {
      final penalty = -0.15;
      score += penalty;
      trace.add({'feature': 'armStrokeWithKick', 'value': armMovement, 'contribution': penalty});
    }

    return score.clamp(0.0, 1.0);
  }

  // =========================================================================
  // Feature Extraction — Body-Axis Coordinate Projection
  // =========================================================================

  /// Compute body axis vectors for a pose.
  /// Returns (axialX, axialY, perpX, perpY, hipMidX, hipMidY) or null if insufficient landmarks.
  _BodyAxis? _computeBodyAxis(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null) return null;

    final shoulderMidX = (leftShoulder.x + rightShoulder.x) / 2;
    final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
    final hipMidX = (leftHip.x + rightHip.x) / 2;
    final hipMidY = (leftHip.y + rightHip.y) / 2;

    // Body axis: shoulder mid → hip mid
    final axX = hipMidX - shoulderMidX;
    final axY = hipMidY - shoulderMidY;
    final axLen = sqrt(axX * axX + axY * axY);
    if (axLen < 1.0) return null;

    // Normalize
    final axialX = axX / axLen;
    final axialY = axY / axLen;

    // Perpendicular axis (90° rotation)
    final perpX = -axialY;
    final perpY = axialX;

    return _BodyAxis(
      axialX: axialX, axialY: axialY,
      perpX: perpX, perpY: perpY,
      hipMidX: hipMidX, hipMidY: hipMidY,
      axisLength: axLen,
    );
  }

  /// Project a landmark onto body-axis coordinates relative to hipMid.
  /// Returns (axialComponent, perpComponent).
  (double, double) _projectOntoBodyAxis(_BodyAxis axis, double lmX, double lmY) {
    final dx = lmX - axis.hipMidX;
    final dy = lmY - axis.hipMidY;
    final axial = dx * axis.axialX + dy * axis.axialY;
    final perp = dx * axis.perpX + dy * axis.perpY;
    return (axial, perp);
  }

  double _analyzeLegFlexion(List<Pose> poses) {
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

    if (kneeAngles.isEmpty) return 0.5;

    final mean = kneeAngles.reduce((a, b) => a + b) / kneeAngles.length;
    final variance = kneeAngles.map((a) => pow(a - mean, 2)).reduce((a, b) => a + b) / kneeAngles.length;
    final stdDev = sqrt(variance);

    return (stdDev / 90).clamp(0.0, 1.0);
  }

  /// Leg symmetry using body-axis perpendicular projection instead of raw Y.
  double _analyzeLegSymmetry(List<Pose> poses) {
    final symmetryScores = <double>[];

    for (final pose in poses) {
      final axis = _computeBodyAxis(pose);
      if (axis == null) continue;

      final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
      final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

      if (leftKnee != null && rightKnee != null) {
        final (_, leftPerp) = _projectOntoBodyAxis(axis, leftKnee.x, leftKnee.y);
        final (_, rightPerp) = _projectOntoBodyAxis(axis, rightKnee.x, rightKnee.y);

        // Normalize diff by axis length (body size)
        final diff = (leftPerp - rightPerp).abs() / axis.axisLength;
        final symmetry = 1.0 - (diff * 2.0).clamp(0.0, 1.0);
        symmetryScores.add(symmetry);
      }
    }

    if (symmetryScores.isEmpty) return 0.5;
    return symmetryScores.reduce((a, b) => a + b) / symmetryScores.length;
  }

  double _analyzeAnkleFlexion(List<Pose> poses) {
    final ankleAngles = <double>[];

    for (final pose in poses) {
      final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
      final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
      final leftHeel = pose.landmarks[PoseLandmarkType.leftHeel];

      if (leftKnee != null && leftAnkle != null && leftHeel != null) {
        final angle = _calculateAngle(
          leftKnee.x, leftKnee.y,
          leftAnkle.x, leftAnkle.y,
          leftHeel.x, leftHeel.y,
        );
        ankleAngles.add(angle);
      }
    }

    if (ankleAngles.isEmpty) return 0.5;

    final mean = ankleAngles.reduce((a, b) => a + b) / ankleAngles.length;
    return ((mean - 60) / 60).clamp(0.0, 1.0);
  }

  /// Arm movement using body-axis projection instead of raw shoulder-wrist distance.
  double _analyzeArmMovement(List<Pose> poses) {
    final armPositions = <double>[];

    for (final pose in poses) {
      final axis = _computeBodyAxis(pose);
      if (axis == null) continue;

      final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];

      if (leftShoulder != null && leftWrist != null) {
        // Project both onto body axis
        final (wristAxial, wristPerp) = _projectOntoBodyAxis(axis, leftWrist.x, leftWrist.y);
        final (shoulderAxial, shoulderPerp) = _projectOntoBodyAxis(axis, leftShoulder.x, leftShoulder.y);

        final dAxial = wristAxial - shoulderAxial;
        final dPerp = wristPerp - shoulderPerp;
        final distance = sqrt(dAxial * dAxial + dPerp * dPerp);

        // Normalize by axis length
        armPositions.add(distance / axis.axisLength);
      }
    }

    if (armPositions.isEmpty) return 0.0;

    final mean = armPositions.reduce((a, b) => a + b) / armPositions.length;
    final variance = armPositions.map((d) => pow(d - mean, 2)).reduce((a, b) => a + b) / armPositions.length;
    final stdDev = sqrt(variance);

    // Normalize — higher stdDev means more arm movement variation
    return (stdDev * 3.0).clamp(0.0, 1.0);
  }

  /// Arm symmetry using body-axis perpendicular projection.
  double _analyzeArmSymmetry(List<Pose> poses) {
    final symmetryScores = <double>[];

    for (final pose in poses) {
      final axis = _computeBodyAxis(pose);
      if (axis == null) continue;

      final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
      final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

      if (leftWrist != null && rightWrist != null) {
        final (_, leftPerp) = _projectOntoBodyAxis(axis, leftWrist.x, leftWrist.y);
        final (_, rightPerp) = _projectOntoBodyAxis(axis, rightWrist.x, rightWrist.y);

        final diff = (leftPerp - rightPerp).abs() / axis.axisLength;
        final symmetry = 1.0 - (diff * 2.0).clamp(0.0, 1.0);
        symmetryScores.add(symmetry);
      }
    }

    if (symmetryScores.isEmpty) return 0.5;
    return symmetryScores.reduce((a, b) => a + b) / symmetryScores.length;
  }

  double _analyzeBodyAngle(List<Pose> poses) {
    final angles = <double>[];

    for (final pose in poses) {
      final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final hip = pose.landmarks[PoseLandmarkType.leftHip];

      if (shoulder != null && hip != null) {
        final angle = atan2(hip.y - shoulder.y, hip.x - shoulder.x).abs();
        angles.add(angle);
      }
    }

    if (angles.isEmpty) return 0.5;

    final mean = angles.reduce((a, b) => a + b) / angles.length;
    return mean;
  }

  /// Body wave using body-axis perpendicular projection for camera-rotation invariance.
  double _analyzeBodyWave(List<Pose> poses) {
    final perpDeviations = <double>[];

    for (final pose in poses) {
      final axis = _computeBodyAxis(pose);
      if (axis == null) continue;

      final knee = pose.landmarks[PoseLandmarkType.leftKnee];
      if (knee == null) continue;

      // Measure perpendicular deviation of knee from body axis
      final (_, perpComp) = _projectOntoBodyAxis(axis, knee.x, knee.y);
      perpDeviations.add(perpComp / axis.axisLength);
    }

    if (perpDeviations.isEmpty) return 0.0;

    final mean = perpDeviations.reduce((a, b) => a + b) / perpDeviations.length;
    final variance = perpDeviations.map((a) => pow(a - mean, 2)).reduce((a, b) => a + b) / perpDeviations.length;
    final stdDev = sqrt(variance);

    // Higher variation = more wave/undulation
    return (stdDev * 5.0).clamp(0.0, 1.0);
  }

  // =========================================================================
  // NEW: Breaststroke Kick Signature Detection
  // =========================================================================

  /// Detect breaststroke kick via ankle separation periodicity.
  ///
  /// Breaststroke kick = periodic expansion/contraction of L-R ankle distance.
  /// More robust than Y-oscillation for rotated cameras.
  double _analyzeBreaststrokeKickSignature(List<Pose> poses) {
    final ankleSeparations = <double>[];

    for (final pose in poses) {
      final axis = _computeBodyAxis(pose);
      if (axis == null) continue;

      final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
      final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

      if (leftAnkle != null && rightAnkle != null) {
        // Project ankles onto perpendicular axis for rotation-invariant separation
        final (_, leftPerp) = _projectOntoBodyAxis(axis, leftAnkle.x, leftAnkle.y);
        final (_, rightPerp) = _projectOntoBodyAxis(axis, rightAnkle.x, rightAnkle.y);

        final separation = (leftPerp - rightPerp).abs() / axis.axisLength;
        ankleSeparations.add(separation);
      }
    }

    if (ankleSeparations.length < 5) return 0.0;

    // Detect periodicity via zero-crossing count on detrended signal
    final mean = ankleSeparations.reduce((a, b) => a + b) / ankleSeparations.length;
    final detrended = ankleSeparations.map((v) => v - mean).toList();

    int zeroCrossings = 0;
    for (int i = 1; i < detrended.length; i++) {
      if ((detrended[i] >= 0 && detrended[i - 1] < 0) ||
          (detrended[i] < 0 && detrended[i - 1] >= 0)) {
        zeroCrossings++;
      }
    }

    // Also measure amplitude of the signal
    final maxSep = ankleSeparations.reduce(max);
    final minSep = ankleSeparations.reduce(min);
    final amplitude = maxSep - minSep;

    // Breaststroke kick has: periodic separation changes (multiple zero crossings)
    // AND significant amplitude
    final periodicityScore = (zeroCrossings / (ankleSeparations.length * 0.3)).clamp(0.0, 1.0);
    final amplitudeScore = (amplitude * 3.0).clamp(0.0, 1.0);

    // Combined score
    return (0.6 * periodicityScore + 0.4 * amplitudeScore).clamp(0.0, 1.0);
  }

  // =========================================================================
  // Utility
  // =========================================================================

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

/// Internal helper to hold body-axis vectors for a frame.
class _BodyAxis {
  final double axialX;
  final double axialY;
  final double perpX;
  final double perpY;
  final double hipMidX;
  final double hipMidY;
  final double axisLength;

  _BodyAxis({
    required this.axialX,
    required this.axialY,
    required this.perpX,
    required this.perpY,
    required this.hipMidX,
    required this.hipMidY,
    required this.axisLength,
  });
}
