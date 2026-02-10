import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class RoundConfigInput extends StatelessWidget {
  final int roundNumber;
  final TextEditingController holdController;
  final TextEditingController? restController;
  final VoidCallback? onDelete;

  const RoundConfigInput({
    super.key,
    required this.roundNumber,
    required this.holdController,
    this.restController,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Round $roundNumber',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppTheme.accentPink,
                    size: 20.sp,
                  ),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildTimeInput(
                  controller: holdController,
                  label: 'Hold (sec)',
                  hint: '30',
                ),
              ),
              if (restController != null) ...[
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildTimeInput(
                    controller: restController!,
                    label: 'Rest (sec)',
                    hint: '60',
                  ),
                ),
              ] else ...[
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rest (sec)',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundDark.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Final Round',
                            style: TextStyle(
                              color: AppTheme.textSecondary.withOpacity(0.7),
                              fontSize: 14.sp,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInput({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            filled: true,
            fillColor: AppTheme.backgroundDark,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 10.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: AppTheme.primaryBlue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: AppTheme.accentPink,
                width: 1,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            final intValue = int.tryParse(value);
            if (intValue == null) {
              return 'Invalid';
            }
            if (intValue < AppConstants.minHoldTime ||
                intValue > AppConstants.maxHoldTime) {
              return '${AppConstants.minHoldTime}-${AppConstants.maxHoldTime}';
            }
            return null;
          },
        ),
      ],
    );
  }
}
