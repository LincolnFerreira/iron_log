class SearchExercise {
  final String id;
  final String name;
  final String? description;
  final String? primaryMuscle;
  final String? equipment;
  final String? category;
  final List<String> muscles;

  const SearchExercise({
    required this.id,
    required this.name,
    this.description,
    this.primaryMuscle,
    this.equipment,
    this.category,
    this.muscles = const [],
  });

  factory SearchExercise.fromJson(Map<String, dynamic> json) {
    return SearchExercise(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      primaryMuscle: json['primaryMuscle']?.toString(),
      equipment: json['equipment']?.toString(),
      category: json['category']?.toString(),
      muscles:
          (json['muscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'primaryMuscle': primaryMuscle,
      'equipment': equipment,
      'category': category,
      'muscles': muscles,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchExercise && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SearchExercise(id: $id, name: $name)';
  }
}
