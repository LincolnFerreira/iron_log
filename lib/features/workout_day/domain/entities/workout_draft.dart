enum WorkoutDraftStatus {
  inProgress,
  pendingUpload,
  failedValidation;

  String get storageValue => name;

  static WorkoutDraftStatus fromStorage(String value) {
    return WorkoutDraftStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WorkoutDraftStatus.inProgress,
    );
  }
}

enum PendingOperation {
  create,
  patch;

  String get storageValue => name;

  static PendingOperation fromStorage(String value) {
    return PendingOperation.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PendingOperation.create,
    );
  }
}

class DraftUploadError {
  const DraftUploadError({this.type, this.statusCode, this.message});

  final String? type;
  final int? statusCode;
  final String? message;
}

class WorkoutDraftSummary {
  const WorkoutDraftSummary({
    required this.id,
    required this.sessionName,
    required this.exerciseCount,
    required this.startedAt,
    this.routineId,
    this.sessionId,
  });

  final String id;
  final String sessionName;
  final int exerciseCount;
  final DateTime startedAt;
  final String? routineId;
  final String? sessionId;
}

class WorkoutDraft {
  const WorkoutDraft({
    required this.id,
    required this.userId,
    required this.status,
    required this.pendingOperation,
    required this.snapshotJson,
    required this.startedAt,
    this.routineId,
    this.sessionId,
    this.serverWorkoutId,
    this.apiPayloadJson,
    this.endedAt,
    this.manualDate,
    this.timerStartedAt,
    this.accumulatedDurationSeconds,
    this.lastErrorType,
    this.lastErrorStatusCode,
    this.lastAttemptAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final WorkoutDraftStatus status;
  final PendingOperation pendingOperation;
  final String? routineId;
  final String? sessionId;
  final String? serverWorkoutId;
  final String snapshotJson;
  final String? apiPayloadJson;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime? manualDate;
  final DateTime? timerStartedAt;
  final int? accumulatedDurationSeconds;
  final String? lastErrorType;
  final int? lastErrorStatusCode;
  final DateTime? lastAttemptAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkoutDraft copyWith({
    String? id,
    String? userId,
    WorkoutDraftStatus? status,
    PendingOperation? pendingOperation,
    String? routineId,
    String? sessionId,
    String? serverWorkoutId,
    String? snapshotJson,
    String? apiPayloadJson,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? manualDate,
    DateTime? timerStartedAt,
    int? accumulatedDurationSeconds,
    String? lastErrorType,
    int? lastErrorStatusCode,
    DateTime? lastAttemptAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutDraft(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      pendingOperation: pendingOperation ?? this.pendingOperation,
      routineId: routineId ?? this.routineId,
      sessionId: sessionId ?? this.sessionId,
      serverWorkoutId: serverWorkoutId ?? this.serverWorkoutId,
      snapshotJson: snapshotJson ?? this.snapshotJson,
      apiPayloadJson: apiPayloadJson ?? this.apiPayloadJson,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      manualDate: manualDate ?? this.manualDate,
      timerStartedAt: timerStartedAt ?? this.timerStartedAt,
      accumulatedDurationSeconds:
          accumulatedDurationSeconds ?? this.accumulatedDurationSeconds,
      lastErrorType: lastErrorType ?? this.lastErrorType,
      lastErrorStatusCode: lastErrorStatusCode ?? this.lastErrorStatusCode,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DraftFlushResult {
  const DraftFlushResult({required this.synced, required this.failed});

  final int synced;
  final int failed;
}
