import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/routines/domain/entities/search_exercise.dart';
import 'package:iron_log/features/routines/presentation/providers/exercise_browse_provider.dart';
import 'package:iron_log/features/routines/presentation/providers/session_selection_provider.dart';
import 'package:iron_log/features/routines/presentation/widgets/session_exercise_card.dart';
import 'package:iron_log/features/routines/presentation/widgets/session_exercise_loading.dart';

/// Lista plana de exercícios ordenada por popularidade (useCount).
/// Exibida quando não há query de busca ativa.
class ExerciseBrowseList extends ConsumerWidget {
  final Function(SearchExercise)? onExerciseSelected;

  const ExerciseBrowseList({super.key, this.onExerciseSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browseAsync = ref.watch(exerciseBrowseProvider);

    return browseAsync.when(
      skipLoadingOnRefresh: false,
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: ExerciseListLoadingSkeleton(message: 'Carregando exercícios...'),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Erro ao carregar exercícios',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
      data: (browse) {
        final selectedMuscles = ref.watch(sessionMuscleFilterProvider);
        final exercises = selectedMuscles.isEmpty
            ? browse.exercises
            : browse.exercises
                  .where(
                    (e) =>
                        e.primaryMuscle != null &&
                        selectedMuscles.contains(e.primaryMuscle),
                  )
                  .toList();

        if (exercises.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                selectedMuscles.isEmpty
                    ? 'Nenhum exercício disponível'
                    : 'Nenhum exercício para os filtros selecionados',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        }

        final selectedIds = ref.watch(sessionAllExerciseIdsProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: exercises
              .map(
                (ex) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SessionExerciseCard(
                    exercise: ex,
                    isSelected: selectedIds.contains(ex.id),
                    onTap: () => onExerciseSelected?.call(ex),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
