import 'package:flutter/material.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';

class ExerciseSmallTile extends StatelessWidget {
  final WorkoutExercise exercise;
  final int index;

  const ExerciseSmallTile({
    super.key,
    required this.exercise,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey(exercise.id),
      dense: true,
      title: Text(
        exercise.name,
        style: Theme.of(context).textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
      leading: CircleAvatar(
        radius: 14,
        child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
