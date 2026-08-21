enum ExerciseTag {
  multi('Multi'),
  iso('Iso'),
  cardio('Cardio'),
  functional('Funcional'),
  stretch('Alongamento');

  const ExerciseTag(this.label);

  final String label;

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
