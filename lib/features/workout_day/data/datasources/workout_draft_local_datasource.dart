import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';

class WorkoutDraftLocalDataSource {
  WorkoutDraftLocalDataSource(this._db);

  final AppDatabase _db;

  Future<WorkoutDraftRow?> getInProgressByUser(String userId) async {
    final query = _db.select(_db.workoutDrafts)
      ..where(
        (t) => t.userId.equals(userId) & t.status.equals('inProgress'),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<List<WorkoutDraftRow>> listPendingUpload(String userId) async {
    final query = _db.select(_db.workoutDrafts)
      ..where(
        (t) =>
            t.userId.equals(userId) &
            t.status.isIn(['pendingUpload', 'failedValidation']),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return query.get();
  }

  Future<WorkoutDraftRow?> getById(String id) async {
    return (_db.select(
      _db.workoutDrafts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsert(WorkoutDraftsCompanion companion) async {
    await _db.into(_db.workoutDrafts).insertOnConflictUpdate(companion);
  }

  Future<void> updateById(String id, WorkoutDraftsCompanion companion) async {
    await (_db.update(_db.workoutDrafts)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<void> deleteById(String id) async {
    await (_db.delete(
      _db.workoutDrafts,
    )..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteOtherInProgress({
    required String userId,
    required String keepId,
  }) async {
    await (_db.delete(_db.workoutDrafts)..where(
          (t) =>
              t.userId.equals(userId) &
              t.status.equals('inProgress') &
              t.id.equals(keepId).not(),
        ))
        .go();
  }
}
