import 'package:hive/hive.dart';

part 'static_session.g.dart';

@HiveType(typeId: 2)
class StaticSession extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String tableType; // co2, o2, custom

  @HiveField(3)
  int rounds;

  @HiveField(4)
  List<int> holdTimes; // seconds for each round

  @HiveField(5)
  List<int> restTimes; // seconds for each rest period

  @HiveField(6)
  List<int> completedHoldTimes; // actual completed times

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime? completedAt;

  @HiveField(9)
  bool isCompleted;

  @HiveField(10)
  int completedRounds;

  StaticSession({
    required this.id,
    required this.userId,
    required this.tableType,
    required this.rounds,
    required this.holdTimes,
    required this.restTimes,
    required this.completedHoldTimes,
    required this.createdAt,
    this.completedAt,
    this.isCompleted = false,
    required this.completedRounds,
  });

  StaticSession copyWith({
    String? id,
    String? userId,
    String? tableType,
    int? rounds,
    List<int>? holdTimes,
    List<int>? restTimes,
    List<int>? completedHoldTimes,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isCompleted,
    int? completedRounds,
  }) {
    return StaticSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tableType: tableType ?? this.tableType,
      rounds: rounds ?? this.rounds,
      holdTimes: holdTimes ?? this.holdTimes,
      restTimes: restTimes ?? this.restTimes,
      completedHoldTimes: completedHoldTimes ?? this.completedHoldTimes,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedRounds: completedRounds ?? this.completedRounds,
    );
  }
}
