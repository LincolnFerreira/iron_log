import 'package:flutter/material.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import '../atoms/workout_metric.dart';

class ActiveWorkoutCard extends StatelessWidget {
  final Routine routine;
  final Session session;

  const ActiveWorkoutCard({
    super.key,
    required this.routine,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 10,
              children: [
                Icon(Icons.today, size: 20),
                Text(
                  'Treino de hoje',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            Column(
              spacing: 16,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${routine.name} - ${session.name}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Hoje',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    WorkoutMetric(
                      value: '${session.exercises.length}',
                      label: 'Exercícios',
                    ),
                    WorkoutMetric(
                      value: '${session.muscles.length}',
                      label: 'Grupos',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
