import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_profile.dart';
import '../providers/video_analysis_provider.dart';
import '../../analysis/screens/analysis_result_screen.dart';

class DNFVideoUploadScreen extends ConsumerWidget {
  const DNFVideoUploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisState = ref.watch(videoAnalysisProvider);

    // Listen for analysis completion
    ref.listen<VideoAnalysisStateModel>(
      videoAnalysisProvider,
      (previous, next) {
        if (next.state == AnalysisState.completed && next.result != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AnalysisResultScreen(result: next.result!),
            ),
          );
        } else if (next.state == AnalysisState.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error ?? 'Analysis failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    // Show analysis in progress
    if (analysisState.state == AnalysisState.analyzing) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80.w,
                  height: 80.h,
                  child: CircularProgressIndicator(
                    value: analysisState.progress,
                    strokeWidth: 6,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Analyzing Video',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '${(analysisState.progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload DNF Video'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'DNF Level Test',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Upload a video to unlock your Official Level',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 24.h),

                // Privacy notice
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
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
                          Icon(
                            Icons.lock_outline,
                            color: AppTheme.primaryBlue,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Your Privacy',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Video is analyzed on-device. Nothing is uploaded to a server.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'If measurement is not possible, we will not score it and we will tell you why.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Requirements card
                _buildRequirementsCard(context),
                SizedBox(height: 32.h),

                // Action buttons
                _buildActionButton(
                  context,
                  ref,
                  title: 'Choose from Gallery',
                  icon: Icons.photo_library,
                  color: AppTheme.primaryBlue,
                  onTap: () => _pickFromGallery(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementsCard(BuildContext context) {
    final requirements = [
      'Side or rear-diagonal view',
      'Full body visible throughout',
      '8-15 seconds of continuous swimming',
      'Good lighting and water clarity',
      'Include at least one complete stroke cycle',
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
              Icon(
                Icons.videocam,
                color: AppTheme.primaryBlue,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Capture Tips',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...requirements.map((req) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: AppTheme.primaryBlue,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        req,
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

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: color,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28.sp),
            SizedBox(width: 12.w),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final videoPath = result.files.first.path;
        if (videoPath != null) {
          // Get user profile for level-based analysis
          final profileBox = Hive.box<UserProfile>('userProfile');
          final profile = profileBox.get('current');

          // Start analysis (DNF uses full clip, category not needed)
          await ref.read(videoAnalysisProvider.notifier).analyzeVideo(
                videoPath: videoPath,
                discipline: 'DNF',
                category: 'full_clip', // Not used by DNFFullAnalyzer
                profile: profile,
              );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
