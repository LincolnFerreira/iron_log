/// DTOs para descanso ativo
library;

class CreateRestDayDto {
  final String date;
  final String type; // 'rest' | 'active_rest'
  final String? activityType;
  final int? duration; // minutes
  final String? intensity;
  final String? note;

  CreateRestDayDto({
    required this.date,
    this.type = 'rest',
    this.activityType,
    this.duration,
    this.intensity,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'type': type,
    'activityType': activityType,
    'duration': duration,
    'intensity': intensity,
    'note': note,
  };
}

class RestDayEntity {
  final String id;
  final String date;
  final String type;
  final String? activityType;
  final int? duration;
  final String? intensity;
  final String? note;
  final bool active;

  RestDayEntity({
    required this.id,
    required this.date,
    required this.type,
    this.activityType,
    this.duration,
    this.intensity,
    this.note,
    required this.active,
  });

  factory RestDayEntity.fromJson(Map<String, dynamic> json) {
    return RestDayEntity(
      id: json['id'] as String,
      date: json['date'] as String,
      type: json['type'] as String? ?? 'rest',
      activityType: json['activityType'] as String?,
      duration: json['duration'] as int?,
      intensity: json['intensity'] as String?,
      note: json['note'] as String?,
      active: json['active'] as bool? ?? false,
    );
  }
}

/// Available activity types for active rest
class ActivityTypeModel {
  final String id;
  final String label;
  final String icon;

  const ActivityTypeModel({
    required this.id,
    required this.label,
    required this.icon,
  });
}

final activityTypes = [
  ActivityTypeModel(id: 'cardio', label: 'Cardio', icon: '🏃'),
  ActivityTypeModel(id: 'yoga', label: 'Yoga', icon: '🧘'),
  ActivityTypeModel(id: 'stretching', label: 'Stretching', icon: '🤸'),
  ActivityTypeModel(id: 'mobility', label: 'Mobilidade', icon: '💪'),
  ActivityTypeModel(id: 'walking', label: 'Caminhada', icon: '🚶'),
];

final intensityLevels = [
  ('light', 'Leve'),
  ('moderate', 'Moderada'),
  ('high', 'Intensa'),
];
