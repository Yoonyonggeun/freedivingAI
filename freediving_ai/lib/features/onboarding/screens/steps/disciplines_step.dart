import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/gradient_button.dart';

class DisciplinesStep extends ConsumerWidget {
  const DisciplinesStep({super.key});

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
              color: AppTheme.primaryPurple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.waves,
              color: AppTheme.primaryPurple,
              size: 32.sp,
            ),
          ),
          SizedBox(height: 24.h),
          // Title
          Text(
            'QUESTION 3',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'What disciplines do you practice?',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Select all that apply 🌊',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 32.h),
          // Discipline chips
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children: AppConstants.disciplines.map((discipline) {
                  final isSelected = onboardingState.mainDisciplines.contains(discipline);
                  return GestureDetector(
                    onTap: () {
                      final currentDisciplines = List<String>.from(onboardingState.mainDisciplines);
                      if (isSelected) {
                        currentDisciplines.remove(discipline);
                      } else {
                        currentDisciplines.add(discipline);
                      }
                      ref
                          .read(onboardingProvider.notifier)
                          .setMainDisciplines(currentDisciplines);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 16.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.primaryGradient : null,
                        color: isSelected ? null : AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : AppTheme.textSecondary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            discipline,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isSelected) ...[
                            SizedBox(width: 8.w),
                            Icon(
                              Icons.check,
                              color: AppTheme.textPrimary,
                              size: 18.sp,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          // Info text
          if (onboardingState.mainDisciplines.isNotEmpty)
            Center(
              child: Text(
                '${onboardingState.mainDisciplines.length} discipline${onboardingState.mainDisciplines.length > 1 ? 's' : ''} selected',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
            ),
          SizedBox(height: 12.h),
          // Next button
          GradientButton(
            text: 'Continue',
            icon: Icons.arrow_forward,
            isEnabled: onboardingState.mainDisciplines.isNotEmpty,
            onPressed: () {
              if (onboardingState.mainDisciplines.isNotEmpty) {
                ref.read(onboardingProvider.notifier).nextStep();
              }
            },
          ),
        ],
      ),
    );
  }
}
