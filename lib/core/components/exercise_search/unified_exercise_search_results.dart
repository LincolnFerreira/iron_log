import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/routines/domain/entities/search_exercise.dart';
import 'unified_exercise_search.dart';

/// Componente unificado para exibir resultados da busca de exercícios
class UnifiedExerciseSearchResults extends ConsumerWidget {
  final Function(SearchExercise)? onExerciseSelected;
  final Widget Function(SearchExercise, VoidCallback)? exerciseCardBuilder;

  const UnifiedExerciseSearchResults({
    super.key,
    this.onExerciseSelected,
    this.exerciseCardBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(unifiedExerciseSearchQueryProvider);
    final searchResults = ref.watch(unifiedExerciseSearchResultsProvider);
    final isLoading = ref.watch(unifiedExerciseSearchLoadingProvider);

    if (searchQuery.isEmpty) {
      return _buildEmptyState();
    }

    if (isLoading) {
      return _buildLoadingState();
    }

    if (searchResults.isEmpty) {
      return _buildNoResultsState(searchQuery);
    }

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final exercise = searchResults[index];

        if (exerciseCardBuilder != null) {
          return exerciseCardBuilder!(
            exercise,
            () => onExerciseSelected?.call(exercise),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildDefaultExerciseCard(exercise),
        );
      },
    );
  }

  Widget _buildDefaultExerciseCard(SearchExercise exercise) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => onExerciseSelected?.call(exercise),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ícone do exercício
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getCategoryColor(exercise.category ?? ''),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    (exercise.category?.isNotEmpty == true)
                        ? exercise.category![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Informações do exercício
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.muscles.isNotEmpty
                          ? exercise.muscles.join(', ')
                          : exercise.primaryMuscle ?? 'Não especificado',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Indicador de categoria
              if (exercise.category != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(
                      exercise.category!,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getCategoryColor(
                        exercise.category!,
                      ).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    exercise.category!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getCategoryColor(exercise.category!),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            Text(
              'Busque por exercícios',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Digite o nome do exercício no campo acima',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
              'Buscando exercícios...',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            Text(
              'Nenhum exercício encontrado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Tente usar palavras diferentes para "$query"',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'multi':
        return Colors.blue;
      case 'iso':
        return Colors.green;
      case 'cardio':
        return Colors.red;
      case 'funcional':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
