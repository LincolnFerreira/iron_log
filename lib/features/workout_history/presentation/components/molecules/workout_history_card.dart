import 'package:flutter/material.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';

/// Card de treino na lista de histórico.
/// Mostra nome da rotina, data/duração, chips de exercícios e mini-stats.
class WorkoutHistoryCard extends StatelessWidget {
  final WorkoutHistory workout;
  final VoidCallback? onTap;

  const WorkoutHistoryCard({super.key, required this.workout, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PR badge
            if (workout.hasPR) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
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
              const SizedBox(height: 8),
            ],
            // Top row: icon + routine name + date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.fitness_center,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.sessionName ?? workout.routineName,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${workout.dateFormatted} · ${workout.durationFormatted}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Exercise chips
            if (workout.exercises.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ExerciseChips(exercises: workout.exercises),
            ],

            const SizedBox(height: 12),
            // Mini stats row
            Row(
              children: [
                _MiniStat(
                  value:
                      '${workout.completedSeries > 0 ? workout.completedSeries : workout.seriesCount}',
                  label: 'Séries',
                  color: const Color(0xFFFFC107),
                ),
                const SizedBox(width: 12),
                _MiniStat(
                  value: workout.volumeFormatted,
                  label: 'Volume',
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 12),
                _MiniStat(
                  value: '${workout.exercises.length}',
                  label: 'Exerc.',
                  color: const Color(0xFF9C27B0),
                ),
                const SizedBox(width: 12),
                _MiniStat(
                  value: '${workout.completionPercent}%',
                  label: 'Concluído',
                  color: workout.completionPercent == 100
                      ? const Color(0xFF4CAF50)
                      : workout.completionPercent >= 70
                      ? const Color(0xFFFFC107)
                      : const Color(0xFFFF7043),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseChips extends StatelessWidget {
  final List<WorkoutHistoryExercise> exercises;

  const _ExerciseChips({required this.exercises});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visible = exercises.take(4).toList();
    final overflow = exercises.length - visible.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...visible.map(
          (e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
            ),
            child: Text(
              e.exerciseName,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontSize: 11),
            ),
          ),
        ),
        if (overflow > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
            child: Text(
              '+$overflow',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
