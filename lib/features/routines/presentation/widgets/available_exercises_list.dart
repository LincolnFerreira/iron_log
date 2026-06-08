import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/components/exercise_search/exercise_search.dart';
import '../../domain/entities/search_exercise.dart';
import '../providers/session_selection_provider.dart';
import 'empty_exercise_state.dart';
import 'exercise_browse_list.dart';
import 'session_exercise_card.dart';
import 'session_exercise_loading.dart';

/// Widget que exibe os exercícios disponíveis baseado na busca
class AvailableExercisesList extends ConsumerWidget {
  final Function(SearchExercise)? onExerciseSelected;

  const AvailableExercisesList({super.key, this.onExerciseSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(exerciseSearchProvider);
    final selectedExerciseIds = ref.watch(sessionAllExerciseIdsProvider);

    if (searchState.query.isEmpty) {
      return ExerciseBrowseList(onExerciseSelected: onExerciseSelected);
    }

    if (searchState.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: ExerciseListLoadingSkeleton(
          message: 'Buscando exercícios...',
          itemCount: 3,
        ),
      );
    }

    if (searchState.results.isEmpty) {
      return EmptyExerciseState(
        query: searchState.query,
        onExerciseCreated: (exercise) {
          ref
              .read(sessionExerciseSelectionNotifierProvider.notifier)
              .toggleExercise(exercise);
        },
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: searchState.results.length,
      itemBuilder: (context, index) {
        final exercise = searchState.results[index];
        final isSelected = selectedExerciseIds.contains(exercise.id);
        return SessionExerciseCard(
          exercise: exercise,
          isSelected: isSelected,
          onTap: () => onExerciseSelected?.call(exercise),
        );
      },
    );
  }
}
