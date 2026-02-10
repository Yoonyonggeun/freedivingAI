import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Shared mock pose generators for DNF regression testing.
///
/// Generates synthetic Pose sequences parameterized by scenario type,
/// duration, camera angle, noise level, turn count, etc.
class TestPoseGenerators {
  static final _rng = Random(42);

  /// Generate a pose sequence for a named scenario.
  static List<Pose> generateScenario({
    required String scenario,
    int durationFrames = 75,
    double cameraAngleDeg = 0.0,
    double noiseLevel = 0.0,
    int turnCount = 0,
    bool includeStart = true,
    bool includeGlide = false,
    double sparseLandmarkRate = 1.0,
  }) {
    switch (scenario) {
      case 'normal_25m':
        return _generateNormal25m(durationFrames, cameraAngleDeg, noiseLevel, includeStart, includeGlide);
      case 'normal_25m_turn':
        return _generateNormalWithTurns(durationFrames, cameraAngleDeg, noiseLevel, includeStart, 1);
      case '50m_two_turns':
        return _generateNormalWithTurns(durationFrames, cameraAngleDeg, noiseLevel, includeStart, 2);
      case 'mid_start':
        return _generateNormal25m(durationFrames, cameraAngleDeg, noiseLevel, false, includeGlide);
      case 'short_clip':
        return _generateNormal25m(durationFrames, cameraAngleDeg, noiseLevel, false, false);
      case 'very_short':
        return _generateNormal25m(durationFrames, cameraAngleDeg, noiseLevel, false, false);
      case 'oblique_45':
        return _generateNormal25m(durationFrames, 45.0, noiseLevel, includeStart, includeGlide);
      case 'oblique_90':
        return _generateNormal25m(durationFrames, 90.0, noiseLevel, includeStart, includeGlide);
      case 'high_noise':
        return _generateNormal25m(durationFrames, cameraAngleDeg, 30.0, includeStart, includeGlide);
      case 'sparse_landmarks':
        return _generateNormal25m(durationFrames, cameraAngleDeg, noiseLevel, includeStart, includeGlide, sparseLandmarkRate: 0.7);
      case 'no_glide':
        return _generateContinuousKick(durationFrames, cameraAngleDeg);
      case 'all_glide':
        return _generateMostlyGliding(durationFrames, cameraAngleDeg);
      case 'long_video':
        return _generateNormalWithTurns(durationFrames, cameraAngleDeg, noiseLevel, includeStart, 3);
      default:
        return _generateNormal25m(durationFrames, cameraAngleDeg, noiseLevel, includeStart, includeGlide);
    }
  }

  /// Normal 25m DNF: start → steady swimming → optional glide phases
  static List<Pose> _generateNormal25m(
    int frames,
    double angleDeg,
    double noise,
    bool includeStart,
    bool includeGlide, {
    double sparseLandmarkRate = 1.0,
  }) {
    final poses = <Pose>[];
    final startFrames = includeStart ? (frames * 0.15).round() : 0;

    for (int i = 0; i < frames; i++) {
      final phase = i < startFrames ? 'start' : 'travel';
      final baseX = 200.0 + (phase == 'travel' ? i * 2.0 : 0); // Travel = moving
      final kickPhase = sin(i * 0.8) * 40; // Breaststroke kick rhythm
      final armPhase = sin(i * 0.4) * 20; // Arm stroke

      final landmarks = _buildSwimmerLandmarks(
        baseX: baseX,
        baseY: 300.0,
        shoulderWidth: 200.0,
        kickAmplitude: phase == 'start' ? 0.0 : kickPhase,
        armAmplitude: phase == 'start' ? 0.0 : armPhase,
        noise: noise,
        sparseLandmarkRate: sparseLandmarkRate,
      );

      poses.add(_applyRotation(Pose(landmarks: landmarks), angleDeg));
    }

    return poses;
  }

  /// Generate swimming with specified number of turns.
  static List<Pose> _generateNormalWithTurns(
    int frames,
    double angleDeg,
    double noise,
    bool includeStart,
    int turnCount,
  ) {
    final poses = <Pose>[];
    final startFrames = includeStart ? (frames * 0.08).round() : 0;
    final framesPerLeg = turnCount > 0
        ? ((frames - startFrames) / (turnCount + 1)).round()
        : frames - startFrames;
    final turnDuration = 5; // frames per turn

    int frameIdx = 0;

    // Start phase
    for (int i = 0; i < startFrames; i++) {
      final landmarks = _buildSwimmerLandmarks(
        baseX: 200.0,
        baseY: 300.0,
        shoulderWidth: 200.0,
        kickAmplitude: 0.0,
        armAmplitude: 0.0,
        noise: noise,
      );
      poses.add(_applyRotation(Pose(landmarks: landmarks), angleDeg));
      frameIdx++;
    }

    // Travel + turn segments
    for (int leg = 0; leg <= turnCount; leg++) {
      final legFrames = leg == turnCount
          ? frames - frameIdx - (leg < turnCount ? turnDuration : 0)
          : framesPerLeg;

      // Travel
      for (int i = 0; i < legFrames && frameIdx < frames; i++) {
        final kickPhase = sin(frameIdx * 0.8) * 40;
        final armPhase = sin(frameIdx * 0.4) * 20;
        final landmarks = _buildSwimmerLandmarks(
          baseX: 200.0 + frameIdx * 2.0,
          baseY: 300.0,
          shoulderWidth: 200.0,
          kickAmplitude: kickPhase,
          armAmplitude: armPhase,
          noise: noise,
        );
        poses.add(_applyRotation(Pose(landmarks: landmarks), angleDeg));
        frameIdx++;
      }

      // Turn (velocity dip + curvature spike)
      if (leg < turnCount) {
        for (int i = 0; i < turnDuration && frameIdx < frames; i++) {
          final curvatureSpike = 30.0; // Bent body
          final landmarks = _buildSwimmerLandmarks(
            baseX: 200.0 + frameIdx * 0.5, // Slow down
            baseY: 300.0,
            shoulderWidth: 200.0,
            kickAmplitude: 5.0,
            armAmplitude: 5.0,
            noise: noise,
            curvatureOffset: curvatureSpike,
            rollOffset: 0.3,
          );
          poses.add(_applyRotation(Pose(landmarks: landmarks), angleDeg));
          frameIdx++;
        }
      }
    }

    return poses;
  }

  /// Continuous kick (no glide phases).
  static List<Pose> _generateContinuousKick(int frames, double angleDeg) {
    return List.generate(frames, (i) {
      final kickPhase = sin(i * 1.0) * 50; // Fast, continuous kick
      final armPhase = sin(i * 0.5) * 15;
      final landmarks = _buildSwimmerLandmarks(
        baseX: 200.0 + i * 2.5,
        baseY: 300.0,
        shoulderWidth: 200.0,
        kickAmplitude: kickPhase,
        armAmplitude: armPhase,
        noise: 0.0,
      );
      return _applyRotation(Pose(landmarks: landmarks), angleDeg);
    });
  }

  /// Mostly gliding (low energy throughout).
  static List<Pose> _generateMostlyGliding(int frames, double angleDeg) {
    return List.generate(frames, (i) {
      final landmarks = _buildSwimmerLandmarks(
        baseX: 200.0 + i * 0.3, // Very slow drift
        baseY: 300.0,
        shoulderWidth: 200.0,
        kickAmplitude: sin(i * 0.2) * 3, // Very low amplitude
        armAmplitude: sin(i * 0.1) * 2,
        noise: 0.0,
      );
      return _applyRotation(Pose(landmarks: landmarks), angleDeg);
    });
  }

  /// Build a full set of swimmer landmarks.
  static Map<PoseLandmarkType, PoseLandmark> _buildSwimmerLandmarks({
    required double baseX,
    required double baseY,
    required double shoulderWidth,
    required double kickAmplitude,
    required double armAmplitude,
    required double noise,
    double sparseLandmarkRate = 1.0,
    double curvatureOffset = 0.0,
    double rollOffset = 0.0,
  }) {
    final landmarks = <PoseLandmarkType, PoseLandmark>{};

    final halfShoulder = shoulderWidth / 2;
    final rollY = rollOffset * halfShoulder;

    // Helper to maybe include a landmark based on sparse rate
    void addLm(PoseLandmarkType type, double x, double y, double likelihood) {
      if (sparseLandmarkRate < 1.0 && _rng.nextDouble() > sparseLandmarkRate) {
        return; // Skip this landmark
      }
      final nx = x + (_rng.nextDouble() - 0.5) * noise;
      final ny = y + (_rng.nextDouble() - 0.5) * noise;
      landmarks[type] = PoseLandmark(
        type: type,
        x: nx,
        y: ny,
        z: 0.0,
        likelihood: likelihood.clamp(0.0, 1.0),
      );
    }

    // Core body landmarks
    addLm(PoseLandmarkType.leftShoulder, baseX - halfShoulder, baseY - rollY, 0.95);
    addLm(PoseLandmarkType.rightShoulder, baseX + halfShoulder, baseY + rollY, 0.95);
    addLm(PoseLandmarkType.leftHip, baseX - halfShoulder * 0.8, baseY + 120 + curvatureOffset, 0.92);
    addLm(PoseLandmarkType.rightHip, baseX + halfShoulder * 0.8, baseY + 120 + curvatureOffset, 0.92);
    addLm(PoseLandmarkType.leftKnee, baseX - halfShoulder * 0.6, baseY + 240, 0.90);
    addLm(PoseLandmarkType.rightKnee, baseX + halfShoulder * 0.6, baseY + 240, 0.90);

    // Ankles with kick amplitude
    addLm(PoseLandmarkType.leftAnkle, baseX - halfShoulder * 0.5, baseY + 350 + kickAmplitude, 0.88);
    addLm(PoseLandmarkType.rightAnkle, baseX + halfShoulder * 0.5, baseY + 350 + kickAmplitude, 0.88);

    // Arms with arm amplitude
    addLm(PoseLandmarkType.leftWrist, baseX - halfShoulder * 1.2, baseY - 10 + armAmplitude, 0.85);
    addLm(PoseLandmarkType.rightWrist, baseX + halfShoulder * 1.2, baseY - 10 + armAmplitude, 0.85);
    addLm(PoseLandmarkType.leftElbow, baseX - halfShoulder * 1.1, baseY + 50, 0.87);
    addLm(PoseLandmarkType.rightElbow, baseX + halfShoulder * 1.1, baseY + 50, 0.87);

    // Head
    addLm(PoseLandmarkType.nose, baseX, baseY - 60, 0.93);

    // Heels (for ankle flexion)
    addLm(PoseLandmarkType.leftHeel, baseX - halfShoulder * 0.5, baseY + 360 + kickAmplitude, 0.80);
    addLm(PoseLandmarkType.rightHeel, baseX + halfShoulder * 0.5, baseY + 360 + kickAmplitude, 0.80);

    return landmarks;
  }

  /// Apply 2D rotation matrix to all landmarks in a pose.
  static Pose _applyRotation(Pose pose, double angleDeg) {
    if (angleDeg == 0.0) return pose;

    final rad = angleDeg * pi / 180;
    final cosA = cos(rad);
    final sinA = sin(rad);

    // Rotate around the center of the pose
    double cx = 0, cy = 0;
    int count = 0;
    for (final lm in pose.landmarks.values) {
      cx += lm.x;
      cy += lm.y;
      count++;
    }
    if (count == 0) return pose;
    cx /= count;
    cy /= count;

    final rotated = <PoseLandmarkType, PoseLandmark>{};
    for (final entry in pose.landmarks.entries) {
      final lm = entry.value;
      final dx = lm.x - cx;
      final dy = lm.y - cy;
      final rx = cx + dx * cosA - dy * sinA;
      final ry = cy + dx * sinA + dy * cosA;
      rotated[entry.key] = PoseLandmark(
        type: lm.type,
        x: rx,
        y: ry,
        z: lm.z,
        likelihood: lm.likelihood,
      );
    }

    return Pose(landmarks: rotated);
  }
}
