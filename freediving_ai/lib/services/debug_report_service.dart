import 'dart:convert';
import 'video_frame_extractor.dart';

/// Collects and structures debug data into a JSON report for video analysis.
///
/// Tracks:
/// - Video metadata (duration, fps, resolution, rotation)
/// - Pose detection quality (frame counts, valid rates, landmark coverage)
/// - Per-frame pose tracking (counts, selection method, switches)
/// - Classification scores with feature breakdown and rule trace
/// - Dual confidence: classificationConfidence vs analysisQualityConfidence
/// - Phase detection segments
class DebugReportService {
  static const String _version = 'debug_v2';

  /// Generate a structured debug report from analysis data.
  Map<String, dynamic> generateReport({
    required String videoPath,
    required double durationSec,
    required int totalFrames,
    required int extractedFrames,
    required int validPoseFrames,
    required List<Map<String, dynamic>> perFrameTracking,
    required Map<String, dynamic> classificationResult,
    required double analysisQualityConfidence,
    required Map<String, dynamic>? analysisQualityBreakdown,
    required List<String> warnings,
    VideoMetadata? videoMetadata,
    Map<String, dynamic>? landmarkCoverageStats,
    Map<String, dynamic>? rotationInfo,
    List<Map<String, dynamic>>? phaseSegments,
  }) {
    // Calculate pose detection stats
    final validRate = extractedFrames > 0
        ? validPoseFrames / extractedFrames
        : 0.0;

    // Calculate tracking stats from per-frame data
    int framesWithMultiplePoses = 0;
    int trackSwitchCount = 0;
    double totalPoseConfidence = 0.0;
    int poseConfidenceCount = 0;
    final poseDropoutTimestamps = <String>[];

    int? lastSelectedMethod;
    bool inDropout = false;
    double dropoutStartTime = 0.0;

    for (int i = 0; i < perFrameTracking.length; i++) {
      final frame = perFrameTracking[i];
      final detectedCount = frame['detectedPoseCount'] as int? ?? 0;
      final method = frame['selectionMethod'] as String? ?? 'none';
      final confidence = frame['poseConfidence'] as double?;
      final frameTime = frame['frameTime'] as double? ?? (i / 5.0);

      if (detectedCount >= 2) {
        framesWithMultiplePoses++;
      }

      if (confidence != null && confidence > 0) {
        totalPoseConfidence += confidence;
        poseConfidenceCount++;
      }

      // Track switches (method change from temporal_continuity to largest_bbox)
      final methodHash = method.hashCode;
      if (lastSelectedMethod != null &&
          lastSelectedMethod != methodHash &&
          method != 'none' &&
          detectedCount > 1) {
        trackSwitchCount++;
      }
      if (detectedCount > 0) {
        lastSelectedMethod = methodHash;
      }

      // Track dropouts
      if (detectedCount == 0) {
        if (!inDropout) {
          inDropout = true;
          dropoutStartTime = frameTime;
        }
      } else {
        if (inDropout) {
          final dropoutEnd = frameTime;
          poseDropoutTimestamps.add(
            '${dropoutStartTime.toStringAsFixed(1)}s-${dropoutEnd.toStringAsFixed(1)}s',
          );
          inDropout = false;
        }
      }
    }

    // Close any trailing dropout
    if (inDropout && perFrameTracking.isNotEmpty) {
      final lastTime = perFrameTracking.last['frameTime'] as double? ??
          (perFrameTracking.length / 5.0);
      poseDropoutTimestamps.add(
        '${dropoutStartTime.toStringAsFixed(1)}s-${lastTime.toStringAsFixed(1)}s',
      );
    }

    final averagePoseConfidence = poseConfidenceCount > 0
        ? totalPoseConfidence / poseConfidenceCount
        : 0.0;

    // Extract classification data
    final classification = classificationResult['classification'] as String? ?? 'UNKNOWN';
    final classificationConfidence = classificationResult['confidence'] as double? ?? 0.0;
    final scores = classificationResult['scores'] as Map<String, dynamic>? ?? {};
    final ruleTrace = classificationResult['ruleTrace'] as List<Map<String, dynamic>>? ?? [];
    final featureValues = classificationResult['featureValues'] as Map<String, dynamic>? ?? {};

    final report = <String, dynamic>{
      'version': _version,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'video': {
        'path': videoPath,
        'durationSec': durationSec,
      },
      'poseDetection': {
        'totalFrames': totalFrames,
        'extractedFrames': extractedFrames,
        'validPoseFrames': validPoseFrames,
        'validRate': double.parse(validRate.toStringAsFixed(3)),
        'framesWithMultiplePoses': framesWithMultiplePoses,
        'trackSwitchCount': trackSwitchCount,
        'averagePoseConfidence': double.parse(averagePoseConfidence.toStringAsFixed(2)),
        'poseDropoutTimestamps': poseDropoutTimestamps,
      },
      'classification': {
        'result': classification,
        'confidence': classificationConfidence,
        'scores': scores,
        'ruleTrace': ruleTrace,
        'featureValues': featureValues,
      },
      'analysisQuality': {
        'confidence': analysisQualityConfidence,
        'breakdown': analysisQualityBreakdown ?? {},
      },
      'warnings': warnings,
    };

    // Extended sections
    if (videoMetadata != null) {
      report['videoMeta'] = videoMetadata.toJson();
    }

    if (landmarkCoverageStats != null) {
      report['landmarkCoverage'] = landmarkCoverageStats;
    }

    if (rotationInfo != null) {
      report['rotation'] = rotationInfo;
    }

    if (phaseSegments != null) {
      final turnCount = phaseSegments.where((s) => s['phase'] == 'TURN').length;
      final totalTravelDuration = phaseSegments
          .where((s) => s['phase'] == 'TRAVEL')
          .fold<double>(0.0, (sum, s) => sum + (s['duration'] as double? ?? 0.0));
      report['phaseDetection'] = {
        'segments': phaseSegments,
        'turnCount': turnCount,
        'totalTravelDurationSec': totalTravelDuration,
      };
    }

    return report;
  }

  /// Print debug report to console in formatted JSON.
  void printReport(Map<String, dynamic> report) {
    const encoder = JsonEncoder.withIndent('  ');
    print('[DebugReport] ${encoder.convert(report)}');
  }
}
