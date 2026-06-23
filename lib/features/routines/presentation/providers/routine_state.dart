import '../../domain/entities/routine.dart';

class RoutineState {
  final List<Routine> routines;
  final bool isLoading;
  final String? error;
  final Routine? selectedRoutine;

  const RoutineState({
    this.routines = const [],
    this.isLoading = false,
    this.error,
    this.selectedRoutine,
  });

  RoutineState copyWith({
    List<Routine>? routines,
    bool? isLoading,
    String? error,
    Routine? selectedRoutine,
    bool clearError = false,
    bool clearSelectedRoutine = false,
  }) {
    return RoutineState(
      routines: routines ?? this.routines,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedRoutine: clearSelectedRoutine
          ? null
          : (selectedRoutine ?? this.selectedRoutine),
    );
  }
}
