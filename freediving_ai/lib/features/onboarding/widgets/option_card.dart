import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';

class OptionCard extends StatelessWidget {
  final String label;
  final String? description;
  final IconData? icon;
  final String? emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const OptionCard({
    super.key,
    required this.label,
    this.description,
    this.icon,
    this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withOpacity(0.2) : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            if (emoji != null)
              Text(
                emoji!,
                style: TextStyle(fontSize: 24.sp),
              )
            else if (icon != null)
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
                size: 24.sp,
              ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      description!,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryBlue,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }
}
