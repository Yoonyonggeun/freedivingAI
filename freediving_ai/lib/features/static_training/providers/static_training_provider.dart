import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/training_table.dart';
import '../../../models/static_session.dart';
import '../../../models/user_profile.dart';

enum TrainingPhase { ready, hold, rest, completed }

class StaticTrainingState {
  final TrainingTable? table;
  final TrainingPhase phase;
  final int currentRound;
  final int remainingSeconds;
  final List<int> completedHoldTimes;
  final bool isRunning;
  final bool isPaused;
  final DateTime? pauseStartTime;
  final int totalPausedSeconds;
  final DateTime? phaseStartTime;

  StaticTrainingState({
    this.table,
    this.phase = TrainingPhase.ready,
    this.currentRound = 0,
    this.remainingSeconds = 0,
    this.completedHoldTimes = const [],
    this.isRunning = false,
    this.isPaused = false,
    this.pauseStartTime,
    this.totalPausedSeconds = 0,
    this.phaseStartTime,
  });

  StaticTrainingState copyWith({
    TrainingTable? table,
    TrainingPhase? phase,
    int? currentRound,
    int? remainingSeconds,
    List<int>? completedHoldTimes,
    bool? isRunning,
    bool? isPaused,
    DateTime? pauseStartTime,
    int? totalPausedSeconds,
    DateTime? phaseStartTime,
  }) {
    return StaticTrainingState(
      table: table ?? this.table,
      phase: phase ?? this.phase,
      currentRound: currentRound ?? this.currentRound,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      completedHoldTimes: completedHoldTimes ?? this.completedHoldTimes,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      pauseStartTime: pauseStartTime,
      totalPausedSeconds: totalPausedSeconds ?? this.totalPausedSeconds,
      phaseStartTime: phaseStartTime ?? this.phaseStartTime,
    );
  }

  int get totalRounds => table?.rounds ?? 0;

  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    if (table == null || currentRound >= totalRounds) return 1.0;
    return currentRound / totalRounds;
  }
}

class StaticTrainingNotifier extends StateNotifier<StaticTrainingState> {
  final String userId;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _hasPlayedCountdownWarning = false;

  StaticTrainingNotifier(this.userId) : super(StaticTrainingState());

  void setTable(TrainingTable table) {
    state = StaticTrainingState(
      table: table,
      phase: TrainingPhase.ready,
    );
  }

  Future<void> start() async {
    if (state.table == null) return;

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      phase: TrainingPhase.hold,
      currentRound: 0,
      remainingSeconds: state.table!.holdTimes[0],
      completedHoldTimes: [],
      totalPausedSeconds: 0,
      phaseStartTime: DateTime.now(),
    );

    await _playSound('hold_start.mp3');
    await HapticFeedback.mediumImpact();

    _hasPlayedCountdownWarning = false;
    _startTimer();
  }

  Future<void> pause() async {
    _timer?.cancel();
    state = state.copyWith(
      isPaused: true,
      pauseStartTime: DateTime.now(),
    );
  }

  Future<void> resume() async {
    if (state.isPaused && state.pauseStartTime != null) {
      final pauseDuration =
          DateTime.now().difference(state.pauseStartTime!).inSeconds;
      state = state.copyWith(
        isPaused: false,
        pauseStartTime: null,
        totalPausedSeconds: state.totalPausedSeconds + pauseDuration,
      );
      _startTimer();
    }
  }

  void stop() {
    _timer?.cancel();
    state = StaticTrainingState(table: state.table);
  }

  Future<void> quit() async {
    _timer?.cancel();

    if (state.table == null) return;

    final session = StaticSession(
      id: const Uuid().v4(),
      userId: userId,
      tableType: state.table!.type,
      rounds: state.table!.rounds,
      holdTimes: state.table!.holdTimes,
      restTimes: state.table!.restTimes,
      completedHoldTimes: state.completedHoldTimes,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      isCompleted: false,
      completedRounds: state.currentRound,
    );

    await _saveSession(session);
    state = StaticTrainingState(table: state.table);
  }

  Future<void> completeHold() async {
    if (state.table == null) return;

    final targetHold = state.table!.holdTimes[state.currentRound];
    final actualHoldTime =
        targetHold - state.remainingSeconds - state.totalPausedSeconds;
    final newCompletedTimes = [...state.completedHoldTimes, actualHoldTime];

    await _playSound('hold_end.mp3');
    await HapticFeedback.mediumImpact();

    // Check if this is the last round (no rest after final round)
    if (state.currentRound >= state.table!.rounds - 1) {
      // Last round completed - move directly to completion
      _timer?.cancel();
      await _playSound('training_complete.mp3');
      await HapticFeedback.heavyImpact();

      state = state.copyWith(
        phase: TrainingPhase.completed,
        isRunning: false,
        completedHoldTimes: newCompletedTimes,
      );
      await _saveSessionCompleted();
    } else {
      // Not last round - proceed to rest phase
      await Future.delayed(const Duration(milliseconds: 500));
      await _playSound('rest_start.mp3');
      await HapticFeedback.mediumImpact();

      // Rest periods exist BETWEEN rounds only (N rounds = N-1 rest periods)
      state = state.copyWith(
        phase: TrainingPhase.rest,
        remainingSeconds: state.table!.restTimes[state.currentRound],
        completedHoldTimes: newCompletedTimes,
        totalPausedSeconds: 0,
        phaseStartTime: DateTime.now(),
      );
      _hasPlayedCountdownWarning = false;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }

      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);

        // Countdown warning at 3 seconds
        if (state.remainingSeconds == 3 &&
            state.phase == TrainingPhase.hold &&
            !_hasPlayedCountdownWarning) {
          _playCountdownWarning();
          _hasPlayedCountdownWarning = true;
        }
      } else {
        _onTimerComplete();
      }
    });
  }

  Future<void> _playCountdownWarning() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 300));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 300));
    await HapticFeedback.mediumImpact();
  }

  Future<void> _onTimerComplete() async {
    if (state.phase == TrainingPhase.hold) {
      await completeHold();
    } else if (state.phase == TrainingPhase.rest) {
      await _moveToNextRound();
    }
  }

  Future<void> _moveToNextRound() async {
    if (state.table == null) return;

    final nextRound = state.currentRound + 1;

    if (nextRound < state.table!.rounds) {
      await _playSound('hold_start.mp3');
      await HapticFeedback.mediumImpact();

      state = state.copyWith(
        phase: TrainingPhase.hold,
        currentRound: nextRound,
        remainingSeconds: state.table!.holdTimes[nextRound],
        totalPausedSeconds: 0,
        phaseStartTime: DateTime.now(),
      );
      _hasPlayedCountdownWarning = false;
    } else {
      // Training completed
      _timer?.cancel();
      await _playSound('training_complete.mp3');
      await HapticFeedback.heavyImpact();

      state = state.copyWith(
        phase: TrainingPhase.completed,
        isRunning: false,
      );
      await _saveSessionCompleted();
    }
  }

  Future<void> _saveSessionCompleted() async {
    if (state.table == null) return;

    final session = StaticSession(
      id: const Uuid().v4(),
      userId: userId,
      tableType: state.table!.type,
      rounds: state.table!.rounds,
      holdTimes: state.table!.holdTimes,
      restTimes: state.table!.restTimes,
      completedHoldTimes: state.completedHoldTimes,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      isCompleted: true,
      completedRounds: state.table!.rounds,
    );

    await _saveSession(session);
  }

  Future<void> _saveSession(StaticSession session) async {
    try {
      final box = Hive.box<StaticSession>('staticSessions');
      await box.add(session);
    } catch (e) {
      // Silent fail - don't interrupt training
    }
  }

  Future<void> _playSound(String filename) async {
    try {
      await _audioPlayer.play(AssetSource('sounds/$filename'));
    } catch (e) {
      // Silent fail if audio file not found
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

// Provider for current user ID
final currentUserIdProvider = Provider<String>((ref) {
  final box = Hive.box<UserProfile>('userProfile');
  final profile = box.get('current');
  return profile?.id ?? 'current';
});

// Static training provider with userId injection
final staticTrainingProvider =
    StateNotifierProvider<StaticTrainingNotifier, StaticTrainingState>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return StaticTrainingNotifier(userId);
});
