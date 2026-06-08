import 'package:flutter/material.dart';

/// Stable keys for E2E / integration tests. Prefix `e2e_` avoids collisions.
abstract final class WorkoutTestKeys {
  static Key exerciseCard(String exerciseId) => Key('e2e_exercise_$exerciseId');

  static Key seriesWeight(int globalIndex) => Key('e2e_weight_$globalIndex');
  static Key seriesReps(int globalIndex) => Key('e2e_reps_$globalIndex');
  static Key seriesDone(int globalIndex) => Key('e2e_done_$globalIndex');

  static const startWorkout = Key('e2e_start_workout');
  static const finishWorkout = Key('e2e_finish_workout');
  static const techniqueMenu = Key('e2e_technique_menu');
  static const clusterApply = Key('e2e_cluster_apply');
  static const removeCluster = Key('e2e_remove_cluster');
  static const terminateCluster = Key('e2e_terminate_cluster');
  static const durationConfirm = Key('e2e_duration_confirm');
  static const workoutSummary = Key('e2e_workout_summary');
}
