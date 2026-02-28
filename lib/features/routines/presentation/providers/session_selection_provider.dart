import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/search_exercise.dart';

/// Providers locais para gerenciar exercícios selecionados em uma sessão
/// Substitui os providers deprecated do exercise_search_field.dart

// IDs dos exercícios selecionados na sessão atual
final sessionSelectedExerciseIdsProvider = StateProvider<Set<String>>(
  (ref) => <String>{},
);

// Objetos completos dos exercícios selecionados na sessão atual
final sessionSelectedExercisesProvider = StateProvider<List<SearchExercise>>(
  (ref) => [],
);

/// Helper para adicionar/remover exercícios selecionados
class SessionExerciseSelectionNotifier extends StateNotifier<void> {
  final Ref ref;

  SessionExerciseSelectionNotifier(this.ref) : super(null);

  void addExercise(SearchExercise exercise) {
    final ids = ref.read(sessionSelectedExerciseIdsProvider);
    final exercises = ref.read(sessionSelectedExercisesProvider);

    if (!ids.contains(exercise.id)) {
      final newIds = Set<String>.from(ids)..add(exercise.id);
      final newExercises = List<SearchExercise>.from(exercises)..add(exercise);

      ref.read(sessionSelectedExerciseIdsProvider.notifier).state = newIds;
      ref.read(sessionSelectedExercisesProvider.notifier).state = newExercises;
    }
  }

  void removeExercise(SearchExercise exercise) {
    final ids = ref.read(sessionSelectedExerciseIdsProvider);
    final exercises = ref.read(sessionSelectedExercisesProvider);

    final newIds = Set<String>.from(ids)..remove(exercise.id);
    final newExercises = List<SearchExercise>.from(exercises)
      ..removeWhere((e) => e.id == exercise.id);

    ref.read(sessionSelectedExerciseIdsProvider.notifier).state = newIds;
    ref.read(sessionSelectedExercisesProvider.notifier).state = newExercises;
  }

  void toggleExercise(SearchExercise exercise) {
    final ids = ref.read(sessionSelectedExerciseIdsProvider);

    if (ids.contains(exercise.id)) {
      removeExercise(exercise);
    } else {
      addExercise(exercise);
    }
  }

  void clearAll() {
    ref.read(sessionSelectedExerciseIdsProvider.notifier).state = <String>{};
    ref.read(sessionSelectedExercisesProvider.notifier).state =
        <SearchExercise>[];
  }
}

final sessionExerciseSelectionNotifierProvider =
    StateNotifierProvider<SessionExerciseSelectionNotifier, void>((ref) {
      return SessionExerciseSelectionNotifier(ref);
    });
