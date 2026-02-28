import 'package:flutter/material.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import '../atoms/workout_loading_card.dart';
import '../atoms/no_workout_card.dart';
import 'active_workout_card.dart';

class TodaysWorkoutCard extends StatelessWidget {
  final Routine? todaysRoutine;
  final Session? todaysSession;
  final bool isLoading;

  const TodaysWorkoutCard({
    super.key,
    this.todaysRoutine,
    this.todaysSession,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const WorkoutLoadingCard();
    }

    if (todaysRoutine == null || todaysSession == null) {
      return const NoWorkoutCard();
    }

    return ActiveWorkoutCard(routine: todaysRoutine!, session: todaysSession!);
  }
}
