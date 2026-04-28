import 'package:flutter/material.dart';

/// Placeholder chart widget for exercises evolution.
/// The real implementation can be reintroduced later.
class ExercisesEvolutionChart extends StatelessWidget {
  final List<dynamic>? data;
  const ExercisesEvolutionChart({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Text(
          'Gráfico de evolução (placeholder)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
