import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../e2e_app.dart';
import '../fixtures.dart';
import '../test_keys.dart';
import '../verify_helper.dart';

export '../auth_helper.dart';
export '../e2e_app.dart';
export '../e2e_bootstrap.dart';
export '../fixtures.dart';
export '../test_keys.dart';
export '../verify_helper.dart';

Future<void> waitForExercisesLoaded(PatrolIntegrationTester $) async {
  final tester = $.tester;
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 400));
    if (find.byKey(WorkoutTestKeys.startWorkout).evaluate().isNotEmpty) {
      await pumpSettleE2e($);
      return;
    }
    if (find.text('Erro ao carregar exercícios').evaluate().isNotEmpty) {
      throw StateError(
        'Falha ao carregar sessão — verifique backend local no ar.',
      );
    }
  }
  throw StateError('Timeout: exercícios não carregaram.');
}

Future<void> tapStartWorkout(PatrolIntegrationTester $) async {
  final tester = $.tester;
  await tester.scrollUntilVisible(find.byKey(WorkoutTestKeys.startWorkout), 120);
  await tester.tap(find.byKey(WorkoutTestKeys.startWorkout));
  await pumpSettleE2e($, timeout: const Duration(seconds: 15));
}

Future<void> tapFinishWorkout(PatrolIntegrationTester $) async {
  final tester = $.tester;
  await tester.scrollUntilVisible(
    find.byKey(WorkoutTestKeys.finishWorkout),
    200,
  );
  await tester.tap(find.byKey(WorkoutTestKeys.finishWorkout));
  await pumpSettleE2e($, timeout: const Duration(seconds: 20));
}

Future<void> confirmDurationIfShown(PatrolIntegrationTester $) async {
  final tester = $.tester;
  final confirm = find.byKey(WorkoutTestKeys.durationConfirm);
  if (confirm.evaluate().isNotEmpty) {
    await tester.tap(confirm);
    await pumpSettleE2e($, timeout: const Duration(seconds: 15));
  }
}

Future<void> enterSeriesValues(
  PatrolIntegrationTester $, {
  required int globalIndex,
  required String weight,
  required String reps,
}) async {
  await _enterField(
    $,
    key: WorkoutTestKeys.seriesWeight(globalIndex),
    value: weight,
    next: true,
  );
  await _enterField(
    $,
    key: WorkoutTestKeys.seriesReps(globalIndex),
    value: reps,
    next: false,
  );
}

Future<void> enterSeriesOnExercise(
  PatrolIntegrationTester $, {
  required String exerciseId,
  required int localSetIndex,
  required String weight,
  required String reps,
}) async {
  await scrollToExercise($, exerciseId);
  final globalIndex = E2eFixtures.seriesOffsetFor(exerciseId) + localSetIndex;
  await enterSeriesValues(
    $,
    globalIndex: globalIndex,
    weight: weight,
    reps: reps,
  );
}

Future<void> _enterField(
  PatrolIntegrationTester $, {
  required Key key,
  required String value,
  required bool next,
}) async {
  final tester = $.tester;
  await tester.scrollUntilVisible(find.byKey(key), 120);
  await tester.tap(find.byKey(key));
  await tester.pump(const Duration(milliseconds: 300));

  await tester.enterText(find.byKey(key), value);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.testTextInput.receiveAction(
    next ? TextInputAction.next : TextInputAction.done,
  );
  await pumpSettleE2e($, timeout: const Duration(seconds: 5));
}

Future<void> applyWarmupOnFirstBlock(
  PatrolIntegrationTester $, {
  required String exerciseId,
}) async {
  await _openTechniqueMenu($, exerciseId: exerciseId);
  await $.tester.tap(find.text('Aquecimento'));
  await pumpSettleE2e($);
}

Future<void> applyDropOnFirstBlock(
  PatrolIntegrationTester $, {
  required String exerciseId,
}) async {
  await _openTechniqueMenu($, exerciseId: exerciseId);
  await $.tester.tap(find.text('Drop Set'));
  await pumpSettleE2e($);
}

Future<void> applyClusterOnFirstBlock(
  PatrolIntegrationTester $, {
  required String exerciseId,
}) async {
  await _openTechniqueMenu($, exerciseId: exerciseId);
  await $.tester.tap(find.text('Cluster Set'));
  await pumpSettleE2e($);
  await $.tester.tap(find.byKey(WorkoutTestKeys.clusterApply));
  await pumpSettleE2e($);
}

Future<void> _openTechniqueMenu(
  PatrolIntegrationTester $, {
  required String exerciseId,
}) async {
  final tester = $.tester;
  final menuFinder = find.descendant(
    of: find.byKey(WorkoutTestKeys.exerciseCard(exerciseId)),
    matching: find.byKey(WorkoutTestKeys.techniqueMenu),
  );

  await tester.scrollUntilVisible(menuFinder, 160);
  await tester.tap(menuFinder);
  await pumpSettleE2e($);
}

Future<void> scrollToExercise(
  PatrolIntegrationTester $,
  String exerciseId,
) async {
  final tester = $.tester;
  await tester.scrollUntilVisible(
    find.byKey(WorkoutTestKeys.exerciseCard(exerciseId)),
    240,
  );
  await pumpSettleE2e($, timeout: const Duration(seconds: 3));
}

Future<Map<String, dynamic>> finishAndFetchLatestWorkout(
  PatrolIntegrationTester $,
) async {
  await tapFinishWorkout($);
  await confirmDurationIfShown($);
  expect(find.byKey(WorkoutTestKeys.workoutSummary), findsOneWidget);

  return WorkoutVerifyHelper().fetchLatestTrainingWorkoutDetail();
}
