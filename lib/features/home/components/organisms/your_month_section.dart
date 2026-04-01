import 'package:flutter/material.dart';
import '../atoms/metric_card.dart';

/// Your Month section displaying monthly metrics and progress towards monthly goal
class YourMonthSection extends StatelessWidget {
  final int workoutsCompleted; // e.g., 3
  final int monthlyGoal; // e.g., 20
  final int totalSeries; // Total series performed this month
  final int totalRoutines; // Number of routines created/available

  const YourMonthSection({
    super.key,
    required this.workoutsCompleted,
    required this.monthlyGoal,
    required this.totalSeries,
    required this.totalRoutines,
  });

  double _getProgressPercentage() {
    return (workoutsCompleted / monthlyGoal * 100).clamp(0, 100);
  }

  int _getRemainingWorkouts() {
    return (monthlyGoal - workoutsCompleted).clamp(0, monthlyGoal);
  }

  @override
  Widget build(BuildContext context) {
    final progressPercentage = _getProgressPercentage();
    final remainingWorkouts = _getRemainingWorkouts();

    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'SEU MÊS',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        // Three metrics in a row
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: MetricCard(
                value: workoutsCompleted.toString(),
                label: 'Treinos',
              ),
            ),
            Expanded(
              child: MetricCard(
                value: totalSeries.toString(),
                label: 'Séries totais',
              ),
            ),
            Expanded(
              child: MetricCard(
                value: totalRoutines.toString(),
                label: 'Rotinas',
              ),
            ),
          ],
        ),
        // Monthly goal progress section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal header with label and progress counter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Meta mensal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$workoutsCompleted/$monthlyGoal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressPercentage / 100,
                  minHeight: 8,
                  backgroundColor: Theme.of(
                    context,
                  ).dividerColor.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              // Progress description
              Text(
                '${progressPercentage.toStringAsFixed(0)}% concluído · faltam $remainingWorkouts treinos para bater a meta 🎯',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
