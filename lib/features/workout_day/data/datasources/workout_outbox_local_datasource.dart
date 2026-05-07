import 'dart:convert';

import '../../../../core/database/app_database.dart';

/// Persistência da fila POST/PATCH `/workout` para envio quando houver rede.
class WorkoutOutboxLocalDataSource {
  WorkoutOutboxLocalDataSource(this._db);

  final AppDatabase _db;

  Future<void> enqueuePost({
    required String rowId,
    required String userId,
    required Map<String, dynamic> workoutPayload,
  }) async {
    final envelope = <String, dynamic>{
      'kind': 'post',
      'payload': workoutPayload,
    };
    await _db
        .into(_db.workoutOutbox)
        .insert(
          WorkoutOutboxCompanion.insert(
            id: rowId,
            userId: userId,
            payloadJson: jsonEncode(envelope),
          ),
        );
  }

  Future<void> enqueuePatch({
    required String rowId,
    required String userId,
    required String workoutId,
    required Map<String, dynamic> patchPayload,
  }) async {
    final envelope = <String, dynamic>{
      'kind': 'patch',
      'workoutId': workoutId,
      'payload': patchPayload,
    };
    await _db
        .into(_db.workoutOutbox)
        .insert(
          WorkoutOutboxCompanion.insert(
            id: rowId,
            userId: userId,
            payloadJson: jsonEncode(envelope),
          ),
        );
  }
}
