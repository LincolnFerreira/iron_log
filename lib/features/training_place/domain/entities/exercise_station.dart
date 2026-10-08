class ExerciseStation {
  const ExerciseStation({
    required this.id,
    required this.exerciseId,
    required this.nickname,
    this.gymId,
    this.brand,
    this.note,
    this.archivedAt,
  });

  final String id;
  final String exerciseId;
  final String? gymId;
  final String nickname;
  final String? brand;
  final String? note;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;
}
