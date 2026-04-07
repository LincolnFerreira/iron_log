import '../../features/workout_day/domain/entities/series_entry.dart';
import '../../features/workout_day/domain/entities/workout_exercise.dart';
import '../../features/workout_day/domain/entities/exercise_tag.dart';

/// Responsável por mapear dados da API para entidades do domínio
/// Segue o Single Responsibility Principle - apenas mapeamento de dados
class WorkoutDataMapper {
  /// Mapeia dados da API para WorkoutExercise
  static WorkoutExercise fromApiData(Map<String, dynamic> exerciseData) {
    final exercise = exerciseData['exercise'] as Map<String, dynamic>? ?? {};
    final config = exerciseData['config'] as Map<String, dynamic>? ?? {};

    final entries = _mapEntries(config);

    return WorkoutExercise(
      id: exercise['id']?.toString() ?? '',
      name: exercise['name']?.toString() ?? '',
      tag: _mapExerciseTag(exercise),
      muscles: _mapMuscles(exercise),
      variation: _mapVariation(config),
      series: entries.isNotEmpty ? entries.length : _mapSeries(config),
      reps: _mapReps(config),
      weight: _mapWeight(config),
      rir: _mapRir(config),
      restTime: _mapRestTime(config),
      entries: entries,
    );
  }

  /// Mapeia lista de exercícios da API
  static List<WorkoutExercise> fromApiList(List<dynamic> exercisesData) {
    return exercisesData
        .map((data) => fromApiData(data as Map<String, dynamic>))
        .toList();
  }

  /// Mapeia uma lista plana de SerieLog (resposta do GET /workout/:id) para
  /// [WorkoutExercise]. Agrupa as séries pelo exerciseId, usando o primeiro
  /// item do grupo como referência para reps/weight/rir/rest.
  static List<WorkoutExercise> fromSerieLogList(List<dynamic> seriesRaw) {
    // Usa LinkedHashMap para preservar ordem de inserção (ordem original da API).
    final grouped = <String, List<Map<String, dynamic>>>{};
    final exerciseMeta = <String, Map<String, dynamic>>{};

    for (final raw in seriesRaw) {
      final serie = raw as Map<String, dynamic>;
      final exerciseId = serie['exerciseId']?.toString() ?? '';
      if (exerciseId.isEmpty) continue;

      grouped.putIfAbsent(exerciseId, () => []).add(serie);

      // Captura metadata do exercício apenas uma vez por grupo.
      exerciseMeta.putIfAbsent(exerciseId, () {
        final exercise = serie['exercise'] as Map<String, dynamic>? ?? {};
        return {
          'id': exerciseId,
          'name': exercise['name']?.toString() ?? '',
          'category': exercise['category']?.toString() ?? '',
          'primaryMuscle': exercise['primaryMuscle']?.toString() ?? '',
          'tags': exercise['tags'] as List<dynamic>? ?? <dynamic>[],
        };
      });
    }

    return grouped.entries.map((entry) {
      final exerciseId = entry.key;
      final series = entry.value;
      final meta = exerciseMeta[exerciseId] ?? <String, dynamic>{};

      // Build per-series entries from the real stored SerieLog rows.
      final entries = series.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        final weightKg = (s['weightKg'] as num?)?.toDouble() ?? 0.0;
        final reps = (s['reps'] as int?) ?? 0;
        final label = s['label']?.toString() ?? 'Top Set';
        return SeriesEntry(
          index: i,
          type: _labelToType(label),
          weight: weightKg > 0 ? weightKg.toString() : '0',
          reps: reps > 0 ? reps.toString() : '0',
          done: true, // already executed
        );
      }).toList();

      final firstSerie = series.first;
      final firstWeight = (firstSerie['weightKg'] as num?)?.toDouble() ?? 0.0;
      final firstReps = firstSerie['reps'] as int? ?? 0;
      final rir = firstSerie['rir'] as int? ?? 0;
      final restSeconds = firstSerie['restSeconds'] as int? ?? 0;

      return WorkoutExercise(
        id: exerciseId,
        name: meta['name']?.toString() ?? '',
        tag: _mapExerciseTag(meta),
        muscles: meta['primaryMuscle']?.toString() ?? 'Não especificado',
        variation: 'Traditional',
        series: series.length,
        reps: firstReps > 0 ? firstReps.toString() : '-',
        weight: firstWeight > 0 ? '${firstWeight}kg' : '0kg',
        rir: rir,
        restTime: restSeconds,
        entries: entries,
      );
    }).toList();
  }

  // Métodos privados para mapeamento específico de cada campo

  static ExerciseTag _mapExerciseTag(Map<String, dynamic> exercise) {
    final category = exercise['category']?.toString().toLowerCase() ?? '';
    final tags = exercise['tags'] as List<dynamic>? ?? [];

    // Prioriza tags se disponível
    if (tags.isNotEmpty) {
      final firstTag = tags.first.toString().toLowerCase();
      switch (firstTag) {
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
      }
    }

    // Fallback para category
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

  static String _mapMuscles(Map<String, dynamic> exercise) {
    // Tenta pegar primaryMuscle primeiro
    final primaryMuscle = exercise['primaryMuscle']?.toString();
    if (primaryMuscle != null && primaryMuscle.isNotEmpty) {
      return primaryMuscle;
    }

    // Fallback para primaryMuscleId ou muscles array
    final primaryMuscleId = exercise['primaryMuscleId']?.toString();
    final muscles = exercise['muscles'] as List<dynamic>?;

    if (muscles != null && muscles.isNotEmpty) {
      return muscles.join(', ');
    }

    return primaryMuscleId ?? 'Não especificado';
  }

  static String _mapVariation(Map<String, dynamic> config) {
    return config['variation']?.toString() ?? 'Traditional';
  }

  static int _mapSeries(Map<String, dynamic> config) {
    final seriesData = config['series'];

    // Se é um array (formato do backend)
    if (seriesData is List) {
      return seriesData.length;
    }

    // Se é um número direto
    if (seriesData is int) {
      return seriesData;
    }

    // Se é string que pode ser convertida
    if (seriesData is String) {
      return int.tryParse(seriesData) ?? 3;
    }

    // Valor padrão
    return 3;
  }

  static String _mapReps(Map<String, dynamic> config) {
    final seriesData = config['series'];

    // Se é um array, pega o primeiro item e extrai reps
    if (seriesData is List && seriesData.isNotEmpty) {
      final firstSeries = seriesData.first as Map<String, dynamic>? ?? {};
      final reps = firstSeries['reps'];

      if (reps != null) {
        return reps.toString();
      }
    }

    // Fallback para campo direto
    final reps = config['reps'];
    if (reps != null) {
      return reps.toString();
    }

    return '-';
  }

  static String _mapWeight(Map<String, dynamic> config) {
    final seriesData = config['series'];

    // Se é um array, pega o primeiro item e extrai weight
    if (seriesData is List && seriesData.isNotEmpty) {
      final firstSeries = seriesData.first as Map<String, dynamic>? ?? {};
      final weight = firstSeries['weight'];

      if (weight != null) {
        return '${weight}kg';
      }
    }

    // Fallback para campo direto
    final weight = config['weight'];
    if (weight != null) {
      return weight.toString().contains('kg')
          ? weight.toString()
          : '${weight}kg';
    }

    return '0kg';
  }

  static int _mapRir(Map<String, dynamic> config) {
    final seriesData = config['series'];

    // Se é um array, pega o primeiro item e extrai RIR
    if (seriesData is List && seriesData.isNotEmpty) {
      final firstSeries = seriesData.first as Map<String, dynamic>? ?? {};
      final rir = firstSeries['rir'];

      if (rir is int) return rir;
      if (rir is String) return int.tryParse(rir) ?? 2;
    }

    // Fallback para campo direto
    final rir = config['rir'];
    if (rir is int) return rir;
    if (rir is String) return int.tryParse(rir) ?? 2;

    return 2;
  }

  static int _mapRestTime(Map<String, dynamic> config) {
    final restTime =
        config['restTime'] ?? config['rest'] ?? config['restSeconds'];

    if (restTime is int) return restTime;
    if (restTime is String) return int.tryParse(restTime) ?? 120;

    return 120; // 2 minutos padrão
  }

  /// Maps config['series'] array to a list of [SeriesEntry].
  /// Returns an empty list when the config has no series array.
  static List<SeriesEntry> _mapEntries(Map<String, dynamic> config) {
    final seriesData = config['series'];
    if (seriesData is! List || seriesData.isEmpty) return const [];

    return seriesData.asMap().entries.map((e) {
      final i = e.key;
      final s = e.value as Map<String, dynamic>? ?? {};
      final weight = s['weight'];
      final reps = s['reps'];
      final label = s['label']?.toString() ?? s['tag']?.toString() ?? 'Top Set';
      return SeriesEntry(
        index: i,
        type: _labelToType(label),
        weight: weight != null ? weight.toString() : '0',
        reps: reps != null ? reps.toString() : '0',
      );
    }).toList();
  }

  /// Converts a backend label string to the integer type used by [SeriesEntry].
  static int _labelToType(String label) {
    switch (label.toLowerCase()) {
      case 'warm-up':
      case 'warmup':
      case 'aquecimento':
        return 0;
      case 'feeder':
      case 'prep':
      case 'preparação':
        return 1;
      case 'back-off':
      case 'backoff':
      case 'back off':
        return 3;
      case 'top set':
      case 'topset':
      case 'trabalho':
      default:
        return 2;
    }
  }
}
