import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/services/auth_service.dart';

import 'e2e_fixture_constants.dart';

/// Cria rotina/sessão/exercícios E2E via API — idempotente, sem seed manual.
class E2eFixtureProvisioner {
  final AuthService _auth = AuthService();

  /// Garante fixtures no backend para o usuário autenticado.
  Future<void> ensure({Map<String, dynamic>? existingRoutine}) async {
    final exerciseIds = await _ensureExercises();

    if (existingRoutine == null) {
      await _createRoutineWithSession(exerciseIds);
      return;
    }

    final routineId = existingRoutine['id']?.toString() ?? '';
    if (routineId.isEmpty) {
      await _createRoutineWithSession(exerciseIds);
      return;
    }

    final sessions = _asList(existingRoutine['sessions']);
    Map<String, dynamic>? session;
    for (final raw in sessions) {
      final map = Map<String, dynamic>.from(raw as Map);
      if (map['name'] == E2eFixtureConstants.sessionName) {
        session = map;
        break;
      }
    }

    if (session == null) {
      final created = await _auth.post(
        ApiEndpoints.sessions,
        data: {
          'routineId': routineId,
          'name': E2eFixtureConstants.sessionName,
          'order': 0,
          'muscles': ['Peito'],
        },
      );
      final sessionId = (created.data as Map)['id']?.toString() ?? '';
      await _replaceSessionExercises(sessionId, exerciseIds);
      return;
    }

    final sessionId = session['id']?.toString() ?? '';
    if (!_hasAllExercises(session)) {
      await _replaceSessionExercises(sessionId, exerciseIds);
    }
  }

  Future<Map<String, String>> _ensureExercises() async {
    final ids = <String, String>{};
    for (final entry in E2eFixtureConstants.exerciseNames.entries) {
      ids[entry.key] = await _ensureExerciseByName(entry.value);
    }
    return ids;
  }

  Future<String> _ensureExerciseByName(String name) async {
    final search = await _auth.get(
      ApiEndpoints.exerciseSearch(name, limit: 10),
    );
    for (final raw in _asList(search.data)) {
      final map = Map<String, dynamic>.from(raw as Map);
      if (map['name']?.toString() == name) {
        final id = map['id']?.toString() ?? '';
        if (id.isNotEmpty) return id;
      }
    }

    final created = await _auth.post(
      ApiEndpoints.exercises,
      data: {
        'name': name,
        'tags': ['e2e'],
        'primaryMuscle': 'Peito',
      },
    );
    final data = created.data as Map;
    return data['id']?.toString() ?? '';
  }

  Future<void> _createRoutineWithSession(Map<String, String> exerciseIds) async {
    final exercises = _buildSessionExercisesPayload(exerciseIds);
    await _auth.post(
      ApiEndpoints.routines,
      data: {
        'name': E2eFixtureConstants.routineName,
        'division': E2eFixtureConstants.division,
        'isTemplate': false,
        'sessions': [
          {
            'name': E2eFixtureConstants.sessionName,
            'order': 0,
            'muscles': ['Peito'],
            'exercises': exercises,
          },
        ],
      },
    );
  }

  Future<void> _replaceSessionExercises(
    String sessionId,
    Map<String, String> exerciseIds,
  ) async {
    if (sessionId.isEmpty) {
      throw StateError('sessionId vazio ao provisionar exercícios E2E');
    }
    await _auth.patch(
      '${ApiEndpoints.sessions}/$sessionId/exercises',
      data: {'exercises': _buildSessionExercisesPayload(exerciseIds)},
    );
  }

  List<Map<String, dynamic>> _buildSessionExercisesPayload(
    Map<String, String> exerciseIds,
  ) {
    final orderedKeys = [
      'normal',
      'warmup',
      'drop',
      'cluster',
    ];
    return [
      for (var i = 0; i < orderedKeys.length; i++)
        {
          'exerciseId': exerciseIds[orderedKeys[i]],
          'order': i + 1,
          'isActive': true,
          'config': Map<String, dynamic>.from(
            E2eFixtureConstants.defaultExerciseConfig,
          ),
        },
    ];
  }

  bool _hasAllExercises(Map<String, dynamic> session) {
    final exercises = _asList(session['exercises']);
    final names = <String>{};
    for (final raw in exercises) {
      final map = Map<String, dynamic>.from(raw as Map);
      final exercise = map['exercise'] as Map<String, dynamic>? ?? map;
      final name = exercise['name']?.toString() ?? '';
      if (name.isNotEmpty) names.add(name);
    }
    for (final name in E2eFixtureConstants.exerciseNames.values) {
      if (!names.contains(name)) return false;
    }
    return true;
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    return [];
  }
}
