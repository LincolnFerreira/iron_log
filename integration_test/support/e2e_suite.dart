import 'package:patrol/patrol.dart';

import 'e2e_bootstrap.dart';

/// Wrapper Patrol: login Google nativo + fixtures + corpo do teste.
void e2eWorkoutPatrolTest(
  String description,
  Future<void> Function(PatrolIntegrationTester $) body, {
  Future<void> Function()? setUp,
}) {
  patrolTest(description, ($) async {
    await E2ePatrolBootstrap.ensureReady($);
    if (setUp != null) await setUp();
    await body($);
  });
}
