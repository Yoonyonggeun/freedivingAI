import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/analysis_result.dart';
import '../../../models/user_profile.dart';
import '../../../services/pose_detection_service.dart';
import '../../../services/indoor_analysis_service.dart';
import '../../../services/indoor_analysis_service_v2.dart';
import '../../../services/dnf_full_analyzer.dart';
import '../../../services/video_frame_extractor.dart' show VideoFrameExtractor, VideoMetadata;
import '../../../services/debug_report_service.dart';
import '../../../services/video_preflight_checker.dart';
import '../../../services/drill_recommender.dart';
import '../../../utils/level_calculator.dart';
import 'package:hive/hive.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum AnalysisState {
  idle,
  analyzing,
  completed,
  error,
}

class VideoAnalysisStateModel {
  final AnalysisState state;
  final AnalysisResult? result;
  final String? error;
  final double progress;

  VideoAnalysisStateModel({
    required this.state,
    this.result,
    this.error,
    this.progress = 0.0,
  });

  VideoAnalysisStateModel copyWith({
    AnalysisState? state,
    AnalysisResult? result,
    String? error,
    double? progress,
  }) {
    return VideoAnalysisStateModel(
      state: state ?? this.state,
      result: result,
      error: error ?? this.error,
      progress: progress ?? this.progress,
    );
  }
}

class VideoAnalysisNotifier extends StateNotifier<VideoAnalysisStateModel> {
  VideoAnalysisNotifier() : super(VideoAnalysisStateModel(state: AnalysisState.idle));

  final PoseDetectionService _poseService = PoseDetectionService();
  final IndoorAnalysisService _indoorAnalysis = IndoorAnalysisService();
  final IndoorAnalysisServiceV2 _indoorAnalysisV2 = IndoorAnalysisServiceV2();
  final DNFFullAnalyzer _dnfAnalyzer = DNFFullAnalyzer();
  final VideoFrameExtractor _frameExtractor = VideoFrameExtractor();
  final DebugReportService _debugReportService = DebugReportService();
  final VideoPreflightChecker _preflightChecker = VideoPreflightChecker();

  Future<void> analyzeVideo({
    required String videoPath,
    required String discipline,
    required String category,
    UserProfile? profile,
  }) async {
    state = VideoAnalysisStateModel(state: AnalysisState.analyzing, progress: 0.0);

    try {
      // Step 1: Initialize and validate file size
      state = state.copyWith(progress: 0.1);

      final file = File(videoPath);
      if (await file.exists()) {
        final sizeBytes = await file.length();
        final sizeMB = sizeBytes / (1024 * 1024);
        print('[VideoAnalysis] Video file size: ${sizeMB.toStringAsFixed(1)} MB');
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Step 2: Extract frames and run pose detection with tracking
      state = state.copyWith(progress: 0.2);
      print('[VideoAnalysis] Starting frame extraction from: $videoPath');

      final trackingResult = await _extractAndAnalyzePosesWithTracking(videoPath);
      final detectedPoses = trackingResult.poses;
      final perFrameTracking = trackingResult.perFrameTracking;
      final extractedFrameCount = trackingResult.extractedFrameCount;

      print('[VideoAnalysis] Pose detection complete: ${detectedPoses.length} poses detected');
      state = state.copyWith(progress: 0.6);

      // Step 2.5: Preflight check (DNF only)
      List<String>? preflightWarnings;
      if (discipline == 'DNF') {
        final preflightResult = _preflightChecker.checkVideo(detectedPoses);
        final criticalIssues = List<String>.from(preflightResult['criticalIssues'] ?? []);
        preflightWarnings = List<String>.from(preflightResult['warnings'] ?? []);
        final shouldProceed = preflightResult['shouldProceed'] as bool? ?? true;

        if (criticalIssues.isNotEmpty) {
          print('[VideoAnalysis] Preflight critical: ${criticalIssues.join(', ')}');
        }
        if (preflightWarnings.isNotEmpty) {
          print('[VideoAnalysis] Preflight warnings: ${preflightWarnings.join(', ')}');
        }

        if (!shouldProceed) {
          state = VideoAnalysisStateModel(
            state: AnalysisState.error,
            error: criticalIssues.join('\n'),
          );
          return;
        }
      }

      // Step 3: Analyze poses
      Map<String, dynamic> analysisData;

      if (discipline == 'DNF') {
        print('[VideoAnalysis] Using DNF Full Analyzer');
        analysisData = _dnfAnalyzer.analyzeDNFFull(
          detectedPoses,
          landmarkCoverage: trackingResult.avgLandmarkCoverage,
          signalContinuity: trackingResult.signalContinuity,
        );
      } else if (detectedPoses.isEmpty) {
        analysisData = _indoorAnalysisV2.analyzeIndoorDiscipline(
          poses: [],
          discipline: discipline,
          category: category,
        );
      } else {
        analysisData = _indoorAnalysisV2.analyzeIndoorDiscipline(
          poses: detectedPoses,
          discipline: discipline,
          category: category,
        );
      }

      // Store preflight warnings in analysisData for result generation
      if (preflightWarnings != null && preflightWarnings.isNotEmpty) {
        analysisData['preflightWarnings'] = preflightWarnings;
      }

      state = state.copyWith(progress: 0.7);
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 4: Generate debug report
      final warnings = <String>[];
      if (_poseService.trackSwitchCount > 2) {
        warnings.add(
          'Multiple people detected in some frames; analysis may be unstable '
          '(track switches: ${_poseService.trackSwitchCount})',
        );
      }

      final durationSec = extractedFrameCount / 5.0; // At 5fps
      final analysisQualityConfidence =
          analysisData['analysisQualityConfidence'] as double? ?? 0.0;

      // Build quality breakdown if available from metadata
      Map<String, dynamic>? qualityBreakdown;
      final metadata = analysisData['metadata'] as Map<String, dynamic>?;
      if (metadata != null) {
        qualityBreakdown = {
          'frameScore': metadata['validFrameRatio'] ?? 0.0,
          'durationScore': metadata['travelDurationSec'] != null
              ? ((metadata['travelDurationSec'] as double) / 6.0).clamp(0.0, 1.0)
              : 0.0,
          'kickScore': metadata['kickCycles'] != null
              ? ((metadata['kickCycles'] as int) / 3.0).clamp(0.0, 1.0)
              : 0.0,
        };
      }

      final classificationResult = {
        'classification': analysisData['classification'] ?? 'UNKNOWN',
        'confidence': analysisData['classificationConfidence'] ?? 0.0,
        'scores': analysisData['classificationScores'] ?? {},
        'ruleTrace': analysisData['classificationRuleTrace'] as List<Map<String, dynamic>>? ?? [],
        'featureValues': analysisData['classificationFeatureValues'] as Map<String, dynamic>? ?? {},
      };

      // Extract phase segments for debug report
      final phaseSegments = (analysisData['phases'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>();

      final debugReport = _debugReportService.generateReport(
        videoPath: videoPath,
        durationSec: durationSec,
        totalFrames: detectedPoses.length,
        extractedFrames: extractedFrameCount,
        validPoseFrames: detectedPoses.length,
        perFrameTracking: perFrameTracking,
        classificationResult: classificationResult,
        analysisQualityConfidence: analysisQualityConfidence,
        analysisQualityBreakdown: qualityBreakdown,
        warnings: warnings,
        videoMetadata: trackingResult.videoMetadata,
        landmarkCoverageStats: trackingResult.landmarkCoverageStats,
        rotationInfo: trackingResult.rotationInfo,
        phaseSegments: phaseSegments,
      );

      // Print debug report to console
      _debugReportService.printReport(debugReport);

      // Store debug report in analysisData
      analysisData['debugReport'] = debugReport;

      // Step 5: Apply level modifiers and generate final result
      final result = _generateAnalysisResultWithData(
        videoPath: videoPath,
        discipline: discipline,
        category: category,
        profile: profile,
        analysisData: analysisData,
      );

      state = state.copyWith(progress: 0.9);
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 6: Save to Hive
      final box = Hive.box<AnalysisResult>('analysisResults');
      await box.add(result);

      // Step 7: Cleanup temp frames
      await _frameExtractor.cleanup();
      print('[VideoAnalysis] Temp frames cleaned up');

      // Complete
      state = VideoAnalysisStateModel(
        state: AnalysisState.completed,
        result: result,
        progress: 1.0,
      );
    } catch (e) {
      await _frameExtractor.cleanup();

      state = VideoAnalysisStateModel(
        state: AnalysisState.error,
        error: e.toString(),
      );
    }
  }

  AnalysisResult _generateAnalysisResultWithData({
    required String videoPath,
    required String discipline,
    required String category,
    UserProfile? profile,
    required Map<String, dynamic> analysisData,
  }) {
    // Get level modifier
    double levelModifier = 1.0;
    bool isBeginner = false;
    bool isElite = false;

    if (profile != null) {
      switch (profile.diverLevel) {
        case 'beginner':
          levelModifier = 0.85;
          isBeginner = true;
          break;
        case 'intermediate':
          levelModifier = 0.95;
          break;
        case 'advanced':
          levelModifier = 1.05;
          break;
        case 'elite':
          levelModifier = 1.15;
          isElite = true;
          break;
      }
    }

    // Get scores from analysis data and apply level modifier
    Map<String, double> categoryScores;
    List<String> strengths;
    List<String> improvements;
    List<String> drills;

    // Handle DNF Full Analyzer output format
    if (discipline == 'DNF' && analysisData.containsKey('coaching')) {
      final coaching = analysisData['coaching'] as Map<String, dynamic>;
      final metrics = analysisData['metrics'] as Map<String, dynamic>;

      categoryScores = {};
      for (final entry in metrics.entries) {
        if (entry.value is Map<String, dynamic>) {
          final metricData = entry.value as Map<String, dynamic>;
          if (metricData.containsKey('overall')) {
            categoryScores[entry.key] = metricData['overall'] as double;
          }
        }
      }

      strengths = List<String>.from(coaching['strengths'] ?? []);
      improvements = List<String>.from(coaching['improvements'] ?? []);

      // Use DrillRecommender instead of coaching['drills']
      final overallScore = analysisData['overallScore'] as double? ?? 0.0;
      final confidence = analysisData['analysisQualityConfidence'] as double? ?? 0.0;
      final classification = analysisData['classification'] as String? ?? 'UNKNOWN';
      final topIssues = List<String>.from(coaching['improvements'] ?? []);

      // Calculate provisional level from PB (default to 1 if no profile)
      final pbDistance = profile?.personalBests['DNF'];
      final provisionalLevel = (pbDistance != null)
          ? LevelCalculator.calculateProvisionalLevel(pbDistance)
          : (profile?.provisionalLevel ?? 1);

      // Calculate official level
      final officialLevel = LevelCalculator.calculateOfficialLevel(
        provisionalLevel: provisionalLevel,
        techniqueScore: overallScore,
        confidence: confidence,
        classification: classification,
      );

      drills = DrillRecommender.getDrills(
        officialLevel: officialLevel,
        provisionalLevel: provisionalLevel,
        confidence: confidence,
        topIssues: topIssues,
        analysisMode: analysisData['analysisMode'] as String?,
      );

      final warnings = List<String>.from(coaching['warnings'] ?? []);
      improvements.addAll(warnings);
    } else {
      categoryScores = Map<String, double>.from(
        analysisData['categoryScores'] as Map<String, dynamic>
      );
      strengths = List<String>.from(analysisData['strengths']);
      improvements = List<String>.from(analysisData['improvements']);
      drills = _getDrills(discipline, isBeginner, isElite);
    }

    // Add preflight warnings to improvements with [Video Quality] prefix
    final preflightWarnings = analysisData['preflightWarnings'] as List<String>?;
    if (preflightWarnings != null) {
      for (final warning in preflightWarnings) {
        improvements.add('[Video Quality] $warning');
      }
    }

    // Apply level modifier to scores
    categoryScores = categoryScores.map((key, value) => MapEntry(
      key,
      (value * levelModifier).clamp(0, 100),
    ));

    double overallScore = analysisData['overallScore'] as double;
    overallScore = (overallScore * levelModifier).clamp(0, 100);

    if (isBeginner && strengths.isNotEmpty) {
      strengths[0] = '${strengths[0]} - great for your level!';
    } else if (isElite && strengths.isNotEmpty) {
      strengths[0] = '${strengths[0]} - competition ready';
    }

    return AnalysisResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: profile?.id ?? 'default',
      discipline: discipline,
      videoPath: videoPath,
      category: category,
      overallScore: overallScore,
      categoryScores: categoryScores,
      strengths: strengths,
      improvements: improvements,
      drillRecommendations: drills,
      poseData: discipline == 'DNF' ? analysisData : analysisData['v2Data'] as Map<String, dynamic>?,
      createdAt: DateTime.now(),
    );
  }

  Map<String, double> _getCategoryScores(String discipline, double levelModifier) {
    Map<String, double> baseScores = {};

    if (discipline == 'DYN' || discipline == 'DNF') {
      baseScores = {
        'Streamline': 75.0,
        'Kick Technique': 82.0,
        'Body Position': 78.0,
        'Glide': 70.0,
        'Turn': 85.0,
      };
    } else if (discipline == 'DYNB') {
      baseScores = {
        'Undulation': 80.0,
        'Head Position': 72.0,
        'Arm Movement': 85.0,
        'Body Wave': 78.0,
        'Rhythm': 88.0,
      };
    }

    return baseScores.map((key, value) => MapEntry(
      key,
      (value * levelModifier).clamp(0, 100),
    ));
  }

  List<String> _getStrengths(String discipline, bool isBeginner, bool isElite) {
    String levelContext = '';
    if (isBeginner) {
      levelContext = ' - excellent for your level!';
    } else if (isElite) {
      levelContext = ' - competition ready';
    }

    if (discipline == 'DYN' || discipline == 'DNF') {
      return [
        'Strong kick technique$levelContext',
        'Good turn execution',
        'Consistent rhythm maintained',
      ];
    } else {
      return [
        'Smooth undulation$levelContext',
        'Excellent arm coordination',
        'Great body wave timing',
      ];
    }
  }

  List<String> _getImprovements(String discipline, bool isBeginner, bool isElite) {
    if (isBeginner) {
      if (discipline == 'DYN' || discipline == 'DNF') {
        return [
          'Great start! Try to keep your body more streamlined',
          'Practice extending your glide phase',
          'Work on pointing your toes more',
        ];
      } else {
        return [
          'Good effort! Focus on keeping your head neutral',
          'Try to make your undulation more fluid',
          'Practice the arm pull timing',
        ];
      }
    } else if (isElite) {
      if (discipline == 'DYN' || discipline == 'DNF') {
        return [
          'Micro-adjustment: slight hip drop detected at 12s',
          'Consider tighter streamline on push-off',
          'Optimize turn rotation speed',
        ];
      } else {
        return [
          'Minor head lift at breathing point',
          'Refine undulation amplitude consistency',
          'Fine-tune arm recovery timing',
        ];
      }
    } else {
      if (discipline == 'DYN' || discipline == 'DNF') {
        return [
          'Improve streamline position',
          'Extend glide phase between kicks',
          'Work on turn efficiency',
        ];
      } else {
        return [
          'Keep head more neutral',
          'Increase undulation depth',
          'Smooth out arm transitions',
        ];
      }
    }
  }

  List<String> _getDrills(String discipline, bool isBeginner, bool isElite) {
    if (isBeginner) {
      if (discipline == 'DYN' || discipline == 'DNF') {
        return [
          'Streamline hold (10 seconds, 3 sets)',
          'Single kick + glide (25m, 4 reps)',
          'Wall push-off practice (10 reps)',
        ];
      } else {
        return [
          'Underwater undulation (15 seconds, 3 sets)',
          'Surface body wave (50m, 3 reps)',
          'Arm timing drill (25m, 4 reps)',
        ];
      }
    } else if (isElite) {
      if (discipline == 'DYN' || discipline == 'DNF') {
        return [
          'Variable tempo training (75m, 5 reps)',
          'Turn + sprint intervals (15s work, 45s rest, 8 sets)',
          'Streamline resistance training (50m, 4 reps with band)',
        ];
      } else {
        return [
          'High-frequency undulation (50m, 5 reps)',
          'Competition pace simulation (full pool, 3 reps)',
          'Power undulation with resistance (25m, 6 reps)',
        ];
      }
    } else {
      if (discipline == 'DYN' || discipline == 'DNF') {
        return [
          'Streamline + 3 kicks (50m, 4 reps)',
          'Turn practice with glide (10 turns)',
          'Kick tempo drill (25m slow, 25m fast, 4 sets)',
        ];
      } else {
        return [
          'Body wave progression (50m, 4 reps)',
          'Arm coordination drill (25m, 6 reps)',
          'Full stroke with focus on rhythm (75m, 3 reps)',
        ];
      }
    }
  }

  /// Derive InputImageRotation from rotation degrees.
  InputImageRotation? _rotationFromDegrees(int degrees) {
    switch (degrees) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return null;
    }
  }

  /// Extract frames from video, run pose detection with multi-pose tracking.
  Future<_PoseTrackingResult> _extractAndAnalyzePosesWithTracking(String videoPath) async {
    final List<Pose> poses = [];
    final List<Map<String, dynamic>> perFrameTracking = [];

    // Reset tracking state for new video
    _poseService.resetTracking();

    try {
      print('[VideoAnalysis] Extracting frames at 5 fps...');
      final extractionResult = await _frameExtractor.extractFrames(
        videoPath,
        fps: 5,
        scale: '720:-2',
        quality: 4,
      );

      final framePaths = extractionResult.framePaths;
      final videoMetadata = extractionResult.metadata;
      final framesExtracted = framePaths.length;
      print('[VideoAnalysis] Extracted $framesExtracted frames');

      // Derive rotation for ML Kit
      final rotation = _rotationFromDegrees(videoMetadata.rotationDegrees);

      int validPoses = 0;
      double totalInferenceMs = 0;
      double totalLandmarkCoverage = 0;
      final perKeypointCounts = <String, int>{};
      int landmarkFrames = 0;

      for (int i = 0; i < framePaths.length; i++) {
        final framePath = framePaths[i];
        final frameTime = i / 5.0;

        try {
          final inputImage = InputImage.fromFilePath(framePath);
          final result = await _poseService.detectPoseFromImageWithTracking(
            inputImage,
            rotation: rotation,
          );

          // Store tracking data
          perFrameTracking.add(result.toTrackingMap(frameTime));

          // Accumulate inference and coverage stats
          totalInferenceMs += result.inferenceMs;
          if (result.pose != null) {
            poses.add(result.pose!);
            validPoses++;
            totalLandmarkCoverage += result.landmarkCoverage;
            landmarkFrames++;

            for (final entry in result.keypointPresence.entries) {
              perKeypointCounts[entry.key] = (perKeypointCounts[entry.key] ?? 0) + (entry.value ? 1 : 0);
            }
          }

          // Update progress periodically
          if ((i + 1) % 10 == 0) {
            final progress = 0.2 + (0.4 * (i + 1) / framePaths.length);
            state = state.copyWith(progress: progress);
          }
        } catch (e) {
          print('[VideoAnalysis] Pose detection failed for frame $i: $e');
          perFrameTracking.add({
            'frameTime': frameTime,
            'detectedPoseCount': 0,
            'selectionMethod': 'error',
            'poseConfidence': 0.0,
            'inferenceMs': 0,
            'landmarkCoverage': 0.0,
          });
        }
      }

      final validFrameRate = framesExtracted > 0 ? validPoses / framesExtracted : 0.0;
      final avgLandmarkCoverage = landmarkFrames > 0 ? totalLandmarkCoverage / landmarkFrames : 0.0;
      final signalContinuity = framesExtracted > 0 ? validPoses / framesExtracted : 0.0;

      // Per-keypoint presence rates
      final perKeypointPresence = <String, double>{};
      String? worstKeypoint;
      double worstRate = 1.0;
      for (final entry in perKeypointCounts.entries) {
        final rate = landmarkFrames > 0 ? entry.value / landmarkFrames : 0.0;
        perKeypointPresence[entry.key] = rate;
        if (rate < worstRate) {
          worstRate = rate;
          worstKeypoint = entry.key;
        }
      }

      final landmarkCoverageStats = <String, dynamic>{
        'averageCoverage': avgLandmarkCoverage,
        'perKeypointPresence': perKeypointPresence,
        'worstKeypoint': worstKeypoint ?? 'unknown',
        'worstKeypointRate': worstRate,
      };

      final rotationInfo = <String, dynamic>{
        'videoRotationDegrees': videoMetadata.rotationDegrees,
        'frameOrientation': videoMetadata.width > videoMetadata.height ? 'landscape' : 'portrait',
        'mlKitRotationApplied': rotation?.name ?? 'rotation0',
      };

      print('[VideoAnalysis] Valid frame rate: ${(validFrameRate * 100).toStringAsFixed(1)}% '
          '($validPoses/$framesExtracted)');
      print('[VideoAnalysis] Avg landmark coverage: ${(avgLandmarkCoverage * 100).toStringAsFixed(1)}%');
      print('[VideoAnalysis] Track switches: ${_poseService.trackSwitchCount}');

      if (validFrameRate < 0.5 && framesExtracted > 0) {
        print('[VideoAnalysis] WARNING: Low valid frame rate.');
      }

      if (_poseService.trackSwitchCount > 2) {
        print('[VideoAnalysis] WARNING: Multiple track switches detected '
            '(${_poseService.trackSwitchCount}). Analysis may be unstable.');
      }

      return _PoseTrackingResult(
        poses: poses,
        perFrameTracking: perFrameTracking,
        extractedFrameCount: framesExtracted,
        videoMetadata: videoMetadata,
        landmarkCoverageStats: landmarkCoverageStats,
        rotationInfo: rotationInfo,
        avgLandmarkCoverage: avgLandmarkCoverage,
        signalContinuity: signalContinuity,
      );
    } catch (e) {
      print('[VideoAnalysis] Frame extraction/pose detection error: $e');
      rethrow;
    }
  }

  void reset() {
    state = VideoAnalysisStateModel(state: AnalysisState.idle);
  }

  @override
  void dispose() {
    _poseService.dispose();
    super.dispose();
  }
}

/// Internal result holder for pose extraction with tracking.
class _PoseTrackingResult {
  final List<Pose> poses;
  final List<Map<String, dynamic>> perFrameTracking;
  final int extractedFrameCount;
  final VideoMetadata? videoMetadata;
  final Map<String, dynamic>? landmarkCoverageStats;
  final Map<String, dynamic>? rotationInfo;
  final double avgLandmarkCoverage;
  final double signalContinuity;

  _PoseTrackingResult({
    required this.poses,
    required this.perFrameTracking,
    required this.extractedFrameCount,
    this.videoMetadata,
    this.landmarkCoverageStats,
    this.rotationInfo,
    this.avgLandmarkCoverage = 0.0,
    this.signalContinuity = 0.0,
  });
}

final videoAnalysisProvider = StateNotifierProvider<VideoAnalysisNotifier, VideoAnalysisStateModel>((ref) {
  return VideoAnalysisNotifier();
});
