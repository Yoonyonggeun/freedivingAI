import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_profile.dart';
import '../../../utils/level_calculator.dart';
import 'provisional_level_screen.dart';

class DNFPBInputScreen extends StatefulWidget {
  const DNFPBInputScreen({super.key});

  @override
  State<DNFPBInputScreen> createState() => _DNFPBInputScreenState();
}

class _DNFPBInputScreenState extends State<DNFPBInputScreen> {
  final TextEditingController _pbController = TextEditingController();
  String _poolLength = '25m';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingPB();
  }

  void _loadExistingPB() {
    final profileBox = Hive.box<UserProfile>('userProfile');
    final profile = profileBox.get('current');

    if (profile != null && profile.personalBests.containsKey('DNF')) {
      _pbController.text = profile.personalBests['DNF']!.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DNF Personal Best'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Scrollable content area
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'What\'s your current DNF distance?',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'This helps us calibrate analysis for your level',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 32.h),

                      // PB Input
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.pool,
                                  color: AppTheme.primaryBlue,
                                  size: 24.sp,
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  'DNF Distance',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),

                            // TextField
                            TextField(
                              controller: _pbController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16.sp),
                              decoration: InputDecoration(
                                hintText: 'e.g. 50',
                                hintStyle: TextStyle(color: AppTheme.textSecondary),
                                suffixText: 'm',
                                suffixStyle: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontSize: 16.sp,
                                ),
                                filled: true,
                                fillColor: AppTheme.backgroundDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryBlue.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryBlue,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Pool length selector
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pool Length',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16.sp,
                              ),
                            ),
                            DropdownButton<String>(
                              value: _poolLength,
                              dropdownColor: AppTheme.surfaceDark,
                              items: ['25m', '50m'].map((length) {
                                return DropdownMenuItem(
                                  value: length,
                                  child: Text(
                                    length,
                                    style: TextStyle(color: AppTheme.textPrimary),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _poolLength = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Fixed bottom button area (floating)
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Skip button
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Skip for now',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Continue button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveAndContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20.h,
                      width: 20.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveAndContinue() async {
    setState(() => _isLoading = true);

    final pbAndLevel = await _updateUserProfile();

    setState(() => _isLoading = false);

    if (pbAndLevel != null) {
      _navigateToProvisionalLevel(pbAndLevel['pb']!, pbAndLevel['level']!);
    }
  }

  Future<Map<String, dynamic>?> _updateUserProfile() async {
    final profileBox = Hive.box<UserProfile>('userProfile');
    final profile = profileBox.get('current');

    if (profile == null) return null;

    final pbText = _pbController.text.trim();
    if (pbText.isNotEmpty) {
      final pb = double.tryParse(pbText);
      if (pb != null && pb > 0) {
        // Save PB
        profile.personalBests['DNF'] = pb;

        // Calculate provisional level using 5-tier system
        final provisionalLevel = LevelCalculator.calculateProvisionalLevel(pb);
        profile.provisionalLevel = provisionalLevel;

        // Keep legacy diverLevel for backward compatibility
        profile.diverLevel = _legacyLevelString(provisionalLevel);

        profile.updatedAt = DateTime.now();
        await profile.save();

        print('[DNF PB] Saved: ${pb}m, Provisional level: $provisionalLevel');

        return {'pb': pb, 'level': provisionalLevel};
      }
    }

    return null;
  }

  String _legacyLevelString(int level) {
    // Map 5-tier to legacy string levels for backward compatibility
    switch (level) {
      case 1:
        return 'beginner';
      case 2:
      case 3:
        return 'intermediate';
      case 4:
        return 'advanced';
      case 5:
        return 'elite';
      default:
        return 'beginner';
    }
  }

  void _navigateToProvisionalLevel(double pb, int level) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProvisionalLevelScreen(
          provisionalLevel: level,
          pbDistance: pb,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pbController.dispose();
    super.dispose();
  }
}
