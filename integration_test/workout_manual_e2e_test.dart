import 'package:flutter_test/flutter_test.dart';

import 'support/e2e_suite.dart';
import 'support/steps/workout_steps.dart';

void main() {
  e2eWorkoutPatrolTest(
    'treino retroativo com duração → POST isManual',
    ($) async {
      await pumpWorkoutDayScreen(
        $,
        manualDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      await waitForExercisesLoaded($);
      await tapStartWorkout($);

      await enterSeriesOnExercise(
        $,
        exerciseId: E2eFixtures.exerciseNormalId,
        localSetIndex: 0,
        weight: '30',
        reps: '10',
      );

      await tapFinishWorkout($);
      await confirmDurationIfShown($);
      expect(find.byKey(WorkoutTestKeys.workoutSummary), findsOneWidget);

      final workout = await WorkoutVerifyHelper().fetchLatestTrainingWorkout();
      expect(workout?['isManual'], isTrue);
    },
  );
}
