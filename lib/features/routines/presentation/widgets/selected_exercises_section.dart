import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/routine.dart';
import 'selected_exercise_card.dart';
import 'exercise_search_field.dart'; // Para acessar o provider

class SelectedExercisesSection extends ConsumerWidget {
  final Session session;

  const SelectedExercisesSection({super.key, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedExercises = ref.watch(selectedExercisesProvider);
    final theme = Theme.of(context);
    final viewportWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = 16.0;
    final cardWidth = viewportWidth - (horizontalPadding * 2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Exercícios Selecionados',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${selectedExercises.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lista horizontal de exercícios selecionados
          if (selectedExercises.isEmpty)
            _buildEmptyState(context)
          else
            SizedBox(
              height: 200,
              child: ReorderableListView(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) {
                  if (oldIndex < newIndex) newIndex -= 1;
                  final exercisesNotifier = ref.read(
                    selectedExercisesProvider.notifier,
                  );
                  final exercises = List<Map<String, dynamic>>.from(
                    selectedExercises,
                  );
                  final exercise = exercises.removeAt(oldIndex);
                  exercises.insert(newIndex, exercise);
                  exercisesNotifier.state = exercises;
                },
                children: selectedExercises.asMap().entries.map((entry) {
                  final exercise = entry.value;
                  return Container(
                    key: ValueKey(exercise['id']),
                    width: cardWidth,
                    margin: const EdgeInsets.only(right: 12),
                    child: SelectedExerciseCard(
                      exercise: _convertToSessionExercise(exercise),
                      onDelete: () => _removeExercise(ref, exercise),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Nenhum exercício selecionado',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Toque em "Buscar" para adicionar exercícios',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeExercise(WidgetRef ref, Map<String, dynamic> exercise) {
    final idsNotifier = ref.read(selectedExerciseIdsProvider.notifier);
    final exercisesNotifier = ref.read(selectedExercisesProvider.notifier);
    final selectedExercises = ref.read(selectedExercisesProvider);
    final selectedIds = ref.read(selectedExerciseIdsProvider);

    final id = exercise['id'] as String;
    final nextIds = Set<String>.from(selectedIds)..remove(id);
    final nextExercises = List<Map<String, dynamic>>.from(selectedExercises)
      ..removeWhere((e) => e['id'] == id);

    idsNotifier.state = nextIds;
    exercisesNotifier.state = nextExercises;
  }

  SessionExercise _convertToSessionExercise(Map<String, dynamic> exercise) {
    // Converte o mapa de exercício da API para um SessionExercise
    // Isso é uma conversão temporária - idealmente deveria vir do backend
    return SessionExercise(
      id: exercise['id'] ?? '',
      exerciseId: exercise['id'] ?? '',
      exercise: Exercise(
        id: exercise['id'] ?? '',
        name: exercise['name'] ?? '',
        description: exercise['description'],
        primaryMuscle: exercise['primaryMuscleId'] ?? exercise['primaryMuscle'],
        equipment: exercise['equipmentId'] ?? exercise['equipment'],
        tags: (exercise['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      ),
      config: exercise['config'] ?? {},
    );
  }
}
