import 'package:hive/hive.dart';

part 'analysis_result.g.dart';

@HiveType(typeId: 1)
class AnalysisResult extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String discipline; // DYN, DNF, etc.

  @HiveField(3)
  String videoPath;

  @HiveField(4)
  String category; // streamline, finning, turn, etc.

  @HiveField(5)
  double overallScore; // 0-100

  @HiveField(6)
  Map<String, double> categoryScores; // sub-category scores

  @HiveField(7)
  List<String> strengths;

  @HiveField(8)
  List<String> improvements;

  @HiveField(9)
  List<String> drillRecommendations;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  Map<String, dynamic>? poseData; // Raw pose detection data

  AnalysisResult({
    required this.id,
    required this.userId,
    required this.discipline,
    required this.videoPath,
    required this.category,
    required this.overallScore,
    required this.categoryScores,
    required this.strengths,
    required this.improvements,
    required this.drillRecommendations,
    required this.createdAt,
    this.poseData,
  });

  AnalysisResult copyWith({
    String? id,
    String? userId,
    String? discipline,
    String? videoPath,
    String? category,
    double? overallScore,
    Map<String, double>? categoryScores,
    List<String>? strengths,
    List<String>? improvements,
    List<String>? drillRecommendations,
    DateTime? createdAt,
    Map<String, dynamic>? poseData,
  }) {
    return AnalysisResult(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      discipline: discipline ?? this.discipline,
      videoPath: videoPath ?? this.videoPath,
      category: category ?? this.category,
      overallScore: overallScore ?? this.overallScore,
      categoryScores: categoryScores ?? this.categoryScores,
      strengths: strengths ?? this.strengths,
      improvements: improvements ?? this.improvements,
      drillRecommendations: drillRecommendations ?? this.drillRecommendations,
      createdAt: createdAt ?? this.createdAt,
      poseData: poseData ?? this.poseData,
    );
  }
}
