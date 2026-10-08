class ExerciseQueryKey {
  const ExerciseQueryKey(this.exerciseId, [this.stationId]);

  final String exerciseId;
  final String? stationId;

  @override
  bool operator ==(Object other) {
    return other is ExerciseQueryKey &&
        other.exerciseId == exerciseId &&
        other.stationId == stationId;
  }

  @override
  int get hashCode => Object.hash(exerciseId, stationId);
}
