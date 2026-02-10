import 'package:hive/hive.dart';

part 'training_template.g.dart';

@HiveType(typeId: 3)
class TrainingTemplate extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final int rounds;

  @HiveField(4)
  final List<int> holdTimes;

  @HiveField(5)
  final List<int> restTimes;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  TrainingTemplate({
    required this.id,
    required this.userId,
    required this.name,
    required this.rounds,
    required this.holdTimes,
    required List<int> restTimes,
    required this.createdAt,
    required this.updatedAt,
  }) : restTimes = _migrateRestTimes(rounds, restTimes);

  // Migrate old templates: N rounds should have N-1 rest times (rest exists BETWEEN rounds)
  static List<int> _migrateRestTimes(int rounds, List<int> restTimes) {
    print('_migrateRestTimes called: rounds=$rounds, restTimes.length=${restTimes.length}');

    if (restTimes.length == rounds - 1) {
      // Already in correct format
      print('✅ RestTimes already in correct format (N-1)');
      return restTimes;
    } else if (restTimes.length == rounds) {
      // Old format: drop the last rest time
      print('⚠️ Migrating TrainingTemplate: dropping last rest time');
      print('Before: $restTimes');
      final migrated = restTimes.sublist(0, rounds - 1);
      print('After: $migrated');
      return migrated;
    } else {
      // Invalid format: return as-is and let validation catch it
      print('❌ WARNING: Invalid restTimes length! Expected ${rounds - 1} or $rounds, got ${restTimes.length}');
      return restTimes;
    }
  }

  TrainingTemplate copyWith({
    String? id,
    String? userId,
    String? name,
    int? rounds,
    List<int>? holdTimes,
    List<int>? restTimes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final newRounds = rounds ?? this.rounds;
    final newRestTimes = restTimes ?? this.restTimes;

    return TrainingTemplate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      rounds: newRounds,
      holdTimes: holdTimes ?? this.holdTimes,
      restTimes: newRestTimes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get totalDuration {
    final holdTotal = holdTimes.fold<int>(0, (sum, time) => sum + time);
    final restTotal = restTimes.fold<int>(0, (sum, time) => sum + time);
    return holdTotal + restTotal;
  }

  String get formattedDuration {
    final minutes = totalDuration ~/ 60;
    final seconds = totalDuration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
