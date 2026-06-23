import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/services/auth_service.dart';
import '../../domain/entities/workout_draft.dart';
import '../../domain/repositories/workout_draft_repository.dart';
import 'workout_log_service.dart';

class WorkoutDraftSyncService {
  WorkoutDraftSyncService({
    required WorkoutDraftRepository repository,
    required WorkoutLogService logService,
    required AuthService auth,
  }) : _repository = repository,
       _logService = logService,
       _auth = auth;

  final WorkoutDraftRepository _repository;
  final WorkoutLogService _logService;
  final AuthService _auth;

  Future<DraftFlushResult> flushPendingUploads() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return const DraftFlushResult(synced: 0, failed: 0);
    }

    final pending = await _repository.listPendingUpload(uid);
    var synced = 0;
    var failed = 0;

    for (final draft in pending) {
      final payloadRaw = draft.apiPayloadJson;
      if (payloadRaw == null || payloadRaw.isEmpty) {
        failed++;
        continue;
      }

      try {
        final payload = jsonDecode(payloadRaw) as Map<String, dynamic>;
        if (draft.pendingOperation == PendingOperation.patch) {
          final workoutId = draft.serverWorkoutId;
          if (workoutId == null || workoutId.isEmpty) {
            failed++;
            continue;
          }
          await _logService.patchRaw(workoutId, payload);
        } else {
          await _logService.postRaw(payload);
        }
        await _repository.deleteAfterSuccessfulUpload(draft.id);
        synced++;
      } on DioException catch (e) {
        await _repository.recordUploadFailure(
          draft.id,
          DraftUploadError(
            type: e.type.name,
            statusCode: e.response?.statusCode,
            message: e.message,
          ),
        );
        failed++;
      } catch (_) {
        failed++;
      }
    }

    return DraftFlushResult(synced: synced, failed: failed);
  }
}
