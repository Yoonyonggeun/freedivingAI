import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Key body landmarks used for coverage calculation.
const List<PoseLandmarkType> _keyLandmarks = [
  PoseLandmarkType.leftShoulder,
  PoseLandmarkType.rightShoulder,
  PoseLandmarkType.leftHip,
  PoseLandmarkType.rightHip,
  PoseLandmarkType.leftKnee,
  PoseLandmarkType.rightKnee,
  PoseLandmarkType.leftAnkle,
  PoseLandmarkType.rightAnkle,
];

/// Result from pose detection on a single frame, with tracking metadata.
class PoseDetectionResult {
  final Pose? pose;
  final int detectedPoseCount; // 0, 1, 2+
  final String selectionMethod; // 'none', 'only_pose', 'largest_bbox', 'temporal_continuity'
  final double? poseConfidence; // average landmark likelihood
  final int inferenceMs; // milliseconds for processImage()
  final double landmarkCoverage; // fraction of 8 key landmarks present
  final Map<String, bool> keypointPresence; // per-keypoint presence

  PoseDetectionResult({
    required this.pose,
    required this.detectedPoseCount,
    required this.selectionMethod,
    this.poseConfidence,
    this.inferenceMs = 0,
    this.landmarkCoverage = 0.0,
    this.keypointPresence = const {},
  });

  Map<String, dynamic> toTrackingMap(double frameTime) => {
    'frameTime': frameTime,
    'detectedPoseCount': detectedPoseCount,
    'selectionMethod': selectionMethod,
    'poseConfidence': poseConfidence ?? 0.0,
    'inferenceMs': inferenceMs,
    'landmarkCoverage': landmarkCoverage,
    'keypointPresence': keypointPresence,
  };
}

class PoseDetectionService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );

  // Tracking state for temporal continuity
  double? _lastSelectedCenterX;
  double? _lastSelectedCenterY;
  int _trackSwitchCount = 0;
  int _consecutiveTrackFrames = 0;

  Future<List<Map<String, dynamic>>> analyzePosesFromVideo(String videoPath) async {
    List<Map<String, dynamic>> allPoses = [];

    try {
      final inputImage = InputImage.fromFilePath(videoPath);
      final poses = await _poseDetector.processImage(inputImage);

      for (var pose in poses) {
        allPoses.add(_convertPoseToMap(pose));
      }
    } catch (e) {
      print('Error analyzing poses: $e');
    }

    return allPoses;
  }

  /// Detect pose from image with multi-pose tracking metadata.
  ///
  /// [rotation] — if provided and non-zero, creates InputImage with rotation
  /// metadata for correct ML Kit orientation handling.
  ///
  /// Selection criteria:
  /// 1. If only one pose, use it
  /// 2. If multiple: prefer temporal continuity (closest to previous frame's pose)
  /// 3. Fallback: largest bounding box area (closest subject)
  Future<PoseDetectionResult> detectPoseFromImageWithTracking(
    InputImage inputImage, {
    InputImageRotation? rotation,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      final poses = await _poseDetector.processImage(inputImage);
      stopwatch.stop();
      final inferenceMs = stopwatch.elapsedMilliseconds;

      if (poses.isEmpty) {
        _consecutiveTrackFrames = 0;
        return PoseDetectionResult(
          pose: null,
          detectedPoseCount: 0,
          selectionMethod: 'none',
          inferenceMs: inferenceMs,
        );
      }

      Pose selectedPose;
      String method;

      if (poses.length == 1) {
        selectedPose = poses.first;
        method = 'only_pose';
        final center = _getPoseCenter(selectedPose);
        _updateTrackingState(center?.$1, center?.$2, false);
        _consecutiveTrackFrames++;
      } else {
        // Multiple poses detected
        if (_lastSelectedCenterX != null && _lastSelectedCenterY != null) {
          final closest = _findClosestPose(poses, _lastSelectedCenterX!, _lastSelectedCenterY!);
          final largest = _findLargestPose(poses);

          final closestCenter = _getPoseCenter(closest);
          final dist = closestCenter != null
              ? _distance(_lastSelectedCenterX!, _lastSelectedCenterY!,
                          closestCenter.$1, closestCenter.$2)
              : double.infinity;

          if (dist < 200) {
            selectedPose = closest;
            method = 'temporal_continuity';
            _updateTrackingState(closestCenter?.$1, closestCenter?.$2, false);
          } else {
            selectedPose = largest;
            method = 'largest_bbox';
            final largestCenter = _getPoseCenter(largest);
            _updateTrackingState(largestCenter?.$1, largestCenter?.$2, true);
          }
        } else {
          selectedPose = _findLargestPose(poses);
          method = 'largest_bbox';
          final center = _getPoseCenter(selectedPose);
          _updateTrackingState(center?.$1, center?.$2, false);
        }
        _consecutiveTrackFrames++;
      }

      // Compute landmark coverage for the selected pose
      final coverage = _computeLandmarkCoverage(selectedPose);

      return PoseDetectionResult(
        pose: selectedPose,
        detectedPoseCount: poses.length,
        selectionMethod: method,
        poseConfidence: _averageLandmarkLikelihood(selectedPose),
        inferenceMs: inferenceMs,
        landmarkCoverage: coverage.coverage,
        keypointPresence: coverage.presence,
      );
    } catch (e) {
      print('Error detecting pose: $e');
      return PoseDetectionResult(
        pose: null,
        detectedPoseCount: 0,
        selectionMethod: 'none',
      );
    }
  }

  /// Compute fraction of 8 key landmarks present and per-keypoint map.
  ({double coverage, Map<String, bool> presence}) _computeLandmarkCoverage(Pose pose) {
    int present = 0;
    final presence = <String, bool>{};

    for (final kp in _keyLandmarks) {
      final lm = pose.landmarks[kp];
      final isPresent = lm != null && lm.likelihood > 0.5;
      presence[kp.name] = isPresent;
      if (isPresent) present++;
    }

    return (coverage: present / _keyLandmarks.length, presence: presence);
  }

  /// Legacy method preserved for backward compatibility.
  Future<Pose?> detectPoseFromImage(InputImage inputImage) async {
    final result = await detectPoseFromImageWithTracking(inputImage);
    return result.pose;
  }

  /// Reset tracking state between videos.
  void resetTracking() {
    _lastSelectedCenterX = null;
    _lastSelectedCenterY = null;
    _trackSwitchCount = 0;
    _consecutiveTrackFrames = 0;
  }

  /// Get cumulative track switch count for the current video.
  int get trackSwitchCount => _trackSwitchCount;

  // ---- Private helpers ----

  void _updateTrackingState(double? centerX, double? centerY, bool isSwitch) {
    _lastSelectedCenterX = centerX;
    _lastSelectedCenterY = centerY;
    if (isSwitch) {
      _trackSwitchCount++;
      _consecutiveTrackFrames = 0;
    }
  }

  Pose _findClosestPose(List<Pose> poses, double targetX, double targetY) {
    Pose? closest;
    double minDist = double.infinity;

    for (final pose in poses) {
      final center = _getPoseCenter(pose);
      if (center == null) continue;
      final dist = _distance(targetX, targetY, center.$1, center.$2);
      if (dist < minDist) {
        minDist = dist;
        closest = pose;
      }
    }

    return closest ?? poses.first;
  }

  Pose _findLargestPose(List<Pose> poses) {
    Pose? largest;
    double maxArea = -1;

    for (final pose in poses) {
      final area = _getBboxArea(pose);
      if (area > maxArea) {
        maxArea = area;
        largest = pose;
      }
    }

    return largest ?? poses.first;
  }

  (double, double)? _getPoseCenter(Pose pose) {
    double sumX = 0, sumY = 0;
    int count = 0;

    for (final lm in pose.landmarks.values) {
      sumX += lm.x;
      sumY += lm.y;
      count++;
    }

    if (count == 0) return null;
    return (sumX / count, sumY / count);
  }

  double _getBboxArea(Pose pose) {
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    for (final lm in pose.landmarks.values) {
      if (lm.x < minX) minX = lm.x;
      if (lm.y < minY) minY = lm.y;
      if (lm.x > maxX) maxX = lm.x;
      if (lm.y > maxY) maxY = lm.y;
    }

    if (minX == double.infinity) return 0;
    return (maxX - minX) * (maxY - minY);
  }

  double _averageLandmarkLikelihood(Pose pose) {
    if (pose.landmarks.isEmpty) return 0.0;
    double sum = 0;
    for (final lm in pose.landmarks.values) {
      sum += lm.likelihood;
    }
    return sum / pose.landmarks.length;
  }

  double _distance(double x1, double y1, double x2, double y2) {
    final dx = x1 - x2;
    final dy = y1 - y2;
    return sqrt(dx * dx + dy * dy);
  }

  Map<String, dynamic> _convertPoseToMap(Pose pose) {
    Map<String, dynamic> poseData = {};

    for (var landmark in pose.landmarks.values) {
      poseData[landmark.type.name] = {
        'x': landmark.x,
        'y': landmark.y,
        'z': landmark.z,
        'likelihood': landmark.likelihood,
      };
    }

    return poseData;
  }

  Map<String, dynamic> calculatePoseMetrics(Pose pose, String discipline) {
    Map<String, dynamic> metrics = {};

    // Get key landmarks
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

    if (leftShoulder != null && rightShoulder != null && leftHip != null && rightHip != null) {
      final shoulderMidX = (leftShoulder.x + rightShoulder.x) / 2;
      final hipMidX = (leftHip.x + rightHip.x) / 2;
      final bodyAlignment = (shoulderMidX - hipMidX).abs();
      metrics['bodyAlignment'] = bodyAlignment;

      final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
      final hipWidth = (leftHip.x - rightHip.x).abs();
      final streamlineRatio = shoulderWidth / (hipWidth + 0.1);
      metrics['streamlineRatio'] = streamlineRatio;
    }

    if (nose != null && leftShoulder != null && rightShoulder != null) {
      final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
      final headTilt = (nose.y - shoulderMidY).abs();
      metrics['headTilt'] = headTilt;
    }

    if (leftAnkle != null && rightAnkle != null && leftKnee != null && rightKnee != null) {
      final leftLegExtension = _calculateDistance(leftKnee, leftAnkle);
      final rightLegExtension = _calculateDistance(rightKnee, rightAnkle);
      metrics['legExtension'] = (leftLegExtension + rightLegExtension) / 2;

      final legSymmetry = (leftLegExtension - rightLegExtension).abs();
      metrics['legSymmetry'] = legSymmetry;
    }

    if (discipline == 'DYN' || discipline == 'DNF') {
      if (leftAnkle != null && rightAnkle != null) {
        final ankleWidth = (leftAnkle.x - rightAnkle.x).abs();
        metrics['kickWidth'] = ankleWidth;
      }
    } else if (discipline == 'DYNB') {
      if (leftHip != null && rightHip != null && leftKnee != null && rightKnee != null) {
        final hipY = (leftHip.y + rightHip.y) / 2;
        final kneeY = (leftKnee.y + rightKnee.y) / 2;
        final undulationDepth = (hipY - kneeY).abs();
        metrics['undulationDepth'] = undulationDepth;
      }
    }

    return metrics;
  }

  double _calculateDistance(PoseLandmark? point1, PoseLandmark? point2) {
    if (point1 == null || point2 == null) return 0.0;

    final dx = point1.x - point2.x;
    final dy = point1.y - point2.y;
    final dz = point1.z - point2.z;

    return (dx * dx + dy * dy + dz * dz);
  }

  void dispose() {
    _poseDetector.close();
  }
}
