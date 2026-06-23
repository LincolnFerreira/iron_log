import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/api_endpoints.dart';
import '../database/app_database.dart';

/// Envia rascunhos `pendingUpload` e legado [WorkoutOutbox].
Future<void> flushWorkoutOutbox({
  required AppDatabase database,
  required Dio dio,
}) async {
  await _flushDraftPendingUploads(database: database, dio: dio);

  final rows = await database.select(database.workoutOutbox).get();
  if (rows.isEmpty) return;

  for (final row in rows) {
    try {
      final envelope = jsonDecode(row.payloadJson) as Map<String, dynamic>;
      final kind = envelope['kind'] as String? ?? 'post';

      if (kind == 'patch') {
        final workoutId = envelope['workoutId'] as String?;
        final payload = envelope['payload'];
        if (workoutId == null || payload is! Map<String, dynamic>) {
          if (kDebugMode) {
            print('WorkoutOutboxSync: payload PATCH inválido id=${row.id}');
          }
          continue;
        }
        await dio.patch(ApiEndpoints.workoutById(workoutId), data: payload);
      } else {
        final payload = envelope['payload'];
        if (payload is! Map<String, dynamic>) {
          if (kDebugMode) {
            print('WorkoutOutboxSync: payload POST inválido id=${row.id}');
          }
          continue;
        }
        await dio.post(ApiEndpoints.workouts, data: payload);
      }

      await (database.delete(
        database.workoutOutbox,
      )..where((t) => t.id.equals(row.id))).go();
    } on DioException catch (e) {
      if (kDebugMode) {
        print('WorkoutOutboxSync: falha ao enviar ${row.id}: $e');
      }
      break;
    } catch (e) {
      if (kDebugMode) {
        print('WorkoutOutboxSync: erro inesperado ${row.id}: $e');
      }
      break;
    }
  }
}

Future<void> _flushDraftPendingUploads({
  required AppDatabase database,
  required Dio dio,
}) async {
  final rows = await (database.select(database.workoutDrafts)
        ..where((t) => t.status.equals('pendingUpload')))
      .get();

  for (final row in rows) {
    final payloadRaw = row.apiPayloadJson;
    if (payloadRaw == null || payloadRaw.isEmpty) continue;

    try {
      final payload = jsonDecode(payloadRaw) as Map<String, dynamic>;
      if (row.pendingOperation == 'patch') {
        final workoutId = row.serverWorkoutId;
        if (workoutId == null || workoutId.isEmpty) continue;
        await dio.patch(ApiEndpoints.workoutById(workoutId), data: payload);
      } else {
        await dio.post(ApiEndpoints.workouts, data: payload);
      }

      await (database.delete(
        database.workoutDrafts,
      )..where((t) => t.id.equals(row.id))).go();
    } on DioException catch (e) {
      if (kDebugMode) {
        print('WorkoutDraftSync: falha ${row.id}: $e');
      }
      await (database.update(database.workoutDrafts)
            ..where((t) => t.id.equals(row.id)))
          .write(
            WorkoutDraftsCompanion(
              lastErrorType: Value(e.type.name),
              lastErrorStatusCode: Value(e.response?.statusCode),
              lastAttemptAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );
      break;
    }
  }
}
