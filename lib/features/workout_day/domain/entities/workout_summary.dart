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

/// Representa um treino anterior no histórico
class WorkoutHistory {
  final String routineName; // ex: "Peito & Tríceps"
  final DateTime date;
  final Duration duration;
  final int seriesCount;

  const WorkoutHistory({
    required this.routineName,
    required this.date,
    required this.duration,
    required this.seriesCount,
  });

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
    return WorkoutHistory(
      routineName: json['routineName'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      duration: Duration(
        seconds:
            json['durationSeconds'] ?? json['duration']?.inSeconds as int? ?? 0,
      ),
      seriesCount: json['seriesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routineName': routineName,
      'date': date.toIso8601String(),
      'durationSeconds': duration.inSeconds,
      'seriesCount': seriesCount,
    };
  }
}
