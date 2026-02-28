import 'session_creation.dart';

/// Entidade para atualização de rotinas de treino
class RoutineUpdate {
  final String? name;
  final String? division;
  final bool? isTemplate;
  final List<SessionCreation>? sessions;

  const RoutineUpdate({
    this.name,
    this.division,
    this.isTemplate,
    this.sessions,
  });

  factory RoutineUpdate.fromJson(Map<String, dynamic> json) {
    return RoutineUpdate(
      name: json['name'] as String?,
      division: json['division'] as String?,
      isTemplate: json['isTemplate'] as bool?,
      sessions: (json['sessions'] as List?)
          ?.map((e) => SessionCreation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (name != null) data['name'] = name;
    if (division != null) data['division'] = division;
    if (isTemplate != null) data['isTemplate'] = isTemplate;
    if (sessions != null) {
      data['sessions'] = sessions!.map((e) => e.toJson()).toList();
    }

    return data;
  }
}
