import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/workout_split.dart';

class WorkoutCreationState {
  final List<WorkoutSplit> workoutSplits;
  final bool isLoading;
  final String? error;

  const WorkoutCreationState({
    this.workoutSplits = const [],
    this.isLoading = false,
    this.error,
  });

  WorkoutCreationState copyWith({
    List<WorkoutSplit>? workoutSplits,
    bool? isLoading,
    String? error,
  }) {
    return WorkoutCreationState(
      workoutSplits: workoutSplits ?? this.workoutSplits,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WorkoutCreationNotifier extends StateNotifier<WorkoutCreationState> {
  WorkoutCreationNotifier() : super(const WorkoutCreationState()) {
    _initializeDefaultSplits();
  }

  void _initializeDefaultSplits() {
    final defaultSplits = [
      const WorkoutSplit(
        id: '1',
        name: 'Push',
        exerciseCount: 8,
        preferredDays: ['Seg', 'Qui'],
        type: 'push',
      ),
      const WorkoutSplit(
        id: '2',
        name: 'Pull',
        exerciseCount: 7,
        preferredDays: ['Ter', 'Sex'],
        type: 'pull',
      ),
      const WorkoutSplit(
        id: '3',
        name: 'Legs',
        exerciseCount: 9,
        preferredDays: ['Qua', 'Sab'],
        type: 'legs',
      ),
    ];

    state = state.copyWith(workoutSplits: defaultSplits);
  }

  void reorderSplits(int oldIndex, int newIndex) {
    final splits = List<WorkoutSplit>.from(state.workoutSplits);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = splits.removeAt(oldIndex);
    splits.insert(newIndex, item);
    state = state.copyWith(workoutSplits: splits);
  }

  void addSplit(WorkoutSplit split) {
    final splits = List<WorkoutSplit>.from(state.workoutSplits)..add(split);
    state = state.copyWith(workoutSplits: splits);
  }

  void removeSplit(String splitId) {
    final splits = state.workoutSplits
        .where((split) => split.id != splitId)
        .toList();
    state = state.copyWith(workoutSplits: splits);
  }

  void updateSplit(WorkoutSplit updatedSplit) {
    final splits = state.workoutSplits.map((split) {
      return split.id == updatedSplit.id ? updatedSplit : split;
    }).toList();
    state = state.copyWith(workoutSplits: splits);
  }

  Future<void> saveWorkoutRotation() async {
    state = state.copyWith(isLoading: true);
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      // Here you would save to your backend/local storage
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao salvar rotação: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final workoutCreationProvider =
    StateNotifierProvider<WorkoutCreationNotifier, WorkoutCreationState>((ref) {
      return WorkoutCreationNotifier();
    });
