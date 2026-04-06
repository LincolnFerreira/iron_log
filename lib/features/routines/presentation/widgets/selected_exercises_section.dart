import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/app_colors.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/search_exercise.dart';
import 'selected_exercise_card.dart';
import '../providers/session_selection_provider.dart';
import '../providers/session_provider.dart';

class SelectedExercisesSection extends ConsumerStatefulWidget {
  final Session session;

  const SelectedExercisesSection({super.key, required this.session});

  @override
  ConsumerState<SelectedExercisesSection> createState() =>
      _SelectedExercisesSectionState();
}

class _SelectedExercisesSectionState
    extends ConsumerState<SelectedExercisesSection> {
  @override
  Widget build(BuildContext context) {
    final selectedExercises = ref.watch(sessionAllExercisesProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header — mesmo estilo dos outros labels da página
        Row(
          children: [
            Text(
              'EXERCÍCIOS SELECIONADOS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
        const SizedBox(height: 12),

        // Lista com drag & drop — sem scroll próprio, flui junto com a página
        ReorderableListView(
          buildDefaultDragHandles: false,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) => ref
              .read(sessionExerciseSelectionNotifierProvider.notifier)
              .reorderExercises(oldIndex, newIndex),
          children: [
            for (int index = 0; index < selectedExercises.length; index++)
              Padding(
                key: ValueKey(selectedExercises[index].id),
                padding: index > 0
                    ? const EdgeInsets.only(top: 8)
                    : EdgeInsets.zero,
                child: SelectedExerciseCard(
                  exercise: _convertToSessionExercise(selectedExercises[index]),
                  onDelete: () => _removeExercise(selectedExercises[index]),
                  index: index,
                  totalCount: selectedExercises.length,
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _removeExercise(SearchExercise exercise) {
    // Remover do provider local (UI)
    ref
        .read(sessionExerciseSelectionNotifierProvider.notifier)
        .removeExercise(exercise);

    // Se é uma sessão existente, remover também do backend
    if (widget.session.id != 'temp') {
      final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
      sessionNotifier.removeExerciseFromSession(widget.session.id, exercise.id);
    }
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
