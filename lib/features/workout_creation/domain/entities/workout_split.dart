import 'package:equatable/equatable.dart';

class WorkoutSplit extends Equatable {
  final String id;
  final String name;
  final int exerciseCount;
  final List<String> preferredDays;
  final String type; // 'push', 'pull', 'legs', etc.

  const WorkoutSplit({
    required this.id,
    required this.name,
    required this.exerciseCount,
    required this.preferredDays,
    required this.type,
  });

  WorkoutSplit copyWith({
    String? id,
    String? name,
    int? exerciseCount,
    List<String>? preferredDays,
    String? type,
  }) {
    return WorkoutSplit(
      id: id ?? this.id,
      name: name ?? this.name,
      exerciseCount: exerciseCount ?? this.exerciseCount,
      preferredDays: preferredDays ?? this.preferredDays,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [id, name, exerciseCount, preferredDays, type];
}
