import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'category_selection_screen.dart';

class DisciplineSelectionScreen extends StatelessWidget {
  const DisciplineSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Filter out STA (static apnea) as it doesn't need video analysis
    final videoDisciplines = AppConstants.disciplines
        .where((d) => d != 'STA')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Analysis'),
      ),
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
                Text(
                  'Select Discipline',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Choose the discipline you want to analyze',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 32.h),
                // Indoor disciplines
                _buildSectionTitle('Indoor / Pool'),
                SizedBox(height: 16.h),
                ...videoDisciplines
                    .where((d) => d.startsWith('D'))
                    .map((discipline) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _buildDisciplineCard(
                            context,
                            discipline,
                            _getDisciplineName(discipline),
                            _getDisciplineIcon(discipline),
                          ),
                        )),
                SizedBox(height: 24.h),
                // Depth disciplines
                _buildSectionTitle('Depth'),
                SizedBox(height: 16.h),
                ...videoDisciplines
                    .where((d) => !d.startsWith('D'))
                    .map((discipline) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _buildDisciplineCard(
                            context,
                            discipline,
                            _getDisciplineName(discipline),
                            _getDisciplineIcon(discipline),
                          ),
                        )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildDisciplineCard(
    BuildContext context,
    String discipline,
    String name,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CategorySelectionScreen(discipline: discipline),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryBlue,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    discipline,
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    name,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
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

  String _getDisciplineName(String discipline) {
    switch (discipline) {
      case 'DYN':
        return 'Dynamic with Fins';
      case 'DNF':
        return 'Dynamic No Fins';
      case 'DYNB':
        return 'Dynamic Bi-Fins';
      case 'CWT':
        return 'Constant Weight';
      case 'CNF':
        return 'Constant No Fins';
      case 'FIM':
        return 'Free Immersion';
      default:
        return discipline;
    }
  }

  IconData _getDisciplineIcon(String discipline) {
    if (discipline.startsWith('D')) {
      return Icons.pool;
    } else {
      return Icons.arrow_downward;
    }
  }
}
