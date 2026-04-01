/// Representa o log de uma série executada
class SerieLog {
  final int serieNumber;
  final String type; // 'warmup', 'work', 'drop', 'failure'
  final String weight; // ex: "80kg" ou "--"
  final String reps; // ex: "10" ou "--"
  final String rir; // "2" ou "--"
  final String status; // 'completed', 'marked_for_later', 'not_registered'

  const SerieLog({
    required this.serieNumber,
    required this.type,
    required this.weight,
    required this.reps,
    required this.rir,
    required this.status,
  });

  /// Retorna a cor da badge baseado no tipo
  String get typeColor {
    switch (type.toLowerCase()) {
      case 'warmup':
        return '#FFA500'; // Orange
      case 'prep':
        return '#9C27B0'; // Purple
      case 'work':
        return '#4CAF50'; // Green
      case 'failure':
        return '#F44336'; // Red
      default:
        return '#FFA500';
    }
  }

  /// Retorna a cor do status icon
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return '#4CAF50'; // Green
      case 'marked_for_later':
        return '#FFA500'; // Orange
      default:
        return '#BDBDBD'; // Gray
    }
  }

  /// Retorna o símbolo do status
  String get statusIcon {
    switch (status.toLowerCase()) {
      case 'completed':
        return '✓';
      case 'marked_for_later':
        return '⏸';
      default:
        return '—';
    }
  }

  factory SerieLog.fromJson(Map<String, dynamic> json) {
    return SerieLog(
      serieNumber: json['serieNumber'] ?? 0,
      type: json['type'] ?? 'work',
      weight: json['weight'] ?? '--',
      reps: json['reps'] ?? '--',
      rir: json['rir'] ?? '--',
      status: json['status'] ?? 'not_registered',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serieNumber': serieNumber,
      'type': type,
      'weight': weight,
      'reps': reps,
      'rir': rir,
      'status': status,
    };
  }
}
