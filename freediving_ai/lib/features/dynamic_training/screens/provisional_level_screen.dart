import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/level_calculator.dart';
import 'dnf_video_upload_screen.dart';

class ProvisionalLevelScreen extends StatelessWidget {
  final int provisionalLevel;
  final double pbDistance;

  const ProvisionalLevelScreen({
    super.key,
    required this.provisionalLevel,
    required this.pbDistance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Level'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Provisional Level',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '(PB-based)',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.h),

                  // Level Display Card
                  Container(
                    padding: EdgeInsets.all(32.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withOpacity(0.3),
                          AppTheme.primaryPurple.withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Level number with circle
                        Container(
                          width: 120.w,
                          height: 120.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryBlue,
                              width: 4,
                            ),
                            color: AppTheme.backgroundDark,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'LEVEL',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Text(
                                  '$provisionalLevel',
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontSize: 56.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Level name
                        Text(
                          LevelCalculator.getLevelName(provisionalLevel),
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),

                        // PB info
                        Text(
                          'Based on your ${pbDistance.toStringAsFixed(0)}m PB',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          LevelCalculator.getPBRangeForLevel(provisionalLevel),
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Upgrade info card
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppTheme.accentYellow.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.accentYellow,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Unlock More',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Upload a DNF video to unlock:',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        _buildBulletPoint('Official Level (PB + Technique)'),
                        _buildBulletPoint('Detailed technique feedback'),
                        _buildBulletPoint('Personalized drill recommendations'),
                        _buildBulletPoint('Stroke-by-stroke analysis'),
                      ],
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Primary CTA
                  ElevatedButton(
                    onPressed: () => _navigateToVideoTest(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Start DNF Level Test (Video)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Secondary CTA
                  TextButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    child: Text(
                      'Not now',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, left: 8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 8.h),
            width: 4.w,
            height: 4.w,
            decoration: BoxDecoration(
              color: AppTheme.accentYellow,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToVideoTest(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DNFVideoUploadScreen(),
      ),
    );
  }
}
