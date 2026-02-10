import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/static_session.dart';
import '../../../models/analysis_result.dart';
import '../../analysis/screens/analysis_result_screen.dart';

class TrainingHistoryScreen extends StatefulWidget {
  const TrainingHistoryScreen({super.key});

  @override
  State<TrainingHistoryScreen> createState() => _TrainingHistoryScreenState();
}

class _TrainingHistoryScreenState extends State<TrainingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training History'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Static'),
            Tab(text: 'Video Analysis'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildStaticHistory(),
            _buildAnalysisHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticHistory() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<StaticSession>('staticSessions').listenable(),
      builder: (context, Box<StaticSession> box, _) {
        final sessions = box.values.toList().reversed.toList();

        if (sessions.isEmpty) {
          return _buildEmptyState('No static training sessions yet');
        }

        return ListView.separated(
          padding: EdgeInsets.all(20.w),
          itemCount: sessions.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _buildStaticSessionCard(session);
          },
        );
      },
    );
  }

  Widget _buildAnalysisHistory() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<AnalysisResult>('analysisResults').listenable(),
      builder: (context, Box<AnalysisResult> box, _) {
        final results = box.values.toList().reversed.toList();

        if (results.isEmpty) {
          return _buildEmptyState('No video analyses yet');
        }

        return ListView.separated(
          padding: EdgeInsets.all(20.w),
          itemCount: results.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final result = results[index];
            return _buildAnalysisCard(result);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80.sp,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticSessionCard(StaticSession session) {
    final completedRounds = session.completedHoldTimes.length;
    final totalRounds = session.rounds;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: AppTheme.primaryBlue,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    session.tableType.toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(session.createdAt),
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSessionStat('Rounds', '$completedRounds/$totalRounds'),
              _buildSessionStat(
                'Avg Hold',
                session.completedHoldTimes.isNotEmpty
                    ? '${(session.completedHoldTimes.reduce((a, b) => a + b) / session.completedHoldTimes.length).toInt()}s'
                    : '-',
              ),
              _buildSessionStat(
                'Status',
                session.isCompleted ? 'Completed' : 'Incomplete',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(AnalysisResult result) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AnalysisResultScreen(result: result),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: _getScoreColor(result.overallScore).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        color: _getScoreColor(result.overallScore)
                            .withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${result.overallScore.toInt()}',
                          style: TextStyle(
                            color: _getScoreColor(result.overallScore),
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.discipline,
                          style: TextStyle(
                            color: AppTheme.primaryPurple,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _formatCategory(result.category),
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textSecondary,
                  size: 16.sp,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              DateFormat('MMM dd, yyyy • HH:mm').format(result.createdAt),
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppTheme.primaryPurple;
    if (score >= 60) return AppTheme.primaryBlue;
    if (score >= 40) return AppTheme.accentYellow;
    return AppTheme.accentPink;
  }

  String _formatCategory(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
