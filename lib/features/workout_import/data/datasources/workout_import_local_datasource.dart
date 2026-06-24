import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:iron_log/core/database/app_database.dart';
import '../../domain/entities/effort_type.dart';
import '../../domain/entities/parsed_workout_import.dart';

class WorkoutImportLocalDataSource {
  WorkoutImportLocalDataSource(this._db);

  final AppDatabase _db;

  Future<void> upsertDraft(WorkoutImportDraft draft) async {
    await _db.into(_db.workoutImportDrafts).insertOnConflictUpdate(
          WorkoutImportDraftsCompanion(
            id: Value(draft.id),
            userId: Value(draft.userId),
            importId: Value(draft.importId),
            status: Value(draft.status.name),
            rawText: Value(draft.rawText),
            reviewSnapshotJson: Value(jsonEncode(draft.snapshot.toJson())),
            lastError: Value(draft.lastError),
            createdAt: Value(draft.createdAt),
            updatedAt: Value(draft.updatedAt),
          ),
        );
  }

  Future<WorkoutImportDraft?> findById(String id) async {
    final row = await (_db.select(_db.workoutImportDrafts)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _rowToDraft(row);
  }

  Future<List<WorkoutImportDraft>> findByStatus(
    String userId,
    Set<ImportDraftStatus> statuses,
  ) async {
    final names = statuses.map((s) => s.name).toList();
    final rows = await (_db.select(_db.workoutImportDrafts)
          ..where(
            (t) => t.userId.equals(userId) & t.status.isIn(names),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows.map(_rowToDraft).toList();
  }

  Future<void> deleteDraft(String id) async {
    await (_db.delete(_db.workoutImportDrafts)..where((t) => t.id.equals(id)))
        .go();
  }

  WorkoutImportDraft _rowToDraft(WorkoutImportDraftRow row) {
    final snapshotJson =
        jsonDecode(row.reviewSnapshotJson) as Map<String, dynamic>;
    return WorkoutImportDraft(
      id: row.id,
      userId: row.userId,
      importId: row.importId,
      status: ImportDraftStatus.values.firstWhere(
        (s) => s.name == row.status,
        orElse: () => ImportDraftStatus.draft,
      ),
      rawText: row.rawText,
      snapshot: ParsedWorkoutImport.fromJson(snapshotJson),
      lastError: row.lastError,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
