import 'package:iron_log/features/workout_day/data/parsers/voice_to_workout_parser.dart';

class ResolvedParsedExercise {
  final ParsedExercise parsed;
  String?
  matchedExerciseId; // exerciseId from session (nullable until user assigns)
  String? matchedExerciseName;
  List<Map<String, String>> candidates;

  ResolvedParsedExercise({
    required this.parsed,
    this.matchedExerciseId,
    this.matchedExerciseName,
    this.candidates = const [],
  });

  bool get isResolved => matchedExerciseId != null;
}
