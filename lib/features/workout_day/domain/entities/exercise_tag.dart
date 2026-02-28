import 'package:flutter/material.dart';

enum ExerciseTag {
  multi('Multi', Colors.blue),
  iso('Iso', Colors.green),
  cardio('Cardio', Colors.orange),
  functional('Funcional', Colors.purple),
  stretch('Alongamento', Colors.teal);

  const ExerciseTag(this.label, this.color);

  final String label;
  final Color color;

  static ExerciseTag fromString(String tag) {
    switch (tag.toLowerCase()) {
      case 'multi':
        return ExerciseTag.multi;
      case 'iso':
        return ExerciseTag.iso;
      case 'cardio':
        return ExerciseTag.cardio;
      case 'functional':
      case 'funcional':
        return ExerciseTag.functional;
      case 'stretch':
      case 'alongamento':
        return ExerciseTag.stretch;
      default:
        return ExerciseTag.multi;
    }
  }
}
