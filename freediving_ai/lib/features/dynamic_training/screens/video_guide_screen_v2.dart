import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_profile.dart';
import '../providers/video_analysis_provider.dart';
import '../../analysis/screens/analysis_result_screen.dart';
import 'camera_screen.dart';

class VideoGuideScreenV2 extends ConsumerWidget {
  final String discipline;
  final String category;

  const VideoGuideScreenV2({
    super.key,
    required this.discipline,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideInfo = _getGuideInfo();
    final analysisState = ref.watch(videoAnalysisProvider);

    // Listen to analysis state changes
    ref.listen<VideoAnalysisStateModel>(
      videoAnalysisProvider,
      (previous, next) {
        if (next.state == AnalysisState.completed && next.result != null) {
          Navigator.of(context).pop(); // Close loading dialog
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AnalysisResultScreen(result: next.result!),
            ),
          );
          // Reset state after navigation
          ref.read(videoAnalysisProvider.notifier).reset();
        } else if (next.state == AnalysisState.error) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${next.error}'),
              backgroundColor: Colors.red,
            ),
          );
          ref.read(videoAnalysisProvider.notifier).reset();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${_formatCategory(category)} Guide'),
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
                // Guide illustration
                _buildGuideIllustration(guideInfo),
                SizedBox(height: 32.h),
                // Camera angle
                _buildInfoCard(
                  'Camera Angle',
                  guideInfo['cameraAngle'],
                  Icons.videocam,
                  AppTheme.primaryBlue,
                ),
                SizedBox(height: 16.h),
                // Distance
                _buildInfoCard(
                  'Distance',
                  guideInfo['distance'],
                  Icons.straighten,
                  AppTheme.primaryPurple,
                ),
                SizedBox(height: 16.h),
                // Tips
                _buildTipsCard(guideInfo['tips']),
                SizedBox(height: 24.h),
                // Action buttons
                _buildActionButtons(context, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideIllustration(Map<String, dynamic> guideInfo) {
    return Container(
      width: double.infinity,
      height: 200.h,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Background
          Center(
            child: Icon(
              guideInfo['illustrationIcon'],
              size: 120.sp,
              color: AppTheme.primaryBlue.withOpacity(0.1),
            ),
          ),
          // Guide text overlay
          Positioned(
            top: 16.h,
            left: 16.w,
            right: 16.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                guideInfo['cameraAngle'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(List<String> tips) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.accentYellow,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Tips',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...tips.map((tip) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 6.h),
                      width: 4.w,
                      height: 4.w,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12.sp,
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

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Record video button
        _buildButton(
          'Record Video',
          Icons.videocam,
          AppTheme.primaryGradient,
          () => _recordVideo(context, ref),
        ),
        SizedBox(height: 12.h),
        // Choose from gallery button
        _buildButton(
          'Choose from Gallery',
          Icons.photo_library,
          null,
          () => _pickFromGallery(context, ref),
          outlined: true,
        ),
        SizedBox(height: 12.h),
        // Skip to demo result button (for testing)
        _buildButton(
          'Skip to Demo Result',
          Icons.skip_next,
          null,
          () => _showDemoResult(context, ref),
          outlined: true,
          isDemoButton: true,
        ),
      ],
    );
  }

  Widget _buildButton(
    String text,
    IconData icon,
    Gradient? gradient,
    VoidCallback onTap, {
    bool outlined = false,
    bool isDemoButton = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          gradient: gradient,
          color: outlined ? null : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(28.r),
          border: outlined
              ? Border.all(
                  color: isDemoButton ? AppTheme.accentYellow : AppTheme.primaryBlue,
                  width: 2,
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isDemoButton ? AppTheme.accentYellow : AppTheme.textPrimary,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              text,
              style: TextStyle(
                color: isDemoButton ? AppTheme.accentYellow : AppTheme.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordVideo(BuildContext context, WidgetRef ref) async {
    try {
      final videoPath = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => CameraScreen(discipline: discipline),
        ),
      );

      if (videoPath != null && context.mounted) {
        await _analyzeVideo(context, ref, videoPath);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery(BuildContext context, WidgetRef ref) async {
    print('🎬 Starting video picker from gallery (using file_picker)...');

    try {
      // Use file_picker which is more stable on iOS simulator
      print('📱 Opening file picker for video selection...');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      print('✅ File picker returned: ${result != null ? "result received" : "null (user cancelled)"}');

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final videoPath = file.path;

        print('📂 File selected: ${file.name}');
        print('📍 Path: $videoPath');
        print('📏 Size: ${file.size} bytes');

        if (videoPath == null || videoPath.isEmpty) {
          print('❌ Invalid video path');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid video file'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (!context.mounted) {
          print('⚠️ Context not mounted after video selection');
          return;
        }

        print('📊 Starting analysis...');
        await _analyzeVideo(context, ref, videoPath);
      } else {
        print('❌ Video selection cancelled or no files selected');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video selection cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ ERROR picking video: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: $stackTrace');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking video: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _analyzeVideo(BuildContext context, WidgetRef ref, String videoPath) async {
    // Get user profile
    final profileBox = Hive.box<UserProfile>('userProfile');
    final profile = profileBox.get('current');

    // Show analyzing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
              SizedBox(height: 24.h),
              Text(
                'Analyzing your technique...',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(videoAnalysisProvider);
                  return Text(
                    '${(state.progress * 100).toInt()}%',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12.sp,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    // Start analysis
    await ref.read(videoAnalysisProvider.notifier).analyzeVideo(
          videoPath: videoPath,
          discipline: discipline,
          category: category,
          profile: profile,
        );
  }

  void _showDemoResult(BuildContext context, WidgetRef ref) {
    // Show demo result without video analysis
    // Use a dummy video path
    _analyzeVideo(context, ref, 'demo_video_path');
  }

  Map<String, dynamic> _getGuideInfo() {
    // Default guide info
    final Map<String, dynamic> defaultInfo = {
      'cameraAngle': 'Side view - Full body',
      'distance': '2-3 meters from camera',
      'tips': [
        'Ensure good lighting',
        'Keep entire body in frame',
        'Film the complete movement',
      ],
      'illustrationIcon': Icons.person,
    };

    // Category-specific guides
    switch (category) {
      case 'streamline':
        return <String, dynamic>{
          ...defaultInfo,
          'cameraAngle': 'Side view - Full body visible',
          'tips': [
            'Film from the side to see body alignment',
            'Include head to feet in frame',
            'Stable camera position',
          ],
        };
      case 'finning':
      case 'dolphin_kick':
        return <String, dynamic>{
          ...defaultInfo,
          'cameraAngle': 'Side view - Lower body focus',
          'distance': '2-3 meters',
          'tips': [
            'Focus on leg and fin movement',
            'Capture multiple fin cycles',
            'Ensure fins are fully visible',
          ],
        };
      case 'arm_stroke':
        return <String, dynamic>{
          ...defaultInfo,
          'cameraAngle': 'Front or above water view',
          'tips': [
            'Capture full arm extension',
            'Film several stroke cycles',
            'Clear view of hand entry and exit',
          ],
        };
      case 'breaststroke_kick':
        return <String, dynamic>{
          ...defaultInfo,
          'cameraAngle': 'Back view - Lower body',
          'tips': [
            'Film from behind to see leg symmetry',
            'Capture complete kick cycle',
            'Include hips and feet',
          ],
        };
      case 'turn':
        return <String, dynamic>{
          ...defaultInfo,
          'cameraAngle': 'Side view at wall',
          'distance': '3-4 meters from wall',
          'tips': [
            'Capture approach and exit',
            'Film the complete turn',
            'Keep wall and swimmer in frame',
          ],
        };
      case 'duck_dive':
      case 'entry':
      case 'start':
        return <String, dynamic>{
          ...defaultInfo,
          'cameraAngle': 'Side view from surface',
          'tips': [
            'Capture surface to underwater transition',
            'Film the initial dive sequence',
            'Include body entry and first few meters',
          ],
        };
      default:
        return defaultInfo;
    }
  }

  String _formatCategory(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
