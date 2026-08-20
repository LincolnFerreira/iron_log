import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workout_provider.g.dart';

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

@Riverpod(keepAlive: true)
class Workout extends _$Workout {
  @override
  WorkoutState build() => WorkoutState();

  void updateCurrentWorkout(String workout) {
    state = state.copyWith(currentWorkout: workout);
  }

  Future<void> startWorkout() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(isLoading: false);
  }
}
