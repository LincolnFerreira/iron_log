import 'serie_log.dart';

/// Resumo de um exercício com todas as suas séries
class ExerciseSummary {
  final String id;
  final String name;
  final String muscleGroup; // ex: "Peito & Tríceps"
  final List<SerieLog> series;

  const ExerciseSummary({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.series,
  });

  /// Total de séries completadas neste exercício
  int get completedSeries =>
      series.where((s) => s.status == 'completed').length;

  /// Total de séries (completadas + não registradas, etc)
  int get totalSeries => series.length;

  /// Percentual de conclusão (0-100)
  int get completionPercent {
    if (totalSeries == 0) return 0;
    return ((completedSeries / totalSeries) * 100).toInt();
  }

  /// Verifica se o exercício foi totalmente completado
  bool get isFullyCompleted => completionPercent == 100;

  factory ExerciseSummary.fromJson(Map<String, dynamic> json) {
    final seriesList =
        (json['series'] as List<dynamic>?)
            ?.map((s) => SerieLog.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    return ExerciseSummary(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      muscleGroup: json['muscleGroup'] ?? '',
      series: seriesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'muscleGroup': muscleGroup,
      'series': series.map((s) => s.toJson()).toList(),
    };
  }
}
