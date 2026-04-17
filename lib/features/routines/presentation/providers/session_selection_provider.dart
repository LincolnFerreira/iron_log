import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/search_exercise.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. Exercícios já salvos na sessão (carregados do backend no initState)
// ─────────────────────────────────────────────────────────────────────────────
final sessionBaseExercisesProvider = StateProvider<List<SearchExercise>>(
  (ref) => [],
);

// ─────────────────────────────────────────────────────────────────────────────
// 2. Exercícios que o usuário selecionou agora (novos, ainda não salvos)
// ─────────────────────────────────────────────────────────────────────────────
final sessionNewlySelectedProvider = StateProvider<List<SearchExercise>>(
  (ref) => [],
);

// ─────────────────────────────────────────────────────────────────────────────
// 3. União reativa das duas listas — é o que a UI exibe e o que é salvo
// ─────────────────────────────────────────────────────────────────────────────
final sessionAllExercisesProvider = Provider<List<SearchExercise>>((ref) {
  final base = ref.watch(sessionBaseExercisesProvider);
  final newly = ref.watch(sessionNewlySelectedProvider);

  // Garante que não há duplicatas caso o mesmo exercício esteja nas duas listas
  final baseIds = base.map((e) => e.id).toSet();
  final uniqueNewly = newly.where((e) => !baseIds.contains(e.id)).toList();

  return [...base, ...uniqueNewly];
});

// IDs de todos os exercícios (base + novos) — usado para marcar checkboxes na busca
final sessionAllExerciseIdsProvider = Provider<Set<String>>((ref) {
  return ref.watch(sessionAllExercisesProvider).map((e) => e.id).toSet();
});

// Filtro de músculos selecionados via chips na UI (conjunto de nomes de músculos)
final sessionMuscleFilterProvider = StateProvider<Set<String>>(
  (ref) => <String>{},
);

// ─────────────────────────────────────────────────────────────────────────────
// Notifier que gerencia as interações do usuário
// ─────────────────────────────────────────────────────────────────────────────
class SessionExerciseSelectionNotifier extends StateNotifier<void> {
  final Ref ref;

  SessionExerciseSelectionNotifier(this.ref) : super(null);

  /// Inicializa a lista base com os exercícios já salvos na sessão.
  /// Deve ser chamado no initState, após limpar o estado anterior.
  void initWithSessionExercises(List<SearchExercise> exercises) {
    ref.read(sessionBaseExercisesProvider.notifier).state = [...exercises];
    ref.read(sessionNewlySelectedProvider.notifier).state = [];
  }

  /// Limpa tudo (chamado no initState antes de repopular).
  void clearAll() {
    ref.read(sessionBaseExercisesProvider.notifier).state = [];
    ref.read(sessionNewlySelectedProvider.notifier).state = [];
  }

  /// Adiciona um exercício novo (vindo da busca).
  void addExercise(SearchExercise exercise) {
    final allIds = ref.read(sessionAllExerciseIdsProvider);
    if (allIds.contains(exercise.id)) return;

    final current = ref.read(sessionNewlySelectedProvider);
    ref.read(sessionNewlySelectedProvider.notifier).state = [
      ...current,
      exercise,
    ];
  }

  /// Remove um exercício de qualquer uma das duas listas.
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

  /// Toggle: adiciona se não existe em nenhuma lista, remove se já existe.
  void toggleExercise(SearchExercise exercise) {
    final allIds = ref.read(sessionAllExerciseIdsProvider);
    if (allIds.contains(exercise.id)) {
      removeExercise(exercise);
    } else {
      addExercise(exercise);
    }
  }

  /// Reordena os exercícios selecionados (drag & drop).
  void reorderExercises(int oldIndex, int newIndex) {
    final all = ref.read(sessionAllExercisesProvider);
    final updated = List<SearchExercise>.from(all);
    if (oldIndex < newIndex) newIndex -= 1;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    // Consolida tudo na lista base e limpa os novos
    ref.read(sessionBaseExercisesProvider.notifier).state = updated;
    ref.read(sessionNewlySelectedProvider.notifier).state = [];
  }
}

final sessionExerciseSelectionNotifierProvider =
    StateNotifierProvider<SessionExerciseSelectionNotifier, void>((ref) {
      return SessionExerciseSelectionNotifier(ref);
    });
