import 'package:flutter_test/flutter_test.dart';
import 'package:freediving_ai/models/component_result.dart';
import 'package:freediving_ai/models/analysis_output.dart';
import 'package:freediving_ai/models/swimmer_track.dart';
import 'package:freediving_ai/services/analysis_output_builder.dart';
import 'package:freediving_ai/services/mode_gate.dart';

void main() {
  group('FeedbackMessageGenerator Integration', () {
    test('AnalysisOutputBuilder generates feedback messages with measurement basis', () {
      // Create component with timeRanges and subMetrics
      final streamlineComponent = ComponentResult(
        componentId: 'streamline',
        status: ComponentStatus.confirmed,
        confidenceLevel: ConfidenceLevel.high,
        rawConfidence: 0.85,
        score: 75.0,
        timeRanges: [TimeRange(startSec: 2.0, endSec: 5.2)],
        measurementBasis: 'video', // Placeholder triggers construction
        fixPath: 'Focus on alignment',
        subMetrics: {
          'bodyAlignment': 0.88,
          'armPosition': 0.86,
        },
      );

      final kickComponent = ComponentResult(
        componentId: 'kick',
        status: ComponentStatus.partial,
        confidenceLevel: ConfidenceLevel.medium,
        rawConfidence: 0.55,
        score: 65.0,
        timeRanges: [
          TimeRange(startSec: 1.0, endSec: 3.0),
          TimeRange(startSec: 5.0, endSec: 7.5),
        ],
        measurementBasis: 'video',
        fixPath: 'Improve symmetry',
      );

      final armComponent = ComponentResult(
        componentId: 'arm',
        status: ComponentStatus.notMeasurable,
        confidenceLevel: ConfidenceLevel.low,
        rawConfidence: 0.35,
        score: null,
        measurementBasis: 'Not visible in video',
        fixPath: null,
      );

      // Build analysis output
      final builder = AnalysisOutputBuilder();
      final output = builder.build(
        components: {
          'streamline': streamlineComponent,
          'kick': kickComponent,
          'arm': armComponent,
        },
        modeGateResult: ModeGateResult(
          mode: 'LEVEL_TEST',
          isLevelTest: true,
          message: 'All gates passed',
          failedGates: [],
        ),
        classification: {
          'classification': 'DNF',
          'confidence': 0.92,
        },
        tracking: TrackingDiagnostics(
          totalFrames: 300,
          trackedFrames: 285,
          trackConfidence: 0.88,
          coverageRatio: 0.95,
          idSwitchCount: 2,
          multiPersonFrameRatio: 0.05,
          avgMatchQuality: 0.88,
        ),
      );

      // Verify streamline component has feedback with measurement basis
      final processedStreamline = output.components['streamline']!;
      expect(processedStreamline.feedbackMessage, isNotNull);
      expect(processedStreamline.feedbackMessage, contains('streamline'));
      expect(processedStreamline.feedbackMessage, contains('75/100'));
      expect(processedStreamline.feedbackMessage, contains('Based on'));
      expect(processedStreamline.feedbackMessage, contains('3s'));
      expect(processedStreamline.feedbackMessage, contains('clear video'));
      expect(processedStreamline.feedbackMessage, contains('excellent body alignment'));
      expect(processedStreamline.feedbackMessage, contains('Focus on'));

      // Verify kick component has feedback with measurement basis
      final processedKick = output.components['kick']!;
      expect(processedKick.feedbackMessage, isNotNull);
      expect(processedKick.feedbackMessage, contains('kick technique'));
      expect(processedKick.feedbackMessage, contains('65/100'));
      expect(processedKick.feedbackMessage, contains('Based on'));
      expect(processedKick.feedbackMessage, contains('5s'));
      expect(processedKick.feedbackMessage, contains('(medium visibility)'));

      // Verify arm component (notMeasurable) has no feedback
      final processedArm = output.components['arm']!;
      expect(processedArm.feedbackMessage, isNull);
    });

    test('AnalysisOutputBuilder handles component without timeRanges', () {
      final component = ComponentResult(
        componentId: 'glide',
        status: ComponentStatus.confirmed,
        confidenceLevel: ConfidenceLevel.high,
        rawConfidence: 0.80,
        score: 70.0,
        timeRanges: [],
        measurementBasis: 'video',
        fixPath: 'Extend glide duration',
      );

      final builder = AnalysisOutputBuilder();
      final output = builder.build(
        components: {'glide': component},
        modeGateResult: ModeGateResult(
          mode: 'QUICK_FEEDBACK',
          isLevelTest: false,
          message: 'Practice mode',
          failedGates: [],
        ),
        classification: {
          'classification': 'DNF',
          'confidence': 0.85,
        },
        tracking: TrackingDiagnostics(
          totalFrames: 200,
          trackedFrames: 180,
          trackConfidence: 0.82,
          coverageRatio: 0.90,
          idSwitchCount: 1,
          multiPersonFrameRatio: 0.05,
          avgMatchQuality: 0.85,
        ),
      );

      final processedGlide = output.components['glide']!;
      expect(processedGlide.feedbackMessage, isNotNull);
      expect(processedGlide.feedbackMessage, contains('glide efficiency'));
      expect(processedGlide.feedbackMessage, contains('70/100'));
      // Should still generate feedback even without detailed measurement basis
    });

    test('AnalysisOutputBuilder handles component with many time ranges', () {
      final component = ComponentResult(
        componentId: 'streamline',
        status: ComponentStatus.confirmed,
        confidenceLevel: ConfidenceLevel.high,
        rawConfidence: 0.85,
        score: 82.0,
        timeRanges: [
          TimeRange(startSec: 1.0, endSec: 2.0),
          TimeRange(startSec: 3.0, endSec: 4.0),
          TimeRange(startSec: 5.0, endSec: 6.0),
          TimeRange(startSec: 7.0, endSec: 8.0),
          TimeRange(startSec: 9.0, endSec: 10.0),
        ],
        measurementBasis: 'video',
        fixPath: 'Maintain form',
      );

      final builder = AnalysisOutputBuilder();
      final output = builder.build(
        components: {'streamline': component},
        modeGateResult: ModeGateResult(
          mode: 'LEVEL_TEST',
          isLevelTest: true,
          message: 'All gates passed',
          failedGates: [],
        ),
        classification: {
          'classification': 'DNF',
          'confidence': 0.90,
        },
        tracking: TrackingDiagnostics(
          totalFrames: 250,
          trackedFrames: 240,
          trackConfidence: 0.90,
          coverageRatio: 0.96,
          idSwitchCount: 1,
          multiPersonFrameRatio: 0.02,
          avgMatchQuality: 0.92,
        ),
      );

      final processed = output.components['streamline']!;
      expect(processed.feedbackMessage, isNotNull);
      expect(processed.feedbackMessage, contains('Based on'));
      expect(processed.feedbackMessage, contains('5s')); // Total duration (rounded)
      expect(processed.feedbackMessage, contains('5 segments'));
    });

    test('AnalysisOutputBuilder preserves compact segment summary', () {
      final component = ComponentResult(
        componentId: 'kick',
        status: ComponentStatus.confirmed,
        confidenceLevel: ConfidenceLevel.high,
        rawConfidence: 0.82,
        score: 78.0,
        timeRanges: [
          TimeRange(startSec: 2.0, endSec: 4.5),
          TimeRange(startSec: 6.0, endSec: 8.0),
        ],
        measurementBasis: 'video',
        fixPath: 'Increase power',
      );

      final builder = AnalysisOutputBuilder();
      final output = builder.build(
        components: {'kick': component},
        modeGateResult: ModeGateResult(
          mode: 'LEVEL_TEST',
          isLevelTest: true,
          message: 'All gates passed',
          failedGates: [],
        ),
        classification: {
          'classification': 'DNF',
          'confidence': 0.88,
        },
        tracking: TrackingDiagnostics(
          totalFrames: 200,
          trackedFrames: 190,
          trackConfidence: 0.92,
          coverageRatio: 0.95,
          idSwitchCount: 0,
          multiPersonFrameRatio: 0.0,
          avgMatchQuality: 0.90,
        ),
      );

      final processed = output.components['kick']!;
      // Feedback message should be generated
      expect(processed.feedbackMessage, isNotNull);
      expect(processed.feedbackMessage, contains('kick technique'));

      // Compact segment summary should still be generated
      expect(processed.compactSegmentSummary, isNotNull);
      expect(processed.compactSegmentSummary, contains('4.5s total'));
    });
  });
}
