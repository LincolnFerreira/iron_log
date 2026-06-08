import 'package:flutter_test/flutter_test.dart';
import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/services/auth_service.dart';

import 'support/e2e_suite.dart';
import 'support/steps/workout_steps.dart';

void main() {
  e2eWorkoutPatrolTest(
    'UI → PATCH: altera reps e persiste',
    ($) async {
      final auth = AuthService();
      final now = DateTime.now().toUtc().toIso8601String();
      final response = await auth.post(
        ApiEndpoints.createWorkout,
        data: {
          'routineId': E2eFixtures.routineId,
          'sessionId': E2eFixtures.sessionId,
          'date': now,
          'endedAt': now,
          'notes': 'E2E_edit_setup_${DateTime.now().millisecondsSinceEpoch}',
          'exercises': [
            {
              'exerciseId': E2eFixtures.exerciseNormalId,
              'name': 'E2E Normal',
              'order': 1,
              'sets': 1,
              'reps': [8],
              'weight': [40],
              'weightUnit': 'kg',
              'techniqueBlocks': [
                {
                  'type': 'NORMAL',
                  'order': 0,
                  'sets': [
                    {'reps': 8, 'weight': 40, 'isDerived': false},
                  ],
                },
              ],
            },
          ],
        },
      );
      final workoutId = (response.data as Map)['workoutId'] as String?;
      expect(workoutId, isNotNull);

      await pumpWorkoutDayScreen($, workoutId: workoutId);
      await waitForExercisesLoaded($);

      await enterSeriesOnExercise(
        $,
        exerciseId: E2eFixtures.exerciseNormalId,
        localSetIndex: 0,
        weight: '45',
        reps: '10',
      );

      await tapFinishWorkout($);
      await confirmDurationIfShown($);
      await pumpSettleE2e($);

      expect(find.text('Treino atualizado com sucesso!'), findsOneWidget);

      final workout = await WorkoutVerifyHelper().fetchWorkout(workoutId!);
      final series = WorkoutVerifyHelper().extractSeries(workout);
      expect(
        WorkoutVerifyHelper().hasSeriesWith(
          series: series,
          reps: 10,
          weight: 45,
        ),
        isTrue,
      );
    },
  );
}
