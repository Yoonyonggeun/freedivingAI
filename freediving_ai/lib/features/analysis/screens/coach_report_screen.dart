import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/analysis_output.dart';
import '../../../models/component_result.dart';
import '../../../models/ui/enums.dart';
import '../../../services/share_card_builder.dart';
import '../../../services/dnf_local_storage.dart';
import '../widgets/angle_coach.dart';
import '../widgets/component_card.dart';
import '../widgets/briefing_panel.dart';
import '../widgets/tracking_health_panel.dart';
import '../../dynamic_training/screens/upload_choice_screen.dart';
import 'share_card_screen.dart';

/// Coach Report Screen - Displays analysis results in coach-like format.
///
/// Sections:
/// 1. Today's Coach Briefing (top card with strength/issue/mission)
/// 2. Angle Coach Summary (camera angle guidance)
/// 3. Tracking Health (if multi-person or issues)
/// 4. Component Cards (6 cards, scrollable)
/// 5. CTAs (Next Mission, Share Card)
class CoachReportScreen extends StatelessWidget {
  final AnalysisOutput output;

  const CoachReportScreen({
    super.key,
    required this.output,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Report'),
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        actions: [
          // Menu button for additional options
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMenu(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Today's Coach Briefing
                      BriefingPanel(
                        strength: _extractStrength(),
                        issue: _extractIssue(),
                        nextMission: _extractNextMission(),
                      ),
                      SizedBox(height: 16.h),

                      // 2. Angle Coach Summary (if not optimal)
                      if (_shouldShowAngleCoach()) ...[
                        AngleCoach(
                          components: output.components,
                        ),
                        SizedBox(height: 16.h),
                      ],

                      // 3. Tracking Health Summary (if issues)
                      if (_shouldShowTrackingHealth()) ...[
                        TrackingHealthPanel(
                          tracking: output.trackingDiagnostics,
                        ),
                        SizedBox(height: 16.h),
                      ],

                      // 4. Component Cards (6 cards)
                      _buildComponentCards(),
                    ],
                  ),
                ),
              ),

              // 5. Bottom CTAs
              _buildBottomCTAs(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComponentCards() {
    // Always show all 6 components in order
    const componentOrder = [
      'streamline',
      'glide',
      'kick',
      'arm',
      'start',
      'turn',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Component Analysis',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        ...componentOrder.map((componentId) {
          final component = output.components[componentId];
          if (component == null) return const SizedBox.shrink();

          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: ComponentCard(
              component: component,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomCTAs(BuildContext context) {
    final showShareCard = _canShowShareCard();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Next Mission button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _onNextMission(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Next Mission Upload',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Share Card button (enabled if ≥2 CONFIRMED components)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: showShareCard ? () => _onShareCard(context) : null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: showShareCard
                        ? AppTheme.accentYellow
                        : AppTheme.textSecondary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.share,
                      size: 20.sp,
                      color: showShareCard
                          ? AppTheme.accentYellow
                          : AppTheme.textSecondary,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Create Share Card',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: showShareCard
                            ? AppTheme.accentYellow
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  String? _extractStrength() {
    // Find the best performing CONFIRMED component
    final confirmed = output.components.entries
        .where((e) => e.value.status == ComponentStatus.confirmed && e.value.score != null)
        .toList()
      ..sort((a, b) => (b.value.score ?? 0).compareTo(a.value.score ?? 0));

    if (confirmed.isEmpty) return null;

    final best = confirmed.first;
    final componentName = _getComponentDisplayName(best.key);
    final score = best.value.score!.toStringAsFixed(0);

    return 'Your $componentName shows excellent form (score: $score/100)';
  }

  String? _extractIssue() {
    // Find the weakest performing measurable component
    final measurable = output.components.entries
        .where((e) =>
            (e.value.status == ComponentStatus.confirmed || e.value.status == ComponentStatus.partial) &&
            e.value.score != null)
        .toList()
      ..sort((a, b) => (a.value.score ?? 0).compareTo(b.value.score ?? 0));

    if (measurable.isEmpty || measurable.first.value.score == null) {
      return null;
    }

    final weakest = measurable.first;
    if ((weakest.value.score ?? 0) >= 70) return null; // No issue if score ≥ 70

    final componentName = _getComponentDisplayName(weakest.key);
    final score = weakest.value.score!.toStringAsFixed(0);

    return '$componentName needs attention (score: $score/100)';
  }

  String _extractNextMission() {
    // Find first NOT_MEASURABLE component
    final notMeasurable = output.components.entries
        .where((e) => e.value.status == ComponentStatus.notMeasurable)
        .toList();

    if (notMeasurable.isNotEmpty) {
      final componentName = _getComponentDisplayName(notMeasurable.first.key);
      final viewType = _extractViewType();
      final viewName = viewType?.displayName ?? 'optimal angle';

      return 'Upload video from $viewName to measure $componentName';
    }

    // If all measurable, suggest improving weakest
    final measurable = output.components.entries
        .where((e) => e.value.status != ComponentStatus.notMeasurable && e.value.score != null)
        .toList()
      ..sort((a, b) => (a.value.score ?? 0).compareTo(b.value.score ?? 0));

    if (measurable.isNotEmpty) {
      final componentName = _getComponentDisplayName(measurable.first.key);
      return 'Focus on improving $componentName technique';
    }

    return 'Continue practicing all components';
  }

  bool _shouldShowAngleCoach() {
    final viewType = _extractViewType();
    // Show if view is not optimal (not SIDE)
    return viewType != null && viewType != ViewType.side;
  }

  bool _shouldShowTrackingHealth() {
    final tracking = output.trackingDiagnostics;
    // Show if there are tracking issues
    return tracking.idSwitchCount > 1 ||
        tracking.multiPersonFrameRatio > 0.10 ||
        tracking.coverageRatio < 0.80;
  }

  bool _canShowShareCard() {
    // Enabled if ≥2 CONFIRMED components
    final confirmedCount = output.components.values
        .where((c) => c.status == ComponentStatus.confirmed)
        .length;
    return confirmedCount >= 2;
  }

  ViewType? _extractViewType() {
    // Extract view type from first component's subMetrics
    for (final component in output.components.values) {
      if (component.subMetrics != null &&
          component.subMetrics!.containsKey('viewType')) {
        final viewTypeStr = component.subMetrics!['viewType'] as String?;
        if (viewTypeStr != null) {
          try {
            return ViewType.values.byName(viewTypeStr);
          } catch (e) {
            // Invalid view type, continue
          }
        }
      }
    }
    return null;
  }

  String _getComponentDisplayName(String componentId) {
    switch (componentId) {
      case 'streamline':
        return 'Streamline';
      case 'glide':
        return 'Glide';
      case 'kick':
        return 'Kick';
      case 'arm':
        return 'Arm Stroke';
      case 'start':
        return 'Start / Push-off';
      case 'turn':
        return 'Turn';
      default:
        return componentId;
    }
  }

  void _onNextMission(BuildContext context) {
    // Navigate to upload choice screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const UploadChoiceScreen(),
      ),
    );
  }

  void _onShareCard(BuildContext context) async {
    final storage = DNFLocalStorage();

    if (!storage.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load session data'),
          backgroundColor: AppTheme.accentYellow,
        ),
      );
      return;
    }

    final builder = ShareCardBuilder();
    final cardData = builder.build(
      currentAnalysis: output,
      sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      storage: storage,
    );

    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShareCardScreen(
          cardData: cardData,
          sessionId: cardData.levelValue.toString(),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.history, color: AppTheme.primaryBlue),
              title: const Text(
                'Session History',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session history coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppTheme.primaryBlue),
              title: const Text(
                'Settings',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
