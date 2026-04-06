import 'package:flutter/material.dart';
import 'package:iron_log/features/workout_day/domain/entities/exercise_summary.dart';
import './serie_row.dart';

/// Bloco de detalhes de um exercício com todas suas séries
class ExerciseDetailBlock extends StatelessWidget {
  final ExerciseSummary exercise;
  final bool animated;
  final int staggerIndex; // Para animação em sequência

  const ExerciseDetailBlock({
    super.key,
    required this.exercise,
    this.animated = true,
    this.staggerIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final block = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Nome do exercício com série e peso na mesma linha
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha 1: Título do exercício
                Text(
                  exercise.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                // Linha 2: Série e peso lado a lado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Lado esquerdo: Série + Tipo
                    Text(
                      'Série: 1 · Trab.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    // Lado direito: Peso x Reps
                    Text(
                      exercise.series.isNotEmpty ? '${exercise.series.first.weight}kg × ${exercise.series.first.reps} reps' : '-kg × - reps',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Divider
          if (exercise.series.isNotEmpty)
            Divider(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          // Séries (exceto a primeira que já está no header)
          if (exercise.series.length > 1)
            ...exercise.series.skip(1).toList().asMap().entries.map((entry) {
              final index = entry.key + 1; // +1 porque pulamos a primeira
              final serie = entry.value;
              return Column(
                children: [
                  SerieRow(serie: serie, animated: animated),
                  if (index < exercise.series.length - 1)
                    Divider(
                      height: 1,
                      indent: 12,
                      endIndent: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.1),
                    ),
                ],
              );
            }),
        ],
      ),
    );

    if (!animated) {
      return block;
    }

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: AlwaysStoppedAnimation(1.0),
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: AlwaysStoppedAnimation(1.0),
                curve: Curves.easeOut,
              ),
            ),
        child: block,
      ),
    );
  }
}
