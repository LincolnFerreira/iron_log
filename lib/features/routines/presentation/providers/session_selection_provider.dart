import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/routines/domain/entities/search_exercise.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_selection_provider.g.dart';

final sessionBaseExercisesProvider = StateProvider<List<SearchExercise>>(
  (ref) => [],
);

final sessionNewlySelectedProvider = StateProvider<List<SearchExercise>>(
  (ref) => [],
);

final sessionAllExercisesProvider = Provider<List<SearchExercise>>((ref) {
  final base = ref.watch(sessionBaseExercisesProvider);
  final newly = ref.watch(sessionNewlySelectedProvider);

  final baseIds = base.map((e) => e.id).toSet();
  final uniqueNewly = newly.where((e) => !baseIds.contains(e.id)).toList();

  return [...base, ...uniqueNewly];
});

final sessionAllExerciseIdsProvider = Provider<Set<String>>((ref) {
  return ref.watch(sessionAllExercisesProvider).map((e) => e.id).toSet();
});

final sessionMuscleFilterProvider = StateProvider<Set<String>>(
  (ref) => <String>{},
);

@Riverpod(keepAlive: true)
class SessionExerciseSelectionNotifier
    extends _$SessionExerciseSelectionNotifier {
  @override
  void build() {}

  void initWithSessionExercises(List<SearchExercise> exercises) {
    ref.read(sessionBaseExercisesProvider.notifier).state = [...exercises];
    ref.read(sessionNewlySelectedProvider.notifier).state = [];
  }

  void clearAll() {
    ref.read(sessionBaseExercisesProvider.notifier).state = [];
    ref.read(sessionNewlySelectedProvider.notifier).state = [];
  }

  void addExercise(SearchExercise exercise) {
    final allIds = ref.read(sessionAllExerciseIdsProvider);
    if (allIds.contains(exercise.id)) return;

    final current = ref.read(sessionNewlySelectedProvider);
    ref.read(sessionNewlySelectedProvider.notifier).state = [
      ...current,
      exercise,
    ];
  }

  void removeExercise(SearchExercise exercise) {
    final base = ref.read(sessionBaseExercisesProvider);
    if (base.any((e) => e.id == exercise.id)) {
      ref.read(sessionBaseExercisesProvider.notifier).state = base
          .where((e) => e.id != exercise.id)
          .toList();
      return;
    }

    final newly = ref.read(sessionNewlySelectedProvider);
    ref.read(sessionNewlySelectedProvider.notifier).state = newly
        .where((e) => e.id != exercise.id)
        .toList();
  }

  void toggleExercise(SearchExercise exercise) {
    final allIds = ref.read(sessionAllExerciseIdsProvider);
    if (allIds.contains(exercise.id)) {
      removeExercise(exercise);
    } else {
      addExercise(exercise);
    }
  }

  void reorderExercises(int oldIndex, int newIndex) {
    final all = ref.read(sessionAllExercisesProvider);
    final updated = List<SearchExercise>.from(all);
    if (oldIndex < newIndex) newIndex -= 1;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    ref.read(sessionBaseExercisesProvider.notifier).state = updated;
    ref.read(sessionNewlySelectedProvider.notifier).state = [];
  }
}
