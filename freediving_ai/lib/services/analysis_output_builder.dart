import '../models/analysis_output.dart';
import '../models/component_result.dart';
import '../models/swimmer_track.dart';
import 'feedback_message_generator.dart';
import 'mode_gate.dart';

/// Transforms raw analysis pipeline outputs into AnalysisOutput UI model.
///
/// This service is the bridge between the analysis backend and the UI layer.
/// It handles:
/// - Status label mapping
/// - Evidence summary generation (top 3 segments)
/// - Quality score calculation with penalty breakdown
/// - Classification result transformation
/// - Gate failure message formatting
/// - Feedback message generation with measurement basis
///
/// Usage:
/// ```dart
/// final builder = AnalysisOutputBuilder();
/// final output = builder.build(
///   components: analyzerComponents,
///   modeGateResult: gateResult,
///   classification: classificationData,
///   tracking: trackingDiagnostics,
/// );
/// ```
class AnalysisOutputBuilder {
  /// Build complete AnalysisOutput from raw analysis results.
  AnalysisOutput build({
    required Map<String, ComponentResult> components,
    required ModeGateResult modeGateResult,
    required Map<String, dynamic> classification,
    required TrackingDiagnostics tracking,
    double? overallScore,
    Map<String, dynamic>? rawAnalysisData,
  }) {
    // Calculate overall score availability
    final overallScoreAvailable = _isOverallScoreAvailable(
      components: components,
      isLevelTest: modeGateResult.isLevelTest,
    );

    // Use provided score or calculate from components
    final finalScore = overallScore ?? _calculateOverallScore(components);

    // Build classification result
    final classificationResult = _buildClassificationResult(classification);

    // Calculate quality score with penalty breakdown
    final qualityScore = _buildQualityScore(
      tracking: tracking,
      components: components,
    );

    // Process components for UI (add compact summaries, filter drills)
    final processedComponents = _processComponentsForUI(components);

    return AnalysisOutput(
      analysisMode: modeGateResult.mode,
      modeMessage: modeGateResult.message,
      failedGates: modeGateResult.failedGates,
      classification: classificationResult,
      overallScore: finalScore,
      overallScoreAvailable: overallScoreAvailable,
      components: processedComponents,
      trackingDiagnostics: tracking,
      qualityScore: qualityScore,
      rawAnalysisData: rawAnalysisData,
    );
  }

  /// Determine if overall score can be trusted.
  ///
  /// Overall score is available when:
  /// - Mode is LEVEL_TEST (all gates passed), AND
  /// - At least 2 essential components are measurable
  bool _isOverallScoreAvailable({
    required Map<String, ComponentResult> components,
    required bool isLevelTest,
  }) {
    if (!isLevelTest) return false;

    const essential = ['streamline', 'kick', 'arm'];
    final measurableEssentialCount = essential.where((id) {
      final c = components[id];
      return c != null && c.isMeasurable;
    }).length;

    return measurableEssentialCount >= 2;
  }

  /// Calculate overall score from component scores.
  ///
  /// Weighted average: streamline 30%, kick 25%, arm 25%, glide 20%
  /// Only includes measurable components in calculation.
  double _calculateOverallScore(Map<String, ComponentResult> components) {
    final weights = {
      'streamline': 0.30,
      'kick': 0.25,
      'arm': 0.25,
      'glide': 0.20,
    };

    double totalScore = 0.0;
    double totalWeight = 0.0;

    for (final entry in weights.entries) {
      final component = components[entry.key];
      if (component != null && component.isMeasurable && component.score != null) {
        totalScore += component.score! * entry.value;
        totalWeight += entry.value;
      }
    }

    if (totalWeight == 0.0) return 0.0;
    return totalScore / totalWeight;
  }

  /// Build ClassificationResult from raw classification data.
  ClassificationResult _buildClassificationResult(
    Map<String, dynamic> classification,
  ) {
    final discipline = classification['classification'] as String? ?? 'UNKNOWN';
    final confidence = (classification['confidence'] as num?)?.toDouble() ?? 0.0;
    final reason = classification['reason'] as String? ?? 'Classification unavailable';
    final isInconclusive = classification['isInconclusive'] as bool? ?? false;
    final scores = classification['scores'] as Map<String, dynamic>? ?? {};
    final scoreDelta = (classification['scoreDelta'] as num?)?.toDouble() ?? 0.0;

    // Build conflict warning if inconclusive
    String? conflictWarning;
    if (isInconclusive) {
      final conflictReasons = classification['conflictReasons'] as List<dynamic>?;
      if (conflictReasons != null && conflictReasons.isNotEmpty) {
        conflictWarning = conflictReasons.join('; ');
      } else {
        conflictWarning = 'Multiple disciplines detected with similar confidence';
      }
    }

    // Convert scores map to double values
    final scoresMap = <String, double>{};
    scores.forEach((key, value) {
      if (value is num) {
        scoresMap[key] = value.toDouble();
      }
    });

    return ClassificationResult(
      discipline: discipline,
      confidence: confidence,
      reason: reason,
      isInconclusive: isInconclusive,
      conflictWarning: conflictWarning,
      scores: scoresMap,
      scoreDelta: scoreDelta,
    );
  }

  /// Build QualityScore with penalty breakdown.
  ///
  /// Base score starts at 1.0, penalties are applied for:
  /// - Low tracking confidence
  /// - ID switches
  /// - Multi-person frames
  /// - Low coverage
  /// - NOT_MEASURABLE components
  QualityScore _buildQualityScore({
    required TrackingDiagnostics tracking,
    required Map<String, ComponentResult> components,
  }) {
    const baseScore = 1.0;
    final penalties = <String, double>{};

    // Tracking confidence penalty
    if (tracking.trackConfidence < 0.70) {
      final penalty = (0.70 - tracking.trackConfidence) * 0.5;
      penalties['tracking_confidence'] = penalty;
    }

    // ID switch penalty
    if (tracking.idSwitchCount > 0) {
      final penalty = tracking.idSwitchCount * 0.05;
      penalties['id_switches'] = penalty;
    }

    // Multi-person penalty
    if (tracking.multiPersonFrameRatio > 0.10) {
      final penalty = tracking.multiPersonFrameRatio * 0.3;
      penalties['multi_person'] = penalty;
    }

    // Coverage penalty
    if (tracking.coverageRatio < 0.80) {
      final penalty = (0.80 - tracking.coverageRatio) * 0.2;
      penalties['tracking_coverage'] = penalty;
    }

    // NOT_MEASURABLE component penalty
    final notMeasurableCount = components.values
        .where((c) => c.status == ComponentStatus.notMeasurable)
        .length;
    if (notMeasurableCount > 0) {
      final penalty = notMeasurableCount * 0.08;
      penalties['not_measurable_components'] = penalty;
    }

    // Calculate overall score
    final totalPenalty = penalties.values.fold<double>(0.0, (a, b) => a + b);
    final overall = (baseScore - totalPenalty).clamp(0.0, 1.0);

    return QualityScore(
      overall: overall,
      baseScore: baseScore,
      penalties: penalties,
    );
  }

  /// Process components for UI display.
  ///
  /// - Adds compact segment summaries (top 3 segments only)
  /// - Filters drills based on component status
  /// - Preserves debug segments in separate field
  Map<String, ComponentResult> _processComponentsForUI(
    Map<String, ComponentResult> components,
  ) {
    final processed = <String, ComponentResult>{};

    for (final entry in components.entries) {
      final component = entry.value;

      // Generate compact segment summary (top 3 time ranges)
      final compactSummary = _generateCompactSegmentSummary(component.timeRanges);

      // Filter drills: only include if component is measurable
      final filteredDrills = component.isMeasurable ? component.drills : <DrillPrescription>[];

      // Generate feedback message with measurement basis
      final feedbackMessage = FeedbackMessageGenerator.generateFeedback(
        component: component,
        includeMeasurementBasis: true,
        includeRecommendation: true,
      );

      // Create processed component with UI-specific fields
      processed[entry.key] = ComponentResult(
        componentId: component.componentId,
        status: component.status,
        confidenceLevel: component.confidenceLevel,
        rawConfidence: component.rawConfidence,
        score: component.score,
        timeRanges: component.timeRanges.take(3).toList(), // Limit to top 3 for main UI
        measurementBasis: component.measurementBasis,
        fixPath: component.fixPath,
        drills: filteredDrills,
        subMetrics: component.subMetrics,
        feedbackMessage: feedbackMessage,
        compactSegmentSummary: compactSummary,
        debugSegments: component.timeRanges.length > 3
            ? component.timeRanges // Keep all for debug view
            : null,
      );
    }

    return processed;
  }

  /// Generate compact segment summary for UI display.
  ///
  /// Returns human-readable summary of top 3 time ranges:
  /// - "2.0-8.4s (6.4s total)"
  /// - "2.0-4.5s, 6.1-8.3s (4.7s total)"
  /// - "2.0-3.2s, 5.1-6.8s, 8.0-9.5s (4.4s total)"
  String? _generateCompactSegmentSummary(List<TimeRange> timeRanges) {
    if (timeRanges.isEmpty) return null;

    final top3 = timeRanges.take(3).toList();
    final totalDuration = top3.fold<double>(0.0, (sum, r) => sum + r.duration);

    if (top3.length == 1) {
      final r = top3[0];
      return '${r.startSec.toStringAsFixed(1)}-${r.endSec.toStringAsFixed(1)}s '
          '(${totalDuration.toStringAsFixed(1)}s total)';
    }

    final rangeStrs = top3.map((r) =>
      '${r.startSec.toStringAsFixed(1)}-${r.endSec.toStringAsFixed(1)}s'
    ).join(', ');

    return '$rangeStrs (${totalDuration.toStringAsFixed(1)}s total)';
  }

  /// Build AnalysisOutput for insufficient data scenarios.
  ///
  /// Used when pose detection fails or video quality is too poor.
  AnalysisOutput buildInsufficientDataResult({
    required String reason,
  }) {
    // Create all NOT_MEASURABLE components
    final components = <String, ComponentResult>{};
    for (final id in ['streamline', 'kick', 'arm', 'glide', 'start', 'turn']) {
      components[id] = ComponentResult(
        componentId: id,
        status: ComponentStatus.notMeasurable,
        confidenceLevel: ConfidenceLevel.low,
        rawConfidence: 0.0,
        measurementBasis: reason,
        fixPath: ComponentResult.getDefaultFixPath(id),
      );
    }

    // Create failed Gate 5 (Data Sufficiency)
    final failedGates = [
      FailedGate(
        gateNumber: 5,
        gateName: 'Data Sufficiency',
        reason: reason,
      ),
    ];

    return AnalysisOutput(
      analysisMode: 'PRACTICE_MODE',
      modeMessage: 'Inconclusive for Level Test — insufficient data',
      failedGates: failedGates,
      classification: ClassificationResult(
        discipline: 'UNKNOWN',
        confidence: 0.0,
        reason: 'Insufficient data for classification',
      ),
      overallScore: 0.0,
      overallScoreAvailable: false,
      components: components,
      trackingDiagnostics: TrackingDiagnostics(
        totalFrames: 0,
        trackedFrames: 0,
        trackConfidence: 0.0,
        coverageRatio: 0.0,
        idSwitchCount: 0,
        multiPersonFrameRatio: 0.0,
        avgMatchQuality: 0.0,
      ),
      qualityScore: QualityScore(
        overall: 0.0,
        baseScore: 1.0,
        penalties: {'insufficient_data': 1.0},
      ),
    );
  }
}
