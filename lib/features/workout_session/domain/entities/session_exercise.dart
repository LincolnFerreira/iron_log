class SessionExercise {
  final String name;
  final int sets;
  final int done;
  final String weight;
  final String reps;

  const SessionExercise({
    required this.name,
    required this.sets,
    required this.done,
    required this.weight,
    required this.reps,
  });

  factory SessionExercise.fromJson(Map<String, dynamic> json) {
    return SessionExercise(
      name: json['name']?.toString() ?? '',
      sets: json['sets'] ?? 0,
      done: json['done'] ?? 0,
      weight: json['weight']?.toString() ?? '0kg',
      reps: json['reps']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'done': done,
      'weight': weight,
      'reps': reps,
    };
  }

  SessionExercise copyWith({
    String? name,
    int? sets,
    int? done,
    String? weight,
    String? reps,
  }) {
    return SessionExercise(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      done: done ?? this.done,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionExercise && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() {
    return 'SessionExercise(name: $name, sets: $sets, done: $done)';
  }
}
