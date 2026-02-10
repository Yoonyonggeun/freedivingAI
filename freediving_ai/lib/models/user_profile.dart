import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String diverLevel; // beginner, intermediate, advanced, elite

  @HiveField(3)
  String competitionLevel; // never, occasional, regular, elite

  @HiveField(4)
  List<String> mainDisciplines;

  @HiveField(5)
  Map<String, double> personalBests; // discipline -> distance/time

  @HiveField(6)
  List<String> trainingGoals;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  @HiveField(9)
  int? provisionalLevel; // 1-5, based on PB only

  @HiveField(10)
  int? officialLevel; // 1-5, based on PB + technique (video-based), nullable

  UserProfile({
    required this.id,
    required this.name,
    required this.diverLevel,
    required this.competitionLevel,
    required this.mainDisciplines,
    required this.personalBests,
    required this.trainingGoals,
    required this.createdAt,
    required this.updatedAt,
    this.provisionalLevel,
    this.officialLevel,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? diverLevel,
    String? competitionLevel,
    List<String>? mainDisciplines,
    Map<String, double>? personalBests,
    List<String>? trainingGoals,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? provisionalLevel,
    int? officialLevel,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      diverLevel: diverLevel ?? this.diverLevel,
      competitionLevel: competitionLevel ?? this.competitionLevel,
      mainDisciplines: mainDisciplines ?? this.mainDisciplines,
      personalBests: personalBests ?? this.personalBests,
      trainingGoals: trainingGoals ?? this.trainingGoals,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      provisionalLevel: provisionalLevel ?? this.provisionalLevel,
      officialLevel: officialLevel ?? this.officialLevel,
    );
  }
}
