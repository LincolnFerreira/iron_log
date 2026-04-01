import 'package:flutter/material.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';
import '../molecules/stat_card.dart';

/// Grid de estatísticas (2x2) - Duração, Séries Feitas, Volume, Conclusão
class StatsGrid extends StatelessWidget {
  final WorkoutSummary workoutSummary;

  const StatsGrid({super.key, required this.workoutSummary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 16,
        childAspectRatio: 2,
        children: [
          // DURAÇÃO
          StatCard(
            value: workoutSummary.durationFormatted,
            label: 'Duração',
            color: const Color(0xFFFFC107), // Yellow/Amber
            animated: true,
          ),
          // SÉRIES FEITAS
          StatCard(
            value:
                '${workoutSummary.completedSeries}/${workoutSummary.totalSeries}',
            label: 'Séries Feitas',
            color: const Color(0xFF4CAF50), // Green
            animated: true,
          ),
          // VOLUME TOTAL
          StatCard(
            value: workoutSummary.totalVolume == 0
                ? '—'
                : '${workoutSummary.totalVolume.toStringAsFixed(0)} kg',
            label: 'Volume Total',
            color: const Color(0xFF2196F3), // Blue
            animated: true,
          ),
          // CONCLUSÃO
          StatCard(
            value: '${workoutSummary.completionPercent}%',
            label: 'Conclusão',
            color: Color(
              int.parse(
                workoutSummary.completionColor.replaceFirst('#', '0xFF'),
              ),
            ),
            animated: true,
          ),
        ],
      ),
    );
  }
}
