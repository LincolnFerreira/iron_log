/// API field name constants to eliminate magic strings
/// Centralizes all field name references from backend API responses
abstract class ApiFieldNames {
  // Session Exercise fields
  static const String exerciseId = 'exerciseId';
  static const String sessionId = 'sessionId';
  static const String exercise = 'exercise';
  static const String config = 'config';
  static const String order = 'order';
  static const String isActive = 'isActive';

  // Exercise fields
  static const String id = 'id';
  static const String name = 'name';
  static const String category = 'category';
  static const String primaryMuscle = 'primaryMuscle';
  static const String tags = 'tags';

  // Config fields (JSON in config)
  static const String series = 'series';
  static const String variation = 'variation';
  static const String reps = 'reps';
  static const String weight = 'weight';
  static const String rir = 'rir';
  static const String rest = 'rest';
  static const String restTime = 'restTime';
  static const String restSeconds = 'restSeconds';
  static const String notes = 'notes';

  // Series config fields (individual item from config.series[])
  static const String label = 'label';
  static const String tag = 'tag';

  // SerieLog fields (executed workout data)
  static const String setIndex = 'setIndex';
  static const String weightUnit = 'weightUnit';
  static const String rirNote = 'rirNote';
  static const String cadence = 'cadence';
  static const String isFailure = 'isFailure';
}
