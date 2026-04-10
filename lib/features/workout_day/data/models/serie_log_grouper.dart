import 'serie_log_dto.dart';

/// Groups a list of SerieLogDto by exerciseId
class SerieLogGrouper {
  /// Group SerieLogDtos by exerciseId, maintaining order
  /// Returns a map where key = exerciseId and value = list of series
  static Map<String, List<SerieLogDto>> groupByExerciseId(
    List<SerieLogDto> series,
  ) {
    final grouped = <String, List<SerieLogDto>>{};
    final exerciseMeta = <String, ExerciseMetadata>{};

    for (final serie in series) {
      final exerciseId = serie.exerciseId ?? '';
      if (exerciseId.isEmpty) continue;

      grouped.putIfAbsent(exerciseId, () => []).add(serie);

      // Capture exercise metadata once per group
      exerciseMeta.putIfAbsent(exerciseId, () {
        final exerciseData = serie.exercise;
        return ExerciseMetadata(
          id: exerciseId,
          name: exerciseData?.name ?? '',
          category: exerciseData?.category ?? '',
          primaryMuscle: exerciseData?.primaryMuscle ?? '',
          tags: exerciseData?.tags ?? [],
        );
      });
    }

    return grouped;
  }

  /// Parse raw JSON to SerieLogDtos, then group
  static Map<String, List<SerieLogDto>> groupFromJson(List<dynamic> jsonList) {
    final series = jsonList
        .map((item) => SerieLogDto.fromJson(item as Map<String, dynamic>))
        .toList();
    return groupByExerciseId(series);
  }
}

/// Holds exercise metadata extracted from series
class ExerciseMetadata {
  final String id;
  final String name;
  final String category;
  final String primaryMuscle;
  final List<dynamic> tags;

  ExerciseMetadata({
    required this.id,
    required this.name,
    required this.category,
    required this.primaryMuscle,
    required this.tags,
  });
}
