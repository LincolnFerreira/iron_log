import 'exercise_summary.dart';

/// Resumo completo de um treino concluído
class WorkoutSummary {
  final String sessionName; // ex: "Peito & Tríceps"
  final DateTime date;
  final Duration duration; // tempo total do treino
  final List<ExerciseSummary> exercises;
  final int totalSeries; // total de séries do treino
  final int completedSeries; // total de séries completadas
  final double totalVolume; // volume total em kg
  final bool isFirstWorkout; // true se for o primeiro treino do usuário
  final List<WorkoutHistory> previousWorkouts; // histórico dos últimos treinos

  const WorkoutSummary({
    required this.sessionName,
    required this.date,
    required this.duration,
    required this.exercises,
    required this.totalSeries,
    required this.completedSeries,
    required this.totalVolume,
    required this.isFirstWorkout,
    required this.previousWorkouts,
  });

  /// Percentual de conclusão do treino (0-100)
  int get completionPercent {
    if (totalSeries == 0) return 0;
    return ((completedSeries / totalSeries) * 100).toInt();
  }

  /// Formatação da data em forma legível: "Ter, 28 Fev"
  String get dateFormatted {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final workoutDay = DateTime(date.year, date.month, date.day);

    final isToday = today == workoutDay;
    final yesterday = today.subtract(const Duration(days: 1));
    final isYesterday = yesterday == workoutDay;

    const monthNames = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    const dayNames = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];

    final dayName = dayNames[date.weekday % 7];
    final monthName = monthNames[date.month - 1];

    if (isToday) {
      return 'Hoje • $dayName, ${date.day} $monthName';
    } else if (isYesterday) {
      return 'Ontem • $dayName, ${date.day} $monthName';
    } else {
      return '$dayName, ${date.day} $monthName';
    }
  }

  /// Formatação da duração: "45m 32s" ou "1h 25m"
  String get durationFormatted {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${minutes}m ${seconds}s';
    }
  }

  /// Mensagem de celebração baseado no contexto
  String get celebrationMessage {
    if (isFirstWorkout) {
      return 'PRIMEIRO TREINO!';
    } else if (completionPercent < 50) {
      return 'TREINO CONCLUÍDO';
    } else {
      return 'TREINO CONCLUÍDO!';
    }
  }

  /// Subtítulo (apud spec: "Treino registrado" vs celebração)
  String get subtitleMessage {
    if (completionPercent < 50) {
      return 'Treino Concluído';
    } else {
      return 'Missão cumprida';
    }
  }

  /// Cor do percentual (roxo normal, vermelho se baixa conclusão)
  String get completionColor {
    if (completionPercent < 50) {
      return '#F44336'; // Red
    } else {
      return '#9C27B0'; // Purple
    }
  }

  factory WorkoutSummary.fromJson(Map<String, dynamic> json) {
    final exercisesList =
        (json['exercises'] as List<dynamic>?)
            ?.map((e) => ExerciseSummary.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final historyList =
        (json['previousWorkouts'] as List<dynamic>?)
            ?.map((h) => WorkoutHistory.fromJson(h as Map<String, dynamic>))
            .toList() ??
        [];

    return WorkoutSummary(
      sessionName: json['sessionName'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      duration: Duration(
        seconds:
            json['durationSeconds'] ?? json['duration']?.inSeconds as int? ?? 0,
      ),
      exercises: exercisesList,
      totalSeries: json['totalSeries'] ?? 0,
      completedSeries: json['completedSeries'] ?? 0,
      totalVolume: (json['totalVolume'] as num?)?.toDouble() ?? 0.0,
      isFirstWorkout: json['isFirstWorkout'] ?? false,
      previousWorkouts: historyList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionName': sessionName,
      'date': date.toIso8601String(),
      'durationSeconds': duration.inSeconds,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'totalSeries': totalSeries,
      'completedSeries': completedSeries,
      'totalVolume': totalVolume,
      'isFirstWorkout': isFirstWorkout,
      'previousWorkouts': previousWorkouts.map((h) => h.toJson()).toList(),
    };
  }
}

/// Exercício resumido para exibição no histórico
class WorkoutHistoryExercise {
  final String exerciseName;
  final int seriesCount;
  final int completedSeries;

  const WorkoutHistoryExercise({
    required this.exerciseName,
    required this.seriesCount,
    this.completedSeries = 0,
  });

  factory WorkoutHistoryExercise.fromJson(Map<String, dynamic> json) {
    final allSeries = (json['series'] as List<dynamic>?) ?? [];
    final doneSeries = allSeries
        .where((s) => s['status'] == 'COMPLETED')
        .length;
    final exercise = json['exercise'] as Map<String, dynamic>?;
    final name =
        exercise?['name']?.toString() ??
        json['name']?.toString() ??
        'Exercício';
    return WorkoutHistoryExercise(
      exerciseName: name,
      seriesCount: allSeries.length,
      completedSeries: doneSeries,
    );
  }
}

/// Representa um treino anterior no histórico
class WorkoutHistory {
  final String id;
  final String routineName; // ex: "Peito & Tríceps"
  final String? sessionName;
  final String? sessionId;
  final DateTime date;
  final Duration duration;
  final int seriesCount;
  final int completedSeries;
  final int totalSeries;
  final double totalVolume;
  final bool hasPR;
  final List<WorkoutHistoryExercise> exercises;

  const WorkoutHistory({
    this.id = '',
    required this.routineName,
    this.sessionName,
    this.sessionId,
    required this.date,
    required this.duration,
    required this.seriesCount,
    this.completedSeries = 0,
    this.totalSeries = 0,
    this.totalVolume = 0,
    this.hasPR = false,
    this.exercises = const [],
  });

  /// Percentual de conclusão (0-100)
  int get completionPercent {
    final total = totalSeries > 0 ? totalSeries : seriesCount;
    if (total == 0) return 0;
    final done = completedSeries > 0 ? completedSeries : seriesCount;
    return ((done / total) * 100).clamp(0, 100).toInt();
  }

  /// Volume formatado: "8.6t" ou "8640kg"
  String get volumeFormatted {
    if (totalVolume <= 0) return '—';
    if (totalVolume >= 1000) {
      return '${(totalVolume / 1000).toStringAsFixed(1)}t';
    }
    return '${totalVolume.toStringAsFixed(0)}kg';
  }

  /// Formatação da data: "Ter, 28 Fev"
  String get dateFormatted {
    const monthNames = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    const dayNames = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];
    final dayName = dayNames[date.weekday % 7];
    final monthName = monthNames[date.month - 1];
    return '$dayName, ${date.day} $monthName';
  }

  /// Data longa para o modal: "Quinta, 3 de Abril de 2026"
  String get dateLong {
    const monthNames = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    const dayNames = [
      'Domingo',
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
    ];
    final dayName = dayNames[date.weekday % 7];
    final monthName = monthNames[date.month - 1];
    return '$dayName, ${date.day} de $monthName de ${date.year}';
  }

  /// Formatação da duração: "45m" ou "1h 25m"
  String get durationFormatted {
    final minutes = duration.inMinutes;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${minutes}m';
    }
  }

  factory WorkoutHistory.fromJson(Map<String, dynamic> json) {
    final exercisesList =
        (json['exercises'] as List<dynamic>?)
            ?.map(
              (e) => WorkoutHistoryExercise.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [];
    final allSeries = exercisesList.fold<int>(
      0,
      (acc, e) => acc + e.seriesCount,
    );
    final doneSeries = exercisesList.fold<int>(
      0,
      (acc, e) => acc + e.completedSeries,
    );

    return WorkoutHistory(
      id: json['id']?.toString() ?? '',
      routineName: json['routineName'] ?? '',
      sessionName: json['sessionName']?.toString(),
      sessionId: json['sessionId']?.toString(),
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      duration: Duration(
        seconds:
            json['durationSeconds'] ?? json['duration']?.inSeconds as int? ?? 0,
      ),
      seriesCount: json['seriesCount'] ?? allSeries,
      completedSeries: json['completedSeries'] ?? doneSeries,
      totalSeries: json['totalSeries'] ?? allSeries,
      totalVolume: (json['totalVolume'] as num?)?.toDouble() ?? 0.0,
      hasPR: json['hasPR'] as bool? ?? false,
      exercises: exercisesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routineName': routineName,
      'sessionName': sessionName,
      'sessionId': sessionId,
      'date': date.toIso8601String(),
      'durationSeconds': duration.inSeconds,
      'seriesCount': seriesCount,
      'completedSeries': completedSeries,
      'totalSeries': totalSeries,
      'totalVolume': totalVolume,
      'hasPR': hasPR,
    };
  }
}
