import 'package:flutter_test/flutter_test.dart';

import 'support/e2e_suite.dart';
import 'support/steps/workout_steps.dart';

void main() {
  e2eWorkoutPatrolTest(
    'UI → POST: warmup, drop e cluster no payload',
    ($) async {
      await pumpWorkoutDayScreen($);
      await waitForExercisesLoaded($);
      await tapStartWorkout($);

      await scrollToExercise($, E2eFixtures.exerciseWarmupId);
      await applyWarmupOnFirstBlock(
        $,
        exerciseId: E2eFixtures.exerciseWarmupId,
      );
      expect(find.text('AQUECIMENTO'), findsWidgets);

      await scrollToExercise($, E2eFixtures.exerciseDropId);
      await applyDropOnFirstBlock(
        $,
        exerciseId: E2eFixtures.exerciseDropId,
      );
      expect(find.text('DROP SET'), findsWidgets);

      await scrollToExercise($, E2eFixtures.exerciseClusterId);
      await applyClusterOnFirstBlock(
        $,
        exerciseId: E2eFixtures.exerciseClusterId,
      );
      expect(find.text('C1'), findsWidgets);
      expect(find.text('Remover cluster'), findsOneWidget);

      final workout = await finishAndFetchLatestWorkout($);
      final helper = WorkoutVerifyHelper();
      final series = helper.extractSeries(workout);

      helper.expectTechniqueTypes(
        series,
        {'WARMUP', 'DROP', 'CLUSTER'},
      );

      final derived = series.where((s) => s['isDerived'] == true);
      expect(derived, isNotEmpty, reason: 'Drop set deve gerar série derivada');

      final clusterMini = series.where(
        (s) =>
            (s['techniqueBlock'] as Map?)?['type'] == 'CLUSTER' &&
            s['miniSetIndex'] != null,
      );
      expect(clusterMini.length, greaterThanOrEqualTo(2));
    },
  );
}
