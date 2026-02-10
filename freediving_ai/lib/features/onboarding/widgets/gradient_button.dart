import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isEnabled = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: isEnabled ? AppTheme.primaryGradient : null,
        color: isEnabled ? null : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(28.r),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: isEnabled
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (icon != null) ...[
                  SizedBox(width: 8.w),
                  Icon(
                    icon,
                    color: isEnabled
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    size: 20.sp,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
