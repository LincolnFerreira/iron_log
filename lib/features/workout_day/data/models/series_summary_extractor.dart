import 'series_config_dto.dart';
import 'serie_log_dto.dart';

/// Extracts summary data (first series) from collections of series
abstract class SeriesSummaryExtractor {
  /// Extract summary values from first series in config
  static Map<String, dynamic> fromConfigList(List<SeriesConfigDto> series) {
    if (series.isEmpty) {
      return {'weight': 0.0, 'reps': 0, 'rir': 0, 'restTime': 0};
    }

    final first = series.first;
    return {
      'weight': first.weight ?? 0.0,
      'reps': first.reps ?? 0,
      'rir': first.rir ?? 0,
      'restTime': first.restTime ?? 0,
    };
  }

  /// Extract summary values from first SerieLog
  static Map<String, dynamic> fromSerieLogList(List<SerieLogDto> series) {
    if (series.isEmpty) {
      return {'weight': 0.0, 'reps': 0, 'rir': 0, 'restTime': 0};
    }

    final first = series.first;
    return {
      'weight': first.weight ?? 0.0,
      'reps': first.reps ?? 0,
      'rir': first.rir ?? 0,
      'restTime': first.restTime ?? 0,
    };
  }
}
