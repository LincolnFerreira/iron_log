import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/api_endpoints.dart';
import '../database/app_database.dart';

/// Envia itens pendentes da tabela [WorkoutOutbox] (POST/PATCH em `/workout`).
Future<void> flushWorkoutOutbox({
  required AppDatabase database,
  required Dio dio,
}) async {
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
            print('WorkoutOutboxSync: descartando linha inválida id=${row.id}');
          }
          await (database.delete(
            database.workoutOutbox,
          )..where((t) => t.id.equals(row.id))).go();
          continue;
        }
        await dio.patch(ApiEndpoints.workoutById(workoutId), data: payload);
      } else {
        final payload = envelope['payload'];
        if (payload is! Map<String, dynamic>) {
          if (kDebugMode) {
            print('WorkoutOutboxSync: payload POST inválido id=${row.id}');
          }
          await (database.delete(
            database.workoutOutbox,
          )..where((t) => t.id.equals(row.id))).go();
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
