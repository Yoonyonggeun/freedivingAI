import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/option_card.dart';
import '../../widgets/gradient_button.dart';
import '../building_program_screen.dart';

class TrainingGoalsStep extends ConsumerWidget {
  const TrainingGoalsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingProvider);

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rocket_launch,
              color: AppTheme.textPrimary,
              size: 32.sp,
            ),
          ),
          SizedBox(height: 24.h),
          // Title
          Text(
            'QUESTION 5',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'What are your training goals?',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Select all that matter to you 🎯',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 32.h),
          // Goals
          Expanded(
            child: ListView.separated(
              itemCount: AppConstants.trainingGoals.length,
              separatorBuilder: (context, index) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final goal = AppConstants.trainingGoals[index];
                final isSelected = onboardingState.trainingGoals.contains(goal['value']);

                return OptionCard(
                  label: goal['label']!,
                  description: goal['description'],
                  emoji: ['🏆', '🥇', '🎯', '🌊'][index],
                  isSelected: isSelected,
                  onTap: () {
                    final currentGoals = List<String>.from(onboardingState.trainingGoals);
                    if (isSelected) {
                      currentGoals.remove(goal['value']);
                    } else {
                      currentGoals.add(goal['value']!);
                    }
                    ref
                        .read(onboardingProvider.notifier)
                        .setTrainingGoals(currentGoals);
                  },
                );
              },
            ),
          ),
          SizedBox(height: 20.h),
          // Complete button
          GradientButton(
            text: 'Start Training',
            icon: Icons.check,
            isEnabled: onboardingState.trainingGoals.isNotEmpty,
            onPressed: () async {
              if (onboardingState.trainingGoals.isNotEmpty) {
                // Show loading dialog
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
                            'Setting up your profile...',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                // Complete onboarding
                try {
                  final profile = await ref.read(onboardingProvider.notifier).completeOnboarding();
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close loading dialog
                    // Navigate to building program screen
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => BuildingProgramScreen(profile: profile),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close loading dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
