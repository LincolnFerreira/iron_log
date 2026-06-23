import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/workout_draft.dart';
import '../../domain/repositories/workout_draft_repository.dart';
import '../datasources/workout_draft_local_datasource.dart';

class WorkoutDraftRepositoryImpl implements WorkoutDraftRepository {
  WorkoutDraftRepositoryImpl(this._local);

  final WorkoutDraftLocalDataSource _local;

  @override
  Future<WorkoutDraft?> getActiveInProgress(String userId) async {
    final row = await _local.getInProgressByUser(userId);
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<List<WorkoutDraft>> listPendingUpload(String userId) async {
    final rows = await _local.listPendingUpload(userId);
    return rows.map(_mapRow).toList();
  }

  @override
  Future<WorkoutDraft?> getById(String draftId) async {
    final row = await _local.getById(draftId);
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<void> saveInProgress(WorkoutDraft draft) async {
    await _local.deleteOtherInProgress(userId: draft.userId, keepId: draft.id);
    await _local.upsert(_toCompanion(draft, status: WorkoutDraftStatus.inProgress));
  }

  @override
  Future<void> markPendingUpload({
    required String draftId,
    required Map<String, dynamic> apiPayload,
    String? serverWorkoutId,
    required PendingOperation operation,
    DateTime? endedAt,
    DraftUploadError? error,
  }) async {
    final existing = await _local.getById(draftId);
    if (existing == null) return;

    await _local.updateById(
      draftId,
      WorkoutDraftsCompanion(
        status: const Value('pendingUpload'),
        pendingOperation: Value(operation.storageValue),
        serverWorkoutId: serverWorkoutId == null
            ? const Value.absent()
            : Value(serverWorkoutId),
        apiPayloadJson: Value(jsonEncode(apiPayload)),
        endedAt: endedAt == null ? const Value.absent() : Value(endedAt),
        lastErrorType: error?.type == null
            ? const Value.absent()
            : Value(error!.type),
        lastErrorStatusCode: error?.statusCode == null
            ? const Value.absent()
            : Value(error!.statusCode!),
        lastAttemptAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteAfterSuccessfulUpload(String draftId) async {
    await _local.deleteById(draftId);
  }

  @override
  Future<void> recordUploadFailure(String draftId, DraftUploadError error) async {
    final existing = await _local.getById(draftId);
    if (existing == null) return;

    await _local.updateById(
      draftId,
      WorkoutDraftsCompanion(
        lastErrorType: error.type == null
            ? const Value.absent()
            : Value(error.type),
        lastErrorStatusCode: error.statusCode == null
            ? const Value.absent()
            : Value(error.statusCode!),
        lastAttemptAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  WorkoutDraft _mapRow(WorkoutDraftRow row) {
    return WorkoutDraft(
      id: row.id,
      userId: row.userId,
      status: WorkoutDraftStatus.fromStorage(row.status),
      pendingOperation: PendingOperation.fromStorage(row.pendingOperation),
      routineId: row.routineId,
      sessionId: row.sessionId,
      serverWorkoutId: row.serverWorkoutId,
      snapshotJson: row.snapshotJson,
      apiPayloadJson: row.apiPayloadJson,
      startedAt: row.startedAt,
      endedAt: row.endedAt,
      manualDate: row.manualDate,
      timerStartedAt: row.timerStartedAt,
      accumulatedDurationSeconds: row.accumulatedDurationSeconds,
      lastErrorType: row.lastErrorType,
      lastErrorStatusCode: row.lastErrorStatusCode,
      lastAttemptAt: row.lastAttemptAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  WorkoutDraftsCompanion _toCompanion(
    WorkoutDraft draft, {
    WorkoutDraftStatus? status,
  }) {
    return WorkoutDraftsCompanion.insert(
      id: draft.id,
      userId: draft.userId,
      status: (status ?? draft.status).storageValue,
      pendingOperation: draft.pendingOperation.storageValue,
      routineId: draft.routineId == null
          ? const Value.absent()
          : Value(draft.routineId!),
      sessionId: draft.sessionId == null
          ? const Value.absent()
          : Value(draft.sessionId!),
      serverWorkoutId: draft.serverWorkoutId == null
          ? const Value.absent()
          : Value(draft.serverWorkoutId!),
      snapshotJson: draft.snapshotJson,
      apiPayloadJson: draft.apiPayloadJson == null
          ? const Value.absent()
          : Value(draft.apiPayloadJson!),
      startedAt: draft.startedAt,
      endedAt: draft.endedAt == null
          ? const Value.absent()
          : Value(draft.endedAt!),
      manualDate: draft.manualDate == null
          ? const Value.absent()
          : Value(draft.manualDate!),
      timerStartedAt: draft.timerStartedAt == null
          ? const Value.absent()
          : Value(draft.timerStartedAt!),
      accumulatedDurationSeconds: draft.accumulatedDurationSeconds == null
          ? const Value.absent()
          : Value(draft.accumulatedDurationSeconds!),
      lastErrorType: draft.lastErrorType == null
          ? const Value.absent()
          : Value(draft.lastErrorType!),
      lastErrorStatusCode: draft.lastErrorStatusCode == null
          ? const Value.absent()
          : Value(draft.lastErrorStatusCode!),
      lastAttemptAt: draft.lastAttemptAt == null
          ? const Value.absent()
          : Value(draft.lastAttemptAt!),
      updatedAt: Value(DateTime.now()),
    );
  }
}
