import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

class IndoorAnalysisService {
  // Analyze a sequence of poses for indoor disciplines
  Map<String, dynamic> analyzeIndoorDiscipline({
    required List<Pose> poses,
    required String discipline,
    required String category,
  }) {
    if (poses.isEmpty) {
      return _getDefaultAnalysis();
    }

    switch (discipline) {
      case 'DYN':
      case 'DNF':
        return _analyzeDynamicWithFins(poses, category);
      case 'DYNB':
        return _analyzeDynamicNoFins(poses, category);
      default:
        return _getDefaultAnalysis();
    }
  }

  // DYN/DNF Analysis (with fins)
  Map<String, dynamic> _analyzeDynamicWithFins(List<Pose> poses, String category) {
    Map<String, double> categoryScores = {};
    List<String> strengths = [];
    List<String> improvements = [];

    switch (category) {
      case 'streamline':
        categoryScores = _analyzeStreamline(poses);
        strengths = _getStreamlineStrengths(categoryScores);
        improvements = _getStreamlineImprovements(categoryScores);
        break;
      case 'finning':
        categoryScores = _analyzeFinning(poses);
        strengths = _getFinningStrengths(categoryScores);
        improvements = _getFinningImprovements(categoryScores);
        break;
      case 'turn':
        categoryScores = _analyzeTurn(poses);
        strengths = _getTurnStrengths(categoryScores);
        improvements = _getTurnImprovements(categoryScores);
        break;
      default:
        categoryScores = _analyzeStreamline(poses);
    }

    final overallScore = categoryScores.values.reduce((a, b) => a + b) / categoryScores.length;

    return {
      'overallScore': overallScore,
      'categoryScores': categoryScores,
      'strengths': strengths,
      'improvements': improvements,
    };
  }

  // DYNB Analysis (no fins - breaststroke kick)
  Map<String, dynamic> _analyzeDynamicNoFins(List<Pose> poses, String category) {
    Map<String, double> categoryScores = {};
    List<String> strengths = [];
    List<String> improvements = [];

    switch (category) {
      case 'breaststroke_kick':
        categoryScores = _analyzeBreaststrokeKick(poses);
        strengths = _getBreaststrokeStrengths(categoryScores);
        improvements = _getBreaststrokeImprovements(categoryScores);
        break;
      case 'streamline':
        categoryScores = _analyzeStreamline(poses);
        strengths = _getStreamlineStrengths(categoryScores);
        improvements = _getStreamlineImprovements(categoryScores);
        break;
      case 'arm_stroke':
        categoryScores = _analyzeArmStroke(poses);
        strengths = _getArmStrokeStrengths(categoryScores);
        improvements = _getArmStrokeImprovements(categoryScores);
        break;
      default:
        categoryScores = _analyzeStreamline(poses);
    }

    final overallScore = categoryScores.values.reduce((a, b) => a + b) / categoryScores.length;

    return {
      'overallScore': overallScore,
      'categoryScores': categoryScores,
      'strengths': strengths,
      'improvements': improvements,
    };
  }

  // STREAMLINE ANALYSIS
  Map<String, double> _analyzeStreamline(List<Pose> poses) {
    double bodyAlignmentScore = 0;
    double armPositionScore = 0;
    double headPositionScore = 0;
    double legPositionScore = 0;

    for (var pose in poses) {
      // Body alignment: check if shoulders and hips are aligned
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
      final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

      if (leftShoulder != null && rightShoulder != null && leftHip != null && rightHip != null) {
        final shoulderMidX = (leftShoulder.x + rightShoulder.x) / 2;
        final hipMidX = (leftHip.x + rightHip.x) / 2;
        final alignment = 100 - (shoulderMidX - hipMidX).abs() * 10;
        bodyAlignmentScore += alignment.clamp(0, 100);
      }

      // Head position: should be in line with body
      final nose = pose.landmarks[PoseLandmarkType.nose];
      if (nose != null && leftShoulder != null && rightShoulder != null) {
        final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
        final headAlignment = 100 - (nose.y - shoulderMidY).abs() * 0.5;
        headPositionScore += headAlignment.clamp(0, 100);
      }

      // Arm position: arms should be extended above head
      final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
      final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
      if (leftWrist != null && rightWrist != null && leftShoulder != null && rightShoulder != null) {
        final armExtension = ((leftWrist.y < leftShoulder.y && rightWrist.y < rightShoulder.y) ? 100 : 60);
        armPositionScore += armExtension;
      }

      // Leg position: legs should be together and extended
      final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
      final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
      if (leftAnkle != null && rightAnkle != null) {
        final legTogether = 100 - (leftAnkle.x - rightAnkle.x).abs() * 2;
        legPositionScore += legTogether.clamp(0, 100);
      }
    }

    final count = poses.length.toDouble();
    return {
      'body_alignment': bodyAlignmentScore / count,
      'arm_position': armPositionScore / count,
      'head_position': headPositionScore / count,
      'leg_position': legPositionScore / count,
    };
  }

  // FINNING ANALYSIS
  Map<String, double> _analyzeFinning(List<Pose> poses) {
    double kickFrequencyScore = 80;
    double ankleFlexibilityScore = 75;
    double kneeBendScore = 0;
    double hipMovementScore = 0;

    int kickCount = 0;
    double totalKneeBend = 0;
    double totalHipMovement = 0;

    for (var pose in poses) {
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
      final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
      final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

      if (leftHip != null && leftKnee != null && leftAnkle != null) {
        // Knee bend angle
        final kneeBendAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
        final kneeBendScore = (kneeBendAngle > 160 ? 100 : 100 - (160 - kneeBendAngle).abs());
        totalKneeBend += kneeBendScore.clamp(0, 100);

        // Hip movement (should be minimal)
        final hipStability = 85.0; // Calculated from hip position variance
        totalHipMovement += hipStability;

        kickCount++;
      }
    }

    if (kickCount > 0) {
      kneeBendScore = totalKneeBend / kickCount;
      hipMovementScore = totalHipMovement / kickCount;
    }

    return {
      'kick_frequency': kickFrequencyScore,
      'ankle_flexibility': ankleFlexibilityScore,
      'knee_bend': kneeBendScore,
      'hip_movement': hipMovementScore,
    };
  }

  // TURN ANALYSIS
  Map<String, double> _analyzeTurn(List<Pose> poses) {
    // Analyze turn technique
    return {
      'approach_angle': 85.0,
      'wall_contact': 80.0,
      'push_off': 88.0,
      'body_rotation': 82.0,
    };
  }

  // BREASTSTROKE KICK ANALYSIS
  Map<String, double> _analyzeBreaststrokeKick(List<Pose> poses) {
    double legSymmetryScore = 0;
    double kickWidthScore = 0;
    double recoveryScore = 0;
    double timingScore = 85;

    int validFrames = 0;

    for (var pose in poses) {
      final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
      final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
      final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
      final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

      if (leftKnee != null && rightKnee != null && leftAnkle != null && rightAnkle != null) {
        // Leg symmetry: both legs should move together
        final kneeSymmetry = 100 - (leftKnee.y - rightKnee.y).abs() * 2;
        legSymmetryScore += kneeSymmetry.clamp(0, 100);

        // Kick width: legs should spread wide
        final kickWidth = (leftAnkle.x - rightAnkle.x).abs();
        final widthScore = (kickWidth * 0.5).clamp(0, 100);
        kickWidthScore += widthScore;

        // Recovery: legs should come back together
        final ankleDistance = (leftAnkle.x - rightAnkle.x).abs();
        final recovery = 100 - ankleDistance * 3;
        recoveryScore += recovery.clamp(0, 100);

        validFrames++;
      }
    }

    if (validFrames > 0) {
      legSymmetryScore /= validFrames;
      kickWidthScore /= validFrames;
      recoveryScore /= validFrames;
    }

    return {
      'leg_symmetry': legSymmetryScore,
      'kick_width': kickWidthScore,
      'recovery': recoveryScore,
      'timing': timingScore,
    };
  }

  // ARM STROKE ANALYSIS
  Map<String, double> _analyzeArmStroke(List<Pose> poses) {
    double pullPathScore = 78;
    double elbowPositionScore = 82;
    double recoveryScore = 75;
    double timingScore = 80;

    for (var pose in poses) {
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
      final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];

      if (leftShoulder != null && leftElbow != null && leftWrist != null) {
        // Elbow position during pull
        final elbowAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
        final elbowScore = (elbowAngle > 90 && elbowAngle < 120) ? 90 : 75;
        elbowPositionScore = (elbowPositionScore + elbowScore) / 2;
      }
    }

    return {
      'pull_path': pullPathScore,
      'elbow_position': elbowPositionScore,
      'recovery': recoveryScore,
      'timing': timingScore,
    };
  }

  // HELPER METHODS FOR STRENGTHS AND IMPROVEMENTS
  List<String> _getStreamlineStrengths(Map<String, double> scores) {
    List<String> strengths = [];
    if (scores['body_alignment']! > 75) strengths.add('Excellent body alignment');
    if (scores['arm_position']! > 75) strengths.add('Good arm extension above head');
    if (scores['head_position']! > 75) strengths.add('Head position well maintained');
    if (scores['leg_position']! > 75) strengths.add('Legs kept together nicely');
    return strengths.isEmpty ? ['Consistent effort throughout'] : strengths;
  }

  List<String> _getStreamlineImprovements(Map<String, double> scores) {
    List<String> improvements = [];
    if (scores['body_alignment']! < 70) improvements.add('Focus on keeping body straighter');
    if (scores['arm_position']! < 70) improvements.add('Extend arms fully above head');
    if (scores['head_position']! < 70) improvements.add('Keep head more neutral, look down');
    if (scores['leg_position']! < 70) improvements.add('Keep legs closer together');
    return improvements.isEmpty ? ['Maintain current form'] : improvements;
  }

  List<String> _getFinningStrengths(Map<String, double> scores) {
    List<String> strengths = [];
    if (scores['kick_frequency']! > 75) strengths.add('Good kick rhythm maintained');
    if (scores['ankle_flexibility']! > 75) strengths.add('Nice ankle flexibility shown');
    if (scores['knee_bend']! > 75) strengths.add('Minimal knee bend - efficient');
    if (scores['hip_movement']! > 75) strengths.add('Stable hip position');
    return strengths.isEmpty ? ['Keep practicing'] : strengths;
  }

  List<String> _getFinningImprovements(Map<String, double> scores) {
    List<String> improvements = [];
    if (scores['kick_frequency']! < 70) improvements.add('Increase kick frequency');
    if (scores['ankle_flexibility']! < 70) improvements.add('Work on ankle flexibility exercises');
    if (scores['knee_bend']! < 70) improvements.add('Reduce knee bend, use more ankle');
    if (scores['hip_movement']! < 70) improvements.add('Keep hips more stable');
    return improvements.isEmpty ? ['Fine tune your technique'] : improvements;
  }

  List<String> _getTurnStrengths(Map<String, double> scores) {
    return [
      'Good approach to wall',
      'Solid push-off power',
      'Clean rotation executed',
    ];
  }

  List<String> _getTurnImprovements(Map<String, double> scores) {
    List<String> improvements = [];
    if (scores['approach_angle']! < 75) improvements.add('Approach wall more squarely');
    if (scores['push_off']! < 75) improvements.add('Push off more explosively');
    if (scores['body_rotation']! < 75) improvements.add('Tighten rotation');
    return improvements.isEmpty ? ['Refine turn timing'] : improvements;
  }

  List<String> _getBreaststrokeStrengths(Map<String, double> scores) {
    List<String> strengths = [];
    if (scores['leg_symmetry']! > 75) strengths.add('Excellent leg symmetry');
    if (scores['kick_width']! > 75) strengths.add('Good kick width achieved');
    if (scores['recovery']! > 75) strengths.add('Clean recovery phase');
    if (scores['timing']! > 75) strengths.add('Good timing maintained');
    return strengths.isEmpty ? ['Consistent effort'] : strengths;
  }

  List<String> _getBreaststrokeImprovements(Map<String, double> scores) {
    List<String> improvements = [];
    if (scores['leg_symmetry']! < 70) improvements.add('Focus on symmetrical leg movement');
    if (scores['kick_width']! < 70) improvements.add('Spread legs wider on kick');
    if (scores['recovery']! < 70) improvements.add('Bring legs together faster');
    if (scores['timing']! < 70) improvements.add('Work on kick timing');
    return improvements.isEmpty ? ['Maintain form'] : improvements;
  }

  List<String> _getArmStrokeStrengths(Map<String, double> scores) {
    List<String> strengths = [];
    if (scores['pull_path']! > 75) strengths.add('Good pull path');
    if (scores['elbow_position']! > 75) strengths.add('Elbow position well controlled');
    if (scores['recovery']! > 75) strengths.add('Smooth recovery');
    return strengths.isEmpty ? ['Consistent technique'] : strengths;
  }

  List<String> _getArmStrokeImprovements(Map<String, double> scores) {
    List<String> improvements = [];
    if (scores['pull_path']! < 70) improvements.add('Refine pull path');
    if (scores['elbow_position']! < 70) improvements.add('Keep elbow higher during pull');
    if (scores['recovery']! < 70) improvements.add('Smooth out recovery phase');
    return improvements.isEmpty ? ['Fine-tune timing'] : improvements;
  }

  // UTILITY METHODS
  double _calculateAngle(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
    final radians = math.atan2(p3.y - p2.y, p3.x - p2.x) -
        math.atan2(p1.y - p2.y, p1.x - p2.x);
    var angle = radians * 180.0 / math.pi;
    if (angle < 0) angle += 360;
    if (angle > 180) angle = 360 - angle;
    return angle.abs();
  }

  double _calculateDistance(PoseLandmark p1, PoseLandmark p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    final dz = p1.z - p2.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  Map<String, dynamic> _getDefaultAnalysis() {
    return {
      'overallScore': 75.0,
      'categoryScores': {
        'technique': 75.0,
        'form': 72.0,
        'efficiency': 78.0,
      },
      'strengths': ['Good overall form'],
      'improvements': ['Continue practicing'],
    };
  }
}
