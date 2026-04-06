import 'package:flutter/material.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';

/// Bottom sheet com o detalhe completo de um treino do histórico.
class WorkoutDetailSheet extends StatelessWidget {
  final WorkoutHistory workout;

  /// Callback acionado quando o usuário toca em "Editar treino".
  /// Se nulo, o botão não é exibido.
  final VoidCallback? onEdit;

  const WorkoutDetailSheet({super.key, required this.workout, this.onEdit});

  static void show(
    BuildContext context,
    WorkoutHistory workout, {
    VoidCallback? onEdit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WorkoutDetailSheet(workout: workout, onEdit: onEdit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Scaffold(
            backgroundColor: colorScheme.surface,
            body: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Handle
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.outline.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // PR badge
                      if (workout.hasPR)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              '🏆 RECORDE PESSOAL',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      // Routine name + date
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Text(
                              workout.routineName,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (workout.sessionName != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                workout.sessionName!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              workout.dateLong,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Stats grid 2x2
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _StatCard(
                              value: workout.durationFormatted,
                              label: 'Duração',
                              color: const Color(0xFFFFC107),
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              value:
                                  '${workout.completedSeries > 0 ? workout.completedSeries : workout.seriesCount} / ${workout.totalSeries > 0 ? workout.totalSeries : workout.seriesCount}',
                              label: 'Séries',
                              color: const Color(0xFF4CAF50),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _StatCard(
                              value: workout.volumeFormatted,
                              label: 'Volume total',
                              color: const Color(0xFF2196F3),
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              value: '${workout.completionPercent}%',
                              label: 'Conclusão',
                              color: workout.completionPercent == 100
                                  ? const Color(0xFF4CAF50)
                                  : workout.completionPercent >= 70
                                  ? const Color(0xFFFFC107)
                                  : const Color(0xFFFF7043),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Exercises section header
                      if (workout.exercises.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'EXERCÍCIOS',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Exercise blocks
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _ExerciseBlock(exercise: workout.exercises[index]),
                    childCount: workout.exercises.length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      children: [
                        if (onEdit != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onEdit!();
                              },
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Editar treino'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: const Text('Fechar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseBlock extends StatelessWidget {
  final WorkoutHistoryExercise exercise;

  const _ExerciseBlock({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              exercise.exerciseName,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${exercise.completedSeries > 0 ? exercise.completedSeries : exercise.seriesCount}'
            '${exercise.seriesCount > 0 ? ' / ${exercise.seriesCount}' : ''}'
            ' séries',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
