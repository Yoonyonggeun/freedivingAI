import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../static_training/screens/training_template_list_screen.dart';
import '../../dynamic_training/screens/discipline_selection_screen.dart';
import '../../dynamic_training/screens/dnf_pb_input_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/screens/training_history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back! 👋',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          AppConstants.appName,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.person_outline,
                      color: AppTheme.textPrimary,
                      size: 28.sp,
                    ),
                  ],
                ),
                SizedBox(height: 32.h),

                // Indoor Pool Disciplines Section
                Text(
                  'Indoor Pool Disciplines',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),

                // DNF Tile (Active)
                _buildDisciplineTile(
                  context,
                  title: 'Dynamic No Fins',
                  subtitle: 'Start DNF analysis',
                  icon: Icons.pool,
                  color: AppTheme.primaryBlue,
                  isEnabled: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DNFPBInputScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(height: 12.h),

                // DYN Tile (Disabled)
                _buildDisciplineTile(
                  context,
                  title: 'Dynamic with Fins',
                  subtitle: 'Coming soon',
                  icon: Icons.pool,
                  color: AppTheme.primaryPurple,
                  isEnabled: false,
                  showComingSoon: true,
                ),
                SizedBox(height: 12.h),

                // DYNB Tile (Disabled)
                _buildDisciplineTile(
                  context,
                  title: 'Dynamic Bi-Fins',
                  subtitle: 'Coming soon',
                  icon: Icons.pool,
                  color: AppTheme.accentPink,
                  isEnabled: false,
                  showComingSoon: true,
                ),

                SizedBox(height: 32.h),

                // Other Features
                Text(
                  'Other Features',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),

                // Grid for other features (Static Training, History, Profile)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  childAspectRatio: 0.85,
                  children: [
                    _buildFeatureCard(
                      context,
                      'Static Training',
                      'CO2/O2 Tables',
                      Icons.timer,
                      AppTheme.primaryBlue,
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TrainingTemplateListScreen(),
                          ),
                        );
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      'Training History',
                      'View Progress',
                      Icons.insights,
                      AppTheme.accentYellow,
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TrainingHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      'Profile',
                      'Settings & PBs',
                      Icons.person,
                      AppTheme.accentPink,
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisciplineTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    bool showComingSoon = false,
    VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: color, size: 28.sp),
              ),
              SizedBox(width: 16.w),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),

              // Lock icon for disabled tiles
              if (!isEnabled)
                Icon(
                  Icons.lock_outline,
                  color: AppTheme.textSecondary,
                  size: 20.sp,
                ),

              // Coming soon badge
              if (showComingSoon)
                Container(
                  margin: EdgeInsets.only(left: 8.w),
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'SOON',
                    style: TextStyle(
                      color: color,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
