import 'effort_type.dart';

class ParsedImportSet {
  final String clientKey;
  final double? weight;
  final int? reps;
  final String weightUnit;
  final EffortType effortType;
  final ConfidenceLevel effortConfidence;
  final bool isFailure;
  final String? label;

  const ParsedImportSet({
    required this.clientKey,
    this.weight,
    this.reps,
    this.weightUnit = 'kg',
    required this.effortType,
    this.effortConfidence = ConfidenceLevel.undetermined,
    this.isFailure = false,
    this.label,
  });

  ParsedImportSet copyWith({
    double? weight,
    int? reps,
    EffortType? effortType,
    bool? isFailure,
  }) {
    return ParsedImportSet(
      clientKey: clientKey,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      weightUnit: weightUnit,
      effortType: effortType ?? this.effortType,
      effortConfidence: effortConfidence,
      isFailure: isFailure ?? this.isFailure,
      label: label,
    );
  }

  Map<String, dynamic> toJson() => {
        'clientKey': clientKey,
        'weight': weight,
        'reps': reps,
        'weightUnit': weightUnit,
        'effortType': effortType.apiValue,
        'effortConfidence': effortConfidence.name,
        'isFailure': isFailure,
        'label': label,
      };

  factory ParsedImportSet.fromJson(Map<String, dynamic> json) {
    return ParsedImportSet(
      clientKey: json['clientKey'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble(),
      reps: json['reps'] as int?,
      weightUnit: json['weightUnit'] as String? ?? 'kg',
      effortType: EffortTypeX.fromApi(json['effortType'] as String?),
      effortConfidence:
          ConfidenceLevelX.fromApi(json['effortConfidence'] as String?),
      isFailure: json['isFailure'] as bool? ?? false,
      label: json['label'] as String?,
    );
  }
}

class ParsedImportExercise {
  final String clientKey;
  final String name;
  final ConfidenceLevel nameConfidence;
  final String? suggestedExerciseId;
  final String? exerciseId;
  final String? notes;
  final List<ParsedImportSet> sets;
  final List<String> uncertainties;
  final bool removed;

  const ParsedImportExercise({
    required this.clientKey,
    required this.name,
    this.nameConfidence = ConfidenceLevel.undetermined,
    this.suggestedExerciseId,
    this.exerciseId,
    this.notes,
    required this.sets,
    this.uncertainties = const [],
    this.removed = false,
  });

  ParsedImportExercise copyWith({
    String? name,
    String? exerciseId,
    List<ParsedImportSet>? sets,
    bool? removed,
  }) {
    return ParsedImportExercise(
      clientKey: clientKey,
      name: name ?? this.name,
      nameConfidence: nameConfidence,
      suggestedExerciseId: suggestedExerciseId,
      exerciseId: exerciseId ?? this.exerciseId,
      notes: notes,
      sets: sets ?? this.sets,
      uncertainties: uncertainties,
      removed: removed ?? this.removed,
    );
  }

  Map<String, dynamic> toJson() => {
        'clientKey': clientKey,
        'name': name,
        'nameConfidence': nameConfidence.name,
        'suggestedExerciseId': suggestedExerciseId,
        'exerciseId': exerciseId,
        'notes': notes,
        'sets': sets.map((s) => s.toJson()).toList(),
        'uncertainties': uncertainties,
        'removed': removed,
      };

  factory ParsedImportExercise.fromJson(Map<String, dynamic> json) {
    return ParsedImportExercise(
      clientKey: json['clientKey'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameConfidence:
          ConfidenceLevelX.fromApi(json['nameConfidence'] as String?),
      suggestedExerciseId: json['suggestedExerciseId'] as String?,
      exerciseId: json['exerciseId'] as String?,
      notes: json['notes'] as String?,
      sets: (json['sets'] as List<dynamic>? ?? [])
          .map((e) => ParsedImportSet.fromJson(e as Map<String, dynamic>))
          .toList(),
      uncertainties: (json['uncertainties'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      removed: json['removed'] as bool? ?? false,
    );
  }
}

class ParsedImportSession {
  final String clientKey;
  final String? title;
  final ConfidenceLevel titleConfidence;
  final String? scheduledDate;
  final ConfidenceLevel dateConfidence;
  final String? sessionNotes;
  final List<ParsedImportExercise> exercises;
  final bool removed;

  const ParsedImportSession({
    required this.clientKey,
    this.title,
    this.titleConfidence = ConfidenceLevel.undetermined,
    this.scheduledDate,
    this.dateConfidence = ConfidenceLevel.undetermined,
    this.sessionNotes,
    required this.exercises,
    this.removed = false,
  });

  ParsedImportSession copyWith({
    String? scheduledDate,
    ConfidenceLevel? dateConfidence,
    List<ParsedImportExercise>? exercises,
    bool? removed,
  }) {
    return ParsedImportSession(
      clientKey: clientKey,
      title: title,
      titleConfidence: titleConfidence,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      dateConfidence: dateConfidence ?? this.dateConfidence,
      sessionNotes: sessionNotes,
      exercises: exercises ?? this.exercises,
      removed: removed ?? this.removed,
    );
  }

  Map<String, dynamic> toJson() => {
        'clientKey': clientKey,
        'title': title,
        'titleConfidence': titleConfidence.name,
        'scheduledDate': scheduledDate,
        'dateConfidence': dateConfidence.name,
        'sessionNotes': sessionNotes,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'removed': removed,
      };

  factory ParsedImportSession.fromJson(Map<String, dynamic> json) {
    return ParsedImportSession(
      clientKey: json['clientKey'] as String? ?? '',
      title: json['title'] as String?,
      titleConfidence:
          ConfidenceLevelX.fromApi(json['titleConfidence'] as String?),
      scheduledDate: json['scheduledDate'] as String?,
      dateConfidence:
          ConfidenceLevelX.fromApi(json['dateConfidence'] as String?),
      sessionNotes: json['sessionNotes'] as String?,
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => ParsedImportExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      removed: json['removed'] as bool? ?? false,
    );
  }
}

class ParsedWorkoutImport {
  final List<ParsedImportSession> sessions;
  final List<String> unmappedFragments;
  final List<String> parserWarnings;

  const ParsedWorkoutImport({
    required this.sessions,
    this.unmappedFragments = const [],
    this.parserWarnings = const [],
  });

  ParsedWorkoutImport copyWith({List<ParsedImportSession>? sessions}) {
    return ParsedWorkoutImport(
      sessions: sessions ?? this.sessions,
      unmappedFragments: unmappedFragments,
      parserWarnings: parserWarnings,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'unmappedFragments': unmappedFragments,
        'parserWarnings': parserWarnings,
      };

  factory ParsedWorkoutImport.fromJson(Map<String, dynamic> json) {
    return ParsedWorkoutImport(
      sessions: (json['sessions'] as List<dynamic>? ?? [])
          .map((e) => ParsedImportSession.fromJson(e as Map<String, dynamic>))
          .toList(),
      unmappedFragments: (json['unmappedFragments'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      parserWarnings: (json['parserWarnings'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class WorkoutImportConfirmResult {
  final String importId;
  final List<String> workoutIds;

  const WorkoutImportConfirmResult({
    required this.importId,
    required this.workoutIds,
  });
}

class WorkoutImportDraft {
  final String id;
  final String userId;
  final String? importId;
  final ImportDraftStatus status;
  final String rawText;
  final ParsedWorkoutImport snapshot;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkoutImportDraft({
    required this.id,
    required this.userId,
    this.importId,
    required this.status,
    required this.rawText,
    required this.snapshot,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });

  WorkoutImportDraft copyWith({
    String? importId,
    ImportDraftStatus? status,
    ParsedWorkoutImport? snapshot,
    String? lastError,
    DateTime? updatedAt,
  }) {
    return WorkoutImportDraft(
      id: id,
      userId: userId,
      importId: importId ?? this.importId,
      status: status ?? this.status,
      rawText: rawText,
      snapshot: snapshot ?? this.snapshot,
      lastError: lastError,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
