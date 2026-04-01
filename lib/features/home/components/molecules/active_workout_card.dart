import 'package:flutter/material.dart';
import 'package:iron_log/core/app_colors.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import '../molecules/exercise_preview_chips.dart';
import '../atoms/start_workout_button.dart';

class ActiveWorkoutCard extends StatelessWidget {
  final Routine routine;
  final Session session;
  final VoidCallback? onStartWorkout;

  const ActiveWorkoutCard({
    super.key,
    required this.routine,
    required this.session,
    this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Session name + "Hoje" label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              session.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryLight,
                fontSize: 26,
              ),
            ),
          ],
        ),
        // Exercise preview chips
        // Start workout button
        StartWorkoutButton(
          sessionName: session.name,
          exerciseCount: session.exercises.length,
          onTap: onStartWorkout ?? () {},
        ),
        ExercisePreviewChips(exercises: session.exercises),
      ],
    );
  }
}
