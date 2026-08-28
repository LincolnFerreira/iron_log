import 'package:flutter/material.dart';
import 'package:iron_log/features/workout_day/presentation/components/atoms/stat_label.dart';
import 'package:iron_log/features/workout_day/presentation/components/atoms/stat_value.dart';

/// Card de estatística - número grande + label em card compacto
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool animated;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          StatValue(value: value, color: color, animated: animated),
          StatLabel(label: label, animated: animated),
        ],
      ),
    );
  }
}
