import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import 'sample_experience_screen.dart';
import '../../dynamic_training/screens/dnf_video_upload_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// First Analysis Choice Screen - Post-onboarding "Get Started" screen.
///
/// Presents two clear paths:
/// 1. Try Sample Analysis - Demo experience without video
/// 2. Analyze My DNF - Upload user's own video
///
/// Design principles:
/// - Responsive layout prevents overflow on all screen sizes
/// - Single language per locale (no mixed Korean/English)
/// - Professional "coach" aesthetic
/// - Entire cards are tappable with clear CTAs
class FirstAnalysisChoiceScreen extends StatelessWidget {
  const FirstAnalysisChoiceScreen({super.key});

  void _onSampleAnalysis(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const SampleExperienceScreen(),
      ),
    );
  }

  void _onMyVideo(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const DNFVideoUploadScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 20.h,
                      ),
                      child: Column(
                        children: [
                          // Header section
                          SizedBox(height: 16.h),
                          _buildHeader(context, l10n),

                          // Flexible spacer pushes content to center on tall screens
                          const Spacer(flex: 1),

                          // Content section
                          _buildContent(context, l10n),

                          // Footer section
                          SizedBox(height: 20.h),
                          _buildFooter(context, l10n),

                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Icon(
          Icons.waves,
          size: 48.sp,
          color: AppTheme.primaryBlue,
          semanticLabel: 'DNF Coach',
        ),
        SizedBox(height: 16.h),
        Text(
          l10n.getStartedTitle,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 26.sp,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          l10n.getStartedSubtitle,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 15.sp,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        // Option 1: Sample Analysis
        _buildChoiceCard(
          context: context,
          icon: Icons.lightbulb_outline,
          iconColor: AppTheme.accentYellow,
          title: l10n.sampleAnalysisTitle,
          description: l10n.sampleAnalysisDescription,
          buttonText: l10n.sampleAnalysisButton,
          buttonColor: AppTheme.accentYellow,
          onTap: () => _onSampleAnalysis(context),
        ),

        // Divider
        SizedBox(height: 16.h),
        _buildDivider(context),
        SizedBox(height: 16.h),

        // Option 2: My Video
        _buildChoiceCard(
          context: context,
          icon: Icons.videocam,
          iconColor: AppTheme.primaryBlue,
          title: l10n.myVideoTitle,
          description: l10n.myVideoDescription,
          buttonText: l10n.myVideoButton,
          buttonColor: AppTheme.primaryBlue,
          onTap: () => _onMyVideo(context),
        ),
      ],
    );
  }

  Widget _buildChoiceCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: iconColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    size: 32.sp,
                    color: iconColor,
                  ),
                ),
                SizedBox(height: 16.h),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 8.h),

                // Description
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14.sp,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 20.h),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: buttonColor == AppTheme.accentYellow
                          ? Colors.black
                          : Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.textSecondary.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.textSecondary.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 14.sp,
            color: AppTheme.textSecondary.withOpacity(0.7),
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              l10n.sampleFooterNote,
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.8),
                fontSize: 11.sp,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
