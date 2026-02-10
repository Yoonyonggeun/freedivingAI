import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/static_training_provider.dart';

class StaticTimerScreen extends ConsumerWidget {
  const StaticTimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(staticTrainingProvider);

    return WillPopScope(
      onWillPop: () async {
        if (state.isRunning) {
          final shouldPop = await _showExitDialog(context, ref);
          if (shouldPop == true) {
            await ref.read(staticTrainingProvider.notifier).quit();
          }
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context, ref, state),
                SizedBox(height: 20.h),
                // Progress
                _buildProgress(context, state),
                SizedBox(height: 40.h),
                // Main Timer
                Expanded(
                  child: Center(
                    child: _buildTimerDisplay(state),
                  ),
                ),
                // Round Info
                _buildRoundInfo(state),
                SizedBox(height: 40.h),
                // Controls
                _buildControls(context, ref, state),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, StaticTrainingState state) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            color: AppTheme.textPrimary,
            onPressed: () async {
              if (state.isRunning) {
                final shouldPop = await _showExitDialog(context, ref);
                if (shouldPop == true) {
                  await ref.read(staticTrainingProvider.notifier).quit();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Icon(
                  state.table?.type == 'co2' ? Icons.science : Icons.trending_up,
                  color: AppTheme.primaryBlue,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  state.table?.type.toUpperCase() ?? '',
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

  Widget _buildProgress(BuildContext context, StaticTrainingState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 8.h,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 8.h,
                width: MediaQuery.of(context).size.width * 0.8 * state.progress,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Round ${state.currentRound + 1} of ${state.totalRounds}',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(StaticTrainingState state) {
    Color phaseColor;
    String phaseText;
    final showWarning =
        state.remainingSeconds <= 10 && state.phase == TrainingPhase.hold;

    switch (state.phase) {
      case TrainingPhase.ready:
        phaseColor = AppTheme.textSecondary;
        phaseText = 'READY';
        break;
      case TrainingPhase.hold:
        phaseColor = showWarning ? AppTheme.accentYellow : AppTheme.primaryBlue;
        phaseText = 'HOLD';
        break;
      case TrainingPhase.rest:
        phaseColor = AppTheme.accentYellow;
        phaseText = 'REST';
        break;
      case TrainingPhase.completed:
        phaseColor = AppTheme.primaryPurple;
        phaseText = 'COMPLETED';
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: showWarning
            ? AppTheme.accentYellow.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            phaseText,
            style: TextStyle(
              color: phaseColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            state.formattedTime,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 72.sp,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundInfo(StaticTrainingState state) {
    if (state.table == null) return const SizedBox();

    final currentRound = state.currentRound.clamp(0, state.totalRounds - 1);
    final holdTime = state.table!.holdTimes[currentRound];
    final restTime = currentRound < state.table!.restTimes.length
        ? state.table!.restTimes[currentRound]
        : 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoCard('Hold', '${holdTime}s', Icons.air),
          _buildInfoCard('Rest', '${restTime}s', Icons.timer_outlined),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20.sp),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10.sp,
                ),
              ),
              Text(
                value,
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
    );
  }

  Widget _buildControls(BuildContext context, WidgetRef ref, StaticTrainingState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!state.isRunning && state.phase == TrainingPhase.ready)
            _buildControlButton(
              icon: Icons.play_arrow,
              color: AppTheme.primaryBlue,
              onTap: () => ref.read(staticTrainingProvider.notifier).start(),
            )
          else if (state.isRunning && !state.isPaused)
            Row(
              children: [
                _buildControlButton(
                  icon: Icons.pause,
                  color: AppTheme.accentYellow,
                  onTap: () => ref.read(staticTrainingProvider.notifier).pause(),
                ),
                SizedBox(width: 20.w),
                if (state.phase == TrainingPhase.hold)
                  _buildControlButton(
                    icon: Icons.check,
                    color: AppTheme.primaryPurple,
                    onTap: () => ref.read(staticTrainingProvider.notifier).completeHold(),
                  ),
              ],
            )
          else if (state.isPaused)
            Row(
              children: [
                _buildControlButton(
                  icon: Icons.play_arrow,
                  color: AppTheme.primaryBlue,
                  onTap: () => ref.read(staticTrainingProvider.notifier).resume(),
                ),
                SizedBox(width: 20.w),
                _buildControlButton(
                  icon: Icons.stop,
                  color: Colors.red,
                  onTap: () async {
                    await ref.read(staticTrainingProvider.notifier).quit();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            )
          else if (state.phase == TrainingPhase.completed)
            _buildControlButton(
              icon: Icons.close,
              color: AppTheme.primaryBlue,
              onTap: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80.w,
        height: 80.w,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
        ),
        child: Icon(
          icon,
          color: color,
          size: 40.sp,
        ),
      ),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context, WidgetRef ref) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'Exit Training?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Your progress will be saved as incomplete.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Exit',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
