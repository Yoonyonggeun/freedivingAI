import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_profile.dart';
import 'first_analysis_choice_screen.dart';
import 'dart:async';

class BuildingProgramScreen extends StatefulWidget {
  final UserProfile profile;

  const BuildingProgramScreen({
    super.key,
    required this.profile,
  });

  @override
  State<BuildingProgramScreen> createState() => _BuildingProgramScreenState();
}

class _BuildingProgramScreenState extends State<BuildingProgramScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  double _progress = 0.0;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Analyzing your profile',
      'description': 'Processing your experience level and goals',
      'icon': Icons.person_search,
      'color': AppTheme.primaryBlue,
    },
    {
      'title': 'Customizing your interface',
      'description': 'Personalizing features based on your disciplines',
      'icon': Icons.tune,
      'color': AppTheme.primaryPurple,
    },
    {
      'title': 'Crafting your training plan',
      'description': 'Building a program tailored specifically for you',
      'icon': Icons.auto_awesome,
      'color': AppTheme.accentPink,
    },
    {
      'title': 'Calibrating AI coaching',
      'description': 'Fine-tuning analysis to match your style',
      'icon': Icons.psychology,
      'color': AppTheme.accentYellow,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startBuildingProcess();
  }

  Future<void> _startBuildingProcess() async {
    for (int i = 0; i < _steps.length; i++) {
      // Step 시작 - currentStep만 업데이트
      if (mounted) {
        setState(() {
          _currentStep = i;
        });
      }

      // 진행 시간 대기
      await Future.delayed(const Duration(milliseconds: 1500));

      // Step 완료 - progress bar 업데이트
      if (mounted) {
        setState(() {
          _progress = (i + 1) / _steps.length;
        });
      }
    }

    // Wait a bit before navigating
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const FirstAnalysisChoiceScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 40.sp,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 32.h),
                // Title
                Text(
                  'Building Your Program',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'This will only take a moment',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 48.h),
                // Steps list
                ..._steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  final isCompleted = index < _currentStep;
                  final isCurrent = index == _currentStep;

                  return _buildStepItem(
                    step: step,
                    isCompleted: isCompleted,
                    isCurrent: isCurrent,
                    isLast: index == _steps.length - 1,
                  );
                }),
                SizedBox(height: 48.h),
                // Progress bar
                Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: 8.h,
                          width: MediaQuery.of(context).size.width * 0.9 * _progress,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      '${(_progress * 100).toInt()}% Complete',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32.h),
                // Personalization hint
                _buildPersonalizationHint(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required Map<String, dynamic> step,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    final opacity = isCompleted || isCurrent ? 1.0 : 0.3;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.h),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: opacity,
        child: Row(
          children: [
            // Icon
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: isCompleted
                    ? step['color'].withOpacity(0.2)
                    : isCurrent
                        ? step['color'].withOpacity(0.3)
                        : AppTheme.surfaceDark,
                shape: BoxShape.circle,
                border: isCurrent
                    ? Border.all(
                        color: step['color'],
                        width: 2,
                      )
                    : null,
              ),
              child: isCompleted
                  ? Icon(
                      Icons.check,
                      color: step['color'],
                      size: 24.sp,
                    )
                  : isCurrent
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation(step['color']),
                          ),
                        )
                      : Icon(
                          step['icon'],
                          color: AppTheme.textSecondary,
                          size: 24.sp,
                        ),
            ),
            SizedBox(width: 16.w),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['title'],
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    step['description'],
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizationHint() {
    String hint = '';

    // Generate personalized message based on user profile
    if (widget.profile.diverLevel == 'beginner') {
      hint = 'Setting up beginner-friendly guidance and tutorials';
    } else if (widget.profile.diverLevel == 'elite') {
      hint = 'Calibrating advanced metrics for competitive analysis';
    } else {
      hint = 'Optimizing for your ${widget.profile.mainDisciplines.join(", ")} training';
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppTheme.primaryBlue,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
