import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/analysis_result.dart';
import '../../../models/user_profile.dart';
import '../../analysis/screens/analysis_result_screen.dart';

class VideoGuideScreen extends StatelessWidget {
  final String discipline;
  final String category;

  const VideoGuideScreen({
    super.key,
    required this.discipline,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final guideInfo = _getGuideInfo();

    return Scaffold(
      appBar: AppBar(
        title: Text('${_formatCategory(category)} Guide'),
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
                // Guide illustration
                _buildGuideIllustration(guideInfo),
                SizedBox(height: 32.h),
                // Camera angle
                _buildInfoCard(
                  'Camera Angle',
                  guideInfo['cameraAngle'],
                  Icons.videocam,
                  AppTheme.primaryBlue,
                ),
                SizedBox(height: 16.h),
                // Distance
                _buildInfoCard(
                  'Distance',
                  guideInfo['distance'],
                  Icons.straighten,
                  AppTheme.primaryPurple,
                ),
                SizedBox(height: 16.h),
                // Tips
                _buildTipsCard(guideInfo['tips']),
                const Spacer(),
                // Action buttons
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideIllustration(Map<String, dynamic> guideInfo) {
    return Container(
      width: double.infinity,
      height: 200.h,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Background
          Center(
            child: Icon(
              guideInfo['illustrationIcon'],
              size: 120.sp,
              color: AppTheme.primaryBlue.withOpacity(0.1),
            ),
          ),
          // Guide text overlay
          Positioned(
            top: 16.h,
            left: 16.w,
            right: 16.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                guideInfo['cameraAngle'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Center guide
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person,
                  size: 60.sp,
                  color: AppTheme.primaryBlue,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Position yourself\nin frame',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  content,
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

  Widget _buildTipsCard(List<String> tips) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.accentYellow,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Tips',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...tips.map((tip) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 6.h),
                      width: 4.w,
                      height: 4.w,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Record video button
        _buildButton(
          'Record Video',
          Icons.videocam,
          AppTheme.primaryGradient,
          () => _pickVideo(context, ImageSource.camera),
        ),
        SizedBox(height: 12.h),
        // Choose from gallery button
        _buildButton(
          'Choose from Gallery',
          Icons.photo_library,
          null,
          () => _pickVideo(context, ImageSource.gallery),
          outlined: true,
        ),
      ],
    );
  }

  Widget _buildButton(
    String text,
    IconData icon,
    Gradient? gradient,
    VoidCallback onTap, {
    bool outlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          gradient: gradient,
          color: outlined ? null : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(28.r),
          border: outlined
              ? Border.all(color: AppTheme.primaryBlue, width: 2)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppTheme.textPrimary,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              text,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideo(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();

    try {
      final video = await picker.pickVideo(source: source);

      if (video != null && context.mounted) {
        // Show analyzing dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Analyzing your technique...',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This may take a moment',
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

        // Simulate analysis delay
        await Future.delayed(const Duration(seconds: 3));

        // Generate dummy analysis result
        final result = _generateDummyAnalysis(video.path);

        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AnalysisResultScreen(result: result),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  AnalysisResult _generateDummyAnalysis(String videoPath) {
    // Get user profile for context-aware analysis
    final profileBox = Hive.box<UserProfile>('userProfile');
    final profile = profileBox.get('current');

    // Generate realistic dummy data based on category AND user level
    final Map<String, double> categoryScores = _getCategoryScores(profile);
    final double overallScore = categoryScores.values.reduce((a, b) => a + b) / categoryScores.length;

    return AnalysisResult(
      id: const Uuid().v4(),
      userId: 'current',
      discipline: discipline,
      videoPath: videoPath,
      category: category,
      overallScore: overallScore,
      categoryScores: categoryScores,
      strengths: _getStrengths(profile),
      improvements: _getImprovements(profile),
      drillRecommendations: _getDrills(profile),
      createdAt: DateTime.now(),
    );
  }

  Map<String, double> _getCategoryScores(UserProfile? profile) {
    // Adjust scores based on user level
    double levelModifier = 1.0;
    if (profile != null) {
      switch (profile.diverLevel) {
        case 'beginner':
          levelModifier = 0.85; // Lower baseline for beginners
          break;
        case 'intermediate':
          levelModifier = 0.95;
          break;
        case 'advanced':
          levelModifier = 1.05;
          break;
        case 'elite':
          levelModifier = 1.15; // Higher expectations for elite
          break;
      }
    }

    Map<String, double> baseScores;
    switch (category) {
      case 'streamline':
        baseScores = {
          'body_alignment': 75.0,
          'arm_position': 70.0,
          'head_position': 72.0,
          'leg_position': 68.0,
        };
        break;
      case 'finning':
        baseScores = {
          'kick_frequency': 70.0,
          'ankle_flexibility': 65.0,
          'knee_bend': 75.0,
          'hip_movement': 72.0,
        };
        break;
      case 'turn':
        baseScores = {
          'approach_angle': 80.0,
          'wall_contact': 85.0,
          'push_off': 78.0,
          'body_rotation': 75.0,
        };
        break;
      default:
        baseScores = {
          'technique': 70.0,
          'form': 75.0,
          'efficiency': 68.0,
        };
    }

    // Apply level modifier
    return baseScores.map((key, value) => MapEntry(
      key,
      (value * levelModifier).clamp(0, 100),
    ));
  }

  List<String> _getStrengths(UserProfile? profile) {
    String levelContext = profile != null ? _getLevelContext(profile.diverLevel) : '';

    switch (category) {
      case 'streamline':
        return [
          'Good body alignment in horizontal position$levelContext',
          'Arms extended above head showing proper form',
          'Streamlined position reducing drag effectively',
        ];
      case 'finning':
        return [
          'Consistent kick rhythm maintained$levelContext',
          'Good ankle flexibility observed for your level',
          'Controlled knee movement during kicks',
        ];
      case 'turn':
        return [
          'Solid push-off from the wall$levelContext',
          'Efficient rotation during turn',
          'Good streamline recovery after turn',
        ];
      default:
        return [
          'Good overall technique$levelContext',
          'Consistent form maintained throughout',
        ];
    }
  }

  List<String> _getImprovements(UserProfile? profile) {
    bool isBeginner = profile?.diverLevel == 'beginner';
    bool isElite = profile?.diverLevel == 'elite';

    switch (category) {
      case 'streamline':
        if (isBeginner) {
          return [
            'Great start! Try to keep your head more neutral',
            'Work on maintaining hip height - this comes with practice',
            'Point your toes more to improve streamline',
          ];
        } else if (isElite) {
          return [
            'Micro-adjustment needed: slight head lift detected',
            'Hip position drops 2-3cm in mid-glide - tighten core',
            'Maximize toe point for competitive edge',
          ];
        }
        return [
          'Keep neck more neutral to reduce drag',
          'Maintain hip height throughout glide',
          'Point toes more for better streamline',
        ];
      case 'finning':
        if (isBeginner) {
          return [
            'Good progress! Try to kick with more amplitude',
            'Reduce the pause between kicks as you build endurance',
            'Keep practicing - your technique is developing well',
          ];
        } else if (isElite) {
          return [
            'Increase kick amplitude by 10-15% for competition',
            'Eliminate micro-pauses between kicks',
            'Fine-tune fin overlap at kick apex',
          ];
        }
        return [
          'Increase kick amplitude for more propulsion',
          'Reduce pause between kicks',
          'Keep fins closer at the top of kick',
        ];
      case 'turn':
        if (isBeginner) {
          return [
            'Nice turn! Build more speed on approach with practice',
            'As you improve, tuck your knees tighter',
            'Good job - keep working on arm extension timing',
          ];
        } else if (isElite) {
          return [
            'Maximize approach velocity for faster turns',
            'Tighten tuck rotation - aim for <1 second',
            'Optimize arm extension timing by 0.2s earlier',
          ];
        }
        return [
          'Approach with more speed',
          'Tuck knees tighter during rotation',
          'Extend arms earlier after push-off',
        ];
      default:
        return [
          'Focus on maintaining consistency',
          'Work on efficiency improvements',
        ];
    }
  }

  String _getLevelContext(String level) {
    switch (level) {
      case 'beginner':
        return ' - excellent for your level!';
      case 'intermediate':
        return ' - showing good progress';
      case 'advanced':
        return ' - well executed';
      case 'elite':
        return ' - competition ready';
      default:
        return '';
    }
  }

  List<String> _getDrills(UserProfile? profile) {
    bool isBeginner = profile?.diverLevel == 'beginner';
    bool isElite = profile?.diverLevel == 'elite';

    switch (category) {
      case 'streamline':
        if (isBeginner) {
          return [
            'Basic wall push-offs: 5-second glides (10 reps)',
            'Superman position practice on deck',
            'Body alignment drills with coach feedback',
          ];
        } else if (isElite) {
          return [
            'Competition streamline holds: 15+ seconds',
            'Hydrodynamic position optimization drills',
            'Video analysis with frame-by-frame review',
          ];
        }
        return [
          'Wall push-offs with 10-second glides',
          'Superman drill with extension focus',
          'Partner alignment checks',
        ];
      case 'finning':
        if (isBeginner) {
          return [
            'Vertical kicking drill (15 seconds x 3)',
            'Basic ankle flexibility exercises',
            'Slow-motion kicking with coach',
          ];
        } else if (isElite) {
          return [
            'High-intensity vertical kicking (45s x 6)',
            'Resistance band ankle strengthening',
            'Power finning intervals with lactate management',
          ];
        }
        return [
          'Vertical kicking drill (30 seconds x 4)',
          'Ankle flexibility exercises',
          'Mirror feedback sessions',
        ];
      case 'turn':
        if (isBeginner) {
          return [
            'Basic somersault practice (shallow end)',
            'Wall touch drills (no rotation)',
            'Turn technique breakdown (5 reps)',
          ];
        } else if (isElite) {
          return [
            'Competition turn simulations with timing',
            'Explosive push-off power training',
            'Turn optimization: sub-1-second rotations',
          ];
        }
        return [
          'Somersault drills on pool floor',
          'Wall touch and push-off reps (10x)',
          'Full turn practice with timing',
        ];
      default:
        return [
          'Technique-focused drills',
          'Video review sessions',
          'Slow-motion practice',
        ];
    }
  }

  Map<String, dynamic> _getGuideInfo() {
    // Default guide info
    final Map<String, dynamic> defaultInfo = {
      'cameraAngle': 'Side view - Full body',
      'distance': '2-3 meters from camera',
      'tips': [
        'Ensure good lighting',
        'Keep entire body in frame',
        'Film the complete movement',
      ],
      'illustrationIcon': Icons.person,
    };

    // Category-specific guides
    switch (category) {
      case 'streamline':
        return {
          ...defaultInfo,
          'cameraAngle': 'Side view - Full body visible',
          'tips': [
            'Film from the side to see body alignment',
            'Include head to feet in frame',
            'Stable camera position',
          ],
        };
      case 'finning':
      case 'dolphin_kick':
        return {
          ...defaultInfo,
          'cameraAngle': 'Side view - Lower body focus',
          'distance': '2-3 meters',
          'tips': [
            'Focus on leg and fin movement',
            'Capture multiple fin cycles',
            'Ensure fins are fully visible',
          ],
        };
      case 'arm_stroke':
        return {
          ...defaultInfo,
          'cameraAngle': 'Front or above water view',
          'tips': [
            'Capture full arm extension',
            'Film several stroke cycles',
            'Clear view of hand entry and exit',
          ],
        };
      case 'breaststroke_kick':
        return {
          ...defaultInfo,
          'cameraAngle': 'Back view - Lower body',
          'tips': [
            'Film from behind to see leg symmetry',
            'Capture complete kick cycle',
            'Include hips and feet',
          ],
        };
      case 'turn':
        return {
          ...defaultInfo,
          'cameraAngle': 'Side view at wall',
          'distance': '3-4 meters from wall',
          'tips': [
            'Capture approach and exit',
            'Film the complete turn',
            'Keep wall and swimmer in frame',
          ],
        };
      case 'duck_dive':
      case 'entry':
      case 'start':
        return {
          ...defaultInfo,
          'cameraAngle': 'Side view from surface',
          'tips': [
            'Capture surface to underwater transition',
            'Film the initial dive sequence',
            'Include body entry and first few meters',
          ],
        };
      default:
        return defaultInfo;
    }
  }

  String _formatCategory(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
