/// DTO for updating session exercises
class SessionExerciseUpdateDto {
  final String exerciseId;
  final int order;
  final String? customName;
  final Map<String, dynamic> config;

  SessionExerciseUpdateDto({
    required this.exerciseId,
    required this.order,
    required this.customName,
    required this.config,
  });

  /// Factory constructor to deserialize from JSON/Map
  factory SessionExerciseUpdateDto.fromJson(Map<String, dynamic> json) {
    return SessionExerciseUpdateDto(
      exerciseId: json['exerciseId']?.toString() ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      customName: json['customName']?.toString(),
      config: (json['config'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Convert to JSON for sending to API
  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'order': order,
      'customName': customName,
      'config': config,
    };
  }
}
