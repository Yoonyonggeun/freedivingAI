class TrainingTable {
  final String type; // 'co2', 'o2', 'custom'
  final int rounds;
  final List<int> holdTimes; // seconds for each round
  final List<int> restTimes; // seconds for each rest period

  TrainingTable({
    required this.type,
    required this.rounds,
    required this.holdTimes,
    required this.restTimes,
  });

  // CO2 Table: Fixed hold time, decreasing rest time
  factory TrainingTable.co2({
    required int rounds,
    required int holdTime,
    required int initialRestTime,
    required int finalRestTime,
  }) {
    final holdTimes = List.filled(rounds, holdTime);
    final restTimes = _generateDecreasingTimes(
      rounds: rounds - 1, // rest periods = rounds - 1
      initial: initialRestTime,
      final_: finalRestTime,
    );

    return TrainingTable(
      type: 'co2',
      rounds: rounds,
      holdTimes: holdTimes,
      restTimes: restTimes,
    );
  }

  // O2 Table: Increasing hold time, fixed rest time
  factory TrainingTable.o2({
    required int rounds,
    required int initialHoldTime,
    required int finalHoldTime,
    required int restTime,
  }) {
    final holdTimes = _generateIncreasingTimes(
      rounds: rounds,
      initial: initialHoldTime,
      final_: finalHoldTime,
    );
    final restTimes = List.filled(rounds - 1, restTime);

    return TrainingTable(
      type: 'o2',
      rounds: rounds,
      holdTimes: holdTimes,
      restTimes: restTimes,
    );
  }

  // Custom Table
  factory TrainingTable.custom({
    required int rounds,
    required List<int> holdTimes,
    required List<int> restTimes,
  }) {
    return TrainingTable(
      type: 'custom',
      rounds: rounds,
      holdTimes: holdTimes,
      restTimes: restTimes,
    );
  }

  // From Template
  factory TrainingTable.fromTemplate(dynamic template) {
    final rounds = template.rounds as int;
    final holdTimes = List<int>.from(template.holdTimes as List);
    final restTimes = List<int>.from(template.restTimes as List);

    // Validate data model: N rounds requires N hold times and N-1 rest times
    if (holdTimes.length != rounds) {
      throw Exception('Invalid template: Expected $rounds hold times, got ${holdTimes.length}');
    }

    // Handle migration: old templates may have N rest times instead of N-1
    List<int> validRestTimes;
    if (restTimes.length == rounds) {
      // Old format: drop the last rest time
      validRestTimes = restTimes.sublist(0, rounds - 1);
      print('Migrating template: dropping last rest time');
    } else if (restTimes.length == rounds - 1) {
      // Correct format: use as-is
      validRestTimes = restTimes;
    } else {
      throw Exception('Invalid template: Expected ${rounds - 1} rest times, got ${restTimes.length}');
    }

    return TrainingTable(
      type: 'custom',
      rounds: rounds,
      holdTimes: holdTimes,
      restTimes: validRestTimes,
    );
  }

  static List<int> _generateDecreasingTimes({
    required int rounds,
    required int initial,
    required int final_,
  }) {
    if (rounds <= 1) return [initial];

    final step = (initial - final_) / (rounds - 1);
    return List.generate(
      rounds,
      (index) => (initial - (step * index)).round(),
    );
  }

  static List<int> _generateIncreasingTimes({
    required int rounds,
    required int initial,
    required int final_,
  }) {
    if (rounds <= 1) return [initial];

    final step = (final_ - initial) / (rounds - 1);
    return List.generate(
      rounds,
      (index) => (initial + (step * index)).round(),
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
