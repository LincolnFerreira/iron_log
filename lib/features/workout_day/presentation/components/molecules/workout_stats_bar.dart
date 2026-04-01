import 'package:flutter/material.dart';

class WorkoutStatsBar extends StatelessWidget {
  final int seriesDone;
  final double volumeKg;
  final int completionPercent;

  const WorkoutStatsBar({
    super.key,
    required this.seriesDone,
    required this.volumeKg,
    required this.completionPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(title: 'Séries feitas', value: seriesDone.toString()),
          _StatItem(
            title: 'Volume',
            value: '${volumeKg.toStringAsFixed(1)} kg',
          ),
          _StatItem(title: 'Concluído', value: '$completionPercent%'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;

  const _StatItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
