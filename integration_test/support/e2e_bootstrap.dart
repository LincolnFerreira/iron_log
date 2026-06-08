import 'package:patrol/patrol.dart';

import 'auth_helper.dart';
import 'fixture_resolver.dart';
import 'fixtures.dart';

/// Auth Google (Patrol) + resolve fixtures E2E antes de cada teste.
class E2ePatrolBootstrap {
  static Future<void> ensureReady(PatrolIntegrationTester $) async {
    await E2eAuthHelper.ensureAuthenticated($);
    await E2eFixtureResolver.resolve();
    E2eFixtures.requireConfigured();
  }
}
