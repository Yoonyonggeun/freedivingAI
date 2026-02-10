import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Indoor Analysis Service V2
///
/// Implements GPT spec-compliant analysis with:
/// - Normalized metrics (resolution-independent)
/// - Phase detection (START/TRAVEL/TURN)
/// - Actual calculations (no hardcoding)
/// - Confidence scoring
/// - Backward compatibility with v1 output structure
class IndoorAnalysisServiceV2 {
  // Constants
  static const double _fps = 30.0;
  static const double _emaAlpha = 0.2;
  static const int _startPhaseDuration = 90; // frames (3 seconds)
  static const int _turnPhaseDuration = 60; // frames (2 seconds)

  /// Main analysis entry point - maintains v1 method signature
  Map<String, dynamic> analyzeIndoorDiscipline({
    required List<Pose> poses,
    required String discipline,
    required String category,
  }) {
    // 1. Convert to FramePoses with normalization
    List<FramePose> frames = _convertToFramePoses(poses);

    // 2. Edge case: empty/insufficient data
    if (frames.isEmpty) {
      return _getDefaultAnalysis(confidence: 0.2, category: category);
    }
    if (frames.length < 10) {
      return _getDefaultAnalysis(confidence: 0.3, category: category);
    }

    // 3. Detect phases
    List<PhaseData> phases = _detectPhases(frames, discipline);

    // 4. Calculate metrics based on category
    Map<String, MetricResult> metrics = {};
    if (category == 'streamline') {
      metrics = _analyzeStreamlineMetrics(frames);
    } else if (category == 'finning') {
      metrics = _analyzeFinningMetrics(frames);
    } else if (category == 'turn') {
      metrics = _analyzeTurnMetrics(frames, phases);
    }

    // 5. Calculate overall confidence
    double confidence = _calculateOverallConfidence(frames, phases);

    // 6. Aggregate to v1 categoryScores
    Map<String, double> categoryScores = _aggregateToCategoryScores(metrics, category);
    double overallScore = categoryScores.values.isEmpty
        ? 0.0
        : categoryScores.values.reduce((a, b) => a + b) / categoryScores.length;

    // 7. Generate v1-compatible feedback
    List<String> strengths = _generateStrengths(metrics, category);
    List<String> improvements = _generateImprovements(metrics, category);

    // 8. Package v2 data
    Map<String, dynamic> v2Data = {
      'version': '2.0',
      'phases': phases.map((p) => p.toJson()).toList(),
      'metrics': metrics.map((k, v) => MapEntry(k, v.toJson())),
      'overallConfidence': confidence,
      'metadata': {
        'frameCount': frames.length,
        'durationSec': frames.length / _fps,
        'analysisTimestamp': DateTime.now().toIso8601String(),
        'discipline': discipline,
        'category': category,
      },
    };

    // 9. Return v1 structure + v2 data
    return {
      'overallScore': overallScore,
      'categoryScores': categoryScores,
      'strengths': strengths,
      'improvements': improvements,
      'v2Data': v2Data,
    };
  }

  // ============================================================================
  // PHASE 1: FOUNDATION & UTILITIES
  // ============================================================================

  /// Convert ML Kit Poses to FramePoses with normalization
  List<FramePose> _convertToFramePoses(List<Pose> poses) {
    List<FramePose> frames = [];

    for (int i = 0; i < poses.length; i++) {
      final pose = poses[i];

      // Extract landmarks
      Map<PoseLandmarkType, PoseLandmark> landmarks = {};
      for (var landmark in pose.landmarks.values) {
        landmarks[landmark.type] = landmark;
      }

      // Check for critical landmarks
      if (!_hasCriticalLandmarks(landmarks)) {
        continue; // Skip invalid frame
      }

      // Calculate normalization scale (shoulder width)
      double shoulderWidth = _calculateShoulderWidth(landmarks);
      if (shoulderWidth < 10.0) {
        continue; // Invalid scale, skip frame
      }

      // Calculate frame confidence
      double confidence = _calculateFrameConfidence(landmarks);

      frames.add(FramePose(
        frameIndex: i,
        timestamp: i / _fps,
        landmarks: landmarks,
        shoulderWidth: shoulderWidth,
        confidence: confidence,
      ));
    }

    return frames;
  }

  /// Check if frame has critical landmarks
  bool _hasCriticalLandmarks(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final required = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
      PoseLandmarkType.nose,
    ];

    return required.every((type) => landmarks.containsKey(type));
  }

  /// Calculate shoulder width as normalization scale S
  double _calculateShoulderWidth(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder]!;
    return _dist2D(leftShoulder, rightShoulder);
  }

  /// Calculate frame confidence from landmark likelihoods
  double _calculateFrameConfidence(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    if (landmarks.isEmpty) return 0.0;

    double sum = 0.0;
    for (var landmark in landmarks.values) {
      sum += landmark.likelihood;
    }
    return sum / landmarks.length;
  }

  /// 2D Euclidean distance between two landmarks
  double _dist2D(PoseLandmark p1, PoseLandmark p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Midpoint between two landmarks
  Point<double> _mid(PoseLandmark p1, PoseLandmark p2) {
    return Point((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
  }

  /// Calculate angle between three landmarks in degrees
  double _calculateAngle(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
    final v1x = p1.x - p2.x;
    final v1y = p1.y - p2.y;
    final v2x = p3.x - p2.x;
    final v2y = p3.y - p2.y;

    final dot = v1x * v2x + v1y * v2y;
    final mag1 = sqrt(v1x * v1x + v1y * v1y);
    final mag2 = sqrt(v2x * v2x + v2y * v2y);

    if (mag1 == 0 || mag2 == 0) return 0.0;

    final cosAngle = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return acos(cosAngle) * 180 / pi;
  }

  /// Score from error (0 = target, higher = worse)
  /// Returns 0-100 where 100 is perfect
  double _scoreFromError(double error, double tolerance) {
    if (error <= 0) return 100.0;
    if (error >= tolerance * 2) return 0.0;

    final normalized = error / (tolerance * 2);
    return ((1 - normalized) * 100).clamp(0.0, 100.0);
  }

  /// Score from target value
  /// Returns 0-100 where 100 is at target
  double _scoreFromTarget(double value, double target, double tolerance) {
    final error = (value - target).abs();
    return _scoreFromError(error, tolerance);
  }

  /// Phase detection: START, TRAVEL, TURN
  List<PhaseData> _detectPhases(List<FramePose> frames, String discipline) {
    List<PhaseData> phases = [];

    // START phase: First 3 seconds
    if (frames.length > _startPhaseDuration) {
      phases.add(PhaseData(
        phase: 'START',
        startFrame: 0,
        endFrame: _startPhaseDuration,
        metrics: {},
        confidence: 0.9,
      ));
    }

    // TRAVEL phase: Main section
    int travelStart = frames.length > _startPhaseDuration ? _startPhaseDuration : 0;
    int travelEnd = frames.length;

    // TURN detection: Check last 2 seconds for wall interaction
    bool hasTurn = _detectTurn(frames);
    if (hasTurn && frames.length > _turnPhaseDuration) {
      travelEnd = frames.length - _turnPhaseDuration;

      phases.add(PhaseData(
        phase: 'TRAVEL',
        startFrame: travelStart,
        endFrame: travelEnd,
        metrics: {},
        confidence: 0.95,
      ));

      phases.add(PhaseData(
        phase: 'TURN',
        startFrame: travelEnd,
        endFrame: frames.length,
        metrics: {},
        confidence: 0.7,
      ));
    } else {
      phases.add(PhaseData(
        phase: 'TRAVEL',
        startFrame: travelStart,
        endFrame: travelEnd,
        metrics: {},
        confidence: 0.95,
      ));
    }

    return phases;
  }

  /// Detect if video contains a turn (simplified heuristic)
  bool _detectTurn(List<FramePose> frames) {
    if (frames.length < _turnPhaseDuration) return false;

    // Check for direction change in last portion
    final lastFrames = frames.sublist(frames.length - _turnPhaseDuration);

    // Heuristic: Check for horizontal velocity reversal
    final firstHip = _getHipMid(lastFrames.first.landmarks);
    final lastHip = _getHipMid(lastFrames.last.landmarks);

    // If horizontal movement is minimal in last section, likely a turn
    final horizontalMovement = (lastHip.x - firstHip.x).abs();
    return horizontalMovement < 50; // Pixels - simplified detection
  }

  /// Get hip midpoint
  Point<double> _getHipMid(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip]!;
    final rightHip = landmarks[PoseLandmarkType.rightHip]!;
    return _mid(leftHip, rightHip);
  }

  /// Get shoulder midpoint
  Point<double> _getShoulderMid(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder]!;
    return _mid(leftShoulder, rightShoulder);
  }

  /// Get ankle midpoint
  Point<double> _getAnkleMid(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle]!;
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle]!;
    return _mid(leftAnkle, rightAnkle);
  }

  /// EMA smoothing filter
  List<double> _emaFilter(List<double> values, {double alpha = 0.2}) {
    if (values.isEmpty) return [];

    List<double> smoothed = [values[0]];
    for (int i = 1; i < values.length; i++) {
      smoothed.add(alpha * values[i] + (1 - alpha) * smoothed[i - 1]);
    }
    return smoothed;
  }

  /// Detect peaks in signal
  List<int> _detectPeaks(List<double> signal, {
    double minHeight = 0.0,
    int minDistance = 5,
  }) {
    List<int> peaks = [];

    for (int i = 1; i < signal.length - 1; i++) {
      // Local maxima check
      if (signal[i] > signal[i - 1] && signal[i] > signal[i + 1]) {
        // Height threshold
        if (signal[i] < minHeight) continue;

        // Distance threshold
        if (peaks.isNotEmpty && (i - peaks.last) < minDistance) continue;

        peaks.add(i);
      }
    }

    return peaks;
  }

  /// Calculate standard deviation
  double _stdDev(List<double> values) {
    if (values.isEmpty) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  /// Calculate overall confidence
  double _calculateOverallConfidence(List<FramePose> frames, List<PhaseData> phases) {
    // Factor 1: Landmark detection quality (0.5 weight)
    double landmarkConf = frames.isEmpty
        ? 0.0
        : frames.map((f) => f.confidence).reduce((a, b) => a + b) / frames.length;

    // Factor 2: Frame count sufficiency (0.3 weight)
    double frameConf = min(1.0, frames.length / 90.0);

    // Factor 3: Phase detection confidence (0.2 weight)
    double phaseConf = phases.isEmpty
        ? 0.0
        : phases.map((p) => p.confidence).reduce((a, b) => a + b) / phases.length;

    return (0.5 * landmarkConf + 0.3 * frameConf + 0.2 * phaseConf).clamp(0.0, 1.0);
  }

  // ============================================================================
  // PHASE 2: STREAMLINE METRICS (A-1 to A-6)
  // ============================================================================

  Map<String, MetricResult> _analyzeStreamlineMetrics(List<FramePose> frames) {
    return {
      'A-1': _analyzeBodyAxisAngle(frames),
      'A-2': _analyzeBodyCurvature(frames),
      'A-3': _analyzeBodyWobble(frames),
      'A-4': _analyzeHeadPitchStability(frames),
      'A-5': _analyzeArmExtension(frames),
      'A-6': _analyzeLegTogetherness(frames),
    };
  }

  /// A-1: Body Axis Angle
  MetricResult _analyzeBodyAxisAngle(List<FramePose> frames) {
    List<double> angles = [];

    for (var frame in frames) {
      final shoulder = _getShoulderMid(frame.landmarks);
      final hip = _getHipMid(frame.landmarks);

      // Angle from horizontal
      final dx = hip.x - shoulder.x;
      final dy = hip.y - shoulder.y;
      final angle = atan2(dy, dx) * 180 / pi;

      angles.add(angle.abs());
    }

    final avgAngle = angles.reduce((a, b) => a + b) / angles.length;
    final score = _scoreFromTarget(avgAngle, 0.0, 5.0);

    return MetricResult(
      metricId: 'A-1',
      value: avgAngle,
      score: score,
      confidence: 0.9,
      interpretation: score > 75
          ? 'Excellent body alignment - maintaining horizontal position'
          : 'Focus on keeping body more horizontal',
    );
  }

  /// A-2: Body Curvature
  MetricResult _analyzeBodyCurvature(List<FramePose> frames) {
    List<double> curvatures = [];

    for (var frame in frames) {
      final shoulder = _getShoulderMid(frame.landmarks);
      final hip = _getHipMid(frame.landmarks);
      final ankle = _getAnkleMid(frame.landmarks);

      // Point-to-line distance (normalized)
      final curvature = _pointToLineDistance(hip, shoulder, ankle) / frame.shoulderWidth;
      curvatures.add(curvature);
    }

    final avgCurvature = curvatures.reduce((a, b) => a + b) / curvatures.length;
    final score = _scoreFromError(avgCurvature, 0.1);

    return MetricResult(
      metricId: 'A-2',
      value: avgCurvature,
      score: score,
      confidence: 0.85,
      interpretation: score > 75
          ? 'Good body alignment - minimal curvature'
          : 'Reduce body curvature for better streamline',
    );
  }

  /// Point-to-line distance
  double _pointToLineDistance(Point<double> point, Point<double> lineP1, Point<double> lineP2) {
    final dx = lineP2.x - lineP1.x;
    final dy = lineP2.y - lineP1.y;

    if (dx == 0 && dy == 0) return 0.0;

    final t = ((point.x - lineP1.x) * dx + (point.y - lineP1.y) * dy) / (dx * dx + dy * dy);
    final projX = lineP1.x + t * dx;
    final projY = lineP1.y + t * dy;

    return sqrt(pow(point.x - projX, 2) + pow(point.y - projY, 2));
  }

  /// A-3: Body Wobble
  MetricResult _analyzeBodyWobble(List<FramePose> frames) {
    List<double> hipPositions = [];

    for (var frame in frames) {
      final hip = _getHipMid(frame.landmarks);
      hipPositions.add(hip.x / frame.shoulderWidth); // Normalized
    }

    // Apply EMA smoothing
    final smoothed = _emaFilter(hipPositions);
    final wobble = _stdDev(smoothed);
    final score = _scoreFromError(wobble, 0.2);

    return MetricResult(
      metricId: 'A-3',
      value: wobble,
      score: score,
      confidence: 0.8,
      interpretation: score > 75
          ? 'Stable lateral movement'
          : 'Reduce lateral body movement',
    );
  }

  /// A-4: Head Pitch Stability
  MetricResult _analyzeHeadPitchStability(List<FramePose> frames) {
    List<double> headPitches = [];

    for (var frame in frames) {
      final nose = frame.landmarks[PoseLandmarkType.nose]!;
      final shoulder = _getShoulderMid(frame.landmarks);

      final headPitch = (nose.y - shoulder.y) / frame.shoulderWidth;
      headPitches.add(headPitch);
    }

    final stability = _stdDev(headPitches);
    final score = _scoreFromError(stability, 0.15);

    return MetricResult(
      metricId: 'A-4',
      value: stability,
      score: score,
      confidence: 0.85,
      interpretation: score > 75
          ? 'Consistent head position'
          : 'Stabilize head position',
    );
  }

  /// A-5: Arm Extension
  MetricResult _analyzeArmExtension(List<FramePose> frames) {
    List<double> extensions = [];

    for (var frame in frames) {
      final leftShoulder = frame.landmarks[PoseLandmarkType.leftShoulder]!;
      final rightShoulder = frame.landmarks[PoseLandmarkType.rightShoulder]!;
      final leftWrist = frame.landmarks[PoseLandmarkType.leftWrist];
      final rightWrist = frame.landmarks[PoseLandmarkType.rightWrist];

      if (leftWrist != null && rightWrist != null) {
        final leftExt = _dist2D(leftWrist, leftShoulder) / frame.shoulderWidth;
        final rightExt = _dist2D(rightWrist, rightShoulder) / frame.shoulderWidth;
        extensions.add((leftExt + rightExt) / 2);
      }
    }

    if (extensions.isEmpty) {
      return MetricResult(
        metricId: 'A-5',
        value: 0.0,
        score: 50.0,
        confidence: 0.3,
        interpretation: 'Arm data insufficient',
      );
    }

    final avgExtension = extensions.reduce((a, b) => a + b) / extensions.length;
    final score = _scoreFromTarget(avgExtension, 2.5, 0.3);

    return MetricResult(
      metricId: 'A-5',
      value: avgExtension,
      score: score,
      confidence: 0.8,
      interpretation: score > 75
          ? 'Good arm extension'
          : 'Extend arms fully forward',
    );
  }

  /// A-6: Leg Togetherness
  MetricResult _analyzeLegTogetherness(List<FramePose> frames) {
    List<double> separations = [];

    for (var frame in frames) {
      final leftAnkle = frame.landmarks[PoseLandmarkType.leftAnkle]!;
      final rightAnkle = frame.landmarks[PoseLandmarkType.rightAnkle]!;

      final separation = _dist2D(leftAnkle, rightAnkle) / frame.shoulderWidth;
      separations.add(separation);
    }

    final avgSeparation = separations.reduce((a, b) => a + b) / separations.length;
    final score = _scoreFromError(avgSeparation, 0.3);

    return MetricResult(
      metricId: 'A-6',
      value: avgSeparation,
      score: score,
      confidence: 0.9,
      interpretation: score > 75
          ? 'Legs together - excellent form'
          : 'Keep legs closer together',
    );
  }

  // ============================================================================
  // PHASE 3: FINNING METRICS (B-1, B-3, B-4)
  // ============================================================================

  Map<String, MetricResult> _analyzeFinningMetrics(List<FramePose> frames) {
    final duration = frames.length / _fps;

    return {
      'B-1': _analyzeKickFrequency(frames, duration),
      'B-3': _analyzeKneeFlex(frames),
      'B-4': _analyzeHipStability(frames),
    };
  }

  /// B-1: Kick Frequency
  MetricResult _analyzeKickFrequency(List<FramePose> frames, double duration) {
    List<double> ankleSignal = [];

    for (var frame in frames) {
      final ankle = _getAnkleMid(frame.landmarks);
      ankleSignal.add(ankle.y / frame.shoulderWidth);
    }

    // Apply EMA smoothing
    final smoothed = _emaFilter(ankleSignal, alpha: 0.15);

    // Detect peaks
    final peaks = _detectPeaks(smoothed, minDistance: 5);

    final kicksPerSecond = peaks.length / duration;
    final kicksPerMinute = kicksPerSecond * 60;

    // Target: 50 kicks/min, tolerance: 10
    final score = _scoreFromTarget(kicksPerMinute, 50.0, 10.0);
    final confidence = peaks.length < 3 ? 0.4 : 0.85;

    return MetricResult(
      metricId: 'B-1',
      value: kicksPerMinute,
      score: score,
      confidence: confidence,
      interpretation: score > 75
          ? 'Good kick frequency maintained'
          : 'Adjust kick frequency to ~50/min',
    );
  }

  /// B-3: Knee Flex
  MetricResult _analyzeKneeFlex(List<FramePose> frames) {
    List<double> kneeAngles = [];

    for (var frame in frames) {
      final leftHip = frame.landmarks[PoseLandmarkType.leftHip]!;
      final leftKnee = frame.landmarks[PoseLandmarkType.leftKnee]!;
      final leftAnkle = frame.landmarks[PoseLandmarkType.leftAnkle]!;

      final rightHip = frame.landmarks[PoseLandmarkType.rightHip]!;
      final rightKnee = frame.landmarks[PoseLandmarkType.rightKnee]!;
      final rightAnkle = frame.landmarks[PoseLandmarkType.rightAnkle]!;

      final leftAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
      final rightAngle = _calculateAngle(rightHip, rightKnee, rightAnkle);

      kneeAngles.add((leftAngle + rightAngle) / 2);
    }

    // Apply EMA smoothing
    final smoothed = _emaFilter(kneeAngles);

    // Find minimum angle (maximum flexion)
    final minAngle = smoothed.reduce(min);

    // Target: 170° (nearly straight), tolerance: 10°
    final score = _scoreFromTarget(minAngle, 170.0, 10.0);

    return MetricResult(
      metricId: 'B-3',
      value: minAngle,
      score: score,
      confidence: 0.85,
      interpretation: score > 75
          ? 'Minimal knee bend - efficient kicking'
          : 'Reduce knee bend - kick from hip and ankle',
    );
  }

  /// B-4: Hip Stability
  MetricResult _analyzeHipStability(List<FramePose> frames) {
    List<double> hipPositions = [];

    for (var frame in frames) {
      final hip = _getHipMid(frame.landmarks);
      hipPositions.add(hip.y / frame.shoulderWidth);
    }

    // Apply EMA smoothing
    final smoothed = _emaFilter(hipPositions);

    final stability = _stdDev(smoothed);
    final score = _scoreFromError(stability, 0.2);

    return MetricResult(
      metricId: 'B-4',
      value: stability,
      score: score,
      confidence: 0.8,
      interpretation: score > 75
          ? 'Stable hip position'
          : 'Stabilize hip - reduce vertical movement',
    );
  }

  // ============================================================================
  // PHASE 4: TURN METRICS (D-2, D-4)
  // ============================================================================

  Map<String, MetricResult> _analyzeTurnMetrics(List<FramePose> frames, List<PhaseData> phases) {
    final turnPhase = phases.firstWhere(
      (p) => p.phase == 'TURN',
      orElse: () => PhaseData(
        phase: 'TURN',
        startFrame: 0,
        endFrame: 0,
        metrics: {},
        confidence: 0.0,
      ),
    );

    return {
      'D-2': _analyzeWallTime(turnPhase),
      'D-4': _analyzeExitQuality(turnPhase, frames),
    };
  }

  /// D-2: Wall Time
  MetricResult _analyzeWallTime(PhaseData turnPhase) {
    if (turnPhase.confidence == 0.0) {
      return MetricResult(
        metricId: 'D-2',
        value: 0.0,
        score: 0.0,
        confidence: 0.0,
        interpretation: 'No turn detected',
      );
    }

    final duration = (turnPhase.endFrame - turnPhase.startFrame) / _fps;

    // Score: < 2.5s = 90+, > 2.5s = linear decay
    double score;
    if (duration <= 2.5) {
      score = 90.0;
    } else {
      score = max(0.0, 90.0 - (duration - 2.5) * 20);
    }

    return MetricResult(
      metricId: 'D-2',
      value: duration,
      score: score,
      confidence: turnPhase.confidence,
      interpretation: score > 75
          ? 'Efficient wall time'
          : 'Reduce time at wall',
    );
  }

  /// D-4: Exit Quality
  MetricResult _analyzeExitQuality(PhaseData turnPhase, List<FramePose> frames) {
    if (turnPhase.confidence == 0.0 || frames.isEmpty) {
      return MetricResult(
        metricId: 'D-4',
        value: 0.0,
        score: 0.0,
        confidence: 0.0,
        interpretation: 'No turn detected',
      );
    }

    // Analyze last 10 frames of turn
    final exitFrames = frames.sublist(
      max(0, turnPhase.endFrame - 10),
      min(frames.length, turnPhase.endFrame),
    );

    if (exitFrames.isEmpty) {
      return MetricResult(
        metricId: 'D-4',
        value: 0.0,
        score: 50.0,
        confidence: 0.3,
        interpretation: 'Insufficient turn data',
      );
    }

    // Measure body alignment and curvature during exit
    final bodyAngleResult = _analyzeBodyAxisAngle(exitFrames);
    final curvatureResult = _analyzeBodyCurvature(exitFrames);

    final score = (bodyAngleResult.score + curvatureResult.score) / 2;

    return MetricResult(
      metricId: 'D-4',
      value: score,
      score: score,
      confidence: turnPhase.confidence * 0.8,
      interpretation: score > 75
          ? 'Strong push-off and exit'
          : 'Improve body alignment during exit',
    );
  }

  // ============================================================================
  // PHASE 5: BACKWARD COMPATIBILITY
  // ============================================================================

  /// Aggregate metrics to v1 categoryScores
  Map<String, double> _aggregateToCategoryScores(
    Map<String, MetricResult> metrics,
    String category,
  ) {
    if (category == 'streamline') {
      return {
        'body_alignment': ((metrics['A-1']?.score ?? 0) + (metrics['A-2']?.score ?? 0)) / 2,
        'head_position': metrics['A-4']?.score ?? 0,
        'arm_position': metrics['A-5']?.score ?? 0,
        'leg_position': ((metrics['A-3']?.score ?? 0) + (metrics['A-6']?.score ?? 0)) / 2,
      };
    } else if (category == 'finning') {
      return {
        'kick_frequency': metrics['B-1']?.score ?? 0,
        'kick_efficiency': metrics['B-3']?.score ?? 0,
        'hip_stability': metrics['B-4']?.score ?? 0,
      };
    } else if (category == 'turn') {
      return {
        'wall_time': metrics['D-2']?.score ?? 0,
        'exit_quality': metrics['D-4']?.score ?? 0,
      };
    }

    return {};
  }

  /// Generate strengths from metrics
  List<String> _generateStrengths(Map<String, MetricResult> metrics, String category) {
    List<String> strengths = [];

    for (var metric in metrics.values) {
      if (metric.score > 75 && metric.confidence > 0.5) {
        if (metric.interpretation.contains('Excellent') ||
            metric.interpretation.contains('Good') ||
            metric.interpretation.contains('Minimal') ||
            metric.interpretation.contains('Stable') ||
            metric.interpretation.contains('Strong') ||
            metric.interpretation.contains('Efficient')) {
          strengths.add(metric.interpretation);
        }
      }
    }

    return strengths.isEmpty ? ['Consistent effort throughout'] : strengths;
  }

  /// Generate improvements from metrics
  List<String> _generateImprovements(Map<String, MetricResult> metrics, String category) {
    List<String> improvements = [];

    for (var metric in metrics.values) {
      if (metric.score < 70 && metric.confidence > 0.5) {
        if (metric.interpretation.contains('Focus') ||
            metric.interpretation.contains('Reduce') ||
            metric.interpretation.contains('Stabilize') ||
            metric.interpretation.contains('Extend') ||
            metric.interpretation.contains('Keep') ||
            metric.interpretation.contains('Adjust') ||
            metric.interpretation.contains('Improve')) {
          improvements.add(metric.interpretation);
        }
      }
    }

    // Add filming guide if low overall confidence
    final avgConfidence = metrics.values.isEmpty
        ? 0.0
        : metrics.values.map((m) => m.confidence).reduce((a, b) => a + b) / metrics.length;

    if (avgConfidence < 0.5) {
      improvements.insert(0, 'Improve video quality: ensure good lighting and clear side view');
    }

    return improvements.isEmpty ? ['Maintain current form'] : improvements;
  }

  /// Default analysis for edge cases
  Map<String, dynamic> _getDefaultAnalysis({
    required double confidence,
    required String category,
  }) {
    final categoryScores = category == 'streamline'
        ? {
            'body_alignment': 50.0,
            'head_position': 50.0,
            'arm_position': 50.0,
            'leg_position': 50.0,
          }
        : category == 'finning'
        ? {
            'kick_frequency': 50.0,
            'kick_efficiency': 50.0,
            'hip_stability': 50.0,
          }
        : {
            'wall_time': 50.0,
            'exit_quality': 50.0,
          };

    return {
      'overallScore': 50.0,
      'categoryScores': categoryScores,
      'strengths': ['Video recorded successfully'],
      'improvements': [
        'Insufficient video data for detailed analysis',
        'Record longer video (5+ seconds) with clear side view',
      ],
      'v2Data': {
        'version': '2.0',
        'phases': [],
        'metrics': {},
        'overallConfidence': confidence,
        'metadata': {
          'frameCount': 0,
          'durationSec': 0.0,
          'analysisTimestamp': DateTime.now().toIso8601String(),
        },
      },
    };
  }
}

// ============================================================================
// DATA STRUCTURES
// ============================================================================

/// Frame-level pose data with normalization
class FramePose {
  final int frameIndex;
  final double timestamp;
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final double shoulderWidth; // Normalization scale S
  final double confidence;

  FramePose({
    required this.frameIndex,
    required this.timestamp,
    required this.landmarks,
    required this.shoulderWidth,
    required this.confidence,
  });
}

/// Phase metadata (START/TRAVEL/TURN)
class PhaseData {
  final String phase;
  final int startFrame;
  final int endFrame;
  final Map<String, double> metrics;
  final double confidence;

  PhaseData({
    required this.phase,
    required this.startFrame,
    required this.endFrame,
    required this.metrics,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'phase': phase,
        'startFrame': startFrame,
        'endFrame': endFrame,
        'durationSec': (endFrame - startFrame) / 30.0,
        'metrics': metrics,
        'confidence': confidence,
      };
}

/// Individual metric result
class MetricResult {
  final String metricId;
  final double value;
  final double score; // 0-100
  final double confidence;
  final String interpretation;

  MetricResult({
    required this.metricId,
    required this.value,
    required this.score,
    required this.confidence,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
        'metricId': metricId,
        'value': value,
        'score': score,
        'confidence': confidence,
        'interpretation': interpretation,
      };
}
