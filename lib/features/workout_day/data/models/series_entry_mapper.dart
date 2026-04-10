import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';

import 'label_type_mapper.dart';
import 'series_config_dto.dart';
import 'serie_log_dto.dart';

/// Maps DTOs to [SeriesEntry] domain entity
abstract class SeriesEntryMapper {
  /// Convert a SeriesConfigDto (from config.series[]) to SeriesEntry
  static SeriesEntry fromConfig(SeriesConfigDto seriesConfig, int index) {
    return SeriesEntry(
      index: index,
      type: LabelTypeMapper.labelToType(seriesConfig.label),
      weight: seriesConfig.weight?.toString() ?? '0',
      reps: seriesConfig.reps?.toString() ?? '0',
      done: false, // Not yet executed
    );
  }

  /// Convert a SerieLogDto (executed set) to SeriesEntry
  static SeriesEntry fromSerieLog(SerieLogDto serieLog, int index) {
    final weight = serieLog.weight ?? 0.0;
    final reps = serieLog.reps ?? 0;

    return SeriesEntry(
      index: index,
      type: LabelTypeMapper.labelToType(serieLog.label),
      weight: weight > 0 ? weight.toString() : '0',
      reps: reps > 0 ? reps.toString() : '0',
      done: true, // Already executed
    );
  }

  /// Convert multiple config series to entries
  static List<SeriesEntry> listFromConfig(List<SeriesConfigDto> series) {
    return series
        .asMap()
        .entries
        .map((e) => fromConfig(e.value, e.key))
        .toList();
  }

  /// Convert multiple SerieLog to entries
  static List<SeriesEntry> listFromSerieLog(List<SerieLogDto> series) {
    return series
        .asMap()
        .entries
        .map((e) => fromSerieLog(e.value, e.key))
        .toList();
  }
}
