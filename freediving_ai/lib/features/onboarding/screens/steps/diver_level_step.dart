import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/option_card.dart';
import '../../widgets/gradient_button.dart';

class DiverLevelStep extends ConsumerWidget {
  const DiverLevelStep({super.key});

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
              color: AppTheme.primaryBlue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: AppTheme.primaryBlue,
              size: 32.sp,
            ),
          ),
          SizedBox(height: 24.h),
          // Title
          Text(
            'QUESTION 1',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'What\'s your diving experience?',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Every champion started somewhere 💪',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 32.h),
          // Options
          Expanded(
            child: ListView.separated(
              itemCount: AppConstants.diverLevels.length,
              separatorBuilder: (context, index) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final level = AppConstants.diverLevels[index];
                final emoji = ['🌱', '⚡', '🔥', '👑'][index];
                return OptionCard(
                  label: level['label']!,
                  description: level['description'],
                  emoji: emoji,
                  isSelected: onboardingState.diverLevel == level['value'],
                  onTap: () {
                    ref
                        .read(onboardingProvider.notifier)
                        .setDiverLevel(level['value']!);
                  },
                );
              },
            ),
          ),
          SizedBox(height: 20.h),
          // Next button
          GradientButton(
            text: 'Forge My Path',
            icon: Icons.arrow_forward,
            isEnabled: onboardingState.diverLevel != null,
            onPressed: () {
              if (onboardingState.diverLevel != null) {
                ref.read(onboardingProvider.notifier).nextStep();
              }
            },
          ),
        ],
      ),
    );
  }
}
