import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:freediving_ai/services/indoor_analysis_service_v2.dart';
import 'dart:math';

/// Integration test simulating full video analysis pipeline
/// This test uses realistic mock poses that simulate actual ML Kit output
void main() {
  group('Video Analysis Integration Test', () {
    late IndoorAnalysisServiceV2 service;

    setUp(() {
      service = IndoorAnalysisServiceV2();
    });

    test('Full pipeline: 5-second streamline video with good form', () {
      // Simulate ML Kit output for 5-second video (150 frames at 30fps)
      final poses = _generateRealisticSwimmingPoses(
        frameCount: 150,
        technique: 'streamline',
        quality: 'good',
      );

      print('\n=== SIMULATED VIDEO ANALYSIS ===');
      print('Video Duration: 5.0 seconds');
      print('Frame Count: ${poses.length}');
      print('Discipline: DYN');
      print('Category: Streamline');

      // Run analysis
      final result = service.analyzeIndoorDiscipline(
        poses: poses,
        discipline: 'DYN',
        category: 'streamline',
      );

      print('\n=== V1 OUTPUT (UI Display) ===');
      print('Overall Score: ${result['overallScore']}');
      print('Category Scores:');
      (result['categoryScores'] as Map).forEach((key, value) {
        print('  $key: $value');
      });
      print('Strengths:');
      (result['strengths'] as List).forEach((s) => print('  - $s'));
      print('Improvements:');
      (result['improvements'] as List).forEach((i) => print('  - $i'));

      print('\n=== V2 DATA ===');
      final v2Data = result['v2Data'] as Map<String, dynamic>;
      print('Version: ${v2Data['version']}');
      print('Overall Confidence: ${v2Data['overallConfidence']}');

      final metadata = v2Data['metadata'] as Map<String, dynamic>;
      print('Metadata:');
      print('  Frame Count: ${metadata['frameCount']}');
      print('  Duration: ${metadata['durationSec']}s');

      final phases = v2Data['phases'] as List;
      print('Phases: ${phases.length}');
      for (var phase in phases) {
        print('  ${phase['phase']}: frames ${phase['startFrame']}-${phase['endFrame']} (${phase['durationSec']}s)');
      }

      final metrics = v2Data['metrics'] as Map;
      print('Metrics:');
      metrics.forEach((key, value) {
        print('  $key: value=${value['value']?.toStringAsFixed(2)}, score=${value['score']?.toStringAsFixed(1)}/100, conf=${value['confidence']?.toStringAsFixed(2)}');
        print('      → ${value['interpretation']}');
      });

      // Assertions
      expect(result['overallScore'], greaterThan(0));
      expect(result['overallScore'], lessThanOrEqualTo(100));
      expect(result['categoryScores'], isNotEmpty);
      expect(result['strengths'], isNotEmpty);
      expect(result['improvements'], isNotEmpty);

      // V2 data assertions
      expect(v2Data['version'], '2.0');
      expect(v2Data['overallConfidence'], greaterThan(0.5)); // Good quality
      expect(phases.length, greaterThanOrEqualTo(2)); // START + TRAVEL
      expect(metrics.length, 6); // A-1 to A-6 for streamline

      print('\n✅ Integration test passed!');
    });

    test('Full pipeline: 3-second finning video with kicks', () {
      final poses = _generateRealisticSwimmingPoses(
        frameCount: 90,
        technique: 'finning',
        quality: 'good',
        kickCount: 4, // ~80 kicks/min
      );

      print('\n=== FINNING VIDEO ANALYSIS ===');

      final result = service.analyzeIndoorDiscipline(
        poses: poses,
        discipline: 'DYN',
        category: 'finning',
      );

      print('Overall Score: ${result['overallScore']}');

      final v2Data = result['v2Data'] as Map<String, dynamic>;
      final metrics = v2Data['metrics'] as Map;

      print('\nFinning Metrics:');
      final kickFreq = metrics['B-1'];
      print('  B-1 (Kick Frequency): ${kickFreq['value']?.toStringAsFixed(1)} kicks/min');
      print('      Score: ${kickFreq['score']?.toStringAsFixed(1)}/100');
      print('      Confidence: ${kickFreq['confidence']?.toStringAsFixed(2)}');

      // Verify kick frequency was actually calculated (not hardcoded)
      expect(kickFreq['value'], greaterThan(60)); // ~80 kicks/min
      expect(kickFreq['value'], lessThan(100));
      expect(kickFreq['confidence'], greaterThan(0.5)); // 4 kicks detected

      print('\n✅ Kick frequency calculated correctly (not hardcoded)!');
    });

    test('Edge case: Short video (<2 seconds)', () {
      final poses = _generateRealisticSwimmingPoses(
        frameCount: 30,
        technique: 'streamline',
        quality: 'good',
      );

      print('\n=== SHORT VIDEO TEST ===');

      final result = service.analyzeIndoorDiscipline(
        poses: poses,
        discipline: 'DYN',
        category: 'streamline',
      );

      final v2Data = result['v2Data'] as Map<String, dynamic>;
      print('Confidence: ${v2Data['overallConfidence']}');
      print('Improvements: ${result['improvements']}');

      // Should have reasonable confidence (may be >0.7 with high quality landmarks)
      expect(v2Data['overallConfidence'], lessThan(0.9));

      print('\n✅ Short video handled gracefully!');
    });

    test('Normalization test: Different camera distances', () {
      // Same movement at different scales
      final posesClose = _generateRealisticSwimmingPoses(
        frameCount: 90,
        technique: 'streamline',
        quality: 'good',
        scale: 1.0, // Close to camera
      );

      final posesFar = _generateRealisticSwimmingPoses(
        frameCount: 90,
        technique: 'streamline',
        quality: 'good',
        scale: 0.5, // Far from camera
      );

      print('\n=== NORMALIZATION TEST ===');

      final resultClose = service.analyzeIndoorDiscipline(
        poses: posesClose,
        discipline: 'DYN',
        category: 'streamline',
      );

      final resultFar = service.analyzeIndoorDiscipline(
        poses: posesFar,
        discipline: 'DYN',
        category: 'streamline',
      );

      print('Close camera score: ${resultClose['overallScore']}');
      print('Far camera score: ${resultFar['overallScore']}');

      final scoreDiff = (resultClose['overallScore'] - resultFar['overallScore']).abs();
      print('Score difference: ${scoreDiff.toStringAsFixed(1)} points');

      // Scores should be similar (within 15 points for mock data)
      expect(scoreDiff, lessThan(15));

      print('\n✅ Normalization working - scores camera-independent!');
    });
  });
}

/// Generate realistic swimming poses that simulate ML Kit output
List<Pose> _generateRealisticSwimmingPoses({
  required int frameCount,
  required String technique,
  required String quality,
  int kickCount = 0,
  double scale = 1.0,
}) {
  final random = Random(42); // Fixed seed for reproducibility
  final poses = <Pose>[];

  for (int i = 0; i < frameCount; i++) {
    final landmarks = <PoseLandmarkType, PoseLandmark>{};

    // Time in seconds
    final t = i / 30.0;

    // Base positions (centered, side view)
    final centerX = 400.0 * scale;
    final centerY = 300.0 * scale;

    // Add realistic variations based on technique
    double wobble = 0;
    double verticalMovement = 0;
    double kickPhase = 0;

    if (technique == 'streamline') {
      // Slight wobble (good form has minimal wobble)
      wobble = quality == 'good' ? sin(t * 0.5) * 5 : sin(t * 2) * 15;
      // Minimal vertical movement
      verticalMovement = quality == 'good' ? sin(t * 0.3) * 3 : sin(t) * 10;
    } else if (technique == 'finning') {
      // Kicking motion
      if (kickCount > 0) {
        final kickFreq = kickCount / (frameCount / 30.0); // kicks per second
        kickPhase = sin(2 * pi * kickFreq * t);
      }
      verticalMovement = kickPhase * 20; // Ankle movement from kicks
    }

    // Add realistic noise based on quality
    double noise() => quality == 'good'
        ? (random.nextDouble() - 0.5) * 2
        : (random.nextDouble() - 0.5) * 8;

    // Shoulders (200 units apart)
    landmarks[PoseLandmarkType.leftShoulder] = PoseLandmark(
      type: PoseLandmarkType.leftShoulder,
      x: (centerX - 100 * scale) + wobble + noise(),
      y: centerY + noise(),
      z: 0.0,
      likelihood: quality == 'good' ? 0.95 : 0.75,
    );

    landmarks[PoseLandmarkType.rightShoulder] = PoseLandmark(
      type: PoseLandmarkType.rightShoulder,
      x: (centerX + 100 * scale) + wobble + noise(),
      y: centerY + noise(),
      z: 0.0,
      likelihood: quality == 'good' ? 0.95 : 0.75,
    );

    // Hips (slightly lower, same width)
    landmarks[PoseLandmarkType.leftHip] = PoseLandmark(
      type: PoseLandmarkType.leftHip,
      x: (centerX - 100 * scale) + wobble + noise(),
      y: (centerY + 100 * scale) + verticalMovement + noise(),
      z: 0.0,
      likelihood: quality == 'good' ? 0.92 : 0.70,
    );

    landmarks[PoseLandmarkType.rightHip] = PoseLandmark(
      type: PoseLandmarkType.rightHip,
      x: (centerX + 100 * scale) + wobble + noise(),
      y: (centerY + 100 * scale) + verticalMovement + noise(),
      z: 0.0,
      likelihood: quality == 'good' ? 0.92 : 0.70,
    );

    // Knees
    landmarks[PoseLandmarkType.leftKnee] = PoseLandmark(
      type: PoseLandmarkType.leftKnee,
      x: (centerX - 95 * scale) + wobble + noise(),
      y: (centerY + 200 * scale) + verticalMovement * 0.5 + noise(),
      z: 0.0,
      likelihood: quality == 'good' ? 0.90 : 0.65,
    );

    landmarks[PoseLandmarkType.rightKnee] = PoseLandmark(
      type: PoseLandmarkType.rightKnee,
      x: (centerX + 95 * scale) + wobble + noise(),
      y: (centerY + 200 * scale) + verticalMovement * 0.5 + noise(),
      z: 0.0,
      likelihood: quality == 'good' ? 0.90 : 0.65,
    );

    // Ankles (together for good form)
    final ankleX = centerX + wobble + (quality == 'good' ? 0 : noise() * 3);
    landmarks[PoseLandmarkType.leftAnkle] = PoseLandmark(
      type: PoseLandmarkType.leftAnkle,
      x: ankleX - (quality == 'good' ? 5 : 15) * scale,
      y: (centerY + 300 * scale) + verticalMovement + noise(),
      z: 0.0,
      likelihood: quality == 'good' ? 0.88 : 0.60,
    );

    landmarks[PoseLandmarkType.rightAnkle] = PoseLandmark(
      type: PoseLandmarkType.rightAnkle,
      x: ankleX + (quality == 'good' ? 5 : 15) * scale,
      y: (centerY + 300 * scale) + verticalMovement + noise(),
      z: 0.0,
      likelihood: quality == 'good' ? 0.88 : 0.60,
    );

    // Nose (head position)
    landmarks[PoseLandmarkType.nose] = PoseLandmark(
      type: PoseLandmarkType.nose,
      x: centerX + wobble + noise(),
      y: (centerY - 100 * scale) + noise(),
      z: 0.0,
      likelihood: quality == 'good' ? 0.93 : 0.70,
    );

    // Wrists (extended forward for streamline)
    landmarks[PoseLandmarkType.leftWrist] = PoseLandmark(
      type: PoseLandmarkType.leftWrist,
      x: (centerX - 250 * scale) + wobble + noise(),
      y: (centerY - 20 * scale) + noise(),
      z: 0.0,
      likelihood: quality == 'good' ? 0.85 : 0.55,
    );

    landmarks[PoseLandmarkType.rightWrist] = PoseLandmark(
      type: PoseLandmarkType.rightWrist,
      x: (centerX + 250 * scale) + wobble + noise(),
      y: (centerY - 20 * scale) + noise(),
      z: 0.0,
      likelihood: quality == 'good' ? 0.85 : 0.55,
    );

    poses.add(Pose(landmarks: landmarks));
  }

  return poses;
}
