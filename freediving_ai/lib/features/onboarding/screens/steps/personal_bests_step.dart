import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/gradient_button.dart';

class PersonalBestsStep extends ConsumerStatefulWidget {
  const PersonalBestsStep({super.key});

  @override
  ConsumerState<PersonalBestsStep> createState() => _PersonalBestsStepState();
}

class _PersonalBestsStepState extends ConsumerState<PersonalBestsStep> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.3),
                    AppTheme.primaryPurple.withOpacity(0.3)
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star,
                color: AppTheme.accentYellow,
                size: 32.sp,
              ),
            ),
            SizedBox(height: 24.h),
            // Title
            Text(
              'QUESTION 4',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'What are your personal bests?',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Optional - helps us track your progress 📈',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 32.h),
            // PB inputs
            ...onboardingState.mainDisciplines.asMap().entries.map((entry) {
              final index = entry.key;
              final discipline = entry.value;

              // Create controller if not exists
              if (!_controllers.containsKey(discipline)) {
                final currentPB = onboardingState.personalBests[discipline];
                _controllers[discipline] = TextEditingController(
                  text: currentPB != null ? currentPB.toString() : '',
                );
              }

              String unit = 'm';
              String hint = 'e.g. 50';
              if (discipline == 'STA') {
                unit = 'seconds';
                hint = 'e.g. 180';
              } else if (discipline.startsWith('D')) {
                unit = 'm';
                hint = 'e.g. 75';
              } else {
                unit = 'm';
                hint = 'e.g. 30';
              }

              return Column(
                children: [
                  if (index > 0) SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getDisciplineIcon(discipline),
                              color: AppTheme.primaryBlue,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              discipline,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        TextField(
                          controller: _controllers[discipline],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16.sp,
                          ),
                          decoration: InputDecoration(
                            hintText: hint,
                            hintStyle: TextStyle(
                              color: AppTheme.textSecondary.withOpacity(0.5),
                            ),
                            suffixText: unit,
                            suffixStyle: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14.sp,
                            ),
                            filled: true,
                            fillColor: AppTheme.backgroundDark,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: AppTheme.primaryBlue,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isEmpty) {
                              ref
                                  .read(onboardingProvider.notifier)
                                  .setPersonalBest(discipline, 0);
                              return;
                            }

                            final pb = double.tryParse(value);
                            if (pb != null && pb > 0) {
                              ref
                                  .read(onboardingProvider.notifier)
                                  .setPersonalBest(discipline, pb);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
            SizedBox(height: 20.h),
            // Skip/Next buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      ref.read(onboardingProvider.notifier).nextStep();
                    },
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  flex: 2,
                  child: GradientButton(
                    text: 'Continue',
                    icon: Icons.arrow_forward,
                    onPressed: () {
                      ref.read(onboardingProvider.notifier).nextStep();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDisciplineIcon(String discipline) {
    if (discipline == 'STA') {
      return Icons.timer;
    } else if (discipline.startsWith('D')) {
      return Icons.pool;
    } else {
      return Icons.arrow_downward;
    }
  }
}
