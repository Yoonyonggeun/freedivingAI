import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/ui/share_card_model.dart';
import '../../../models/ui/enums.dart';

/// Share Card Screen - Display shareable level card with screenshot capability.
///
/// Features:
/// - Visual card showing level state, value, coverage
/// - Improvement line (if previous sessions exist)
/// - Next mission suggestion
/// - Native screenshot capture (2x pixel ratio)
/// - Native share dialog integration
class ShareCardScreen extends StatefulWidget {
  final ShareCardModel cardData;
  final String sessionId;

  const ShareCardScreen({
    super.key,
    required this.cardData,
    required this.sessionId,
  });

  @override
  State<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends State<ShareCardScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isCapturing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Your Progress'),
        backgroundColor: AppTheme.backgroundDark,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Scrollable card content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Center(
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: _ShareCardContent(cardData: widget.cardData),
                    ),
                  ),
                ),
              ),

              // Bottom CTAs
              _buildBottomCTAs(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCTAs() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary: Share button
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: ElevatedButton(
                onPressed: _isCapturing ? null : _onShareImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
                child: _isCapturing
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.share, color: Colors.white),
                          SizedBox(width: 8.w),
                          Text(
                            'Share as Image',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          SizedBox(height: 12.h),

          // Secondary: Back button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.textSecondary, width: 1.5),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
              ),
              child: Text(
                'Back to Report',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Capture the card as PNG image using RenderRepaintBoundary.
  Future<Uint8List?> _captureShareCard() async {
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Could not find render boundary');
      }

      // Capture at 2x pixel ratio for quality
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing card: $e');
      return null;
    }
  }

  /// Share the card image using native share dialog.
  Future<void> _onShareImage() async {
    setState(() => _isCapturing = true);

    try {
      final imageBytes = await _captureShareCard();

      if (imageBytes == null) {
        if (!mounted) return;
        _showError('Failed to capture image. Please try again.');
        return;
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/dnf_coach_level.png');
      await file.writeAsBytes(imageBytes);

      // Share via native dialog
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'DNF Coach Level ${widget.cardData.levelValue}',
      );

      if (!mounted) return;

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ready to share!'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
      if (!mounted) return;
      _showError('Failed to share. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: AppTheme.accentYellow,
      ),
    );
  }
}

/// Isolated widget for screenshot capture.
/// Contains the visual card content that will be shared.
class _ShareCardContent extends StatelessWidget {
  final ShareCardModel cardData;

  const _ShareCardContent({required this.cardData});

  @override
  Widget build(BuildContext context) {
    final isConfirmed = cardData.levelState == LevelState.confirmed;

    return Container(
      constraints: BoxConstraints(maxWidth: 400.w),
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isConfirmed
              ? AppTheme.primaryBlue.withOpacity(0.6)
              : AppTheme.accentYellow.withOpacity(0.6),
          width: 3,
        ),
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceDark,
            AppTheme.backgroundDark.withOpacity(0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'DNF COACH',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(width: 8.w),
              Text('🏊', style: TextStyle(fontSize: 20.sp)),
            ],
          ),

          SizedBox(height: 24.h),

          // Level state badge
          _buildLevelStateBadge(isConfirmed),

          SizedBox(height: 20.h),

          // Level value (large)
          Text(
            'Level ${cardData.levelValue}',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 56.sp,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),

          SizedBox(height: 16.h),

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
                '${cardData.coverageCount}/6 ✓',
                style: TextStyle(
                  color: isConfirmed ? AppTheme.primaryBlue : AppTheme.accentYellow,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Divider
          Divider(color: AppTheme.textSecondary.withOpacity(0.2)),

          SizedBox(height: 20.h),

          // Improvement line (conditional)
          if (cardData.improvementLine != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                cardData.improvementLine!,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20.h),
          ],

          // Next mission
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppTheme.accentYellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              cardData.nextMissionLine,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: 20.h),

          // Divider
          Divider(color: AppTheme.textSecondary.withOpacity(0.2)),

          SizedBox(height: 16.h),

          // Disclaimer
          Text(
            cardData.disclaimer,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelStateBadge(bool isConfirmed) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isConfirmed
            ? AppTheme.primaryBlue.withOpacity(0.2)
            : AppTheme.accentYellow.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isConfirmed
              ? AppTheme.primaryBlue.withOpacity(0.4)
              : AppTheme.accentYellow.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isConfirmed ? '✅' : '📊',
            style: TextStyle(fontSize: 18.sp),
          ),
          SizedBox(width: 10.w),
          Text(
            isConfirmed ? 'CONFIRMED' : 'PROVISIONAL',
            style: TextStyle(
              color: isConfirmed ? AppTheme.primaryBlue : AppTheme.accentYellow,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
