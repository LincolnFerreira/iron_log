import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkoutState {
  final String currentWorkout;
  final bool isLoading;

  WorkoutState({
    this.currentWorkout = 'Treino A - Peito e Tríceps',
    this.isLoading = false,
  });

  WorkoutState copyWith({String? currentWorkout, bool? isLoading}) {
    return WorkoutState(
      currentWorkout: currentWorkout ?? this.currentWorkout,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WorkoutNotifier extends StateNotifier<WorkoutState> {
  WorkoutNotifier() : super(WorkoutState());

  void updateCurrentWorkout(String workout) {
    state = state.copyWith(currentWorkout: workout);
  }

  Future<void> startWorkout() async {
    state = state.copyWith(isLoading: true);
    // Implement workout start logic here
    await Future.delayed(const Duration(seconds: 1)); // Simulated delay
    state = state.copyWith(isLoading: false);
  }
}

final workoutProvider = StateNotifierProvider<WorkoutNotifier, WorkoutState>((
  ref,
) {
  return WorkoutNotifier();
});
