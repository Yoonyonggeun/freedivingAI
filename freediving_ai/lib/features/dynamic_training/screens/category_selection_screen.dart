import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'video_guide_screen_v2.dart';

class CategorySelectionScreen extends StatelessWidget {
  final String discipline;

  const CategorySelectionScreen({
    super.key,
    required this.discipline,
  });

  @override
  Widget build(BuildContext context) {
    final categories = AppConstants.analysisCategories[discipline] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('$discipline Analysis'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What do you want to analyze?',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Select the aspect of your technique',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 32.h),
                Expanded(
                  child: ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder: (context, index) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _buildCategoryCard(context, category);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String category) {
    final categoryInfo = _getCategoryInfo(category);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VideoGuideScreenV2(
              discipline: discipline,
              category: category,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: categoryInfo['color'].withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: categoryInfo['color'].withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                categoryInfo['icon'],
                color: categoryInfo['color'],
                size: 28.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryInfo['name'],
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    categoryInfo['description'],
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
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

  Map<String, dynamic> _getCategoryInfo(String category) {
    switch (category) {
      case 'streamline':
        return {
          'name': 'Streamline',
          'description': 'Body alignment and position',
          'icon': Icons.straighten,
          'color': AppTheme.primaryBlue,
        };
      case 'finning':
        return {
          'name': 'Finning Technique',
          'description': 'Leg movement and efficiency',
          'icon': Icons.waves,
          'color': AppTheme.primaryPurple,
        };
      case 'arm_stroke':
        return {
          'name': 'Arm Stroke',
          'description': 'Arm movement and timing',
          'icon': Icons.back_hand,
          'color': AppTheme.accentPink,
        };
      case 'breaststroke_kick':
        return {
          'name': 'Breaststroke Kick',
          'description': 'Leg technique for no-fin',
          'icon': Icons.accessibility_new,
          'color': AppTheme.accentYellow,
        };
      case 'dolphin_kick':
        return {
          'name': 'Dolphin Kick',
          'description': 'Mono-fin technique',
          'icon': Icons.water,
          'color': AppTheme.primaryBlue,
        };
      case 'head_position':
        return {
          'name': 'Head Position',
          'description': 'Head and neck alignment',
          'icon': Icons.face,
          'color': AppTheme.primaryPurple,
        };
      case 'turn':
        return {
          'name': 'Turn Technique',
          'description': 'Wall turn execution',
          'icon': Icons.u_turn_right,
          'color': AppTheme.accentPink,
        };
      case 'entry':
      case 'start':
        return {
          'name': 'Entry/Start',
          'description': 'Initial dive technique',
          'icon': Icons.play_arrow,
          'color': AppTheme.accentYellow,
        };
      case 'duck_dive':
        return {
          'name': 'Duck Dive',
          'description': 'Surface dive technique',
          'icon': Icons.arrow_downward,
          'color': AppTheme.primaryBlue,
        };
      case 'pulling_technique':
        return {
          'name': 'Pulling Technique',
          'description': 'Rope pulling for FIM',
          'icon': Icons.moving,
          'color': AppTheme.primaryPurple,
        };
      case 'ascent':
        return {
          'name': 'Ascent',
          'description': 'Rising technique',
          'icon': Icons.arrow_upward,
          'color': AppTheme.accentPink,
        };
      default:
        return {
          'name': category.replaceAll('_', ' ').toUpperCase(),
          'description': 'Technique analysis',
          'icon': Icons.analytics,
          'color': AppTheme.textSecondary,
        };
    }
  }
}
