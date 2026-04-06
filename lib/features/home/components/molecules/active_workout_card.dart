import 'package:flutter/material.dart';
import 'package:iron_log/core/app_colors.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import '../molecules/exercise_preview_chips.dart';
import '../atoms/start_workout_button.dart';
import '../organisms/session_picker_sheet.dart';

class ActiveWorkoutCard extends StatelessWidget {
  final Routine routine;
  final Session session;
  final List<Session> sessions;
  final VoidCallback? onStartWorkout;
  final void Function(Session)? onSelectSession;

  const ActiveWorkoutCard({
    super.key,
    required this.routine,
    required this.session,
    this.sessions = const [],
    this.onStartWorkout,
    this.onSelectSession,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Routine name + swap button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              routine.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (sessions.length > 1)
              GestureDetector(
                onTap: () => SessionPickerSheet.show(
                  context,
                  sessions: sessions,
                  currentSession: session,
                  onSelectSession: onSelectSession ?? (_) {},
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Trocar',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 18,
                      color: AppColors.primaryLight,
                    ),
                  ],
                ),
              ),
          ],
        ),
        // Session name heading
        Text(
          session.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryLight,
            fontSize: 26,
          ),
        ),
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
