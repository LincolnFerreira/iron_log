import 'package:flutter/material.dart';
import 'package:iron_log/features/workout_day/domain/entities/exercise_tag.dart';

/// Presentation mapping for [ExerciseTag] colors (domain stays Flutter-free).
Color exerciseTagColor(ExerciseTag tag) {
  switch (tag) {
    case ExerciseTag.multi:
      return Colors.blue;
    case ExerciseTag.iso:
      return Colors.green;
    case ExerciseTag.cardio:
      return Colors.orange;
    case ExerciseTag.functional:
      return Colors.purple;
    case ExerciseTag.stretch:
      return Colors.teal;
  }
}
