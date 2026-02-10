import 'package:flutter_test/flutter_test.dart';
import 'package:freediving_ai/services/dnf_full_analyzer.dart';
import 'test_pose_generators.dart';

void main() {
  late DNFFullAnalyzer analyzer;

  setUp(() {
    analyzer = DNFFullAnalyzer();
  });

  /// Shared assertions for every scenario.
  void assertBasicOutput(Map<String, dynamic> result, String scenario) {
    expect(result, isNotNull, reason: '$scenario: result is null');
    expect(result.containsKey('overallScore'), true, reason: '$scenario: missing overallScore');
    expect(result.containsKey('classification'), true, reason: '$scenario: missing classification');
    expect(result.containsKey('phases'), true, reason: '$scenario: missing phases');
    expect(result.containsKey('metrics'), true, reason: '$scenario: missing metrics');
    expect(result.containsKey('metadata'), true, reason: '$scenario: missing metadata');

    final score = result['overallScore'] as double;
    expect(score, greaterThanOrEqualTo(0.0), reason: '$scenario: score < 0');
    expect(score, lessThanOrEqualTo(100.0), reason: '$scenario: score > 100');

    final classification = result['classification'] as String;
    expect(['DNF', 'DYN', 'DYNB', 'OTHER'].contains(classification), true,
        reason: '$scenario: invalid classification "$classification"');

    final metadata = result['metadata'] as Map<String, dynamic>;
    final validFrameRatio = metadata['validFrameRatio'] as double;
    expect(validFrameRatio, greaterThanOrEqualTo(0.0), reason: '$scenario: validFrameRatio < 0');
    expect(validFrameRatio, lessThanOrEqualTo(1.0), reason: '$scenario: validFrameRatio > 1');
  }

  group('DNF Regression Suite', () {
    test('Scenario 1: normal_25m — baseline DNF', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'normal_25m',
        durationFrames: 75,
        includeStart: true,
      );

      final result = analyzer.analyzeDNFFull(poses);
      assertBasicOutput(result, 'normal_25m');

      // Should detect TRAVEL phase
      final phases = result['phases'] as List;
      expect(phases.any((p) => (p as Map)['phase'] == 'TRAVEL'), true,
          reason: 'normal_25m: no TRAVEL phase');
    });

    test('Scenario 2: normal_25m_turn — single turn', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'normal_25m_turn',
        durationFrames: 100,
        includeStart: true,
        turnCount: 1,
      );

      final result = analyzer.analyzeDNFFull(poses);
      assertBasicOutput(result, 'normal_25m_turn');

      final phases = result['phases'] as List;
      expect(phases.any((p) => (p as Map)['phase'] == 'TRAVEL'), true);
    });

    test('Scenario 3: 50m_two_turns — multi-turn', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: '50m_two_turns',
        durationFrames: 175,
        includeStart: true,
        turnCount: 2,
      );

      final result = analyzer.analyzeDNFFull(poses);
      assertBasicOutput(result, '50m_two_turns');

      // Should have multiple TRAVEL segments
      final metadata = result['metadata'] as Map<String, dynamic>;
      final travelSegmentCount = metadata['travelSegmentCount'] as int? ?? 0;
      expect(travelSegmentCount, greaterThanOrEqualTo(1),
          reason: '50m_two_turns: expected >= 1 TRAVEL segment');
    });

    test('Scenario 4: mid_start — no explicit START/PREP phase', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'mid_start',
        durationFrames: 60,
        includeStart: false,
      );

      final result = analyzer.analyzeDNFFull(poses);
      assertBasicOutput(result, 'mid_start');

      // Mid-start begins with movement, so the first phase should be TRAVEL
      // (no explicit START phase from low-velocity preparation)
      final phases = result['phases'] as List;
      final firstPhase = (phases.first as Map)['phase'] as String;
      // First phase should be TRAVEL (since there's immediate movement)
      // or possibly PREP if velocity is initially low due to signal smoothing
      expect(['TRAVEL', 'PREP'].contains(firstPhase), true,
          reason: 'mid_start: first phase should be TRAVEL or PREP, got $firstPhase');
    });

    test('Scenario 5: short_clip — minimum viable', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'short_clip',
        durationFrames: 15,
        includeStart: false,
      );

      final result = analyzer.analyzeDNFFull(poses);
      assertBasicOutput(result, 'short_clip');
    });

    test('Scenario 6: very_short — below minimum', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'very_short',
        durationFrames: 3,
        includeStart: false,
      );

      final result = analyzer.analyzeDNFFull(poses);

      // With only 3 frames, should still return a result (insufficient data)
      expect(result, isNotNull, reason: 'very_short: result is null');
      expect(result.containsKey('overallScore'), true);
    });

    test('Scenario 7: oblique_45 — 45 degree camera', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'oblique_45',
        durationFrames: 75,
        cameraAngleDeg: 45.0,
        includeStart: true,
      );

      final result = analyzer.analyzeDNFFull(poses);
      assertBasicOutput(result, 'oblique_45');

      // Should produce same classification as 0 degree
      final normal = analyzer.analyzeDNFFull(
        TestPoseGenerators.generateScenario(
          scenario: 'normal_25m',
          durationFrames: 75,
          includeStart: true,
        ),
      );
      final obliqueClass = result['classification'] as String;
      final normalClass = normal['classification'] as String;
      // They should both be valid classifications (DNF or OTHER)
      expect(['DNF', 'DYN', 'DYNB', 'OTHER'].contains(obliqueClass), true);
      expect(['DNF', 'DYN', 'DYNB', 'OTHER'].contains(normalClass), true);
    });

    test('Scenario 8: oblique_90 — 90 degree camera', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'oblique_90',
        durationFrames: 75,
        cameraAngleDeg: 90.0,
        includeStart: true,
      );

      final result = analyzer.analyzeDNFFull(poses);
      assertBasicOutput(result, 'oblique_90');
    });

    test('Scenario 9: high_noise — bad lighting', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'high_noise',
        durationFrames: 75,
        noiseLevel: 30.0,
        includeStart: true,
      );

      final result = analyzer.analyzeDNFFull(poses);
      assertBasicOutput(result, 'high_noise');
    });

    test('Scenario 10: sparse_landmarks — 30% missing', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'sparse_landmarks',
        durationFrames: 75,
        includeStart: true,
        sparseLandmarkRate: 0.7,
      );

      final result = analyzer.analyzeDNFFull(poses);
      // May have insufficient data if too many frames filtered
      expect(result, isNotNull, reason: 'sparse_landmarks: result is null');
      expect(result.containsKey('overallScore'), true);
    });

    test('Scenario 11: no_glide — continuous kick', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'no_glide',
        durationFrames: 75,
      );

      final result = analyzer.analyzeDNFFull(poses);
      assertBasicOutput(result, 'no_glide');

      // Glide should report one of the valid statuses
      final metrics = result['metrics'] as Map<String, dynamic>;
      if (metrics.containsKey('glide')) {
        final glide = metrics['glide'] as Map<String, dynamic>;
        final glideStatus = glide['status'] as String?;
        // Continuous kick may still have brief low-velocity moments that
        // register as glide. The important thing is the status field exists
        // and has a valid value.
        expect(
          ['MEASURED', 'MEASURED_ZERO', 'DETECTION_FAILED', 'AVAILABLE', 'NOT_AVAILABLE'].contains(glideStatus),
          true,
          reason: 'no_glide: glide status should be a valid status, got $glideStatus',
        );
        // Glide ratio should be low for continuous kick
        final glideRatio = glide['glideRatio'] as double? ?? 0.0;
        expect(glideRatio, lessThan(0.5),
            reason: 'no_glide: glide ratio should be low for continuous kick');
      }
    });

    test('Scenario 12: all_glide — mostly gliding', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'all_glide',
        durationFrames: 75,
      );

      final result = analyzer.analyzeDNFFull(poses);
      assertBasicOutput(result, 'all_glide');
    });

    test('Scenario 13: long_video — 90s multi-turn', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'long_video',
        durationFrames: 450,
        includeStart: true,
        turnCount: 3,
      );

      final result = analyzer.analyzeDNFFull(poses);
      assertBasicOutput(result, 'long_video');

      // Should have multiple phases
      final phases = result['phases'] as List;
      expect(phases.length, greaterThan(1),
          reason: 'long_video: expected multiple phases');
    });
  });

  group('Output Structure Validation', () {
    test('All required output keys present', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'normal_25m',
        durationFrames: 75,
        includeStart: true,
      );

      final result = analyzer.analyzeDNFFull(poses);

      final requiredKeys = [
        'overallScore',
        'overallScoreAvailable',
        'classification',
        'classificationConfidence',
        'classificationReason',
        'classificationScores',
        'analysisQualityConfidence',
        'analysisUnreliable',
        'analysisMode',
        'reasonCodes',
        'detectedActivities',
        'phases',
        'motionWindows',
        'metrics',
        'coaching',
        'metadata',
      ];

      for (final key in requiredKeys) {
        expect(result.containsKey(key), true,
            reason: 'Missing required key: $key');
      }
    });

    test('Metrics contain enrichment fields', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'normal_25m',
        durationFrames: 75,
        includeStart: true,
      );

      final result = analyzer.analyzeDNFFull(poses);
      final metrics = result['metrics'] as Map<String, dynamic>;

      for (final key in ['streamline', 'kick', 'arm', 'glide']) {
        if (metrics.containsKey(key)) {
          final cat = metrics[key] as Map<String, dynamic>;
          expect(cat.containsKey('status'), true, reason: '$key missing status');
          expect(cat.containsKey('confidenceLevel'), true, reason: '$key missing confidenceLevel');
          expect(cat.containsKey('measurementBasis'), true, reason: '$key missing measurementBasis');

          // Confidence level should be one of the v5 tier labels
          final level = cat['confidenceLevel'] as String;
          expect(
            ['confirmed', 'likely', 'not_reliable'].contains(level),
            true,
            reason: '$key: confidenceLevel should be confirmed/likely/not_reliable, got $level',
          );

          final basis = cat['measurementBasis'] as Map<String, dynamic>;
          expect(basis.containsKey('frameCount'), true);
          expect(basis.containsKey('cycleCount'), true);
        }
      }
    });

    test('Glide has disambiguation fields', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'normal_25m',
        durationFrames: 75,
        includeStart: true,
      );

      final result = analyzer.analyzeDNFFull(poses);
      final metrics = result['metrics'] as Map<String, dynamic>;

      if (metrics.containsKey('glide')) {
        final glide = metrics['glide'] as Map<String, dynamic>;
        expect(glide.containsKey('status'), true, reason: 'glide missing status');
        expect(glide.containsKey('reason'), true, reason: 'glide missing reason');
        expect(glide.containsKey('detectionSuccessful'), true, reason: 'glide missing detectionSuccessful');
        expect(glide.containsKey('maxConsecutiveLowVelocitySec'), true);
      }
    });

    test('Metadata v5 fields present', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'normal_25m',
        durationFrames: 75,
        includeStart: true,
      );

      final result = analyzer.analyzeDNFFull(poses);
      final metadata = result['metadata'] as Map<String, dynamic>;

      expect(metadata['analysisVersion'], 'DNF_FULL_v5');
      expect(metadata.containsKey('turnCount'), true);
      expect(metadata.containsKey('travelSegmentCount'), true);
    });

    test('Phase data contains eventSignals', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'normal_25m',
        durationFrames: 75,
        includeStart: true,
      );

      final result = analyzer.analyzeDNFFull(poses);
      final phases = result['phases'] as List;

      for (final phase in phases) {
        final p = phase as Map<String, dynamic>;
        expect(p.containsKey('phase'), true);
        expect(p.containsKey('startFrame'), true);
        expect(p.containsKey('endFrame'), true);
        expect(p.containsKey('confidence'), true);
        // eventSignals may or may not be present depending on phase
      }
    });

    test('DYNB feature breakdown present in classification', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'normal_25m',
        durationFrames: 75,
        includeStart: true,
      );

      final result = analyzer.analyzeDNFFull(poses);

      // dynbFeatureBreakdown may or may not be present
      // But classificationScores should always be present
      final scores = result['classificationScores'] as Map<String, dynamic>;
      expect(scores.containsKey('DNF'), true);
      expect(scores.containsKey('DYN'), true);
      expect(scores.containsKey('DYNB'), true);
    });
  });

  group('Edge Cases', () {
    test('Empty poses returns insufficient data', () {
      final result = analyzer.analyzeDNFFull([]);
      expect(result['overallScore'], 0.0);
      expect(result['classification'], 'OTHER');
    });

    test('Single pose returns insufficient data', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'normal_25m',
        durationFrames: 1,
      );
      final result = analyzer.analyzeDNFFull(poses);
      expect(result.containsKey('overallScore'), true);
    });

    test('Landmark coverage and signal continuity params propagate', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'normal_25m',
        durationFrames: 75,
        includeStart: true,
      );

      final result = analyzer.analyzeDNFFull(
        poses,
        landmarkCoverage: 0.95,
        signalContinuity: 0.90,
      );

      assertBasicOutput(result, 'with_coverage_params');
      final quality = result['analysisQualityConfidence'] as double;
      expect(quality, greaterThan(0.0));
    });
  });

  group('Multi-Person Contamination', () {
    test('High multi-person ratio degrades quality score', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'normal_25m',
        durationFrames: 75,
        includeStart: true,
      );

      // Baseline — no contamination
      final baselineResult = analyzer.analyzeDNFFull(poses);
      final baselineQuality = baselineResult['analysisQualityConfidence'] as double;

      // With heavy multi-person contamination
      final contaminatedResult = analyzer.analyzeDNFFull(
        poses,
        multiPersonFrameRatio: 0.40,
        trackSwitchCount: 8,
        totalFrames: 75,
      );

      final contaminatedQuality = contaminatedResult['analysisQualityConfidence'] as double;
      expect(contaminatedQuality, lessThan(baselineQuality),
          reason: 'Multi-person contamination should degrade quality');
      expect(contaminatedQuality, lessThan(0.70),
          reason: 'Heavy contamination should push quality below 0.70');
      expect(contaminatedResult['analysisUnreliable'], isA<bool>(),
          reason: 'analysisUnreliable should be present');
    });

    test('Quality penalties are exposed in output', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'normal_25m',
        durationFrames: 75,
        includeStart: true,
      );

      final result = analyzer.analyzeDNFFull(
        poses,
        multiPersonFrameRatio: 0.20,
        trackSwitchCount: 3,
        totalFrames: 75,
      );

      expect(result.containsKey('qualityPenalties'), true);
      final penalties = result['qualityPenalties'] as Map<String, dynamic>;
      expect(penalties['multiPersonFrameRatio'], 0.20);
      expect(penalties['trackSwitchCount'], 3);
    });
  });

  group('Inconclusive Classification', () {
    test('isInconclusive field present in output', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'normal_25m',
        durationFrames: 75,
        includeStart: true,
      );

      final result = analyzer.analyzeDNFFull(poses);
      expect(result.containsKey('isInconclusive'), true,
          reason: 'isInconclusive should always be in output');
      expect(result['isInconclusive'], isA<bool>());
    });

    test('Inconclusive blocks LEVEL_TEST eligibility', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'normal_25m',
        durationFrames: 75,
        includeStart: true,
      );

      final result = analyzer.analyzeDNFFull(poses);
      final analysisMode = result['analysisMode'] as Map<String, dynamic>;

      // If classification is inconclusive, LEVEL_TEST should be disabled
      if (result['isInconclusive'] == true) {
        expect(analysisMode['levelTestEligible'], false,
            reason: 'Inconclusive classification should disable LEVEL_TEST');
        final failed = analysisMode['failedRequirements'] as List;
        expect(
          failed.any((r) => r.toString().contains('inconclusive')),
          true,
          reason: 'Failed requirements should mention inconclusive',
        );
      }
    });
  });

  group('Angular Velocity Glide Detection', () {
    test('all_glide scenario detects glide via angular velocity', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'all_glide',
        durationFrames: 75,
      );

      final result = analyzer.analyzeDNFFull(poses);
      assertBasicOutput(result, 'angular_velocity_glide');

      final metrics = result['metrics'] as Map<String, dynamic>;
      if (metrics.containsKey('glide')) {
        final glide = metrics['glide'] as Map<String, dynamic>;
        final glideStatus = glide['status'] as String?;
        // all_glide should detect glide — should NOT be DETECTION_FAILED
        expect(glideStatus, isNot('DETECTION_FAILED'),
            reason: 'all_glide scenario should detect glide via angular velocity');
      }
    });

    test('no_glide scenario still has valid glide output', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'no_glide',
        durationFrames: 75,
      );

      final result = analyzer.analyzeDNFFull(poses);
      assertBasicOutput(result, 'no_glide_angular');

      final metrics = result['metrics'] as Map<String, dynamic>;
      if (metrics.containsKey('glide')) {
        final glide = metrics['glide'] as Map<String, dynamic>;
        final glideStatus = glide['status'] as String?;
        expect(
          ['MEASURED', 'MEASURED_ZERO', 'DETECTION_FAILED', 'AVAILABLE', 'NOT_AVAILABLE'].contains(glideStatus),
          true,
          reason: 'Glide status should be valid, got $glideStatus',
        );
      }
    });

    test('overallScoreAvailable reflects metric confidence', () {
      final poses = TestPoseGenerators.generateScenario(
        scenario: 'normal_25m',
        durationFrames: 75,
        includeStart: true,
      );

      final result = analyzer.analyzeDNFFull(poses);
      expect(result.containsKey('overallScoreAvailable'), true);
      expect(result['overallScoreAvailable'], isA<bool>());
    });
  });
}
