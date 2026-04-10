import 'package:iron_log/features/workout_day/domain/entities/exercise_tag.dart';

import 'session_exercise_dto.dart';

/// Maps ExerciseDataDto to ExerciseTag enum
abstract class ExerciseTagMapper {
  /// Converts exercise data (tags or category) to ExerciseTag
  static ExerciseTag map(ExerciseDataDto? exercise) {
    if (exercise == null) return ExerciseTag.multi;

    // Priority: tags first, then category
    if (exercise.tags.isNotEmpty) {
      final firstTag = exercise.tags.first.toString().toLowerCase();
      final result = _tagToEnum(firstTag);
      if (result != null) return result;
    }

    final category = exercise.category?.toLowerCase() ?? '';
    return _categoryToEnum(category);
  }

  static ExerciseTag? _tagToEnum(String tag) {
    switch (tag) {
      case 'multi':
      case 'composto':
        return ExerciseTag.multi;
      case 'iso':
      case 'isolamento':
        return ExerciseTag.iso;
      case 'cardio':
      case 'cardiovascular':
        return ExerciseTag.cardio;
      case 'funcional':
      case 'functional':
        return ExerciseTag.functional;
      default:
        return null;
    }
  }

  static ExerciseTag _categoryToEnum(String category) {
    switch (category) {
      case 'multi':
      case 'composto':
        return ExerciseTag.multi;
      case 'iso':
      case 'isolamento':
        return ExerciseTag.iso;
      case 'cardio':
      case 'cardiovascular':
        return ExerciseTag.cardio;
      case 'funcional':
      case 'functional':
        return ExerciseTag.functional;
      default:
        return ExerciseTag.multi;
    }
  }
}
