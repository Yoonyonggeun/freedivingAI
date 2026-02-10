import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/user_profile.dart';

class OnboardingState {
  final String? diverLevel;
  final String? competitionLevel;
  final List<String> mainDisciplines;
  final Map<String, double> personalBests;
  final List<String> trainingGoals;
  final int currentStep;

  OnboardingState({
    this.diverLevel,
    this.competitionLevel,
    this.mainDisciplines = const [],
    this.personalBests = const {},
    this.trainingGoals = const [],
    this.currentStep = 0,
  });

  OnboardingState copyWith({
    String? diverLevel,
    String? competitionLevel,
    List<String>? mainDisciplines,
    Map<String, double>? personalBests,
    List<String>? trainingGoals,
    int? currentStep,
  }) {
    return OnboardingState(
      diverLevel: diverLevel ?? this.diverLevel,
      competitionLevel: competitionLevel ?? this.competitionLevel,
      mainDisciplines: mainDisciplines ?? this.mainDisciplines,
      personalBests: personalBests ?? this.personalBests,
      trainingGoals: trainingGoals ?? this.trainingGoals,
      currentStep: currentStep ?? this.currentStep,
    );
  }

  bool get isComplete =>
      diverLevel != null &&
      competitionLevel != null &&
      mainDisciplines.isNotEmpty &&
      trainingGoals.isNotEmpty;
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(OnboardingState());

  void setDiverLevel(String level) {
    state = state.copyWith(diverLevel: level);
  }

  void setCompetitionLevel(String level) {
    state = state.copyWith(competitionLevel: level);
  }

  void setMainDisciplines(List<String> disciplines) {
    state = state.copyWith(mainDisciplines: disciplines);
  }

  void setPersonalBest(String discipline, double value) {
    final newPBs = Map<String, double>.from(state.personalBests);
    newPBs[discipline] = value;
    state = state.copyWith(personalBests: newPBs);
  }

  void setTrainingGoals(List<String> goals) {
    state = state.copyWith(trainingGoals: goals);
  }

  void nextStep() {
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<UserProfile> completeOnboarding() async {
    if (!state.isComplete) {
      throw Exception('Onboarding not complete');
    }

    final profile = UserProfile(
      id: const Uuid().v4(),
      name: 'User', // Can be updated later
      diverLevel: state.diverLevel!,
      competitionLevel: state.competitionLevel!,
      mainDisciplines: state.mainDisciplines,
      personalBests: state.personalBests,
      trainingGoals: state.trainingGoals,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to Hive
    final box = Hive.box<UserProfile>('userProfile');
    await box.put('current', profile);

    return profile;
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});
