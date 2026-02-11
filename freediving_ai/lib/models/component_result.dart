/// Component-level analysis result for DNF analysis pipeline.
///
/// Each of the 6 DNF components (streamline, kick, arm, glide, start, turn)
/// produces a [ComponentResult] with status, confidence, score, time ranges,
/// measurement basis, fix path, and drill prescriptions.

/// Status of a measured component.
enum ComponentStatus {
  /// Confident measurement: rawConf >= 0.70, duration >= 2.0s
  confirmed,

  /// Partial measurement: rawConf >= 0.45, duration >= 0.8s
  partial,

  /// Visibility/landmark/tracking limitations prevent measurement
  /// (e.g., body truncated, landmarks occluded, multi-person confusion)
  notMeasurable,

  /// Measurement was possible, but event not detected or below threshold
  /// (e.g., glide durations < 0.6s, no arm strokes detected)
  /// Avoids blaming swimmer when data quality is good but event absent
  measurableNoEvent,
}

/// Confidence level for display purposes.
enum ConfidenceLevel {
  high,   // >= 0.70
  medium, // >= 0.45
  low,    // < 0.45
}

/// A time range within the video.
class TimeRange {
  final double startSec;
  final double endSec;

  const TimeRange({required this.startSec, required this.endSec});

  double get duration => endSec - startSec;

  Map<String, dynamic> toJson() => {
    'startSec': startSec,
    'endSec': endSec,
    'duration': duration,
  };

  factory TimeRange.fromJson(Map<String, dynamic> json) => TimeRange(
    startSec: (json['startSec'] as num).toDouble(),
    endSec: (json['endSec'] as num).toDouble(),
  );
}

/// A candidate segment in the timeline for a component.
class TimelineCandidate {
  final TimeRange range;
  final double confidence;
  final String label;

  const TimelineCandidate({
    required this.range,
    required this.confidence,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
    'range': range.toJson(),
    'confidence': confidence,
    'label': label,
  };
}

/// A drill prescription for a specific component deficiency.
class DrillPrescription {
  final String name;
  final String type; // 'in_water' or 'dryland'
  final String? distance;
  final String? reps;
  final String? rest;
  final String? progression;
  final String? regression;
  final String description;

  const DrillPrescription({
    required this.name,
    required this.type,
    this.distance,
    this.reps,
    this.rest,
    this.progression,
    this.regression,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    if (distance != null) 'distance': distance,
    if (reps != null) 'reps': reps,
    if (rest != null) 'rest': rest,
    if (progression != null) 'progression': progression,
    if (regression != null) 'regression': regression,
    'description': description,
  };
}

/// Result of analyzing a single DNF component.
class ComponentResult {
  final String componentId; // 'streamline', 'kick', 'arm', 'glide', 'start', 'turn'
  final ComponentStatus status;
  final ConfidenceLevel confidenceLevel;
  final double rawConfidence; // 0.0-1.0
  final double? score; // 0-100, null if notMeasurable/measurableNoEvent
  final List<TimeRange> timeRanges; // video segments where this was measured
  final String measurementBasis; // e.g. "measured from 2.0-8.4s where landmarks visible with 78% confidence"
  final String? fixPath; // actionable advice when notMeasurable
  final List<DrillPrescription> drills;
  final Map<String, dynamic>? subMetrics; // component-specific detail scores
  final String? feedbackMessage; // coaching text with measurement citation

  /// Compact summary for main UI (top 3 segments only).
  final String? compactSegmentSummary;

  /// Full segment list (for debug/advanced view only).
  final List<TimeRange>? debugSegments;

  const ComponentResult({
    required this.componentId,
    required this.status,
    required this.confidenceLevel,
    required this.rawConfidence,
    this.score,
    this.timeRanges = const [],
    required this.measurementBasis,
    this.fixPath,
    this.drills = const [],
    this.subMetrics,
    this.feedbackMessage,
    this.compactSegmentSummary,
    this.debugSegments,
  });

  /// Whether this component produced actionable data (can generate feedback/drills).
  bool get isMeasurable =>
      status == ComponentStatus.confirmed ||
      status == ComponentStatus.partial;

  /// Whether measurement was attempted (excludes NOT_MEASURABLE cases).
  bool get wasMeasurementAttempted =>
      status != ComponentStatus.notMeasurable;

  Map<String, dynamic> toJson() => {
    'componentId': componentId,
    'status': status.name,
    'confidenceLevel': confidenceLevel.name,
    'rawConfidence': rawConfidence,
    if (score != null) 'score': score,
    'timeRanges': timeRanges.map((t) => t.toJson()).toList(),
    'measurementBasis': measurementBasis,
    if (fixPath != null) 'fixPath': fixPath,
    'drills': drills.map((d) => d.toJson()).toList(),
    if (subMetrics != null) 'subMetrics': subMetrics,
    if (feedbackMessage != null) 'feedbackMessage': feedbackMessage,
    if (compactSegmentSummary != null) 'compactSegmentSummary': compactSegmentSummary,
    if (debugSegments != null) 'debugSegments': debugSegments!.map((t) => t.toJson()).toList(),
  };

  /// Create a ComponentResult from existing metric data (bridge from old format).
  factory ComponentResult.fromMetricMap({
    required String componentId,
    required Map<String, dynamic> metricData,
    List<TimeRange> timeRanges = const [],
  }) {
    final confidence = metricData['confidence'] as double? ?? 0.0;
    final overall = metricData['overall'] as double?;
    final duration = timeRanges.fold<double>(0.0, (s, t) => s + t.duration);

    ComponentStatus status;
    if (confidence >= 0.70 && duration >= 2.0) {
      status = ComponentStatus.confirmed;
    } else if (confidence >= 0.45 && duration >= 0.8) {
      status = ComponentStatus.partial;
    } else {
      status = ComponentStatus.notMeasurable;
    }

    ConfidenceLevel confLevel;
    if (confidence >= 0.70) {
      confLevel = ConfidenceLevel.high;
    } else if (confidence >= 0.45) {
      confLevel = ConfidenceLevel.medium;
    } else {
      confLevel = ConfidenceLevel.low;
    }

    final fixPath = status == ComponentStatus.notMeasurable
        ? getDefaultFixPath(componentId)
        : null;

    return ComponentResult(
      componentId: componentId,
      status: status,
      confidenceLevel: confLevel,
      rawConfidence: confidence,
      score: status != ComponentStatus.notMeasurable ? overall : null,
      timeRanges: timeRanges,
      measurementBasis: buildMeasurementBasis(componentId, timeRanges, confidence),
      fixPath: fixPath,
      subMetrics: Map<String, dynamic>.from(metricData),
    );
  }

  static String buildMeasurementBasis(
    String componentId,
    List<TimeRange> ranges,
    double confidence,
  ) {
    if (ranges.isEmpty) {
      return 'Full travel phase | Confidence: ${(confidence * 100).round()}%';
    }

    final segmentCount = ranges.length;
    final totalDuration = ranges.fold<double>(0.0, (s, t) => s + t.duration);

    // User-friendly concise summary (no raw intervals)
    final roundedDuration = totalDuration.round(); // No decimals for clean display
    final confPct = (confidence * 100).round();

    return 'Detected $segmentCount segment${segmentCount > 1 ? "s" : ""} | '
        'Total: ${roundedDuration}s | Confidence: $confPct%';
  }

  /// Generate technical details with raw time intervals (for debug/advanced view).
  static String buildTechnicalDetails(
    List<TimeRange> ranges,
    double confidence,
  ) {
    if (ranges.isEmpty) {
      return 'No specific time ranges (full travel phase analyzed)';
    }

    final rangeStr = ranges.map((r) =>
      '${r.startSec.toStringAsFixed(1)}-${r.endSec.toStringAsFixed(1)}s'
    ).join(', ');

    final totalDuration = ranges.fold<double>(0.0, (s, t) => s + t.duration);

    return 'Measured from: $rangeStr\n'
        'Total duration: ${totalDuration.toStringAsFixed(1)}s\n'
        'Confidence: ${(confidence * 100).toStringAsFixed(1)}%';
  }

  static String getDefaultFixPath(String componentId) {
    switch (componentId) {
      case 'streamline':
        return 'Film from the side with full body visible, ensure good lighting';
      case 'kick':
        return 'Record at least 3 visible kick cycles from side angle';
      case 'arm':
        return 'Ensure arms are visible — film from side or slightly elevated angle';
      case 'glide':
        return 'Record at least 6 seconds of continuous swimming with visible pauses between strokes';
      case 'start':
        return 'Include wall push-off in the video from side angle';
      case 'turn':
        return 'Include a wall turn in the video — film from side showing approach and departure';
      default:
        return 'Improve video quality for better detection';
    }
  }
}
