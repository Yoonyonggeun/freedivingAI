import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'video_classifier.dart';

/// DNF Full Clip Analyzer
///
/// Analyzes complete 25m DNF clips with automatic segmentation:
/// - Phase detection: START / TRAVEL / TURN
/// - Motion classification: ARM_STROKE / BREAST_KICK / GLIDE / MIXED
/// - Biomechanics metrics with confidence gating
/// - Defensive handling of missing START/TURN
class DNFFullAnalyzer {
  // Constants
  static const double _fps = 5.0; // Frame extraction rate
  static const double _emaAlpha = 0.25; // Smoothing factor
  static const double _vLowThreshold = 0.08; // Low velocity threshold (normalized)
  static const double _lowEnergyThreshold = 0.05; // Low energy threshold
  static const double _angularVelocityGlideThreshold = 15.0; // deg/s

  // Window parameters for motion classification
  static const double _windowSize = 1.6; // seconds
  static const double _windowStep = 0.25; // seconds
  static const int _minPeakDistance = 2; // frames at 5fps = 0.4s

  /// Main analysis entry point
  ///
  /// Returns comprehensive analysis with timeline, metrics, and coaching.
  /// Optional [landmarkCoverage] and [signalContinuity] enhance quality scoring.
  Map<String, dynamic> analyzeDNFFull(
    List<Pose> poses, {
    double? landmarkCoverage,
    double? signalContinuity,
    double? multiPersonFrameRatio,
    int? trackSwitchCount,
    int? totalFrames,
  }) {
    if (poses.isEmpty) {
      return _getInsufficientDataResult(
        'No poses detected. Check video quality and lighting.',
      );
    }

    if (poses.length < 5) {
      return _getInsufficientDataResult(
        'Too few frames (${poses.length}). Minimum 5 frames (1 second at 5fps) required.',
      );
    }

    // 1. Convert to FrameData with normalization
    final frames = _convertToFrameData(poses);

    if (frames.length < 5) {
      return _getInsufficientDataResult(
        'Only ${frames.length} valid frames detected from ${poses.length} total frames.\n'
        'Body landmarks (shoulders, hips) not clearly visible.\n'
        'Please ensure:\n'
        '• Full body is in frame\n'
        '• Good lighting\n'
        '• Camera is stable\n'
        '• Swimmer is visible from side angle',
      );
    }

    // 2. Phase detection (START / TRAVEL / TURN)
    final phases = _detectPhases(frames);

    // 3. Collect ALL TRAVEL segments (supports 50m+ multi-turn videos)
    final travelPhases = phases.where((p) => p.phase == 'TRAVEL').toList();
    if (travelPhases.isEmpty) {
      travelPhases.add(PhaseData(
        phase: 'TRAVEL',
        startFrame: 0,
        endFrame: frames.length,
        confidence: 0.5,
      ));
    }

    final totalTravelDuration = travelPhases.fold<double>(0.0, (s, p) => s + p.duration);

    if (totalTravelDuration < 1.0) {
      return _getInsufficientDataResult(
        'Swimming phase too short (${totalTravelDuration.toStringAsFixed(1)}s). '
        'Need at least 1 second of continuous swimming movement.\n'
        'Video should show active swimming, not just starting position.',
      );
    }

    // 4. Concatenate all TRAVEL frames for analysis
    final travelFrames = <FrameData>[];
    for (final tp in travelPhases) {
      travelFrames.addAll(frames.sublist(
        tp.startFrame,
        min(tp.endFrame, frames.length),
      ));
    }
    final motionWindows = _classifyMotion(travelFrames);

    // 5. Calculate metrics
    final metrics = _calculateMetrics(travelFrames, motionWindows);

    // 6. Generate coaching with confidence gating
    final coaching = _generateCoaching(metrics, motionWindows);

    // 7. Calculate overall score
    final overallScore = _calculateOverallScore(metrics);

    // 8. Classify video (DNF vs DYN/DYNB/OTHER)
    final classifier = VideoClassifier();
    final classificationResult = classifier.classify(poses);

    // 9. Enrich metrics with per-metric status/reasons and measurement basis
    _enrichMetricsWithStatus(metrics, motionWindows, travelFrames);

    // 10. Calculate analysis quality confidence
    final validFrameRatio = frames.length / poses.length;
    final totalKickCycles = _countTotalKickCycles(motionWindows);
    final analysisQualityConfidence = _calculateAnalysisQualityConfidence(
      validFrameRatio: validFrameRatio,
      travelDuration: totalTravelDuration,
      kickCycles: totalKickCycles,
      metrics: metrics,
      landmarkCoverage: landmarkCoverage,
      signalContinuity: signalContinuity,
      multiPersonFrameRatio: multiPersonFrameRatio,
      trackSwitchCount: trackSwitchCount,
      totalFrames: totalFrames,
    );

    // 11. Determine analysis mode
    final classification = classificationResult['classification'] as String;
    final uncertainClassification = classificationResult['uncertainClassification'] as bool? ?? false;
    final isInconclusive = classificationResult['isInconclusive'] as bool? ?? false;

    final levelTestEligible = classification == 'DNF' &&
        !isInconclusive &&
        totalKickCycles >= 3 &&
        totalTravelDuration >= 6.0 &&
        validFrameRatio >= 0.30;

    final failedRequirements = <String>[];
    if (classification != 'DNF') {
      failedRequirements.add('Classification is $classification, not DNF');
    }
    if (isInconclusive) {
      failedRequirements.add('Classification is inconclusive — discipline cannot be confirmed');
    }
    if (totalKickCycles < 3) {
      failedRequirements.add('Kick cycles detected: $totalKickCycles (min required: 3)');
    }
    if (totalTravelDuration < 6.0) {
      failedRequirements.add('Travel duration: ${totalTravelDuration.toStringAsFixed(1)}s (min required: 6s)');
    }
    if (validFrameRatio < 0.30) {
      failedRequirements.add('Valid frame ratio: ${(validFrameRatio * 100).toStringAsFixed(0)}% (min required: 30%)');
    }

    final analysisMode = <String, dynamic>{
      'mode': levelTestEligible ? 'LEVEL_TEST' : 'QUICK_FEEDBACK',
      'levelTestEligible': levelTestEligible,
      'failedRequirements': failedRequirements,
      'stats': <String, dynamic>{
        'validFrameRatio': validFrameRatio,
        'travelDuration': totalTravelDuration,
        'kickCycles': totalKickCycles,
        'classification': classification,
      },
    };

    // 12. Collect reason codes
    final reasonCodes = <String>[];
    final hasStart = phases.any((p) => p.phase == 'START' || p.phase == 'PREP');
    final hasTurn = phases.any((p) => p.phase == 'TURN');
    if (!hasStart) reasonCodes.add('START_UNKNOWN');
    if (!hasTurn) reasonCodes.add('TURN_UNKNOWN');

    // 13. Extract detected activities from motion windows
    final detectedActivities = motionWindows
        .map((w) => w.label)
        .toSet()
        .where((label) => label != 'MIXED')
        .toList();

    // 14. Turn count
    final turnCount = phases.where((p) => p.phase == 'TURN').length;

    // 15. Overall score availability — all 4 essential metrics must have confidence >= 0.55
    final essentialMetrics = ['streamline', 'kick', 'arm', 'glide'];
    final overallScoreAvailable = essentialMetrics.every((key) {
      if (!metrics.containsKey(key)) return false;
      final cat = metrics[key] as Map<String, dynamic>;
      return (cat['confidence'] as double? ?? 0.0) >= 0.55;
    });

    // 16. Aggregate capture guidance from unreliable metrics and inconclusive classification
    final aggregatedCaptureGuidance = <String>[];
    for (final key in essentialMetrics) {
      if (metrics.containsKey(key)) {
        final cat = metrics[key] as Map<String, dynamic>;
        if (cat['confidenceLevel'] == 'not_reliable' && cat.containsKey('captureGuidance')) {
          final guidance = cat['captureGuidance'] as List<String>;
          for (final tip in guidance) {
            if (!aggregatedCaptureGuidance.contains(tip)) {
              aggregatedCaptureGuidance.add(tip);
            }
          }
        }
      }
    }
    if (isInconclusive) {
      final classifierGuidance = classificationResult['captureGuidance'] as List<String>? ?? [];
      for (final tip in classifierGuidance) {
        if (!aggregatedCaptureGuidance.contains(tip)) {
          aggregatedCaptureGuidance.add(tip);
        }
      }
    }

    return <String, dynamic>{
      'overallScore': overallScore,
      'overallScoreAvailable': overallScoreAvailable,
      'classification': classificationResult['classification'],
      'classificationConfidence': classificationResult['confidence'],
      'classificationReason': classificationResult['reason'],
      'classificationScores': classificationResult['scores'],
      'classificationFeatureValues': classificationResult['featureValues'],
      'classificationRuleTrace': classificationResult['ruleTrace'],
      'uncertainClassification': uncertainClassification,
      'isInconclusive': isInconclusive,
      if (isInconclusive) 'conflictReasons': classificationResult['conflictReasons'],
      if (isInconclusive) 'captureGuidance': classificationResult['captureGuidance'],
      if (classificationResult.containsKey('dynbFeatureBreakdown'))
        'dynbFeatureBreakdown': classificationResult['dynbFeatureBreakdown'],
      'analysisQualityConfidence': analysisQualityConfidence,
      'analysisUnreliable': analysisQualityConfidence < 0.50,
      'qualityPenalties': <String, dynamic>{
        'multiPersonFrameRatio': multiPersonFrameRatio ?? 0.0,
        'trackSwitchCount': trackSwitchCount ?? 0,
        'totalFrames': totalFrames ?? 0,
      },
      'analysisMode': analysisMode,
      'reasonCodes': reasonCodes,
      'detectedActivities': detectedActivities,
      'phases': phases.map((p) => p.toJson()).toList(),
      'motionWindows': motionWindows.map((w) => w.toJson()).toList(),
      'metrics': metrics,
      'coaching': coaching,
      if (aggregatedCaptureGuidance.isNotEmpty)
        'captureGuidance': aggregatedCaptureGuidance,
      'metadata': <String, dynamic>{
        'totalFrames': frames.length,
        'durationSec': frames.length / _fps,
        'travelDurationSec': totalTravelDuration,
        'validFrameRatio': validFrameRatio,
        'kickCycles': totalKickCycles,
        'turnCount': turnCount,
        'travelSegmentCount': travelPhases.length,
        'analysisVersion': 'DNF_FULL_v5',
      },
    };
  }

  // =========================================================================
  // PHASE 1: Frame Data Conversion & Normalization
  // =========================================================================

  List<FrameData> _convertToFrameData(List<Pose> poses) {
    final frames = <FrameData>[];

    for (int i = 0; i < poses.length; i++) {
      final pose = poses[i];
      final landmarks = <PoseLandmarkType, PoseLandmark>{};

      for (var landmark in pose.landmarks.values) {
        landmarks[landmark.type] = landmark;
      }

      // Calculate shoulder width for normalization
      final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

      if (leftShoulder == null || rightShoulder == null) continue;

      final shoulderWidth = _dist2D(leftShoulder, rightShoulder);
      if (shoulderWidth < 10.0) continue; // Invalid scale

      // Calculate hip midpoint for velocity
      final leftHip = landmarks[PoseLandmarkType.leftHip];
      final rightHip = landmarks[PoseLandmarkType.rightHip];

      if (leftHip == null || rightHip == null) continue;

      final hipMid = _midpoint(leftHip, rightHip);

      frames.add(FrameData(
        frameIndex: i,
        timestamp: i / _fps,
        landmarks: landmarks,
        shoulderWidth: shoulderWidth,
        hipMid: hipMid,
      ));
    }

    // Smooth hip positions with EMA
    _smoothHipPositions(frames);

    // Calculate velocities
    for (int i = 1; i < frames.length; i++) {
      final prev = frames[i - 1];
      final curr = frames[i];
      final dt = curr.timestamp - prev.timestamp;

      if (dt > 0) {
        final dx = curr.hipMid.x - prev.hipMid.x;
        final dy = curr.hipMid.y - prev.hipMid.y;
        final dist = sqrt(dx * dx + dy * dy);

        // Normalize by shoulder width and time
        curr.velocity = dist / curr.shoulderWidth / dt;
      }
    }

    // Compute curvature and roll for each frame
    for (final frame in frames) {
      // Curvature: shoulder-hip-knee angle deviation from 180°
      final shoulderMid = _getShoulderMid(frame.landmarks);
      final kneeMid = _getKneeMid(frame.landmarks);
      if (shoulderMid != null && kneeMid != null) {
        final hipPt = frame.hipMid;
        // Angle at hip between shoulder-mid and knee-mid
        final v1x = shoulderMid.x - hipPt.x;
        final v1y = shoulderMid.y - hipPt.y;
        final v2x = kneeMid.x - hipPt.x;
        final v2y = kneeMid.y - hipPt.y;
        final dot = v1x * v2x + v1y * v2y;
        final m1 = sqrt(v1x * v1x + v1y * v1y);
        final m2 = sqrt(v2x * v2x + v2y * v2y);
        if (m1 > 0 && m2 > 0) {
          final cosA = (dot / (m1 * m2)).clamp(-1.0, 1.0);
          final angleDeg = acos(cosA) * 180 / pi;
          frame.curvature = (180.0 - angleDeg).abs(); // deviation from straight
        }
      }

      // Roll: |leftShoulder.y - rightShoulder.y| / shoulderWidth
      final ls = frame.landmarks[PoseLandmarkType.leftShoulder];
      final rs = frame.landmarks[PoseLandmarkType.rightShoulder];
      if (ls != null && rs != null && frame.shoulderWidth > 0) {
        frame.roll = (ls.y - rs.y).abs() / frame.shoulderWidth;
      }
    }

    // Compute joint angles and angular velocities
    _computeJointAngles(frames);

    return frames;
  }

  /// Compute angle at vertex between points a-vertex-c using dot product.
  /// Returns angle in degrees.
  double _computeAngle3Points(PoseLandmark a, PoseLandmark vertex, PoseLandmark c) {
    final v1x = a.x - vertex.x;
    final v1y = a.y - vertex.y;
    final v2x = c.x - vertex.x;
    final v2y = c.y - vertex.y;
    final dot = v1x * v2x + v1y * v2y;
    final m1 = sqrt(v1x * v1x + v1y * v1y);
    final m2 = sqrt(v2x * v2x + v2y * v2y);
    if (m1 == 0 || m2 == 0) return 0.0;
    final cosA = (dot / (m1 * m2)).clamp(-1.0, 1.0);
    return acos(cosA) * 180 / pi;
  }

  /// Compute joint angles and angular velocities for all frames.
  /// Called at the end of _convertToFrameData.
  void _computeJointAngles(List<FrameData> frames) {
    // Per-frame: compute joint angles
    for (final frame in frames) {
      final lm = frame.landmarks;

      // Knee angle: avg of L/R hip-knee-ankle
      double kneeSum = 0;
      int kneeCount = 0;
      for (final side in [
        (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
        (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
      ]) {
        final a = lm[side.$1];
        final v = lm[side.$2];
        final c = lm[side.$3];
        if (a != null && v != null && c != null) {
          kneeSum += _computeAngle3Points(a, v, c);
          kneeCount++;
        }
      }
      if (kneeCount > 0) frame.kneeAngle = kneeSum / kneeCount;

      // Hip angle: avg of L/R shoulder-hip-knee
      double hipSum = 0;
      int hipCount = 0;
      for (final side in [
        (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
        (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
      ]) {
        final a = lm[side.$1];
        final v = lm[side.$2];
        final c = lm[side.$3];
        if (a != null && v != null && c != null) {
          hipSum += _computeAngle3Points(a, v, c);
          hipCount++;
        }
      }
      if (hipCount > 0) frame.hipAngle = hipSum / hipCount;

      // Shoulder angle: avg of L/R elbow-shoulder-hip
      double shoulderSum = 0;
      int shoulderCount = 0;
      for (final side in [
        (PoseLandmarkType.leftElbow, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
        (PoseLandmarkType.rightElbow, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
      ]) {
        final a = lm[side.$1];
        final v = lm[side.$2];
        final c = lm[side.$3];
        if (a != null && v != null && c != null) {
          shoulderSum += _computeAngle3Points(a, v, c);
          shoulderCount++;
        }
      }
      if (shoulderCount > 0) frame.shoulderAngle = shoulderSum / shoulderCount;

      // Elbow angle: avg of L/R shoulder-elbow-wrist
      double elbowSum = 0;
      int elbowCount = 0;
      for (final side in [
        (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
        (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
      ]) {
        final a = lm[side.$1];
        final v = lm[side.$2];
        final c = lm[side.$3];
        if (a != null && v != null && c != null) {
          elbowSum += _computeAngle3Points(a, v, c);
          elbowCount++;
        }
      }
      if (elbowCount > 0) frame.elbowAngle = elbowSum / elbowCount;
    }

    // Between consecutive frames: compute angular velocities
    for (int i = 1; i < frames.length; i++) {
      final prev = frames[i - 1];
      final curr = frames[i];
      final dt = curr.timestamp - prev.timestamp;
      if (dt <= 0) continue;

      curr.angularVelocityKnee = (curr.kneeAngle - prev.kneeAngle).abs() / dt;
      curr.angularVelocityHip = (curr.hipAngle - prev.hipAngle).abs() / dt;
      curr.angularVelocityShoulder = (curr.shoulderAngle - prev.shoulderAngle).abs() / dt;
      curr.angularVelocityElbow = (curr.elbowAngle - prev.elbowAngle).abs() / dt;

      curr.meanAngularVelocity = (curr.angularVelocityKnee +
              curr.angularVelocityHip +
              curr.angularVelocityShoulder +
              curr.angularVelocityElbow) /
          4.0;
    }
  }

  void _smoothHipPositions(List<FrameData> frames) {
    if (frames.isEmpty) return;

    for (int i = 1; i < frames.length; i++) {
      final prev = frames[i - 1];
      final curr = frames[i];

      final smoothedX = _emaAlpha * curr.hipMid.x + (1 - _emaAlpha) * prev.hipMid.x;
      final smoothedY = _emaAlpha * curr.hipMid.y + (1 - _emaAlpha) * prev.hipMid.y;

      curr.hipMid = Point2D(smoothedX, smoothedY);
    }
  }

  // =========================================================================
  // PHASE 2: Signal-Driven Phase Detection (State Machine)
  // =========================================================================

  /// EMA smooth a signal list in-place.
  List<double> _emaSmooth(List<double> signal, double alpha) {
    if (signal.length < 2) return signal;
    final result = List<double>.from(signal);
    for (int i = 1; i < result.length; i++) {
      result[i] = alpha * signal[i] + (1 - alpha) * result[i - 1];
    }
    return result;
  }

  double _stddev(List<double> values) {
    return sqrt(_variance(values));
  }

  /// Signal-driven phase detection.
  ///
  /// Walks through EMA-smoothed velocity/curvature/roll and uses adaptive
  /// thresholds derived from signal statistics. Produces multiple TRAVEL/TURN
  /// segments for 50m+ videos.
  List<PhaseData> _detectPhases(List<FrameData> frames) {
    if (frames.length < 3) {
      return [
        PhaseData(phase: 'TRAVEL', startFrame: 0, endFrame: frames.length, confidence: 0.5),
      ];
    }

    // 1. Extract and EMA-smooth signals
    final rawVelocity = frames.map((f) => f.velocity).toList();
    final rawCurvature = frames.map((f) => f.curvature).toList();
    final rawRoll = frames.map((f) => f.roll).toList();

    const smoothAlpha = 0.3;
    final velocity = _emaSmooth(rawVelocity, smoothAlpha);
    final curvature = _emaSmooth(rawCurvature, smoothAlpha);
    final roll = _emaSmooth(rawRoll, smoothAlpha);

    // 2. Derive adaptive thresholds from signal statistics
    final vMedian = _median(velocity);
    final vThreshold = vMedian * 0.3;
    final curvMedian = _median(curvature);
    final curvStdDev = _stddev(curvature);
    final curvThreshold = curvMedian + 2.0 * curvStdDev;
    final rollMedian = _median(roll);
    final rollStdDev = _stddev(roll);
    final rollThreshold = rollMedian + 2.0 * rollStdDev;

    // Minimum frames for phase duration thresholds
    final minPrepToStartFrames = max(1, (0.5 * _fps).round()); // 0.5s
    final maxTurnCandidateFrames = (3.0 * _fps).round(); // 3s

    // 3. State machine (using string constants since Dart doesn't support local enums)
    const stUnknown = 'unknown';
    const stPrep = 'prep';
    const stStart = 'start';
    const stTravel = 'travel';
    const stTurnCandidate = 'turnCandidate';

    var smState = stUnknown;
    int phaseStartIdx = 0;
    int turnCandidateStart = 0;
    int consecutiveHighV = 0;

    final phases = <PhaseData>[];

    void closePhase(String label, int startIdx, int endIdx, double conf, {String? subType}) {
      if (endIdx > startIdx) {
        final seg = frames.sublist(startIdx, min(endIdx, frames.length));
        final avgV = seg.isEmpty ? 0.0 : seg.map((f) => f.velocity).reduce((a, b) => a + b) / seg.length;
        final avgC = seg.isEmpty ? 0.0 : seg.map((f) => f.curvature).reduce((a, b) => a + b) / seg.length;
        final avgR = seg.isEmpty ? 0.0 : seg.map((f) => f.roll).reduce((a, b) => a + b) / seg.length;
        phases.add(PhaseData(
          phase: label,
          startFrame: startIdx,
          endFrame: endIdx,
          confidence: conf,
          subType: subType,
          eventSignals: {'velocity': avgV, 'curvature': avgC, 'roll': avgR},
        ));
      }
    }

    for (int i = 0; i < frames.length; i++) {
      final v = velocity[i];
      final c = curvature[i];
      final r = roll[i];
      final isLowV = v < vThreshold;
      final isHighCurvOrRoll = c > curvThreshold || r > rollThreshold;

      if (smState == stUnknown) {
        if (isLowV) {
          smState = stPrep;
          phaseStartIdx = i;
        } else {
          smState = stTravel;
          phaseStartIdx = i;
        }
      } else if (smState == stPrep) {
        if (!isLowV) {
          consecutiveHighV++;
          if (consecutiveHighV >= minPrepToStartFrames) {
            closePhase('PREP', phaseStartIdx, i - consecutiveHighV + 1, 0.7);
            smState = stStart;
            phaseStartIdx = i - consecutiveHighV + 1;
            consecutiveHighV = 0;
          }
        } else {
          consecutiveHighV = 0;
        }
      } else if (smState == stStart) {
        if (v > vThreshold) {
          consecutiveHighV++;
          if (consecutiveHighV >= minPrepToStartFrames) {
            closePhase('START', phaseStartIdx, i, 0.8);
            smState = stTravel;
            phaseStartIdx = i;
            consecutiveHighV = 0;
          }
        } else {
          consecutiveHighV = 0;
        }
      } else if (smState == stTravel) {
        if (isLowV && isHighCurvOrRoll) {
          closePhase('TRAVEL', phaseStartIdx, i, 0.9);
          smState = stTurnCandidate;
          turnCandidateStart = i;
        }
        // Velocity dip without curvature/roll: stay in TRAVEL
      } else if (smState == stTurnCandidate) {
        final candidateDuration = i - turnCandidateStart;
        if (!isLowV) {
          closePhase('TURN', turnCandidateStart, i, 0.85, subType: 'CONFIRMED');
          smState = stTravel;
          phaseStartIdx = i;
        } else if (candidateDuration > maxTurnCandidateFrames) {
          closePhase('TURN', turnCandidateStart, i, 0.5, subType: 'UNKNOWN');
          smState = stTravel;
          phaseStartIdx = i;
        }
      }
    }

    // Close any remaining open phase
    if (smState == stPrep) {
      closePhase('PREP', phaseStartIdx, frames.length, 0.5);
    } else if (smState == stStart) {
      closePhase('START', phaseStartIdx, frames.length, 0.6);
    } else if (smState == stTravel) {
      closePhase('TRAVEL', phaseStartIdx, frames.length, 0.9);
    } else if (smState == stTurnCandidate) {
      closePhase('TURN', turnCandidateStart, frames.length, 0.5, subType: 'UNKNOWN');
    } else {
      closePhase('TRAVEL', phaseStartIdx, frames.length, 0.5);
    }

    // 4. Post-process: merge adjacent same-type phases
    final merged = <PhaseData>[];
    for (final p in phases) {
      if (merged.isNotEmpty && merged.last.phase == p.phase) {
        // Merge
        final prev = merged.removeLast();
        merged.add(PhaseData(
          phase: p.phase,
          startFrame: prev.startFrame,
          endFrame: p.endFrame,
          confidence: (prev.confidence + p.confidence) / 2,
          subType: prev.subType ?? p.subType,
          eventSignals: p.eventSignals,
        ));
      } else {
        merged.add(p);
      }
    }

    // Ensure at least one TRAVEL phase exists
    if (!merged.any((p) => p.phase == 'TRAVEL')) {
      merged.add(PhaseData(phase: 'TRAVEL', startFrame: 0, endFrame: frames.length, confidence: 0.5));
    }

    return merged;
  }

  // =========================================================================
  // PHASE 3: Motion Classification (ARM / KICK / GLIDE / MIXED)
  // =========================================================================

  List<MotionWindow> _classifyMotion(List<FrameData> frames) {
    final windows = <MotionWindow>[];

    final windowFrames = (_windowSize * _fps).toInt();
    final stepFrames = (_windowStep * _fps).toInt();

    for (int start = 0; start + windowFrames <= frames.length; start += stepFrames) {
      final windowData = frames.sublist(start, start + windowFrames);
      final motion = _classifyWindow(windowData);

      windows.add(motion);
    }

    return windows;
  }

  MotionWindow _classifyWindow(List<FrameData> frames) {
    // Calculate wrist and ankle energies
    final eArm = _calculateWristEnergy(frames);
    final eLeg = _calculateAnkleEnergy(frames);

    // Detect leg periodicity
    final legPeriodicity = _detectLegPeriodicity(frames);

    // Angular velocity metrics for glide detection
    final angularVelocities = frames
        .where((f) => f.meanAngularVelocity > 0)
        .map((f) => f.meanAngularVelocity)
        .toList();
    final windowMeanAngularVelocity = angularVelocities.isNotEmpty
        ? angularVelocities.reduce((a, b) => a + b) / angularVelocities.length
        : 0.0;

    // Streamline hold: fraction of frames with shoulderAngle > 150 AND kneeAngle > 160
    final streamlineFrames = frames.where(
      (f) => f.shoulderAngle > 150 && f.kneeAngle > 160,
    ).length;
    final streamlineHold = frames.isNotEmpty ? streamlineFrames / frames.length : 0.0;

    // Classification rules (ordered by priority)
    String label;
    double confidence;

    if (legPeriodicity >= 2 && eLeg > 1.1 * eArm) {
      // Priority 1: Breaststroke kick
      label = 'BREAST_KICK';
      confidence = 0.85;
    } else if (eArm > 1.2 * eLeg) {
      // Priority 2: Arm stroke
      label = 'ARM_STROKE';
      confidence = 0.80;
    } else if (angularVelocities.isNotEmpty &&
        windowMeanAngularVelocity < _angularVelocityGlideThreshold &&
        streamlineHold > 0.5) {
      // Priority 3: Angular-velocity glide (camera-motion invariant)
      label = 'GLIDE';
      confidence = 0.80;
    } else if (eArm < _lowEnergyThreshold && eLeg < _lowEnergyThreshold) {
      // Priority 4: Energy-based glide (fallback)
      label = 'GLIDE';
      confidence = 0.65;
    } else {
      label = 'MIXED';
      confidence = 0.50;
    }

    return MotionWindow(
      startTime: frames.first.timestamp,
      endTime: frames.last.timestamp,
      label: label,
      confidence: confidence,
      energyArm: eArm,
      energyLeg: eLeg,
      periodicity: legPeriodicity,
    );
  }

  double _calculateWristEnergy(List<FrameData> frames) {
    final velocities = <double>[];

    for (int i = 1; i < frames.length; i++) {
      final prev = frames[i - 1];
      final curr = frames[i];

      final wristMidPrev = _getWristMid(prev.landmarks);
      final wristMidCurr = _getWristMid(curr.landmarks);

      if (wristMidPrev == null || wristMidCurr == null) continue;

      // Project wrist movement onto body-axis perpendicular for rotation invariance
      final bodyAxis = _getBodyAxisForFrame(curr);
      double dist;
      if (bodyAxis != null) {
        final dxRaw = wristMidCurr.x - wristMidPrev.x;
        final dyRaw = wristMidCurr.y - wristMidPrev.y;
        // Perpendicular component of movement
        final perpComponent = (dxRaw * bodyAxis.perpX + dyRaw * bodyAxis.perpY).abs();
        final axialComponent = (dxRaw * bodyAxis.axialX + dyRaw * bodyAxis.axialY).abs();
        dist = sqrt(perpComponent * perpComponent + axialComponent * axialComponent);
      } else {
        final dx = wristMidCurr.x - wristMidPrev.x;
        final dy = wristMidCurr.y - wristMidPrev.y;
        dist = sqrt(dx * dx + dy * dy);
      }

      final dt = curr.timestamp - prev.timestamp;
      if (dt > 0) {
        velocities.add(dist / curr.shoulderWidth / dt);
      }
    }

    return velocities.isEmpty ? 0.0 : _rms(velocities);
  }

  double _calculateAnkleEnergy(List<FrameData> frames) {
    final velocities = <double>[];

    for (int i = 1; i < frames.length; i++) {
      final prev = frames[i - 1];
      final curr = frames[i];

      final ankleMidPrev = _getAnkleMid(prev.landmarks);
      final ankleMidCurr = _getAnkleMid(curr.landmarks);

      if (ankleMidPrev == null || ankleMidCurr == null) continue;

      // Project ankle movement onto body-axis perpendicular for rotation invariance
      final bodyAxis = _getBodyAxisForFrame(curr);
      double dist;
      if (bodyAxis != null) {
        final dxRaw = ankleMidCurr.x - ankleMidPrev.x;
        final dyRaw = ankleMidCurr.y - ankleMidPrev.y;
        final perpComponent = (dxRaw * bodyAxis.perpX + dyRaw * bodyAxis.perpY).abs();
        final axialComponent = (dxRaw * bodyAxis.axialX + dyRaw * bodyAxis.axialY).abs();
        dist = sqrt(perpComponent * perpComponent + axialComponent * axialComponent);
      } else {
        final dx = ankleMidCurr.x - ankleMidPrev.x;
        final dy = ankleMidCurr.y - ankleMidPrev.y;
        dist = sqrt(dx * dx + dy * dy);
      }

      final dt = curr.timestamp - prev.timestamp;
      if (dt > 0) {
        velocities.add(dist / curr.shoulderWidth / dt);
      }
    }

    return velocities.isEmpty ? 0.0 : _rms(velocities);
  }

  int _detectLegPeriodicity(List<FrameData> frames) {
    // Extract ankle perpendicular component (rotation-invariant)
    final signal = <double>[];
    for (final frame in frames) {
      final ankleMid = _getAnkleMid(frame.landmarks);
      if (ankleMid == null) continue;

      final bodyAxis = _getBodyAxisForFrame(frame);
      if (bodyAxis != null) {
        // Project ankle onto perpendicular axis
        final dx = ankleMid.x - bodyAxis.hipMidX;
        final dy = ankleMid.y - bodyAxis.hipMidY;
        final perpComp = dx * bodyAxis.perpX + dy * bodyAxis.perpY;
        signal.add(perpComp / frame.shoulderWidth);
      } else {
        // Fallback to raw Y
        signal.add(ankleMid.y / frame.shoulderWidth);
      }
    }

    if (signal.length < 5) return 0;

    // Detect peaks
    final peaks = _detectPeaks(signal, minDistance: _minPeakDistance);
    return peaks.length;
  }

  // =========================================================================
  // PHASE 4: Metrics Calculation
  // =========================================================================

  Map<String, dynamic> _calculateMetrics(
    List<FrameData> frames,
    List<MotionWindow> windows,
  ) {
    final metrics = <String, dynamic>{};

    // Get motion-specific windows
    final kickWindows = windows.where((w) => w.label == 'BREAST_KICK').toList();
    final armWindows = windows.where((w) => w.label == 'ARM_STROKE').toList();
    final glideWindows = windows.where((w) => w.label == 'GLIDE').toList();

    // Streamline metrics (on GLIDE windows preferentially)
    final streamlineFrames = glideWindows.isNotEmpty
        ? _getFramesForWindows(frames, glideWindows)
        : frames;
    metrics['streamline'] = _calculateStreamlineMetrics(streamlineFrames);

    // Kick metrics (requires >= 3 cycles)
    if (kickWindows.isNotEmpty) {
      final totalKickCycles = kickWindows.fold<int>(
        0,
        (sum, w) => sum + w.periodicity,
      );

      if (totalKickCycles >= 1) {
        final kickFrames = _getFramesForWindows(frames, kickWindows);
        metrics['kick'] = _calculateKickMetrics(kickFrames, totalKickCycles);
        metrics['kick']['confidence'] = totalKickCycles >= 3 ? 0.85 : 0.65;
      } else {
        metrics['kick'] = <String, dynamic>{
          'confidence': 0.4,
          'message': 'Insufficient kick cycles detected ($totalKickCycles/1)',
        };
      }
    } else {
      metrics['kick'] = <String, dynamic>{
        'confidence': 0.0,
        'message': 'No kick windows detected',
      };
    }

    // Arm metrics (requires >= 1 cycle)
    if (armWindows.isNotEmpty) {
      final armFrames = _getFramesForWindows(frames, armWindows);
      metrics['arm'] = _calculateArmMetrics(armFrames);
      metrics['arm']['confidence'] = armWindows.length >= 2 ? 0.80 : 0.60;
    } else {
      metrics['arm'] = <String, dynamic>{
        'confidence': 0.4,
        'message': 'Insufficient arm stroke cycles',
      };
    }

    // Glide effectiveness
    final travelTime = frames.last.timestamp - frames.first.timestamp;
    final glideTime = glideWindows.fold<double>(
      0.0,
      (sum, w) => sum + (w.endTime - w.startTime),
    );
    metrics['glide'] = _calculateGlideMetrics(glideTime, travelTime, frames);

    return metrics;
  }

  List<FrameData> _getFramesForWindows(
    List<FrameData> frames,
    List<MotionWindow> windows,
  ) {
    final selectedFrames = <FrameData>[];

    for (final window in windows) {
      final windowFrames = frames.where(
        (f) => f.timestamp >= window.startTime && f.timestamp <= window.endTime,
      );
      selectedFrames.addAll(windowFrames);
    }

    return selectedFrames;
  }

  Map<String, dynamic> _calculateStreamlineMetrics(List<FrameData> frames) {
    if (frames.isEmpty) {
      return <String, dynamic>{'confidence': 0.0, 'message': 'No streamline data'};
    }

    final axisAngles = <double>[];
    final curvatures = <double>[];
    final wobbles = <double>[];
    final headPitches = <double>[];

    for (final frame in frames) {
      // Body axis angle
      final shoulderMid = _getShoulderMid(frame.landmarks);
      final ankleMid = _getAnkleMid(frame.landmarks);

      if (shoulderMid != null && ankleMid != null) {
        final angle = _angle(ankleMid, shoulderMid);
        axisAngles.add(angle.abs());

        // Curvature
        final hipMid = frame.hipMid;
        final curv = _distancePointToLine(
          hipMid,
          shoulderMid,
          ankleMid,
        ) / frame.shoulderWidth;
        curvatures.add(curv);
      }

      // Head pitch
      final nose = frame.landmarks[PoseLandmarkType.nose];
      if (nose != null && shoulderMid != null) {
        final headPitch = _angle(
          Point2D(nose.x, nose.y),
          shoulderMid,
        );
        headPitches.add(headPitch);
      }
    }

    // Wobble (lateral/vertical motion variance)
    final hipYs = frames.map((f) => f.hipMid.y / f.shoulderWidth).toList();
    final wobble = _rms(_highpass(hipYs));

    // Calculate scores
    final axisScore = axisAngles.isEmpty
        ? 50.0
        : _scoreFromError(_mean(axisAngles), 5.0, 20.0);

    final curvScore = curvatures.isEmpty
        ? 50.0
        : _scoreFromError(_mean(curvatures), 0.03, 0.18);

    final wobbleScore = _scoreFromError(wobble, 0.02, 0.12);

    final headScore = headPitches.isEmpty
        ? 50.0
        : _scoreFromError(_variance(headPitches), 8.0, 35.0);

    final overallScore = 0.30 * axisScore +
        0.30 * curvScore +
        0.20 * wobbleScore +
        0.20 * headScore;

    return <String, dynamic>{
      'overall': overallScore,
      'axisAngle': axisScore,
      'curvature': curvScore,
      'wobble': wobbleScore,
      'headStability': headScore,
      'confidence': 0.85,
    };
  }

  Map<String, dynamic> _calculateKickMetrics(
    List<FrameData> frames,
    int totalCycles,
  ) {
    if (frames.isEmpty) {
      return <String, dynamic>{'confidence': 0.0, 'message': 'No kick data'};
    }

    final widths = <double>[];
    final symKneeYs = <double>[];
    final symAnkleYs = <double>[];

    for (final frame in frames) {
      final leftAnkle = frame.landmarks[PoseLandmarkType.leftAnkle];
      final rightAnkle = frame.landmarks[PoseLandmarkType.rightAnkle];

      if (leftAnkle != null && rightAnkle != null) {
        final width = _dist2D(leftAnkle, rightAnkle) / frame.shoulderWidth;
        widths.add(width);

        symAnkleYs.add((leftAnkle.y - rightAnkle.y).abs() / frame.shoulderWidth);
      }

      final leftKnee = frame.landmarks[PoseLandmarkType.leftKnee];
      final rightKnee = frame.landmarks[PoseLandmarkType.rightKnee];

      if (leftKnee != null && rightKnee != null) {
        symKneeYs.add((leftKnee.y - rightKnee.y).abs() / frame.shoulderWidth);
      }
    }

    // Scores
    final widthScore = widths.isEmpty
        ? 50.0
        : _scoreFromTarget(_mean(widths), 0.35, 0.12, 0.30);

    final symKneeScore = symKneeYs.isEmpty
        ? 50.0
        : _scoreFromError(_mean(symKneeYs), 0.03, 0.15);

    final symAnkleScore = symAnkleYs.isEmpty
        ? 50.0
        : _scoreFromError(_mean(symAnkleYs), 0.03, 0.15);

    final symScore = (symKneeScore + symAnkleScore) / 2;

    // Recovery and rhythm (simplified for v1)
    final recoveryScore = 70.0; // Placeholder
    final rhythmScore = 75.0; // Placeholder

    final overallScore = 0.25 * widthScore +
        0.25 * recoveryScore +
        0.25 * symScore +
        0.25 * rhythmScore;

    return <String, dynamic>{
      'overall': overallScore,
      'width': widthScore,
      'symmetry': symScore,
      'recovery': recoveryScore,
      'rhythm': rhythmScore,
      'cycles': totalCycles,
      'confidence': 0.85,
    };
  }

  Map<String, dynamic> _calculateArmMetrics(List<FrameData> frames) {
    if (frames.isEmpty) {
      return <String, dynamic>{
        'confidence': 0.0,
        'message': 'No arm stroke data available',
      };
    }

    // Measure wrist displacement relative to body axis
    final wristDisplacements = <double>[];
    final elbowAngles = <double>[];

    for (final frame in frames) {
      // Get body axis
      final leftShoulder = frame.landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = frame.landmarks[PoseLandmarkType.rightShoulder];
      final leftHip = frame.landmarks[PoseLandmarkType.leftHip];
      final rightHip = frame.landmarks[PoseLandmarkType.rightHip];

      if (leftShoulder == null || rightShoulder == null ||
          leftHip == null || rightHip == null) continue;

      final shoulderMidX = (leftShoulder.x + rightShoulder.x) / 2;
      final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
      final hipMidX = (leftHip.x + rightHip.x) / 2;
      final hipMidY = (leftHip.y + rightHip.y) / 2;

      final axLen = sqrt(pow(hipMidX - shoulderMidX, 2) + pow(hipMidY - shoulderMidY, 2));
      if (axLen < 1.0) continue;

      // Body-axis perpendicular
      final axialX = (hipMidX - shoulderMidX) / axLen;
      final axialY = (hipMidY - shoulderMidY) / axLen;
      final perpX = -axialY;
      final perpY = axialX;

      // Wrist displacement relative to shoulder on perp axis
      final leftWrist = frame.landmarks[PoseLandmarkType.leftWrist];
      if (leftWrist != null) {
        final dx = leftWrist.x - shoulderMidX;
        final dy = leftWrist.y - shoulderMidY;
        final perpComp = (dx * perpX + dy * perpY).abs() / axLen;
        wristDisplacements.add(perpComp);
      }

      // Elbow angle
      final leftElbow = frame.landmarks[PoseLandmarkType.leftElbow];
      if (leftElbow != null && leftWrist != null) {
        final v1x = leftShoulder.x - leftElbow.x;
        final v1y = leftShoulder.y - leftElbow.y;
        final v2x = leftWrist.x - leftElbow.x;
        final v2y = leftWrist.y - leftElbow.y;
        final dot = v1x * v2x + v1y * v2y;
        final m1 = sqrt(v1x * v1x + v1y * v1y);
        final m2 = sqrt(v2x * v2x + v2y * v2y);
        if (m1 > 0 && m2 > 0) {
          final cosA = (dot / (m1 * m2)).clamp(-1.0, 1.0);
          elbowAngles.add(acos(cosA) * 180 / pi);
        }
      }
    }

    if (wristDisplacements.isEmpty) {
      return <String, dynamic>{
        'confidence': 0.0,
        'message': 'No arm stroke data available',
      };
    }

    // Score sweep: larger perpendicular displacement = wider sweep
    final sweepMean = _mean(wristDisplacements);
    final sweepScore = _scoreFromTarget(sweepMean, 0.5, 0.15, 0.40);

    // Score elbow: ~90-120 degrees is optimal for arm stroke
    final elbowScore = elbowAngles.isEmpty
        ? 50.0
        : _scoreFromTarget(_mean(elbowAngles), 105.0, 15.0, 45.0);

    // Rhythm: measure variance of wrist displacement (lower = more rhythmic)
    final sweepVariance = _variance(wristDisplacements);
    final rhythmScore = _scoreFromError(sweepVariance, 0.02, 0.15);

    final overallScore = 0.35 * sweepScore +
        0.30 * elbowScore +
        0.35 * rhythmScore;

    return <String, dynamic>{
      'overall': overallScore,
      'rhythm': rhythmScore,
      'elbow': elbowScore,
      'sweep': sweepScore,
      'confidence': wristDisplacements.length >= 10 ? 0.75 : 0.50,
    };
  }

  /// Glide analysis with disambiguation:
  /// - MEASURED: glide detected with glideRatio > 0
  /// - MEASURED_ZERO: no glide phase, swimmer doesn't glide
  /// - DETECTION_FAILED: no stable low-velocity window found
  ///
  /// Uses two signals: angular-velocity scan (camera-motion invariant, primary)
  /// and translation-velocity scan (secondary). Best estimate = max of both.
  Map<String, dynamic> _calculateGlideMetrics(
    double glideTime,
    double travelTime,
    List<FrameData> travelFrames,
  ) {
    final glideRatio = travelTime > 0 ? glideTime / travelTime : 0.0;

    // Scan 1: longest consecutive low translation-velocity run (existing)
    double maxConsecutiveLowVSec = 0.0;
    double currentRunStart = -1;
    for (final frame in travelFrames) {
      if (frame.velocity < _vLowThreshold) {
        if (currentRunStart < 0) currentRunStart = frame.timestamp;
        final runDuration = frame.timestamp - currentRunStart;
        if (runDuration > maxConsecutiveLowVSec) {
          maxConsecutiveLowVSec = runDuration;
        }
      } else {
        currentRunStart = -1;
      }
    }

    // Scan 2: longest consecutive low angular-velocity run (camera-invariant)
    double maxConsecutiveLowAngVSec = 0.0;
    double angRunStart = -1;
    for (final frame in travelFrames) {
      if (frame.meanAngularVelocity > 0 &&
          frame.meanAngularVelocity < _angularVelocityGlideThreshold) {
        if (angRunStart < 0) angRunStart = frame.timestamp;
        final runDuration = frame.timestamp - angRunStart;
        if (runDuration > maxConsecutiveLowAngVSec) {
          maxConsecutiveLowAngVSec = runDuration;
        }
      } else {
        angRunStart = -1;
      }
    }

    // Use best estimate from both signals
    final bestGlideRunSec = max(maxConsecutiveLowVSec, maxConsecutiveLowAngVSec);

    final minGlideWindow = 0.6; // seconds (3 frames at 5fps)
    String status;
    String reason;
    bool detectionSuccessful;
    double confidence;

    if (bestGlideRunSec >= minGlideWindow && glideRatio > 0) {
      status = 'MEASURED';
      reason = 'Glide detected: ${(glideRatio * 100).toStringAsFixed(0)}%';
      detectionSuccessful = true;
      confidence = 0.70;

      // Clarity bonus: if angular velocity median is well below threshold
      final angVels = travelFrames
          .where((f) => f.meanAngularVelocity > 0)
          .map((f) => f.meanAngularVelocity)
          .toList();
      if (angVels.isNotEmpty) {
        final medAngV = _median(angVels);
        if (medAngV < _angularVelocityGlideThreshold * 0.5) {
          confidence = (confidence + 0.10).clamp(0.0, 1.0);
        }
      }
    } else if (bestGlideRunSec >= minGlideWindow && glideRatio == 0) {
      status = 'MEASURED_ZERO';
      reason = 'No glide phase — swimmer doesn\'t glide';
      detectionSuccessful = true;
      confidence = 0.60;
    } else {
      status = 'DETECTION_FAILED';
      reason = 'No stable glide window detected '
          '(translation: ${maxConsecutiveLowVSec.toStringAsFixed(1)}s, '
          'angular: ${maxConsecutiveLowAngVSec.toStringAsFixed(1)}s)';
      detectionSuccessful = false;
      confidence = 0.30;
    }

    final score = detectionSuccessful
        ? _scoreFromTarget(glideRatio, 0.35, 0.10, 0.30)
        : 0.0;

    return <String, dynamic>{
      'overall': score,
      'glideRatio': glideRatio,
      'status': status,
      'reason': reason,
      'detectionSuccessful': detectionSuccessful,
      'maxConsecutiveLowVelocitySec': maxConsecutiveLowVSec,
      'maxConsecutiveLowAngularVelocitySec': maxConsecutiveLowAngVSec,
      'confidence': confidence,
    };
  }

  // =========================================================================
  // PHASE 5: Coaching Generation
  // =========================================================================

  Map<String, dynamic> _generateCoaching(
    Map<String, dynamic> metrics,
    List<MotionWindow> windows,
  ) {
    final strengths = <String>[];
    final improvements = <String>[];
    final drills = <String>[];
    final warnings = <String>[];

    // Check each metric category
    final categories = ['streamline', 'kick', 'arm', 'glide'];

    for (final category in categories) {
      if (!metrics.containsKey(category)) continue;

      final catMetrics = metrics[category] as Map<String, dynamic>;
      final confidence = catMetrics['confidence'] as double? ?? 0.0;

      // Only recommend drills linked to measured defects (confidence >= 0.55)
      if (confidence < 0.55) {
        if (confidence == 0.0) {
          warnings.add(catMetrics['message'] ?? 'Not measured: $category');
        } else {
          warnings.add('${_formatCategoryName(category)}: Low confidence '
              '(${(confidence * 100).toStringAsFixed(0)}%) — measurement unreliable');
        }
        continue;
      }

      final score = catMetrics['overall'] as double? ?? 0.0;

      if (score >= 75) {
        strengths.add(_getStrengthMessage(category, score));
      } else if (score < 60) {
        improvements.add(_getImprovementMessage(category, catMetrics));
        drills.addAll(_getDrillsForCategory(category, catMetrics));
      } else {
        // Score 60-75: OK but could improve — note but don't generate drills
        strengths.add('${_formatCategoryName(category)}: Decent (${score.toStringAsFixed(0)}/100)');
      }
    }

    return <String, dynamic>{
      'strengths': strengths,
      'improvements': improvements,
      'drills': drills,
      'warnings': warnings,
    };
  }

  String _formatCategoryName(String category) {
    return category[0].toUpperCase() + category.substring(1);
  }

  String _getStrengthMessage(String category, double score) {
    switch (category) {
      case 'streamline':
        return 'Excellent streamline position (${score.toStringAsFixed(0)}/100)';
      case 'kick':
        return 'Strong breaststroke kick technique';
      case 'arm':
        return 'Good arm stroke coordination';
      case 'glide':
        return 'Effective glide phase utilization';
      default:
        return 'Good $category performance';
    }
  }

  String _getImprovementMessage(String category, Map<String, dynamic> metrics) {
    switch (category) {
      case 'streamline':
        if (metrics['curvature'] < 60) {
          return 'Reduce body curvature (banana shape) during glide';
        } else if (metrics['wobble'] < 60) {
          return 'Minimize lateral wobble for better streamline';
        } else if (metrics['headStability'] < 60) {
          return 'Keep head more stable and neutral';
        }
        return 'Improve streamline alignment';
      case 'kick':
        if (metrics['symmetry'] < 60) {
          return 'Work on leg symmetry - both legs should move together';
        } else if (metrics['width'] < 60) {
          return 'Adjust kick width for optimal propulsion';
        }
        return 'Refine breaststroke kick technique';
      case 'arm':
        return 'Improve arm stroke efficiency';
      case 'glide':
        return 'Extend glide phase between strokes';
      default:
        return 'Focus on $category technique';
    }
  }

  List<String> _getDrillsForCategory(String category, Map<String, dynamic> metrics) {
    // Simplified for v1 - will be expanded with dnf_drills.json
    switch (category) {
      case 'streamline':
        return [
          'Streamline hold drill (10s, 3 sets)',
          'Wall push-off with streamline focus',
        ];
      case 'kick':
        return [
          'Breaststroke kick on back (25m, 4 reps)',
          'Kick symmetry drill with mirror',
        ];
      case 'arm':
        return [
          'Arm stroke with buoy (25m, 4 reps)',
          'Single arm drill (25m each arm)',
        ];
      case 'glide':
        return [
          'Stroke + glide counting drill',
          'Distance per stroke focus',
        ];
      default:
        return [];
    }
  }

  // =========================================================================
  // PHASE 6: Analysis Quality & Status Enrichment
  // =========================================================================

  /// Calculate analysis quality confidence (0.0~1.0)
  /// Independent of VideoClassifier — measures data quality, not discipline type.
  ///
  /// Uses conservative fallback defaults (0.5 instead of 0.85/0.90) when
  /// actual values aren't provided, and applies penalties for multi-person
  /// contamination, track switches, and low-confidence metric segments.
  double _calculateAnalysisQualityConfidence({
    required double validFrameRatio,
    required double travelDuration,
    required int kickCycles,
    required Map<String, dynamic> metrics,
    double? landmarkCoverage,
    double? signalContinuity,
    double? multiPersonFrameRatio,
    int? trackSwitchCount,
    int? totalFrames,
  }) {
    // valid frame ratio (target: 0.50+)
    final frameScore = (validFrameRatio / 0.50).clamp(0.0, 1.0);

    // travel duration sufficiency (target: 6s+)
    final durationScore = (travelDuration / 6.0).clamp(0.0, 1.0);

    // kick cycles detected (target: 3+)
    final kickScore = (kickCycles / 3.0).clamp(0.0, 1.0);

    // per-category metric confidence average
    double metricConfSum = 0.0;
    int metricCount = 0;
    for (final key in ['streamline', 'kick', 'arm', 'glide']) {
      if (metrics.containsKey(key)) {
        final cat = metrics[key] as Map<String, dynamic>;
        final conf = cat['confidence'] as double? ?? 0.0;
        metricConfSum += conf;
        metricCount++;
      }
    }
    final metricAvg = metricCount > 0 ? metricConfSum / metricCount : 0.0;

    // landmark coverage — conservative fallback (0.5 instead of 0.85)
    final landmarkCoverageScore = (landmarkCoverage ?? 0.5).clamp(0.0, 1.0);

    // signal continuity — conservative fallback (0.5 instead of 0.90)
    final signalContinuityScore = (signalContinuity ?? 0.5).clamp(0.0, 1.0);

    final baseQuality = (0.25 * frameScore +
            0.20 * durationScore +
            0.15 * kickScore +
            0.15 * landmarkCoverageScore +
            0.10 * signalContinuityScore +
            0.15 * metricAvg)
        .clamp(0.0, 1.0);

    // Penalty system
    double penalty = 0.0;

    // Multi-person contamination penalty
    final mpRatio = multiPersonFrameRatio ?? 0.0;
    if (mpRatio > 0.05) {
      penalty += (mpRatio - 0.05) * 0.8;
    }

    // Track switch penalty
    if (trackSwitchCount != null && totalFrames != null && totalFrames! > 0) {
      final switchRate = trackSwitchCount! / totalFrames!;
      if (switchRate > 0.02) {
        penalty += switchRate * 2.0;
      }
    }

    // Missing segment penalty: per metric with confidence < 0.4
    for (final key in ['streamline', 'kick', 'arm', 'glide']) {
      if (metrics.containsKey(key)) {
        final cat = metrics[key] as Map<String, dynamic>;
        final conf = cat['confidence'] as double? ?? 0.0;
        if (conf < 0.4) {
          penalty += 0.03;
        }
        // Extra penalty for glide DETECTION_FAILED
        if (key == 'glide' && cat['status'] == 'DETECTION_FAILED') {
          penalty += 0.05;
        }
      }
    }

    return (baseQuality - penalty).clamp(0.0, 1.0);
  }

  /// Count total kick cycles from motion windows
  int _countTotalKickCycles(List<MotionWindow> windows) {
    return windows
        .where((w) => w.label == 'BREAST_KICK')
        .fold<int>(0, (sum, w) => sum + w.periodicity);
  }

  /// Enrich each metric with status/reasons/requirements/measurementBasis/confidenceLevel.
  void _enrichMetricsWithStatus(
    Map<String, dynamic> metrics,
    List<MotionWindow> motionWindows,
    List<FrameData> travelFrames,
  ) {
    final enrichments = <String, Map<String, dynamic>>{
      'streamline': {
        'minConfidence': 0.40,
        'requirements': ['Record with full body visible from side angle'],
      },
      'kick': {
        'minConfidence': 0.40,
        'requirements': ['Record >= 3 visible kick cycles from side angle'],
      },
      'arm': {
        'minConfidence': 0.40,
        'requirements': ['Record >= 1 arm stroke cycle with visible arms'],
      },
      'glide': {
        'minConfidence': 0.30,
        'requirements': ['Record >= 6 seconds of continuous swimming'],
      },
    };

    // Count per-category frames and cycles
    final kickWindows = motionWindows.where((w) => w.label == 'BREAST_KICK').toList();
    final armWindows = motionWindows.where((w) => w.label == 'ARM_STROKE').toList();
    final glideWindows = motionWindows.where((w) => w.label == 'GLIDE').toList();

    final windowFrameCounts = <String, int>{
      'streamline': travelFrames.length,
      'kick': kickWindows.fold<int>(0, (s, w) => s + ((w.endTime - w.startTime) * _fps).round()),
      'arm': armWindows.fold<int>(0, (s, w) => s + ((w.endTime - w.startTime) * _fps).round()),
      'glide': glideWindows.fold<int>(0, (s, w) => s + ((w.endTime - w.startTime) * _fps).round()),
    };

    final windowCycleCounts = <String, int>{
      'streamline': 0,
      'kick': kickWindows.fold<int>(0, (s, w) => s + w.periodicity),
      'arm': armWindows.length,
      'glide': glideWindows.length,
    };

    for (final entry in enrichments.entries) {
      final key = entry.key;
      final spec = entry.value;

      if (!metrics.containsKey(key)) {
        metrics[key] = <String, dynamic>{
          'confidence': 0.0,
          'status': 'NOT_AVAILABLE',
          'reasons': ['No $key data detected'],
          'requirements': spec['requirements'],
        };
        continue;
      }

      final cat = metrics[key] as Map<String, dynamic>;
      final confidence = cat['confidence'] as double? ?? 0.0;
      final minConf = spec['minConfidence'] as double;

      if (confidence >= minConf) {
        cat['status'] = 'AVAILABLE';
        cat['reasons'] = <String>[];
      } else {
        cat['status'] = 'NOT_AVAILABLE';
        final reasons = <String>[];
        if (cat.containsKey('message')) {
          reasons.add(cat['message'] as String);
        } else {
          reasons.add('Confidence too low: ${(confidence * 100).toStringAsFixed(0)}% (min: ${(minConf * 100).toStringAsFixed(0)}%)');
        }
        cat['reasons'] = reasons;
      }
      cat['requirements'] = spec['requirements'];

      // Add measurement basis
      cat['measurementBasis'] = {
        'frameCount': windowFrameCounts[key] ?? 0,
        'cycleCount': windowCycleCounts[key] ?? 0,
      };

      // Add confidence level label (three-tier system)
      if (confidence >= 0.70) {
        cat['confidenceLevel'] = 'confirmed';
      } else if (confidence >= 0.55) {
        cat['confidenceLevel'] = 'likely';
      } else {
        cat['confidenceLevel'] = 'not_reliable';
        // Add per-metric guidance for unreliable measurements
        cat['notReliableReasons'] = <String>[
          '${_formatCategoryName(key)} confidence is ${(confidence * 100).toStringAsFixed(0)}% (needs ≥55%)',
          if (cat.containsKey('message')) cat['message'] as String,
        ];
        cat['captureGuidance'] = _getCaptureGuidanceForMetric(key);
      }
    }
  }

  /// Get filming tips for a specific metric category.
  List<String> _getCaptureGuidanceForMetric(String category) {
    switch (category) {
      case 'streamline':
        return [
          'Film from the side with the full body in frame',
          'Ensure good lighting and a stable camera',
        ];
      case 'kick':
        return [
          'Record at least 3 visible kick cycles',
          'Film from the side to show leg movement clearly',
        ];
      case 'arm':
        return [
          'Record at least 1 full arm stroke cycle',
          'Ensure arms are visible throughout the stroke',
        ];
      case 'glide':
        return [
          'Record at least 6 seconds of continuous swimming',
          'Include the glide phase between strokes',
        ];
      default:
        return ['Film with full body visible from the side'];
    }
  }

  // =========================================================================
  // Body Axis Helpers (for rotation-invariant projections)
  // =========================================================================

  _FrameBodyAxis? _getBodyAxisForFrame(FrameData frame) {
    final leftShoulder = frame.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = frame.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = frame.landmarks[PoseLandmarkType.leftHip];
    final rightHip = frame.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null) return null;

    final shoulderMidX = (leftShoulder.x + rightShoulder.x) / 2;
    final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
    final hipMidX = (leftHip.x + rightHip.x) / 2;
    final hipMidY = (leftHip.y + rightHip.y) / 2;

    final axX = hipMidX - shoulderMidX;
    final axY = hipMidY - shoulderMidY;
    final axLen = sqrt(axX * axX + axY * axY);
    if (axLen < 1.0) return null;

    final axialX = axX / axLen;
    final axialY = axY / axLen;
    final perpX = -axialY;
    final perpY = axialX;

    return _FrameBodyAxis(
      axialX: axialX, axialY: axialY,
      perpX: perpX, perpY: perpY,
      hipMidX: hipMidX, hipMidY: hipMidY,
      axisLength: axLen,
    );
  }

  // =========================================================================
  // Helper Functions
  // =========================================================================

  double _calculateOverallScore(Map<String, dynamic> metrics) {
    final scores = <double>[];
    final weights = <double>[];

    final categories = {
      'streamline': 0.35,
      'kick': 0.30,
      'arm': 0.20,
      'glide': 0.15,
    };

    for (final entry in categories.entries) {
      if (metrics.containsKey(entry.key)) {
        final catMetrics = metrics[entry.key] as Map<String, dynamic>;
        final confidence = catMetrics['confidence'] as double? ?? 0.0;

        if (confidence >= 0.55) {
          final score = catMetrics['overall'] as double? ?? 0.0;
          scores.add(score);
          weights.add(entry.value);
        }
      }
    }

    if (scores.isEmpty) return 0.0;

    final totalWeight = weights.fold<double>(0.0, (a, b) => a + b);
    if (totalWeight == 0) return 0.0;

    double weightedSum = 0.0;
    for (int i = 0; i < scores.length; i++) {
      weightedSum += scores[i] * weights[i];
    }

    return weightedSum / totalWeight;
  }

  Map<String, dynamic> _getInsufficientDataResult(String message) {
    return <String, dynamic>{
      'overallScore': 0.0,
      'classification': 'OTHER',
      'classificationConfidence': 0.0,
      'classificationReason': 'Insufficient data for classification',
      'classificationScores': {
        'DNF': 0.0,
        'DYN': 0.0,
        'DYNB': 0.0,
      },
      'analysisQualityConfidence': 0.0,
      'analysisMode': <String, dynamic>{
        'mode': 'QUICK_FEEDBACK',
        'levelTestEligible': false,
        'failedRequirements': [message],
        'stats': <String, dynamic>{
          'validFrameRatio': 0.0,
          'travelDuration': 0.0,
          'kickCycles': 0,
          'classification': 'OTHER',
        },
      },
      'reasonCodes': <String>['INSUFFICIENT_DATA'],
      'detectedActivities': <String>[],
      'phases': [],
      'motionWindows': [],
      'metrics': <String, dynamic>{},
      'coaching': <String, dynamic>{
        'strengths': [],
        'improvements': [],
        'drills': [],
        'warnings': [message],
      },
      'metadata': <String, dynamic>{
        'analysisVersion': 'DNF_FULL_v3',
        'error': message,
      },
    };
  }

  // Scoring functions
  double _scoreFromError(double error, double a, double b) {
    if (error <= 0) return 100.0;
    if (error >= b * 2) return 0.0;

    final normalized = error / (b * 2);
    return ((1 - normalized) * 100).clamp(0.0, 100.0);
  }

  double _scoreFromTarget(double value, double target, double tol, double maxDev) {
    final error = (value - target).abs();
    if (error <= tol) return 100.0;
    if (error >= maxDev) return 0.0;

    final normalized = (error - tol) / (maxDev - tol);
    return ((1 - normalized) * 100).clamp(0.0, 100.0);
  }

  // Geometry helpers
  double _dist2D(PoseLandmark a, PoseLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }

  Point2D _midpoint(PoseLandmark a, PoseLandmark b) {
    return Point2D((a.x + b.x) / 2, (a.y + b.y) / 2);
  }

  Point2D? _getShoulderMid(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final left = landmarks[PoseLandmarkType.leftShoulder];
    final right = landmarks[PoseLandmarkType.rightShoulder];
    if (left == null || right == null) return null;
    return Point2D((left.x + right.x) / 2, (left.y + right.y) / 2);
  }

  Point2D? _getAnkleMid(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final left = landmarks[PoseLandmarkType.leftAnkle];
    final right = landmarks[PoseLandmarkType.rightAnkle];
    if (left == null || right == null) return null;
    return Point2D((left.x + right.x) / 2, (left.y + right.y) / 2);
  }

  Point2D? _getKneeMid(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final left = landmarks[PoseLandmarkType.leftKnee];
    final right = landmarks[PoseLandmarkType.rightKnee];
    if (left == null || right == null) return null;
    return Point2D((left.x + right.x) / 2, (left.y + right.y) / 2);
  }

  Point2D? _getWristMid(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final left = landmarks[PoseLandmarkType.leftWrist];
    final right = landmarks[PoseLandmarkType.rightWrist];
    if (left == null || right == null) return null;
    return Point2D((left.x + right.x) / 2, (left.y + right.y) / 2);
  }

  double _angle(Point2D from, Point2D to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    return atan2(dy, dx) * 180 / pi;
  }

  double _distancePointToLine(Point2D point, Point2D lineStart, Point2D lineEnd) {
    final dx = lineEnd.x - lineStart.x;
    final dy = lineEnd.y - lineStart.y;
    final length = sqrt(dx * dx + dy * dy);

    if (length == 0) return 0.0;

    final t = ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) / (length * length);
    final projX = lineStart.x + t * dx;
    final projY = lineStart.y + t * dy;

    final distX = point.x - projX;
    final distY = point.y - projY;

    return sqrt(distX * distX + distY * distY);
  }

  // Signal processing
  List<int> _detectPeaks(List<double> signal, {int minDistance = 5}) {
    final peaks = <int>[];

    for (int i = 1; i < signal.length - 1; i++) {
      if (signal[i] > signal[i - 1] && signal[i] > signal[i + 1]) {
        if (peaks.isEmpty || (i - peaks.last) >= minDistance) {
          peaks.add(i);
        }
      }
    }

    return peaks;
  }

  List<double> _highpass(List<double> signal) {
    if (signal.length < 2) return signal;

    final result = <double>[];
    final mean = _mean(signal);

    for (final value in signal) {
      result.add(value - mean);
    }

    return result;
  }

  // Statistics
  double _mean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _median(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isEven
        ? (sorted[mid - 1] + sorted[mid]) / 2
        : sorted[mid];
  }

  double _variance(List<double> values) {
    if (values.length < 2) return 0.0;
    final mean = _mean(values);
    final sqDiffs = values.map((v) => (v - mean) * (v - mean));
    return sqDiffs.reduce((a, b) => a + b) / values.length;
  }

  double _rms(List<double> values) {
    if (values.isEmpty) return 0.0;
    final squares = values.map((v) => v * v);
    return sqrt(squares.reduce((a, b) => a + b) / values.length);
  }
}

// ============================================================================
// Data Classes
// ============================================================================

class FrameData {
  final int frameIndex;
  final double timestamp;
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final double shoulderWidth;
  Point2D hipMid;
  double velocity;
  double curvature; // shoulder-hip-knee angle deviation from 180°
  double roll; // |leftShoulder.y - rightShoulder.y| / shoulderWidth

  // Joint angles (degrees)
  double kneeAngle;
  double hipAngle;
  double shoulderAngle;
  double elbowAngle;

  // Angular velocities (deg/s)
  double angularVelocityKnee;
  double angularVelocityHip;
  double angularVelocityShoulder;
  double angularVelocityElbow;

  // Mean angular velocity across all four joints (deg/s)
  double meanAngularVelocity;

  FrameData({
    required this.frameIndex,
    required this.timestamp,
    required this.landmarks,
    required this.shoulderWidth,
    required this.hipMid,
    this.velocity = 0.0,
    this.curvature = 0.0,
    this.roll = 0.0,
    this.kneeAngle = 0.0,
    this.hipAngle = 0.0,
    this.shoulderAngle = 0.0,
    this.elbowAngle = 0.0,
    this.angularVelocityKnee = 0.0,
    this.angularVelocityHip = 0.0,
    this.angularVelocityShoulder = 0.0,
    this.angularVelocityElbow = 0.0,
    this.meanAngularVelocity = 0.0,
  });
}

class PhaseData {
  final String phase;
  final int startFrame;
  final int endFrame;
  final double confidence;
  final String? subType; // 'CONFIRMED' | 'UNKNOWN' for TURN phases
  final Map<String, double>? eventSignals; // avg velocity/curvature/roll

  PhaseData({
    required this.phase,
    required this.startFrame,
    required this.endFrame,
    required this.confidence,
    this.subType,
    this.eventSignals,
  });

  double get duration => (endFrame - startFrame) / DNFFullAnalyzer._fps;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'phase': phase,
        'startFrame': startFrame,
        'endFrame': endFrame,
        'startTime': startFrame / DNFFullAnalyzer._fps,
        'endTime': endFrame / DNFFullAnalyzer._fps,
        'duration': duration,
        'confidence': confidence,
        if (subType != null) 'subType': subType,
        if (eventSignals != null) 'eventSignals': eventSignals,
      };
}

class MotionWindow {
  final double startTime;
  final double endTime;
  final String label;
  final double confidence;
  final double energyArm;
  final double energyLeg;
  final int periodicity;

  MotionWindow({
    required this.startTime,
    required this.endTime,
    required this.label,
    required this.confidence,
    required this.energyArm,
    required this.energyLeg,
    required this.periodicity,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'startTime': startTime,
        'endTime': endTime,
        'duration': endTime - startTime,
        'label': label,
        'confidence': confidence,
        'energyArm': energyArm,
        'energyLeg': energyLeg,
        'periodicity': periodicity,
      };
}

class Point2D {
  final double x;
  final double y;

  Point2D(this.x, this.y);
}

/// Body axis vectors for a single frame, used for rotation-invariant projections.
class _FrameBodyAxis {
  final double axialX;
  final double axialY;
  final double perpX;
  final double perpY;
  final double hipMidX;
  final double hipMidY;
  final double axisLength;

  _FrameBodyAxis({
    required this.axialX,
    required this.axialY,
    required this.perpX,
    required this.perpY,
    required this.hipMidX,
    required this.hipMidY,
    required this.axisLength,
  });
}
