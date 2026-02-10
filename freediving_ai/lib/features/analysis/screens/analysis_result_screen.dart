import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/analysis_result.dart';
import '../../../models/user_profile.dart';
import '../../../utils/level_calculator.dart';
import 'package:video_player/video_player.dart';

class AnalysisResultScreen extends StatefulWidget {
  final AnalysisResult result;

  const AnalysisResultScreen({
    super.key,
    required this.result,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    // TODO: Initialize with actual video path
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  // Helper getters to extract data from poseData
  String get _classification {
    return widget.result.poseData?['classification'] as String? ?? 'UNKNOWN';
  }

  double get _classificationConfidence {
    return widget.result.poseData?['classificationConfidence'] as double? ?? 0.0;
  }

  String get _classificationReason {
    return widget.result.poseData?['classificationReason'] as String? ?? 'No classification data available';
  }

  double get _analysisQualityConfidence {
    return widget.result.poseData?['analysisQualityConfidence'] as double? ?? 0.0;
  }

  Map<String, dynamic>? get _analysisMode {
    return widget.result.poseData?['analysisMode'] as Map<String, dynamic>?;
  }

  bool get _isLevelTestEligible {
    return _analysisMode?['levelTestEligible'] as bool? ?? false;
  }

  List<String> get _detectedActivities {
    final activities = widget.result.poseData?['detectedActivities'];
    if (activities is List) {
      return activities.cast<String>();
    }
    return <String>[];
  }

  Map<String, dynamic>? get _metrics {
    return widget.result.poseData?['metrics'] as Map<String, dynamic>?;
  }

  /// Whether the detected classification matches the requested discipline.
  bool get _classificationMatchesDiscipline {
    return _classification == widget.result.discipline ||
           _classification == 'UNKNOWN';
  }

  int? get _officialLevel {
    final profile = Hive.box<UserProfile>('userProfile').get('current');
    if (profile?.provisionalLevel == null) return null;
    if (!_isLevelTestEligible) return null;

    final techniqueScore = widget.result.overallScore;

    return LevelCalculator.calculateOfficialLevel(
      provisionalLevel: profile!.provisionalLevel!,
      techniqueScore: techniqueScore,
      confidence: _analysisQualityConfidence,
      classification: _classification,
      levelTestEligible: _isLevelTestEligible,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share results
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: ListView(
          padding: EdgeInsets.all(20.w),
          children: [
            // 1. Detected Activity
            if (_detectedActivities.isNotEmpty) ...[
              _buildDetectedActivityCard(),
              SizedBox(height: 16.h),
            ],

            // 2. Analysis Mode Badge
            _buildAnalysisModeBadge(),
            SizedBox(height: 16.h),

            // 3. Classification Card (always shown)
            _buildClassificationCard(),
            SizedBox(height: 16.h),

            // 4. Dual Confidence Badges
            _buildDualConfidenceBadges(),
            SizedBox(height: 16.h),

            // 5. Classification Mismatch Warning
            if (!_classificationMatchesDiscipline) ...[
              _buildClassificationMismatchCard(),
              SizedBox(height: 16.h),
            ],

            // === GATED CONTENT: Only show scores/drills if classification matches ===
            if (_classificationMatchesDiscipline) ...[
              // 6. Overall Score (only if quality confidence >= 0.35)
              if (_analysisQualityConfidence >= 0.35) ...[
                _buildOverallScore(),
                SizedBox(height: 16.h),
              ],

              // 7. Official Level Card (only if level test eligible)
              if (_isLevelTestEligible) ...[
                _buildOfficialLevelCard(),
                SizedBox(height: 24.h),
              ],

              // Content gated by analysisQualityConfidence
              if (_analysisQualityConfidence >= 0.35) ...[
                // 8. What We Measured
                _buildMeasuredSection(widget.result),
                SizedBox(height: 16.h),

                // 9. Not Available section
                _buildNotAvailableSection(),
                SizedBox(height: 24.h),

                // Category Scores
                _buildCategoryScores(),
                SizedBox(height: 24.h),
              ] else if (_analysisQualityConfidence >= 0.20) ...[
                // Partial data — show what we measured but warn
                _buildMeasuredSection(widget.result),
                SizedBox(height: 16.h),
                _buildNotAvailableSection(),
                SizedBox(height: 24.h),
              ] else ...[
                _buildLowConfidenceMessage(),
                SizedBox(height: 24.h),
              ],

              // 10. Drills (only if from measured defects)
              if (widget.result.drillRecommendations.isNotEmpty) ...[
                _buildDrillsSection(),
                SizedBox(height: 24.h),
              ],

              // 11. Strengths / Improvements
              if (widget.result.strengths.isNotEmpty) ...[
                _buildSection(
                  'Strengths',
                  widget.result.strengths,
                  Icons.thumb_up,
                  AppTheme.primaryPurple,
                ),
                SizedBox(height: 24.h),
              ],
              if (widget.result.improvements.isNotEmpty) ...[
                _buildSection(
                  'Areas for Improvement',
                  widget.result.improvements,
                  Icons.trending_up,
                  AppTheme.accentYellow,
                ),
                SizedBox(height: 24.h),
              ],
            ] else ...[
              // Classification mismatch — show filming tips only
              _buildFilmingTipsCard(),
              SizedBox(height: 24.h),
            ],

            // Action Buttons (always shown)
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // NEW: Classification Mismatch Card
  // =========================================================================

  Widget _buildClassificationMismatchCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.orange.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Discipline Mismatch',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'This video does not appear to be ${widget.result.discipline}.',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Detected: $_classification',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _classificationReason,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            '${widget.result.discipline} scores and drills are hidden because the detected activity does not match.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13.sp,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // NEW: Dual Confidence Badges
  // =========================================================================

  Widget _buildDualConfidenceBadges() {
    return Row(
      children: [
        Expanded(child: _buildClassificationConfidenceBadge()),
        SizedBox(width: 8.w),
        Expanded(child: _buildAnalysisQualityBadge()),
      ],
    );
  }

  Widget _buildClassificationConfidenceBadge() {
    final confidence = _classificationConfidence;
    final confColor = confidence >= 0.60
        ? Colors.green
        : confidence >= 0.35
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: confColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: confColor.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          Text(
            'Classification',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '$_classification (${(confidence * 100).toStringAsFixed(0)}%)',
            style: TextStyle(
              color: confColor,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisQualityBadge() {
    final confidence = _analysisQualityConfidence;
    final confLevel = confidence >= 0.60
        ? 'High'
        : confidence >= 0.35
            ? 'Moderate'
            : 'Low';
    final confColor = confidence >= 0.60
        ? Colors.green
        : confidence >= 0.35
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: confColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: confColor.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          Text(
            'Analysis Quality',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '$confLevel (${(confidence * 100).toStringAsFixed(0)}%)',
            style: TextStyle(
              color: confColor,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // NEW: Filming Tips Card (shown when classification doesn't match)
  // =========================================================================

  Widget _buildFilmingTipsCard() {
    final tips = [
      'Ensure you are performing ${widget.result.discipline} in the video',
      'Film from a side angle with full body visible',
      'Ensure good lighting and water clarity',
      'Keep the camera stable during recording',
      'Include at least 3 complete movement cycles',
    ];

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppTheme.primaryBlue, size: 24.sp),
              SizedBox(width: 12.w),
              Text(
                'Filming Tips',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...tips.map((tip) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, color: AppTheme.primaryBlue, size: 18.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // =========================================================================
  // Existing Widgets (preserved with minor updates)
  // =========================================================================

  Widget _buildOverallScore() {
    // If analysis quality is too low, show "Measurement Unavailable" instead
    if (_analysisQualityConfidence < 0.35) {
      return Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppTheme.textSecondary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.do_not_disturb, color: AppTheme.textSecondary, size: 48.sp),
            SizedBox(height: 12.h),
            Text(
              'Measurement Unavailable',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Analysis quality too low to generate reliable scores',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.3),
            AppTheme.primaryPurple.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Overall Score',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120.w,
                height: 120.w,
                child: CircularProgressIndicator(
                  value: widget.result.overallScore / 100,
                  strokeWidth: 12.w,
                  backgroundColor: AppTheme.surfaceDark,
                  valueColor: AlwaysStoppedAnimation(
                    _getScoreColor(widget.result.overallScore),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.result.overallScore.toInt()}',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 48.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getScoreLabel(widget.result.overallScore),
                    style: TextStyle(
                      color: _getScoreColor(widget.result.overallScore),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            '${widget.result.discipline} - ${_formatCategory(widget.result.category)}',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryScores() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Scores',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          ...widget.result.categoryScores.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: _buildScoreBar(
                _formatCategory(entry.key),
                entry.value,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, double score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14.sp,
              ),
            ),
            Text(
              '${score.toInt()}%',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Stack(
          children: [
            Container(
              height: 8.h,
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            FractionallySizedBox(
              widthFactor: score / 100,
              child: Container(
                height: 8.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getScoreColor(score),
                      _getScoreColor(score).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...items.map((item) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 6.h),
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDrillsSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, color: AppTheme.accentPink, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Recommended Drills',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...widget.result.drillRecommendations.map((drill) {
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppTheme.accentPink.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    color: AppTheme.accentPink,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      drill,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryBlue,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Automatically Saved to History',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        _buildButton(
          'Analyze Another Video',
          Icons.videocam,
          AppTheme.primaryPurple,
          () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ],
    );
  }

  Widget _buildButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isUncertainClassification {
    return widget.result.poseData?['uncertainClassification'] as bool? ?? false;
  }

  Map<String, dynamic>? get _classificationScores {
    return widget.result.poseData?['classificationScores'] as Map<String, dynamic>?;
  }

  Widget _buildClassificationCard() {
    IconData icon;
    Color color;
    String title;

    // DYNB uncertain label
    final dynbScore = _classificationScores?['DYNB'] as double? ?? 0.0;
    final isUncertainDYNB = _classification == 'DYNB' && (dynbScore < 0.5 || _isUncertainClassification);

    switch (_classification) {
      case 'DNF':
        icon = Icons.check_circle;
        color = Colors.green;
        title = 'DNF Confirmed';
        break;
      case 'DYN':
        icon = Icons.warning;
        color = Colors.orange;
        title = 'Looks like DYN (Fins)';
        break;
      case 'DYNB':
        icon = isUncertainDYNB ? Icons.help_outline : Icons.warning;
        color = isUncertainDYNB ? Colors.amber : Colors.orange;
        title = isUncertainDYNB ? 'Fins Status Uncertain' : 'Looks like DYNB (Bi-Fins)';
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
        title = 'Unrelated Activity';
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _classificationReason,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13.sp,
                  ),
                ),
                if (!_classificationMatchesDiscipline) ...[
                  SizedBox(height: 4.h),
                  Text(
                    '${widget.result.discipline} analysis not applicable',
                    style: TextStyle(
                      color: Colors.orange.withOpacity(0.8),
                      fontSize: 12.sp,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialLevelCard() {
    final profile = Hive.box<UserProfile>('userProfile').get('current');
    final provisionalLevel = profile?.provisionalLevel;
    final officialLevel = _officialLevel;

    if (officialLevel != null) {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryBlue.withOpacity(0.3),
              AppTheme.primaryPurple.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: AppTheme.accentYellow, size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  'Official Level Unlocked!',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $officialLevel',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      LevelCalculator.getLevelName(officialLevel),
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (provisionalLevel != null && officialLevel != provisionalLevel)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppTheme.accentYellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      officialLevel > provisionalLevel ? '+${officialLevel - provisionalLevel} Level!' : '${officialLevel - provisionalLevel} Level',
                      style: TextStyle(
                        color: AppTheme.accentYellow,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'Based on: PB + ${widget.result.overallScore.toStringAsFixed(0)}% technique score',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      );
    } else {
      final modeFailedReqs = (_analysisMode?['failedRequirements'] as List?)?.cast<String>() ?? [];
      final reasons = LevelCalculator.getOfficialLevelNotAssignedReasons(
        confidence: _analysisQualityConfidence,
        classification: _classification,
        techniqueScore: widget.result.overallScore,
        levelTestEligible: _isLevelTestEligible,
        failedRequirements: modeFailedReqs,
      );

      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppTheme.textSecondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.textSecondary, size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  'Official Level Not Assigned',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ...reasons.map((reason) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, color: AppTheme.textSecondary, size: 6.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      reason,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            if (provisionalLevel != null) ...[
              SizedBox(height: 12.h),
              Text(
                'Your Provisional Level: $provisionalLevel (${LevelCalculator.getLevelName(provisionalLevel)})',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      );
    }
  }

  Widget _buildLowConfidenceMessage() {
    final failedReqs = (_analysisMode?['failedRequirements'] as List?)?.cast<String>() ?? [];
    final stats = _analysisMode?['stats'] as Map<String, dynamic>?;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 24.sp),
              SizedBox(width: 12.w),
              Text(
                'Measurement Unavailable',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Analysis quality: ${(_analysisQualityConfidence * 100).toStringAsFixed(0)}% (need >= 20%)',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14.sp,
            ),
          ),
          if (stats != null) ...[
            SizedBox(height: 8.h),
            Text(
              'Valid frames: ${((stats['validFrameRatio'] as double? ?? 0) * 100).toStringAsFixed(0)}% '
              '| Travel: ${(stats['travelDuration'] as double? ?? 0).toStringAsFixed(1)}s '
              '| Kicks: ${stats['kickCycles'] ?? 0}',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
            ),
          ],
          if (failedReqs.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Text(
              'Issues detected:',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            ...failedReqs.map((req) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.close, color: Colors.red, size: 18.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      req,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          SizedBox(height: 16.h),
          Text(
            'How to improve:',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          ...[
            'Ensure full body is visible throughout',
            'Film from side angle',
            'Good lighting and water clarity',
            'Include at least 3 complete kick cycles',
            'Minimum 8-15 seconds of continuous swimming',
          ].map((tip) => Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, color: AppTheme.primaryBlue, size: 18.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDetectedActivityCard() {
    final activityLabels = {
      'ARM_STROKE': 'Arm Stroke',
      'BREAST_KICK': 'Breaststroke Kick',
      'GLIDE': 'Glide',
    };

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detected Activity',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _detectedActivities.map((activity) {
              final label = activityLabels[activity] ?? activity;
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisModeBadge() {
    final isLevelTest = _analysisMode?['mode'] == 'LEVEL_TEST';
    final color = isLevelTest ? Colors.green : Colors.blue;
    final label = isLevelTest ? 'DNF Level Test' : 'Quick Feedback';
    final icon = isLevelTest ? Icons.verified : Icons.flash_on;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotAvailableSection() {
    final metrics = _metrics;
    if (metrics == null) return const SizedBox.shrink();

    final unavailable = <MapEntry<String, Map<String, dynamic>>>[];
    for (final key in ['streamline', 'kick', 'arm', 'glide']) {
      if (metrics.containsKey(key)) {
        final cat = metrics[key] as Map<String, dynamic>;
        if (cat['status'] == 'NOT_AVAILABLE' || cat['status'] == 'DETECTION_FAILED') {
          unavailable.add(MapEntry(key, cat));
        }
      }
    }

    if (unavailable.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Not Available',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppTheme.textSecondary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: unavailable.map((entry) {
              final name = _formatCategory(entry.key);
              final reasons = (entry.value['reasons'] as List?)?.cast<String>() ?? [];
              final requirements = (entry.value['requirements'] as List?)?.cast<String>() ?? [];
              // Use glide-specific reason if available
              final glideReason = entry.value['reason'] as String?;
              final displayReasons = entry.key == 'glide' && glideReason != null
                  ? [glideReason]
                  : reasons;
              final label = entry.key == 'glide' && entry.value['status'] == 'DETECTION_FAILED'
                  ? '$name — Not Available'
                  : name;

              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.block, color: AppTheme.textSecondary, size: 18.sp),
                        SizedBox(width: 8.w),
                        Text(
                          label,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    ...displayReasons.map((r) => Padding(
                      padding: EdgeInsets.only(left: 26.w, top: 4.h),
                      child: Text(
                        r,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                    )),
                    ...requirements.map((r) => Padding(
                      padding: EdgeInsets.only(left: 26.w, top: 4.h),
                      child: Text(
                        r,
                        style: TextStyle(
                          color: AppTheme.primaryBlue.withOpacity(0.7),
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasuredSection(AnalysisResult result) {
    final metrics = _metrics;

    final available = <MapEntry<String, Map<String, dynamic>>>[];
    if (metrics != null) {
      for (final key in ['streamline', 'kick', 'arm', 'glide']) {
        if (metrics.containsKey(key)) {
          final cat = metrics[key] as Map<String, dynamic>;
          if (cat['status'] == 'AVAILABLE') {
            available.add(MapEntry(key, cat));
          }
          // Also show MEASURED_ZERO glide under measured
          if (key == 'glide' && cat['status'] == 'MEASURED_ZERO') {
            available.add(MapEntry(key, cat));
          }
        }
      }
    }

    if (available.isEmpty && metrics == null) {
      final validMetrics = result.categoryScores.entries
          .where((e) => e.value > 0)
          .toList();
      if (validMetrics.isEmpty) return const SizedBox.shrink();
      // Fallback: wrap in simple map
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What We Measured',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: validMetrics.map((m) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: 20.sp),
                    SizedBox(width: 12.w),
                    Expanded(child: Text(_formatCategory(m.key), style: TextStyle(color: AppTheme.textPrimary, fontSize: 14.sp))),
                    Text('${m.value.toInt()}%', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 14.sp, fontWeight: FontWeight.w600)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      );
    }

    if (available.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What We Measured',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            children: available.map((metric) {
              final cat = metric.value;
              final score = cat['overall'] as double? ?? 0.0;
              final confidenceLevel = cat['confidenceLevel'] as String? ?? '';
              final measurementBasis = cat['measurementBasis'] as Map<String, dynamic>?;
              final frameCount = measurementBasis?['frameCount'] as int? ?? 0;
              final isGlideMeasuredZero = metric.key == 'glide' && cat['status'] == 'MEASURED_ZERO';

              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryBlue,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            _formatCategory(metric.key),
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        Text(
                          isGlideMeasuredZero
                              ? '0%'
                              : '${score.toInt()}%',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    // Evidence basis line
                    Padding(
                      padding: EdgeInsets.only(left: 32.w, top: 2.h),
                      child: Text(
                        isGlideMeasuredZero
                            ? 'No glide phase detected'
                            : '$confidenceLevel confidence | $frameCount frames',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }


  Color _getScoreColor(double score) {
    if (score >= 80) return AppTheme.primaryPurple;
    if (score >= 60) return AppTheme.primaryBlue;
    if (score >= 40) return AppTheme.accentYellow;
    return AppTheme.accentPink;
  }

  String _getScoreLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Work';
  }

  String _formatCategory(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
