import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';
import 'steps/diver_level_step.dart';
import 'steps/competition_level_step.dart';
import 'steps/disciplines_step.dart';
import 'steps/personal_bests_step.dart';
import 'steps/training_goals_step.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingProvider);
    final totalSteps = 5;

    final steps = [
      const DiverLevelStep(),
      const CompetitionLevelStep(),
      const DisciplinesStep(),
      const PersonalBestsStep(),
      const TrainingGoalsStep(),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with progress
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (onboardingState.currentStep > 0)
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            color: AppTheme.textPrimary,
                            onPressed: () {
                              ref.read(onboardingProvider.notifier).previousStep();
                            },
                          )
                        else
                          SizedBox(width: 48.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.waves,
                                color: AppTheme.primaryBlue,
                                size: 16.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Setup',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 48.w),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    // Progress bar
                    Stack(
                      children: [
                        Container(
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 4.h,
                          width: (MediaQuery.of(context).size.width - 40.w) *
                              ((onboardingState.currentStep + 1) / totalSteps),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${onboardingState.currentStep + 1} of $totalSteps',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              // Step content
              Expanded(
                child: steps[onboardingState.currentStep.clamp(0, totalSteps - 1)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
