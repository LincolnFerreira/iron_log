import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/services/http_service.dart';
import '../../domain/entities/parsed_workout_import.dart';

class WorkoutImportRemoteDataSource {
  WorkoutImportRemoteDataSource(this._http);

  final HttpService _http;

  Future<({String importId, ParsedWorkoutImport parsed})> parse({
    required String rawText,
  }) async {
    final response = await _http.post(
      ApiEndpoints.workoutImportParse,
      data: {'rawText': rawText},
    );
    final data = response.data as Map<String, dynamic>;
    return (
      importId: data['importId'] as String,
      parsed: ParsedWorkoutImport.fromJson(
        data['parsed'] as Map<String, dynamic>,
      ),
    );
  }

  Future<WorkoutImportConfirmResult> confirm({
    required String importId,
    required ParsedWorkoutImport snapshot,
  }) async {
    final body = {
      'importId': importId,
      'sessions': snapshot.sessions
          .where((s) => !s.removed)
          .map(_sessionToApi)
          .toList(),
    };
    final response = await _http.post(
      ApiEndpoints.workoutImportConfirm,
      data: body,
    );
    final data = response.data as Map<String, dynamic>;
    return WorkoutImportConfirmResult(
      importId: data['importId'] as String,
      workoutIds: (data['workoutIds'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> _sessionToApi(ParsedImportSession session) {
    return {
      'clientKey': session.clientKey,
      'title': session.title,
      'scheduledDate': session.scheduledDate,
      'removed': session.removed,
      'sessionNotes': session.sessionNotes,
      'exercises': session.exercises
          .where((e) => !e.removed)
          .map((e) => {
                'clientKey': e.clientKey,
                'name': e.name,
                'exerciseId': e.exerciseId,
                'removed': e.removed,
                'notes': e.notes,
                'sets': e.sets
                    .map(
                      (s) => {
                        'weight': s.weight,
                        'reps': s.reps,
                        'weightUnit': s.weightUnit,
                        'effortType': s.effortType.name,
                        'isFailure': s.isFailure,
                      },
                    )
                    .toList(),
              })
          .toList(),
    };
  }
}
