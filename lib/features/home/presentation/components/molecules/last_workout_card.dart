import 'package:flutter/material.dart';
import '../atoms/workout_metric.dart';

class LastWorkoutCard extends StatelessWidget {
  final String workoutName;
  final String date;
  final String duration;
  final String volume;
  final String exercises;
  final String observation;

  const LastWorkoutCard({
    super.key,
    required this.workoutName,
    required this.date,
    required this.duration,
    required this.volume,
    required this.exercises,
    required this.observation,
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
                Icon(Icons.access_time_filled, size: 20),
                Text(
                  'Último treino',
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
                    Text(workoutName),
                    Text(date, style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    WorkoutMetric(value: duration, label: 'Duração'),
                    WorkoutMetric(value: volume, label: 'Volume'),
                    WorkoutMetric(value: exercises, label: 'Exercícios'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Observação:', style: Theme.of(context).textTheme.bodyMedium),
            Text(
              '"$observation"',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
