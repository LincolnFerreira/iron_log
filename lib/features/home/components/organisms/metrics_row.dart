import 'package:flutter/material.dart';

import '../atoms/metric_card.dart';

class MetricsRow extends StatelessWidget {
  final int monthlyWorkouts;
  final int currentStreak;

  const MetricsRow({
    super.key,
    required this.monthlyWorkouts,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            value: monthlyWorkouts.toString(),
            label: 'Treinos este mês',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: MetricCard(
            value: currentStreak.toString(),
            label: 'Sequência atual',
          ),
        ),
      ],
    );
  }
}
