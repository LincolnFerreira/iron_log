import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'exercise_search_field.dart';
import 'exercise_result_card.dart';
import '../components/molecules/exercise_search_initial_state.dart';
import '../components/molecules/exercise_search_no_results.dart';
import '../../domain/entities/search_exercise.dart';

class ExerciseSearchResults extends ConsumerWidget {
  final VoidCallback? onExerciseSelected;

  const ExerciseSearchResults({super.key, this.onExerciseSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(exerciseSearchQueryProvider);
    final searchResults = ref.watch(exerciseSearchResultsProvider);

    if (searchQuery.isEmpty) {
      return const ExerciseSearchInitialState();
    }

    if (searchResults.isEmpty) {
      return ExerciseSearchNoResults(searchQuery: searchQuery);
    }

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final exercise = searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ExerciseResultCard(
            exercise: exercise,
            onSelect: () {
              final container = ProviderScope.containerOf(context);
              final ids = container.read(selectedExerciseIdsProvider);
              final selectedExercises = container.read(
                selectedExercisesProvider,
              );
              final idsNotifier = container.read(
                selectedExerciseIdsProvider.notifier,
              );
              final exercisesNotifier = container.read(
                selectedExercisesProvider.notifier,
              );

              final id = exercise.id;
              final nextIds = Set<String>.of(ids);
              final nextExercises = List<SearchExercise>.from(
                selectedExercises,
              );
              final wasSelected = nextIds.contains(id);

              if (wasSelected) {
                nextIds.remove(id);
                nextExercises.removeWhere((e) => e.id == id);
              } else {
                nextIds.add(id);
                nextExercises.add(exercise);
              }

              idsNotifier.state = nextIds;
              exercisesNotifier.state = nextExercises;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    wasSelected
                        ? 'Exercício "${exercise.name}" removido'
                        : 'Exercício "${exercise.name}" selecionado!',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );

              // Se foi selecionado (não removido), chama o callback para fechar a tela
              if (!wasSelected) {
                onExerciseSelected?.call();
              }
            },
          ),
        );
      },
    );
  }
}
