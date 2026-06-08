import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iron_log/core/providers/sync_providers.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/routines/routine_providers.dart';
import 'package:iron_log/features/workout_day/presentation/pages/workout_day_screen.dart';
import 'package:patrol/patrol.dart';

import 'fixtures.dart';

HttpService ensureHttpService() {
  final http = HttpService();
  http.initialize();
  return http;
}

List<Override> e2eProviderOverrides() {
  return [
    httpServiceProvider.overrideWithValue(ensureHttpService()),
    ...routineProvidersOverrides,
    ...syncProvidersOverrides,
  ];
}

Future<void> pumpWorkoutDayScreen(
  PatrolIntegrationTester $, {
  String? routineId,
  String? sessionId,
  DateTime? manualDate,
  String? workoutId,
}) async {
  final rid = routineId ?? E2eFixtures.routineId;
  final sid = sessionId ?? E2eFixtures.sessionId;

  Widget home;
  if (workoutId != null && workoutId.isNotEmpty) {
    home = WorkoutDayScreen.edit(workoutId: workoutId);
  } else if (manualDate != null) {
    home = WorkoutDayScreen.manual(
      manualDate: manualDate,
      routineId: rid,
      sessionId: sid,
    );
  } else {
    home = WorkoutDayScreen.create(routineId: rid, sessionId: sid);
  }

  await $.pumpWidget(
    ProviderScope(
      overrides: e2eProviderOverrides(),
      child: MaterialApp(home: home),
    ),
  );

  await pumpSettleE2e($);
}

Future<void> pumpSettleE2e(
  PatrolIntegrationTester $, {
  Duration timeout = const Duration(seconds: 12),
}) async {
  final tester = $.tester;
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (!tester.binding.hasScheduledFrame) {
      await tester.pump(const Duration(milliseconds: 300));
      if (!tester.binding.hasScheduledFrame) return;
    }
  }
}
