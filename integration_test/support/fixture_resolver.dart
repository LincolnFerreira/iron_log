import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/services/auth_service.dart';

import 'e2e_fixture_constants.dart';
import 'e2e_fixture_provisioner.dart';
import 'fixtures.dart';

/// Resolve (e provisiona se necessário) IDs da rotina/sessão E2E via API.
class E2eFixtureResolver {
  static Future<void> resolve() async {
    if (E2eFixtures.isConfigured) return;

    final auth = AuthService();
    var routine = await _findRoutine(auth);

    if (routine != null && _tryApply(routine)) return;

    await E2eFixtureProvisioner().ensure(existingRoutine: routine);

    routine = await _findRoutine(auth);
    if (routine != null && _tryApply(routine)) return;

    // Lista pode vir sem exercises aninhados — busca detalhe.
    if (routine != null) {
      final id = routine['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        final detail = await auth.get(ApiEndpoints.routineById(id));
        if (_tryApply(Map<String, dynamic>.from(detail.data as Map))) {
          return;
        }
      }
    }

    throw StateError(
      'Não foi possível provisionar fixtures E2E. '
      'Confira backend local (${ApiEndpoints.baseUrl}).',
    );
  }

  static Future<Map<String, dynamic>?> _findRoutine(AuthService auth) async {
    final response = await auth.get(ApiEndpoints.routines);
    for (final raw in _asList(response.data)) {
      final map = Map<String, dynamic>.from(raw as Map);
      if (map['name'] == E2eFixtureConstants.routineName) {
        return map;
      }
    }
    return null;
  }

  static bool _tryApply(Map<String, dynamic> routineJson) {
    final routineId = routineJson['id']?.toString() ?? '';
    final sessions = _asList(routineJson['sessions']);
    Map<String, dynamic>? sessionJson;
    for (final raw in sessions) {
      final map = Map<String, dynamic>.from(raw as Map);
      if (map['name'] == E2eFixtureConstants.sessionName) {
        sessionJson = map;
        break;
      }
    }
    if (sessionJson == null) return false;

    final sessionId = sessionJson['id']?.toString() ?? '';
    final exercises = _asList(sessionJson['exercises']);
    final byName = <String, String>{};

    for (final raw in exercises) {
      final map = Map<String, dynamic>.from(raw as Map);
      final exercise = map['exercise'] as Map<String, dynamic>? ?? map;
      final name = exercise['name']?.toString() ?? '';
      final id = map['exerciseId']?.toString() ??
          exercise['id']?.toString() ??
          '';
      if (name.isNotEmpty && id.isNotEmpty) {
        byName[name] = id;
      }
    }

    final names = E2eFixtureConstants.exerciseNames;
    if (!byName.containsKey(names['normal']) ||
        !byName.containsKey(names['warmup']) ||
        !byName.containsKey(names['drop']) ||
        !byName.containsKey(names['cluster'])) {
      return false;
    }

    E2eFixtures.applyResolved(
      routineId: routineId,
      sessionId: sessionId,
      exerciseNormalId: byName[names['normal']]!,
      exerciseWarmupId: byName[names['warmup']]!,
      exerciseDropId: byName[names['drop']]!,
      exerciseClusterId: byName[names['cluster']]!,
    );
    return true;
  }

  static List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    return [];
  }
}
