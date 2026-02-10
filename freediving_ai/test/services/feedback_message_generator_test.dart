import 'package:flutter_test/flutter_test.dart';
import 'package:freediving_ai/services/feedback_message_generator.dart';
import 'package:freediving_ai/models/component_result.dart';

void main() {
  group('FeedbackMessageGenerator', () {
    group('generateFeedback', () {
      test('should return null for notMeasurable component', () {
        final component = _createComponent(
          componentId: 'streamline',
          status: ComponentStatus.notMeasurable,
          score: null,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(feedback, isNull);
      });

      test('should generate complete feedback with all sections', () {
        final component = _createComponent(
          componentId: 'streamline',
          status: ComponentStatus.confirmed,
          score: 75.0,
          timeRanges: [TimeRange(startSec: 2.0, endSec: 5.2)],
          rawConfidence: 0.85,
          subMetrics: {
            'bodyAlignment': 0.88,
            'armPosition': 0.82,
          },
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(feedback, isNotNull);
        expect(feedback, contains('streamline'));
        expect(feedback, contains('75/100'));
        expect(feedback, contains('Based on'));
        expect(feedback, contains('We observed'));
      });

      test('should include measurement basis when requested', () {
        final component = _createComponent(
          componentId: 'kick',
          status: ComponentStatus.confirmed,
          score: 65.0,
          timeRanges: [TimeRange(startSec: 1.0, endSec: 4.5)],
          rawConfidence: 0.78,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
          includeMeasurementBasis: true,
        );

        expect(feedback, contains('Based on'));
        expect(feedback, contains('3.5s'));
      });

      test('should exclude measurement basis when not requested', () {
        final component = _createComponent(
          componentId: 'arm',
          status: ComponentStatus.confirmed,
          score: 80.0,
          timeRanges: [TimeRange(startSec: 2.0, endSec: 6.0)],
          rawConfidence: 0.82,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
          includeMeasurementBasis: false,
        );

        expect(feedback, isNot(contains('Based on')));
      });

      test('should include recommendation when requested', () {
        final component = _createComponent(
          componentId: 'streamline',
          status: ComponentStatus.confirmed,
          score: 65.0,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
          includeRecommendation: true,
        );

        expect(
          feedback!.contains('Focus on') ||
              feedback.contains('Work on') ||
              feedback.contains('Practice'),
          isTrue,
        );
      });

      test('should exclude recommendation when not requested', () {
        final component = _createComponent(
          componentId: 'streamline',
          status: ComponentStatus.confirmed,
          score: 65.0,
          subMetrics: {'bodyAlignment': 0.75},
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
          includeRecommendation: false,
        );

        // Should have component name and score but no recommendation verbs
        expect(feedback, contains('streamline'));
        expect(feedback, isNot(contains('Focus on')));
        expect(feedback, isNot(contains('Work on')));
        expect(feedback, isNot(contains('Practice')));
      });

      test('should handle partial status with appropriate assessment', () {
        final component = _createComponent(
          componentId: 'kick',
          status: ComponentStatus.partial,
          score: 68.0,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(
          feedback!.contains('promising') || feedback.contains('developing'),
          isTrue,
        );
      });

      test('should handle high score with advanced recommendation', () {
        final component = _createComponent(
          componentId: 'streamline',
          status: ComponentStatus.confirmed,
          score: 85.0,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(
          feedback!.contains('Excellent') ||
              feedback.contains('Strong') ||
              feedback.contains('Great'),
          isTrue,
        );
      });

      test('should handle low score with fundamental recommendation', () {
        final component = _createComponent(
          componentId: 'kick',
          status: ComponentStatus.confirmed,
          score: 45.0,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(
          feedback!.contains('Practice') || feedback.contains('Focus on'),
          isTrue,
        );
      });
    });

    group('generateCompactFeedback', () {
      test('should generate feedback without measurement basis', () {
        final component = _createComponent(
          componentId: 'arm',
          status: ComponentStatus.confirmed,
          score: 72.0,
          timeRanges: [TimeRange(startSec: 1.0, endSec: 5.0)],
          rawConfidence: 0.80,
        );

        final feedback = FeedbackMessageGenerator.generateCompactFeedback(
          component: component,
        );

        expect(feedback, isNotNull);
        expect(feedback, contains('arm stroke'));
        expect(feedback, isNot(contains('Based on')));
      });
    });

    group('_formatMeasurementBasis', () {
      test('should format single time range with high confidence', () {
        final component = _createComponent(
          status: ComponentStatus.confirmed,
          timeRanges: [TimeRange(startSec: 2.0, endSec: 5.2)],
          rawConfidence: 0.85,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(feedback, contains('3.2s'));
        expect(feedback, contains('clear video'));
        expect(feedback, contains('2.0-5.2s'));
        expect(feedback, isNot(contains('85% confidence'))); // High confidence doesn't show percentage
      });

      test('should format multiple time ranges', () {
        final component = _createComponent(
          status: ComponentStatus.confirmed,
          timeRanges: [
            TimeRange(startSec: 1.0, endSec: 3.0),
            TimeRange(startSec: 5.0, endSec: 7.5),
          ],
          rawConfidence: 0.75,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(feedback, contains('4.5s'));
        expect(feedback, contains('2 segments'));
      });

      test('should show confidence percentage for medium confidence', () {
        final component = _createComponent(
          status: ComponentStatus.partial,
          timeRanges: [TimeRange(startSec: 1.0, endSec: 3.5)],
          rawConfidence: 0.55,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(feedback, contains('55% confidence'));
      });

      test('should qualify video as "limited" for low confidence', () {
        final component = _createComponent(
          status: ComponentStatus.partial,
          timeRanges: [TimeRange(startSec: 1.0, endSec: 2.2)],
          rawConfidence: 0.40,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(feedback, contains('limited video'));
        expect(feedback, contains('40% confidence'));
      });

      test('should handle empty time ranges gracefully', () {
        final component = _createComponent(
          status: ComponentStatus.confirmed,
          timeRanges: [],
          rawConfidence: 0.75,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        // Should still generate feedback, just without detailed time ranges
        expect(feedback, isNotNull);
      });

      test('should use pre-formatted measurement basis if provided', () {
        final component = ComponentResult(
          componentId: 'streamline',
          status: ComponentStatus.confirmed,
          confidenceLevel: ConfidenceLevel.high,
          rawConfidence: 0.85,
          score: 70.0,
          measurementBasis: 'Based on custom measurement approach',
          fixPath: null,
          subMetrics: null,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(feedback, contains('Based on custom measurement approach'));
      });
    });

    group('Component-specific observations', () {
      test('should generate streamline observations from subMetrics', () {
        final component = _createComponent(
          componentId: 'streamline',
          status: ComponentStatus.confirmed,
          score: 75.0,
          subMetrics: {
            'bodyAlignment': 0.88,
            'armPosition': 0.86,
          },
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(feedback, contains('excellent body alignment'));
        expect(feedback, contains('arms well-positioned'));
      });

      test('should generate kick observations from subMetrics', () {
        final component = _createComponent(
          componentId: 'kick',
          status: ComponentStatus.confirmed,
          score: 70.0,
          subMetrics: {
            'symmetry': 0.78,
            'power': 0.72,
          },
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(
          feedback!.contains('symmetric') || feedback.contains('kick'),
          isTrue,
        );
        expect(feedback, contains('power'));
      });

      test('should generate arm observations from subMetrics', () {
        final component = _createComponent(
          componentId: 'arm',
          status: ComponentStatus.confirmed,
          score: 73.0,
          subMetrics: {
            'sweepWidth': 0.75,
            'timing': 0.80,
          },
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(feedback, contains('sweep'));
        expect(feedback, contains('timing'));
      });

      test('should generate glide observations from subMetrics', () {
        final component = _createComponent(
          componentId: 'glide',
          status: ComponentStatus.confirmed,
          score: 68.0,
          subMetrics: {
            'avgGlideDuration': 1.8,
            'intervalCount': 3,
          },
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(feedback, contains('3 glide intervals'));
        expect(feedback, contains('1.8s'));
      });

      test('should generate start observations from subMetrics', () {
        final component = _createComponent(
          componentId: 'start',
          status: ComponentStatus.confirmed,
          score: 77.0,
          subMetrics: {
            'pushOffPower': 0.82,
          },
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(feedback!.contains('push') && feedback.contains('wall'), isTrue);
      });

      test('should generate turn observations from subMetrics', () {
        final component = _createComponent(
          componentId: 'turn',
          status: ComponentStatus.confirmed,
          score: 74.0,
          subMetrics: {
            'rotationSpeed': 0.78,
            'streamlineAfter': 0.85,
          },
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(feedback, contains('rotation'));
        expect(feedback, contains('streamline'));
      });

      test('should handle missing subMetrics gracefully', () {
        final component = _createComponent(
          componentId: 'streamline',
          status: ComponentStatus.confirmed,
          score: 70.0,
          subMetrics: null,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        // Should still generate feedback without observations section
        expect(feedback, isNotNull);
        expect(feedback, contains('streamline'));
      });

      test('should handle empty subMetrics map', () {
        final component = _createComponent(
          componentId: 'kick',
          status: ComponentStatus.confirmed,
          score: 65.0,
          subMetrics: {},
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(feedback, isNotNull);
        expect(feedback, contains('kick'));
      });
    });

    group('Performance assessment', () {
      test('should use excellent for score >= 90', () {
        final component = _createComponent(
          status: ComponentStatus.confirmed,
          score: 92.0,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(feedback, contains('excellent'));
      });

      test('should use strong for score >= 80', () {
        final component = _createComponent(
          status: ComponentStatus.confirmed,
          score: 85.0,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(feedback, contains('strong'));
      });

      test('should use good for score >= 70', () {
        final component = _createComponent(
          status: ComponentStatus.confirmed,
          score: 73.0,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(feedback, contains('good'));
      });

      test('should use needs improvement for low scores', () {
        final component = _createComponent(
          status: ComponentStatus.confirmed,
          score: 42.0,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(
          feedback!.contains('needs improvement') ||
              feedback.contains('improvement'),
          isTrue,
        );
      });
    });

    group('Recommendations', () {
      test('should provide advanced recommendation for high scores', () {
        final component = _createComponent(
          componentId: 'streamline',
          status: ComponentStatus.confirmed,
          score: 88.0,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(
          feedback!.contains('Excellent') ||
              feedback.contains('fatigue') ||
              feedback.contains('race pace'),
          isTrue,
        );
      });

      test('should provide medium recommendation for mid scores', () {
        final component = _createComponent(
          componentId: 'kick',
          status: ComponentStatus.confirmed,
          score: 68.0,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(
          feedback!.contains('Focus on') || feedback.contains('Work on'),
          isTrue,
        );
      });

      test('should provide fundamental recommendation for low scores', () {
        final component = _createComponent(
          componentId: 'arm',
          status: ComponentStatus.confirmed,
          score: 48.0,
        );

        final feedback = FeedbackMessageGenerator.generateFeedback(
          component: component,
        );

        expect(
          feedback!.contains('Isolate') || feedback.contains('Focus on'),
          isTrue,
        );
      });

      test('should provide component-specific recommendations', () {
        final streamline = _createComponent(
          componentId: 'streamline',
          status: ComponentStatus.confirmed,
          score: 50.0,
        );

        final kick = _createComponent(
          componentId: 'kick',
          status: ComponentStatus.confirmed,
          score: 50.0,
        );

        final streamlineFeedback = FeedbackMessageGenerator.generateFeedback(
          component: streamline,
        );
        final kickFeedback = FeedbackMessageGenerator.generateFeedback(
          component: kick,
        );

        // Recommendations should be different for different components
        expect(streamlineFeedback, isNot(equals(kickFeedback)));
      });
    });

    group('generateMeasurementCitation', () {
      test('should generate citation with single time range', () {
        final component = _createComponent(
          status: ComponentStatus.confirmed,
          timeRanges: [TimeRange(startSec: 2.0, endSec: 5.2)],
          rawConfidence: 0.85,
        );

        final citation = FeedbackMessageGenerator.generateMeasurementCitation(
          component,
        );

        expect(citation, equals('Measured from 2.0-5.2s (85% confidence)'));
      });

      test('should generate citation with multiple time ranges (≤3)', () {
        final component = _createComponent(
          status: ComponentStatus.confirmed,
          timeRanges: [
            TimeRange(startSec: 1.0, endSec: 2.5),
            TimeRange(startSec: 4.0, endSec: 6.0),
          ],
          rawConfidence: 0.78,
        );

        final citation = FeedbackMessageGenerator.generateMeasurementCitation(
          component,
        );

        expect(citation, contains('1.0-2.5s'));
        expect(citation, contains('4.0-6.0s'));
        expect(citation, contains('78% confidence'));
      });

      test('should show segment count for many time ranges', () {
        final component = _createComponent(
          status: ComponentStatus.confirmed,
          timeRanges: [
            TimeRange(startSec: 1.0, endSec: 2.0),
            TimeRange(startSec: 3.0, endSec: 4.0),
            TimeRange(startSec: 5.0, endSec: 6.0),
            TimeRange(startSec: 7.0, endSec: 8.0),
          ],
          rawConfidence: 0.72,
        );

        final citation = FeedbackMessageGenerator.generateMeasurementCitation(
          component,
        );

        expect(citation, contains('4 segments'));
        expect(citation, contains('72% confidence'));
      });

      test('should handle empty time ranges', () {
        final component = _createComponent(
          status: ComponentStatus.confirmed,
          timeRanges: [],
          rawConfidence: 0.65,
        );

        final citation = FeedbackMessageGenerator.generateMeasurementCitation(
          component,
        );

        expect(citation, equals('Confidence: 65%'));
      });
    });

    group('Component display names', () {
      test('should map component IDs to display names', () {
        final components = [
          ('streamline', 'streamline'),
          ('kick', 'kick technique'),
          ('arm', 'arm stroke'),
          ('glide', 'glide efficiency'),
          ('start', 'start/push-off'),
          ('turn', 'turn execution'),
        ];

        for (final (id, expectedName) in components) {
          final component = _createComponent(
            componentId: id,
            status: ComponentStatus.confirmed,
            score: 70.0,
          );

          final feedback = FeedbackMessageGenerator.generateFeedback(
            component: component,
          );

          expect(feedback, contains(expectedName));
        }
      });
    });
  });
}

/// Helper to create ComponentResult for testing.
ComponentResult _createComponent({
  String componentId = 'test',
  required ComponentStatus status,
  double? score,
  List<TimeRange>? timeRanges,
  double rawConfidence = 0.75,
  Map<String, dynamic>? subMetrics,
}) {
  final confLevel = rawConfidence >= 0.70
      ? ConfidenceLevel.high
      : rawConfidence >= 0.45
          ? ConfidenceLevel.medium
          : ConfidenceLevel.low;

  return ComponentResult(
    componentId: componentId,
    status: status,
    confidenceLevel: confLevel,
    rawConfidence: rawConfidence,
    score: score,
    // Placeholder to trigger construction from timeRanges
    measurementBasis: 'video',
    fixPath: status == ComponentStatus.confirmed || status == ComponentStatus.partial
        ? 'Improve technique'
        : null,
    subMetrics: subMetrics,
    timeRanges: timeRanges ?? [],
  );
}
