import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'exercise_search_field.dart';
import 'exercise_result_card.dart';

class ExerciseSearchResults extends ConsumerWidget {
  final VoidCallback? onExerciseSelected;

  const ExerciseSearchResults({super.key, this.onExerciseSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(exerciseSearchQueryProvider);
    final searchResults = ref.watch(exerciseSearchResultsProvider);

    if (searchQuery.isEmpty) {
      return _buildInitialState(context);
    }

    if (searchResults.isEmpty) {
      return _buildNoResultsState(context, searchQuery);
    }

    return _buildResultsList(context, searchResults);
  }

  Widget _buildInitialState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Busque por exercícios',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Digite pelo menos 2 caracteres',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context, String query) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum resultado encontrado',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente buscar por "$query"',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(
    BuildContext context,
    List<Map<String, dynamic>> results,
  ) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final exercise = results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ExerciseResultCard(
            exercise: exercise,
            onSelect: () {
              // Atualiza providers de selecionados
              final container = ProviderScope.containerOf(context);
              final ids = container.read(selectedExerciseIdsProvider);
              final selectedExercises = container.read(selectedExercisesProvider);
              final idsNotifier = container.read(selectedExerciseIdsProvider.notifier);
              final exercisesNotifier = container.read(selectedExercisesProvider.notifier);

              final id = (exercise['id'] as String? ?? '');
              final nextIds = Set<String>.of(ids);
              final nextExercises = List<Map<String, dynamic>>.from(selectedExercises);
              final wasSelected = nextIds.contains(id);

              if (wasSelected) {
                nextIds.remove(id);
                nextExercises.removeWhere((e) => (e['id'] as String?) == id);
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
                        ? 'Exercício "${exercise['name']}" removido'
                        : 'Exercício "${exercise['name']}" selecionado!',
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
