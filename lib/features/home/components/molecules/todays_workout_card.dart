import 'package:flutter/material.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import '../atoms/workout_loading_card.dart';
import '../atoms/no_workout_card.dart';
import 'active_workout_card.dart';

class TodaysWorkoutCard extends StatelessWidget {
  final Routine? todaysRoutine;
  final Session? todaysSession;
  final bool isLoading;
  final VoidCallback? onStartWorkout;
  final VoidCallback? onNoWorkoutTap;
  final List<Session> sessions;
  final void Function(Session)? onSelectSession;

  const TodaysWorkoutCard({
    super.key,
    this.todaysRoutine,
    this.todaysSession,
    this.isLoading = false,
    this.onStartWorkout,
    this.onNoWorkoutTap,
    this.sessions = const [],
    this.onSelectSession,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const WorkoutLoadingCard();
    }

    if (todaysRoutine == null || todaysSession == null) {
      return NoWorkoutCard(onTap: onNoWorkoutTap);
    }

    return ActiveWorkoutCard(
      routine: todaysRoutine!,
      session: todaysSession!,
      sessions: sessions,
      onStartWorkout: onStartWorkout,
      onSelectSession: onSelectSession,
    );
  }
}
