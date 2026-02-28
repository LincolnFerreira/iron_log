import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/search_exercise.dart';
import 'selected_exercise_card.dart';
import '../providers/session_selection_provider.dart';
import 'atoms/empty_exercises_state.dart';

class SelectedExercisesSection extends ConsumerStatefulWidget {
  final Session session;

  const SelectedExercisesSection({super.key, required this.session});

  @override
  ConsumerState<SelectedExercisesSection> createState() =>
      _SelectedExercisesSectionState();
}

class _SelectedExercisesSectionState
    extends ConsumerState<SelectedExercisesSection> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedExercises = ref.watch(sessionSelectedExercisesProvider);
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
            const EmptyExercisesState()
          else
            SizedBox(
              height: 200,
              child: ReorderableListView(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) {
                  _onReorder(oldIndex, newIndex);
                },
                children: selectedExercises.asMap().entries.map((entry) {
                  final exercise = entry.value;
                  return Container(
                    key: ValueKey(exercise.id),
                    width: cardWidth,
                    margin: const EdgeInsets.only(right: 12),
                    child: SelectedExerciseCard(
                      exercise: _convertToSessionExercise(exercise),
                      onDelete: () => _removeExercise(exercise),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;

    final exercisesNotifier = ref.read(
      sessionSelectedExercisesProvider.notifier,
    );
    final selectedExercises = ref.read(sessionSelectedExercisesProvider);
    final exercises = List<SearchExercise>.from(selectedExercises);
    final exercise = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, exercise);
    exercisesNotifier.state = exercises;

    // Debounce: aguarda 800ms após última mudança antes de persistir
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _persistExercisesOrder(exercises);
    });
  }

  Future<void> _persistExercisesOrder(List<SearchExercise> exercises) async {
    // TODO: Implementar chamada ao backend para atualizar ordem dos exercícios
    // Aguardando endpoint no backend para atualizar SessionExercise.order
  }

  void _removeExercise(SearchExercise exercise) {
    ref
        .read(sessionExerciseSelectionNotifierProvider.notifier)
        .removeExercise(exercise);
  }

  SessionExercise _convertToSessionExercise(SearchExercise exercise) {
    // Converte o SearchExercise para um SessionExercise
    // TODO: Implementar integração real com API quando disponível
    return SessionExercise(
      id: exercise.id,
      exerciseId: exercise.id,
      exercise: Exercise(
        id: exercise.id,
        name: exercise.name,
        description: exercise.description,
        primaryMuscle: exercise.primaryMuscle ?? '',
        equipment: exercise.equipment ?? '',
        tags: [], // TODO: Mapear tags quando disponível
      ),
      config: {}, // TODO: Configuração padrão do exercício
    );
  }
}
