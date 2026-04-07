import 'package:drift/drift.dart' as drift;

import '../../../../core/database/app_database.dart';
import '../models/routine_model.dart';

abstract class RoutineLocalDataSource {
  /// Get all routines for user from local database
  Future<List<RoutineModel>> getRoutines(String userId);

  /// Get single routine by ID
  Future<RoutineModel?> getRoutine(String id);

  /// Save routine to local database (insert or update)
  Future<void> saveRoutine(RoutineModel routine);

  /// Save multiple routines (batch operation)
  Future<void> saveRoutines(List<RoutineModel> routines);

  /// Delete routine from local database
  Future<void> deleteRoutine(String id);

  /// Get all pending changes (synced = false)
  Future<List<RoutineModel>> getPendingChanges(String userId);

  /// Mark routine as synced
  Future<void> markAsSynced(String id);

  /// Mark routine as modified (pending sync)
  Future<void> markAsModified(String id);

  /// Clear all routines for user
  Future<void> clearRoutines(String userId);

  /// Watch all routines for user (returns stream)
  Stream<List<RoutineModel>> watchRoutines(String userId);
}

class RoutineLocalDataSourceImpl implements RoutineLocalDataSource {
  final AppDatabase database;

  RoutineLocalDataSourceImpl({required this.database});

  @override
  Future<List<RoutineModel>> getRoutines(String userId) async {
    final rows = await (database.select(
      database.routines,
    )..where((r) => r.userId.equals(userId))).get();
    return rows.map(_convertToModel).toList();
  }

  @override
  Future<RoutineModel?> getRoutine(String id) async {
    final row = await (database.select(
      database.routines,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    return row != null ? _convertToModel(row) : null;
  }

  @override
  Future<void> saveRoutine(RoutineModel routine) async {
    final companion = _routineToCompanion(routine);
    await database.into(database.routines).insertOnConflictUpdate(companion);
  }

  @override
  Future<void> saveRoutines(List<RoutineModel> routines) async {
    // Use insertOnConflictUpdate for each routine individually
    for (final routine in routines) {
      final companion = _routineToCompanion(routine);
      await database.into(database.routines).insertOnConflictUpdate(companion);
    }
  }

  @override
  Future<void> deleteRoutine(String id) async {
    await (database.delete(
      database.routines,
    )..where((r) => r.id.equals(id))).go();
  }

  @override
  Future<List<RoutineModel>> getPendingChanges(String userId) async {
    final rows =
        await (database.select(database.routines)..where(
              (r) => r.userId.equals(userId) & r.pendingSync.equals(true),
            ))
            .get();
    return rows.map(_convertToModel).toList();
  }

  @override
  Future<void> markAsSynced(String id) async {
    await (database.update(
      database.routines,
    )..where((r) => r.id.equals(id))).write(
      RoutinesCompanion(
        pendingSync: const drift.Value(false),
        syncedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> markAsModified(String id) async {
    await (database.update(
      database.routines,
    )..where((r) => r.id.equals(id))).write(
      RoutinesCompanion(
        pendingSync: const drift.Value(true),
        version: drift.Value.absent(),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> clearRoutines(String userId) async {
    await (database.delete(
      database.routines,
    )..where((r) => r.userId.equals(userId))).go();
  }

  @override
  Stream<List<RoutineModel>> watchRoutines(String userId) {
    return (database.select(database.routines)
          ..where((r) => r.userId.equals(userId)))
        .watch()
        .map((rows) => rows.map(_convertToModel).toList());
  }

  /// Convert Drift row to RoutineModel
  RoutineModel _convertToModel(Routine row) {
    return RoutineModel(
      id: row.id,
      userId: row.userId,
      name: row.name,
      division: row.division,
      isTemplate: row.isTemplate,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      sessions: [],

      /// Offline-first fields
      version: row.version,
      pendingSync: row.pendingSync,
      syncedAt: row.syncedAt,
    );
  }

  /// Convert RoutineModel to Drift companion for insert/update
  RoutinesCompanion _routineToCompanion(RoutineModel routine) {
    return RoutinesCompanion(
      id: drift.Value(routine.id),
      userId: drift.Value(routine.userId),
      name: drift.Value(routine.name),
      division: drift.Value(routine.division),
      isTemplate: drift.Value(routine.isTemplate),
      version: drift.Value(routine.version ?? 1),
      pendingSync: drift.Value(routine.pendingSync ?? false),
      syncedAt: routine.syncedAt != null
          ? drift.Value(routine.syncedAt)
          : const drift.Value.absent(),
      createdAt: drift.Value(routine.createdAt),
      updatedAt: drift.Value(DateTime.now()),
    );
  }
}
