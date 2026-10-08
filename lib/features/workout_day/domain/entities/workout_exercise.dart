import 'package:iron_log/features/workout_day/domain/entities/exercise_tag.dart';
import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import 'package:iron_log/features/workout_day/domain/entities/technique_block.dart';
import 'package:iron_log/features/workout_day/domain/entities/weight_unit.dart';

// Sentinel used in copyWith to distinguish "not provided" from explicit null.
const _notSet = Object();

class WorkoutExercise {
  final String id;
  final String name;
  final ExerciseTag tag;
  final String muscles;
  final String variation;
  final int series;
  final String reps;
  final String weight;
  final int rir;
  final int restTime;
  final WeightUnit weightUnit;
  final int? order;

  /// Per-series data as typed by the user. When non-empty, this is the
  /// source of truth for the API payload. [reps] and [weight] are used
  /// only as defaults when initialising new rows.
  final List<SeriesEntry> entries;

  /// Technique blocks grouping sets by training technique.
  final List<TechniqueBlock> blocks;

  /// Optional observation the user may add for this exercise.
  final String? notes;

  /// Tipo de equipamento do catálogo (máquina, cabo, barra...).
  final String? equipmentName;

  /// Máquina física escolhida nesta execução. Nulo = sem estação.
  final String? stationId;
  final String? stationNickname;

  /// Id do movimento no catálogo. Na edição, [id] continua sendo o
  /// exercício da sessão; a estação e o histórico usam este id.
  final String? catalogExerciseId;

  String get movementId =>
      (catalogExerciseId != null && catalogExerciseId!.isNotEmpty)
          ? catalogExerciseId!
          : id;

  const WorkoutExercise({
    required this.id,
    required this.name,
    required this.tag,
    required this.muscles,
    required this.variation,
    required this.series,
    required this.reps,
    required this.weight,
    required this.rir,
    required this.restTime,
    this.weightUnit = WeightUnit.kg,
    this.order,
    this.entries = const [],
    this.blocks = const [],
    this.notes,
    this.equipmentName,
    this.stationId,
    this.stationNickname,
    this.catalogExerciseId,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      tag: ExerciseTag.fromString(json['tag']?.toString() ?? 'multi'),
      muscles: json['muscles']?.toString() ?? '',
      variation: json['variation']?.toString() ?? 'Traditional',
      series: json['series'] ?? 3,
      reps: json['reps']?.toString() ?? '-',
      weight: json['weight']?.toString() ?? '0',
      rir: json['rir'] ?? 2,
      restTime: json['restTime'] ?? 120,
      weightUnit: WeightUnit.fromString(json['weightUnit']?.toString() ?? 'kg'),
      order: (json['order'] as num?)?.toInt(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tag': tag.label,
      'muscles': muscles,
      'variation': variation,
      'series': series,
      'reps': reps,
      'weight': weight,
      'rir': rir,
      'restTime': restTime,
      'weightUnit': weightUnit.label,
      if (order != null) 'order': order,
      if (notes != null) 'notes': notes,
    };
  }

  /// Converts to the config format expected by the backend SessionExercise.config field.
  ///
  /// Output: `{ series: [{ label, reps, weight, rir, rest }], variation, notes }`
  Map<String, dynamic> toConfigJson() {
    final seriesList = entries.isNotEmpty
        ? entries
              .map(
                (e) => {
                  'label': e.backendLabel,
                  'reps': int.tryParse(e.reps) ?? 0,
                  'weight': double.tryParse(e.weight) ?? 0.0,
                  'rir': rir,
                  'rest': restTime,
                },
              )
              .toList()
        : List.generate(
            series,
            (_) => {
              'label': 'Top Set',
              'reps': int.tryParse(reps) ?? 0,
              'weight': double.tryParse(weight) ?? 0.0,
              'rir': rir,
              'rest': restTime,
            },
          );

    return {
      'series': seriesList,
      'variation': variation,
      if (notes != null) 'notes': notes,
    };
  }

  WorkoutExercise copyWith({
    String? id,
    String? name,
    ExerciseTag? tag,
    String? muscles,
    String? variation,
    int? series,
    String? reps,
    String? weight,
    int? rir,
    int? restTime,
    WeightUnit? weightUnit,
    int? order,
    List<SeriesEntry>? entries,
    List<TechniqueBlock>? blocks,
    Object? notes = _notSet,
    Object? equipmentName = _notSet,
    Object? stationId = _notSet,
    Object? stationNickname = _notSet,
    String? catalogExerciseId,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      tag: tag ?? this.tag,
      muscles: muscles ?? this.muscles,
      variation: variation ?? this.variation,
      series: series ?? this.series,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      rir: rir ?? this.rir,
      restTime: restTime ?? this.restTime,
      weightUnit: weightUnit ?? this.weightUnit,
      order: order ?? this.order,
      entries: entries ?? this.entries,
      blocks: blocks ?? this.blocks,
      notes: notes == _notSet ? this.notes : notes as String?,
      equipmentName: equipmentName == _notSet
          ? this.equipmentName
          : equipmentName as String?,
      stationId: stationId == _notSet ? this.stationId : stationId as String?,
      stationNickname: stationNickname == _notSet
          ? this.stationNickname
          : stationNickname as String?,
      catalogExerciseId: catalogExerciseId ?? this.catalogExerciseId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutExercise && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'WorkoutExercise(id: $id, name: $name, series: $series, reps: $reps)';
  }
}
