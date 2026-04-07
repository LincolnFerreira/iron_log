import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Main sync manager: orchestrates offline-first sync operations
class SyncManager {
  final Dio dio;
  final AppDatabase database;
  final Connectivity connectivity;

  // State tracking
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _pendingChanges = 0;

  // Streams
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  final _conflictController = StreamController<SyncConflict>.broadcast();

  SyncManager({
    required this.dio,
    required this.database,
    required this.connectivity,
  }) {
    _initConnectivityListener();
  }

  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;
  Stream<SyncConflict> get conflicts => _conflictController.stream;

  SyncStatus get currentStatus => SyncStatus(
    isSyncing: _isSyncing,
    lastSyncTime: _lastSyncTime,
    pendingChanges: _pendingChanges,
  );

  /// Initialize connectivity listener for auto-sync
  void _initConnectivityListener() {
    connectivity.onConnectivityChanged.listen((result) async {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        // Internet detected, trigger auto-sync if pending changes exist
        await syncIfNeeded();
      }
    });
  }

  /// Trigger sync only if there are pending changes
  Future<void> syncIfNeeded() async {
    _pendingChanges = await _countPendingChanges();

    if (_pendingChanges > 0 && !_isSyncing) {
      await sync();
    }
  }

  /// Main sync operation
  Future<SyncResult> sync() async {
    if (_isSyncing) return SyncResult.empty();

    _isSyncing = true;
    _syncStatusController.add(currentStatus);

    try {
      // Collect all pending changes from local database
      final changes = await _collectPendingChanges();

      if (changes.isEmpty) {
        _isSyncing = false;
        return SyncResult(synced: [], conflicts: [], failed: []);
      }

      // Send to server
      final response = await dio.post<Map<String, dynamic>>(
        '/sync',
        data: {'changes': changes},
      );

      final result = SyncResult.fromJson(response.data ?? {});

      // Handle conflicts
      for (final conflict in result.conflicts) {
        _conflictController.add(conflict);
      }

      // Apply synced changes to local database
      for (final syncedItem in result.synced) {
        await _markAsSynced(
          syncedItem['entity'] as String,
          syncedItem['entityId'] as String,
        );
      }

      _lastSyncTime = DateTime.now();
      _pendingChanges = await _countPendingChanges();

      _isSyncing = false;
      _syncStatusController.add(currentStatus);

      return result;
    } catch (e) {
      _isSyncing = false;
      _syncStatusController.add(currentStatus);
      rethrow;
    }
  }

  /// Resolve a conflict with user's decision
  Future<void> resolveConflict({
    required String conflictId,
    required ConflictResolution resolution,
    Map<String, dynamic>? mergedData,
  }) async {
    await dio.post(
      '/sync/conflicts/$conflictId/resolve',
      data: {'resolution': resolution.name, 'mergedData': mergedData},
    );

    // Re-sync after conflict resolution
    await sync();
  }

  /// Collect all pending changes from local database
  Future<List<Map<String, dynamic>>> _collectPendingChanges() async {
    final changes = <Map<String, dynamic>>[];

    // Routines
    final routines = await (database.select(
      database.routines,
    )..where((r) => r.pendingSync.equals(true))).get();

    for (final routine in routines) {
      changes.add({
        'entity': 'Routine',
        'entityId': routine.id,
        'operation': routine.version == 1 ? 'create' : 'update',
        'localVersion': routine.version,
        'data': _routineToJson(routine),
      });
    }

    // Sessions
    final sessions = await (database.select(
      database.sessions,
    )..where((s) => s.pendingSync.equals(true))).get();

    for (final session in sessions) {
      changes.add({
        'entity': 'Session',
        'entityId': session.id,
        'operation': session.version == 1 ? 'create' : 'update',
        'localVersion': session.version,
        'data': _sessionToJson(session),
      });
    }

    // WorkoutSessions
    final workouts = await (database.select(
      database.workoutSessions,
    )..where((w) => w.pendingSync.equals(true))).get();

    for (final workout in workouts) {
      changes.add({
        'entity': 'WorkoutSession',
        'entityId': workout.id,
        'operation': workout.version == 1 ? 'create' : 'update',
        'localVersion': workout.version,
        'data': _workoutSessionToJson(workout),
      });
    }

    // SerieLogs
    final series = await (database.select(
      database.serieLogs,
    )..where((s) => s.pendingSync.equals(true))).get();

    for (final log in series) {
      changes.add({
        'entity': 'SerieLog',
        'entityId': log.id,
        'operation': log.version == 1 ? 'create' : 'update',
        'localVersion': log.version,
        'data': _serieLogToJson(log),
      });
    }

    return changes;
  }

  /// Count pending changes
  Future<int> _countPendingChanges() async {
    final routines = await (database.select(
      database.routines,
    )..where((r) => r.pendingSync.equals(true))).get();

    final sessions = await (database.select(
      database.sessions,
    )..where((s) => s.pendingSync.equals(true))).get();

    final workouts = await (database.select(
      database.workoutSessions,
    )..where((w) => w.pendingSync.equals(true))).get();

    final series = await (database.select(
      database.serieLogs,
    )..where((s) => s.pendingSync.equals(true))).get();

    return routines.length + sessions.length + workouts.length + series.length;
  }

  /// Mark entity as synced in local database
  Future<void> _markAsSynced(String entity, String entityId) async {
    final now = DateTime.now();

    switch (entity) {
      case 'Routine':
        await (database.update(
          database.routines,
        )..where((r) => r.id.equals(entityId))).write(
          RoutinesCompanion(
            pendingSync: const Value(false),
            syncedAt: Value(now),
          ),
        );
        break;
      case 'Session':
        await (database.update(
          database.sessions,
        )..where((s) => s.id.equals(entityId))).write(
          SessionsCompanion(
            pendingSync: const Value(false),
            syncedAt: Value(now),
          ),
        );
        break;
      case 'WorkoutSession':
        await (database.update(
          database.workoutSessions,
        )..where((w) => w.id.equals(entityId))).write(
          WorkoutSessionsCompanion(
            pendingSync: const Value(false),
            syncedAt: Value(now),
          ),
        );
        break;
      case 'SerieLog':
        await (database.update(
          database.serieLogs,
        )..where((s) => s.id.equals(entityId))).write(
          SerieLogsCompanion(
            pendingSync: const Value(false),
            syncedAt: Value(now),
          ),
        );
        break;
    }
  }

  // Conversion helpers
  Map<String, dynamic> _routineToJson(Routine r) => {
    'id': r.id,
    'userId': r.userId,
    'name': r.name,
    'division': r.division,
    'isTemplate': r.isTemplate,
    'version': r.version,
    'pendingSync': r.pendingSync,
    'syncedAt': r.syncedAt?.toIso8601String(),
  };

  Map<String, dynamic> _sessionToJson(Session s) => {
    'id': s.id,
    'routineId': s.routineId,
    'name': s.name,
    'order': s.order,
    'muscles': s.muscles,
    'version': s.version,
    'pendingSync': s.pendingSync,
    'syncedAt': s.syncedAt?.toIso8601String(),
  };

  Map<String, dynamic> _workoutSessionToJson(WorkoutSession w) => {
    'id': w.id,
    'userId': w.userId,
    'routineId': w.routineId,
    'startedAt': w.startedAt.toIso8601String(),
    'endedAt': w.endedAt?.toIso8601String(),
    'isManual': w.isManual,
    'notes': w.notes,
    'totalVolume': w.totalVolume,
    'topSetsCount': w.topSetsCount,
    'avgRIR': w.avgRIR,
    'version': w.version,
    'pendingSync': w.pendingSync,
    'syncedAt': w.syncedAt?.toIso8601String(),
  };

  Map<String, dynamic> _serieLogToJson(SerieLog s) => {
    'id': s.id,
    'sessionId': s.sessionId,
    'exerciseId': s.exerciseId,
    'setIndex': s.setIndex,
    'label': s.label,
    'reps': s.reps,
    'weightKg': s.weightKg,
    'weightUnit': s.weightUnit,
    'rir': s.rir,
    'restSec': s.restSec,
    'isFailure': s.isFailure,
    'version': s.version,
    'pendingSync': s.pendingSync,
    'syncedAt': s.syncedAt?.toIso8601String(),
  };

  void dispose() {
    _syncStatusController.close();
    _conflictController.close();
  }
}

// Models

class SyncStatus {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int pendingChanges;

  SyncStatus({
    required this.isSyncing,
    required this.lastSyncTime,
    required this.pendingChanges,
  });
}

class SyncResult {
  final List<Map<String, dynamic>> synced;
  final List<SyncConflict> conflicts;
  final List<Map<String, dynamic>> failed;

  SyncResult({
    required this.synced,
    required this.conflicts,
    required this.failed,
  });

  factory SyncResult.empty() =>
      SyncResult(synced: [], conflicts: [], failed: []);

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      synced: List<Map<String, dynamic>>.from(json['synced'] ?? []),
      conflicts: List<Map<String, dynamic>>.from(
        json['conflicts'] ?? [],
      ).map((c) => SyncConflict.fromJson(c)).toList(),
      failed: List<Map<String, dynamic>>.from(json['failed'] ?? []),
    );
  }
}

class SyncConflict {
  final String entity;
  final String entityId;
  final int localVersion;
  final int remoteVersion;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;

  SyncConflict({
    required this.entity,
    required this.entityId,
    required this.localVersion,
    required this.remoteVersion,
    required this.localData,
    required this.remoteData,
  });

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      entity: json['entity'],
      entityId: json['entityId'],
      localVersion: json['localVersion'],
      remoteVersion: json['remoteVersion'],
      localData: json['localData'],
      remoteData: json['remoteData'],
    );
  }
}

enum ConflictResolution { local, remote, merged }
