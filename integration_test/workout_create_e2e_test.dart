import 'package:flutter_test/flutter_test.dart';

import 'support/e2e_suite.dart';
import 'support/steps/workout_steps.dart';

void main() {
  e2eWorkoutPatrolTest(
    'UI → POST: séries normais persistidas no backend',
    ($) async {
      await pumpWorkoutDayScreen($);
      await waitForExercisesLoaded($);
      await tapStartWorkout($);

      await enterSeriesOnExercise(
        $,
        exerciseId: E2eFixtures.exerciseNormalId,
        localSetIndex: 0,
        weight: '42',
        reps: '8',
      );
      await enterSeriesOnExercise(
        $,
        exerciseId: E2eFixtures.exerciseNormalId,
        localSetIndex: 1,
        weight: '42',
        reps: '8',
      );

      final workout = await finishAndFetchLatestWorkout($);
      final series = WorkoutVerifyHelper().extractSeries(workout);

      expect(
        WorkoutVerifyHelper().hasSeriesWith(
          series: series,
          reps: 8,
          weight: 42,
        ),
        isTrue,
        reason: 'Backend deve refletir peso/reps digitados na UI',
      );
    },
  );
}
