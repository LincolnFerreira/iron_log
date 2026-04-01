import 'package:flutter/material.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';
import '../molecules/history_item_card.dart';

/// Seção de histórico - treinos anteriores
class HistorySection extends StatelessWidget {
  final WorkoutSummary workoutSummary;

  const HistorySection({super.key, required this.workoutSummary});

  @override
  Widget build(BuildContext context) {
    // Não mostra se não houver histórico
    if (workoutSummary.previousWorkouts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Limita a 5 itens
    final displayedWorkouts = workoutSummary.previousWorkouts.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho de seção
          Text(
            'Histórico',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          // Card contendo todos os itens
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: displayedWorkouts.asMap().entries.map((entry) {
                final index = entry.key;
                final workout = entry.value;
                return Column(
                  children: [
                    HistoryItemCard(workoutHistory: workout, animated: true),
                    if (index < displayedWorkouts.length - 1)
                      Divider(
                        height: 0,
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
