import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/ui/enums.dart';
import '../../../models/ui/passport_model.dart';
import '../../../models/component_result.dart';
import '../../../providers/dnf_storage_provider.dart';
import '../../../services/confirmed_level_service.dart';
import '../../onboarding/screens/sample_experience_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../dynamic_training/screens/dnf_video_upload_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/user_profile.dart';
import '../../../models/analysis_result.dart';
import '../../../models/static_session.dart';
import '../../../models/training_template.dart';
import '../../../services/debug_preferences.dart';

/// Home Passport Screen - Displays user's DNF level, coverage, and mission.
///
/// Shows:
/// - Level badge (PROVISIONAL/CONFIRMED)
/// - Coverage count (X/6)
/// - Mission suggestion card
/// - Component grid (6 components)
/// - "Check Level" floating button (conditionally enabled)
class HomePassportScreen extends ConsumerStatefulWidget {
  const HomePassportScreen({super.key});

  @override
  ConsumerState<HomePassportScreen> createState() => _HomePassportScreenState();
}

class _HomePassportScreenState extends ConsumerState<HomePassportScreen> {
  final _levelService = ConfirmedLevelService();
  PassportModel? _passportModel;
  bool _isLoading = true;
  bool _canCheckLevel = false;

  @override
  void initState() {
    super.initState();
    _loadPassportData();
  }

  Future<void> _loadPassportData() async {
    try {
      final storage = ref.read(dnfStorageProvider);
      final sessions = storage.getRecentSessionSummaries(validityWindowDays: 14);

      // Compute confirmed level
      final levelResult = _levelService.computeConfirmedLevel(
        sessionSummaries: sessions,
        currentTimestamp: DateTime.now(),
        validityWindowDays: 14,
      );

      // Generate passport model
      final passport = _levelService.getPassportModel(
        confirmedResult: levelResult,
        recentSessions: sessions,
      );

      setState(() {
        _passportModel = passport;
        _canCheckLevel = levelResult.isConfirmed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onCheckLevel() {
    if (!_canCheckLevel) {
      // Show progress tooltip
      final missingCount = 6 - (_passportModel?.coverageCount ?? 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$missingCount/6 components still needed. ${_passportModel?.nextSuggestedMission.shortTip ?? "Keep uploading to unlock level check!"}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Show celebration screen/dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          '🎉 Level Confirmed!',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Congratulations! You\'ve achieved',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'CONFIRMED Level ${_passportModel?.levelValue}',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'All 6 components measured!',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Awesome!',
              style: TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  void _onUploadVideo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DNFVideoUploadScreen(),
      ),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility, color: AppTheme.primaryBlue),
              title: Text(
                'View Sample Experience',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SampleExperienceScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: AppTheme.accentYellow),
              title: Text(
                'Session History',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to history screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppTheme.textSecondary),
              title: Text(
                'Settings',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to settings screen
              },
            ),
            const Divider(color: AppTheme.textSecondary, thickness: 0.5),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.redAccent),
              title: Text(
                'Reset App',
                style: TextStyle(color: Colors.redAccent),
              ),
              subtitle: Text(
                'Clear all data and start fresh',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.sp),
              ),
              onTap: () {
                Navigator.pop(context);
                _showResetConfirmation();
              },
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.redAccent, size: 28),
            SizedBox(width: 12.w),
            Text(
              'Reset App?',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete:',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            _buildResetItem('All session data and analysis results'),
            _buildResetItem('Personal bests and user profile'),
            _buildResetItem('Confirmed level progress'),
            _buildResetItem('Debug settings'),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.redAccent, size: 20),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetAllAppData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Reset App',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.redAccent, size: 18),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllAppData() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Container(
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryBlue),
                  SizedBox(height: 16.h),
                  Text(
                    'Resetting app...',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      print('🔄 Starting app reset...');

      // 0. Preserve sample_shown flag (user already saw sample experience)
      print('💾 Preserving sample_shown flag...');
      bool sampleShown = false;
      try {
        if (Hive.isBoxOpen('dnf_preferences')) {
          final prefsBox = Hive.box('dnf_preferences');
          sampleShown = prefsBox.get('sample_shown', defaultValue: false) as bool;
          print('  ℹ️ Current sample_shown value: $sampleShown');
        }
      } catch (e) {
        print('  ⚠️ Could not read sample_shown: $e');
      }

      // 1. Clear ALL SharedPreferences
      print('📦 Clearing SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ SharedPreferences cleared');

      // 2. Clear all Hive boxes first
      print('📦 Clearing all Hive boxes...');
      try {
        if (Hive.isBoxOpen('userProfile')) {
          await Hive.box<UserProfile>('userProfile').clear();
        }
        if (Hive.isBoxOpen('analysisResults')) {
          await Hive.box<AnalysisResult>('analysisResults').clear();
        }
        if (Hive.isBoxOpen('staticSessions')) {
          await Hive.box<StaticSession>('staticSessions').clear();
        }
        if (Hive.isBoxOpen('trainingTemplates')) {
          await Hive.box<TrainingTemplate>('trainingTemplates').clear();
        }
        if (Hive.isBoxOpen('dnf_session_summaries')) {
          await Hive.box<String>('dnf_session_summaries').clear();
        }
        if (Hive.isBoxOpen('dnf_best_evidence')) {
          await Hive.box<String>('dnf_best_evidence').clear();
        }
        if (Hive.isBoxOpen('dnf_preferences')) {
          await Hive.box('dnf_preferences').clear();
        }
        print('✅ All boxes cleared');
      } catch (e) {
        print('⚠️ Error clearing boxes: $e');
      }

      // 3. Close all boxes
      print('📦 Closing all Hive boxes...');
      try {
        if (Hive.isBoxOpen('userProfile')) {
          await Hive.box<UserProfile>('userProfile').close();
        }
        if (Hive.isBoxOpen('analysisResults')) {
          await Hive.box<AnalysisResult>('analysisResults').close();
        }
        if (Hive.isBoxOpen('staticSessions')) {
          await Hive.box<StaticSession>('staticSessions').close();
        }
        if (Hive.isBoxOpen('trainingTemplates')) {
          await Hive.box<TrainingTemplate>('trainingTemplates').close();
        }
        if (Hive.isBoxOpen('dnf_session_summaries')) {
          await Hive.box<String>('dnf_session_summaries').close();
        }
        if (Hive.isBoxOpen('dnf_best_evidence')) {
          await Hive.box<String>('dnf_best_evidence').close();
        }
        if (Hive.isBoxOpen('dnf_preferences')) {
          await Hive.box('dnf_preferences').close();
        }
        print('✅ All boxes closed');
      } catch (e) {
        print('⚠️ Error closing boxes: $e');
      }

      // 4. Delete individual boxes from disk (more reliable than deleteFromDisk)
      print('💣 Deleting boxes from disk...');
      try {
        await Hive.deleteBoxFromDisk('userProfile');
        await Hive.deleteBoxFromDisk('analysisResults');
        await Hive.deleteBoxFromDisk('staticSessions');
        await Hive.deleteBoxFromDisk('trainingTemplates');
        await Hive.deleteBoxFromDisk('dnf_session_summaries');
        await Hive.deleteBoxFromDisk('dnf_best_evidence');
        await Hive.deleteBoxFromDisk('dnf_preferences');
        print('✅ All boxes deleted from disk');
      } catch (e) {
        print('⚠️ Error deleting boxes: $e');
      }

      // 5. Also try deleteFromDisk as backup
      try {
        await Hive.deleteFromDisk();
        print('✅ Hive.deleteFromDisk() completed');
      } catch (e) {
        print('⚠️ deleteFromDisk error (can be ignored): $e');
      }

      // 6. Reopen dnf_preferences box and restore sample_shown flag
      print('📦 Restoring sample_shown flag...');
      try {
        final prefsBox = await Hive.openBox('dnf_preferences');
        await prefsBox.put('sample_shown', sampleShown);
        print('✅ sample_shown flag restored: $sampleShown');
        print('  ℹ️ This ensures user goes to onboarding, not sample experience');
      } catch (e) {
        print('⚠️ Could not restore sample_shown: $e');
      }

      await Future.delayed(const Duration(milliseconds: 500));
      print('✅ App reset complete! Closing app...');

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show final message and exit app - DON'T navigate anywhere
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Reset Complete!',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'All data has been completely deleted:',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                _buildResetItem('✓ All session data'),
                _buildResetItem('✓ User profile'),
                _buildResetItem('✓ Preferences'),
                _buildResetItem('✓ Storage files'),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 20),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Tap "Close App" and reopen to start fresh.',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Close App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ Error during reset: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _passportModel == null
                  ? _buildEmptyState()
                  : _buildPassportContent(),
        ),
      ),
      floatingActionButton: !_isLoading && _passportModel != null
          ? FloatingActionButton.extended(
              onPressed: _onCheckLevel,
              backgroundColor: _canCheckLevel
                  ? AppTheme.primaryBlue
                  : AppTheme.textSecondary.withOpacity(0.5),
              icon: Icon(
                _canCheckLevel ? Icons.check_circle : Icons.lock,
                color: Colors.white,
              ),
              label: Text(
                'Check Level',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pool,
              size: 80.sp,
              color: AppTheme.primaryBlue.withOpacity(0.5),
            ),
            SizedBox(height: 24.h),
            Text(
              'No Sessions Yet',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Upload your first DNF video to start tracking your technique and progress!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: _onUploadVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Upload First Video',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassportContent() {
    return Column(
      children: [
        // Header
        _buildHeader(),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 16.h),

                // Level Badge
                _buildLevelBadge(),
                SizedBox(height: 24.h),

                // Mission Card
                _buildMissionCard(),
                SizedBox(height: 24.h),

                // Component Grid
                Text(
                  'Components',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                _buildComponentGrid(),

                SizedBox(height: 100.h), // Space for floating button
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'DNF Coach',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: _showMenu,
            icon: Icon(
              Icons.menu,
              color: AppTheme.textPrimary,
              size: 28.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge() {
    final passport = _passportModel!;
    final isConfirmed = passport.levelState == LevelState.confirmed;

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isConfirmed
              ? AppTheme.primaryBlue.withOpacity(0.5)
              : AppTheme.accentYellow.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Level state badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isConfirmed
                  ? AppTheme.primaryBlue.withOpacity(0.2)
                  : AppTheme.accentYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isConfirmed ? '✅' : '📊',
                  style: TextStyle(fontSize: 16.sp),
                ),
                SizedBox(width: 8.w),
                Text(
                  isConfirmed ? 'CONFIRMED' : 'PROVISIONAL',
                  style: TextStyle(
                    color: isConfirmed ? AppTheme.primaryBlue : AppTheme.accentYellow,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Level value
          Text(
            'Level ${passport.levelValue}',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 48.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),

          // Coverage
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Coverage: ',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16.sp,
                ),
              ),
              Text(
                '${passport.coverageCount}/6 ✓',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '(${passport.validityNote})',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard() {
    final mission = _passportModel!.nextSuggestedMission;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.accentYellow.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🎯',
                style: TextStyle(fontSize: 24.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                'Weekly Mission',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Mission details
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppTheme.accentYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '📹',
                      style: TextStyle(fontSize: 20.sp),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Upload ${_getViewTypeName(mission.recommendedView)}',
                      style: TextStyle(
                        color: AppTheme.accentYellow,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  mission.shortTip,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Duration: ${mission.durationRequirement}',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Upload button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onUploadVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Start Mission',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentGrid() {
    final components = _passportModel!.components;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.1,
      ),
      itemCount: components.length,
      itemBuilder: (context, index) {
        return _buildComponentCard(components[index]);
      },
    );
  }

  Widget _buildComponentCard(ComponentPassportItem component) {
    final statusColor = _getStatusColor(component.status);
    final statusIcon = _getStatusIcon(component.status);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Component icon
          Text(
            _getComponentIcon(component.type),
            style: TextStyle(fontSize: 32.sp),
          ),
          SizedBox(height: 8.h),

          // Component name
          Text(
            _getComponentName(component.type),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),

          // Status indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                statusIcon,
                style: TextStyle(fontSize: 16.sp),
              ),
              SizedBox(width: 4.w),
              if (component.confidence != null)
                Text(
                  _getConfidenceName(component.confidence!),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods for enum display values
  Color _getStatusColor(ComponentStatus status) {
    switch (status) {
      case ComponentStatus.confirmed:
        return const Color(0xFF4CAF50); // Green
      case ComponentStatus.partial:
        return AppTheme.accentYellow;
      case ComponentStatus.notMeasurable:
      case ComponentStatus.measurableNoEvent:
        return AppTheme.textSecondary;
    }
  }

  String _getStatusIcon(ComponentStatus status) {
    switch (status) {
      case ComponentStatus.confirmed:
        return '✅';
      case ComponentStatus.partial:
        return '🟡';
      case ComponentStatus.notMeasurable:
      case ComponentStatus.measurableNoEvent:
        return '❌';
    }
  }

  String _getViewTypeName(ViewType type) {
    switch (type) {
      case ViewType.side:
        return 'SIDE view';
      case ViewType.front:
        return 'FRONT view';
      case ViewType.back:
        return 'BACK view';
      case ViewType.oblique:
        return 'OBLIQUE view';
      case ViewType.unknown:
        return 'any view';
    }
  }

  String _getConfidenceName(ConfidenceLabel label) {
    switch (label) {
      case ConfidenceLabel.high:
        return 'HIGH';
      case ConfidenceLabel.medium:
        return 'MED';
      case ConfidenceLabel.low:
        return 'LOW';
    }
  }

  String _getComponentIcon(ComponentType type) {
    switch (type) {
      case ComponentType.streamline:
        return '🏊';
      case ComponentType.glide:
        return '⏱️';
      case ComponentType.kick:
        return '🦵';
      case ComponentType.arm:
        return '💪';
      case ComponentType.start:
        return '🚀';
      case ComponentType.turn:
        return '🔄';
    }
  }

  String _getComponentName(ComponentType type) {
    switch (type) {
      case ComponentType.streamline:
        return 'Streamline';
      case ComponentType.glide:
        return 'Glide';
      case ComponentType.kick:
        return 'Kick';
      case ComponentType.arm:
        return 'Arm Stroke';
      case ComponentType.start:
        return 'Start';
      case ComponentType.turn:
        return 'Turn';
    }
  }
}
