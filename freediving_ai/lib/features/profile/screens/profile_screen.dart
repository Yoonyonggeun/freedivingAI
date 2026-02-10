import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/user_profile.dart';
import '../../../models/analysis_result.dart';
import '../../../models/static_session.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import 'training_history_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileBox = Hive.box<UserProfile>('userProfile');
    final profile = profileBox.get('current');

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Text(
            'No profile found',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Edit profile
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: ListView(
          padding: EdgeInsets.all(20.w),
          children: [
            // User Info Card
            _buildUserInfoCard(profile),
            SizedBox(height: 20.h),
            // Stats Cards
            _buildStatsCards(profile),
            SizedBox(height: 20.h),
            // Disciplines
            _buildDisciplinesSection(profile),
            SizedBox(height: 20.h),
            // Personal Bests
            _buildPersonalBestsSection(profile),
            SizedBox(height: 20.h),
            // Quick Actions
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(UserProfile profile) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.3),
            AppTheme.primaryPurple.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 40.sp,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          // Name
          Text(
            profile.name,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          // Level Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getLevelIcon(profile.diverLevel),
                  color: AppTheme.accentYellow,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  _getLevelLabel(profile.diverLevel),
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(UserProfile profile) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Trainings',
            '0', // TODO: Count from history
            Icons.fitness_center,
            AppTheme.primaryBlue,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            'Disciplines',
            '${profile.mainDisciplines.length}',
            Icons.waves,
            AppTheme.primaryPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32.sp),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisciplinesSection(UserProfile profile) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Disciplines',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: profile.mainDisciplines.map((discipline) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  discipline,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalBestsSection(UserProfile profile) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Bests',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.star,
                color: AppTheme.accentYellow,
                size: 20.sp,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (profile.personalBests.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.h),
                child: Text(
                  'No personal bests recorded yet',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            )
          else
            ...profile.personalBests.entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      '${entry.value.toInt()}m',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        _buildActionButton(
          'Training History',
          Icons.history,
          AppTheme.primaryBlue,
          () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TrainingHistoryScreen(),
              ),
            );
          },
        ),
        SizedBox(height: 12.h),
        _buildActionButton(
          'Settings',
          Icons.settings,
          AppTheme.textSecondary,
          () {
            // TODO: Settings
          },
        ),
        SizedBox(height: 12.h),
        _buildActionButton(
          'Reset App Data',
          Icons.refresh,
          Colors.red,
          () => _showResetConfirmation(context),
        ),
      ],
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'Reset App Data?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'This will delete all your data including:\n\n'
          '• Profile and settings\n'
          '• Training history\n'
          '• Analysis results\n'
          '• Personal bests\n\n'
          'This action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Clear all Hive boxes
              final profileBox = Hive.box<UserProfile>('userProfile');
              final analysisBox = Hive.box<AnalysisResult>('analysisResults');
              final sessionBox = Hive.box<StaticSession>('staticSessions');

              await profileBox.clear();
              await analysisBox.clear();
              await sessionBox.clear();

              if (context.mounted) {
                Navigator.of(context).pop(); // Close dialog

                // Navigate to onboarding
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const OnboardingScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Reset',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
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
            Icon(icon, color: color, size: 24.sp),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondary,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'beginner':
        return Icons.star_border;
      case 'intermediate':
        return Icons.star_half;
      case 'advanced':
        return Icons.star;
      case 'elite':
        return Icons.emoji_events;
      default:
        return Icons.person;
    }
  }

  String _getLevelLabel(String level) {
    switch (level) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      case 'elite':
        return 'Elite';
      default:
        return level.toUpperCase();
    }
  }
}
