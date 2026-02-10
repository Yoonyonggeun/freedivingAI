class AppConstants {
  // App Info
  static const String appName = 'FreeDiving AI';
  static const String appVersion = '1.0.0';

  // Disciplines
  static const List<String> disciplines = [
    'DYN',   // Dynamic with Fins
    'DNF',   // Dynamic No Fins
    'DYNB',  // Dynamic Bi-Fins
    'CWT',   // Constant Weight
    'CNF',   // Constant No Fins
    'FIM',   // Free Immersion
    'STA',   // Static Apnea
  ];

  // Diver Levels
  static const List<Map<String, String>> diverLevels = [
    {'label': 'Beginner', 'description': '0-2 years', 'value': 'beginner'},
    {'label': 'Intermediate', 'description': '3-5 years', 'value': 'intermediate'},
    {'label': 'Advanced', 'description': '6+ years', 'value': 'advanced'},
    {'label': 'Elite/Competitive', 'description': 'Competition level', 'value': 'elite'},
  ];

  // Competition Levels
  static const List<Map<String, String>> competitionLevels = [
    {'label': 'Never competed', 'description': 'Training for personal improvement', 'value': 'never'},
    {'label': 'Occasionally', 'description': 'Occasional local competitions', 'value': 'occasional'},
    {'label': 'Regularly', 'description': 'Regular competition participation', 'value': 'regular'},
    {'label': 'Elite level', 'description': 'National/international competitions', 'value': 'elite'},
  ];

  // Training Goals
  static const List<Map<String, String>> trainingGoals = [
    {'label': 'Personal Best', 'description': 'Break personal records', 'value': 'pb'},
    {'label': 'Competition Prep', 'description': 'Prepare for competitions', 'value': 'competition'},
    {'label': 'Technique Improvement', 'description': 'Improve form and efficiency', 'value': 'technique'},
    {'label': 'Hobby/Fun', 'description': 'Casual training and enjoyment', 'value': 'hobby'},
  ];

  // Video Analysis Categories
  static const Map<String, List<String>> analysisCategories = {
    'DYN': ['streamline', 'finning', 'head_position', 'turn', 'entry'],
    'DNF': ['streamline', 'arm_stroke', 'breaststroke_kick', 'head_position', 'turn', 'start'],
    'DYNB': ['streamline', 'dolphin_kick', 'head_position', 'turn', 'entry'],
    'CWT': ['duck_dive', 'finning', 'arm_stroke', 'head_position'],
    'CNF': ['duck_dive', 'arm_stroke', 'breaststroke_kick', 'head_position'],
    'FIM': ['entry', 'pulling_technique', 'head_position', 'ascent'],
  };

  // Pose Detection Landmarks (MediaPipe)
  static const Map<String, int> poseLandmarks = {
    'nose': 0,
    'left_eye_inner': 1,
    'left_eye': 2,
    'left_eye_outer': 3,
    'right_eye_inner': 4,
    'right_eye': 5,
    'right_eye_outer': 6,
    'left_ear': 7,
    'right_ear': 8,
    'mouth_left': 9,
    'mouth_right': 10,
    'left_shoulder': 11,
    'right_shoulder': 12,
    'left_elbow': 13,
    'right_elbow': 14,
    'left_wrist': 15,
    'right_wrist': 16,
    'left_pinky': 17,
    'right_pinky': 18,
    'left_index': 19,
    'right_index': 20,
    'left_thumb': 21,
    'right_thumb': 22,
    'left_hip': 23,
    'right_hip': 24,
    'left_knee': 25,
    'right_knee': 26,
    'left_ankle': 27,
    'right_ankle': 28,
    'left_heel': 29,
    'right_heel': 30,
    'left_foot_index': 31,
    'right_foot_index': 32,
  };

  // CO2/O2 Table Defaults
  static const int defaultCO2Rounds = 8;
  static const int defaultO2Rounds = 8;
  static const int defaultHoldTime = 60; // seconds
  static const int defaultRestTime = 120; // seconds

  // Training Template Constraints
  static const int maxTrainingTemplates = 2;
  static const int minRounds = 1;
  static const int maxRounds = 10;
  static const int minHoldTime = 10; // seconds
  static const int maxHoldTime = 600; // 10 minutes
  static const int minRestTime = 10; // seconds
  static const int maxRestTime = 600; // 10 minutes
}
