class HomeMetrics {
  final int workoutsCompleted;
  final int monthlyGoal;
  final int totalSeries;
  final int totalRoutines;

  const HomeMetrics({
    required this.workoutsCompleted,
    required this.monthlyGoal,
    required this.totalSeries,
    required this.totalRoutines,
  });

  factory HomeMetrics.fromJson(Map<String, dynamic> json) {
    return HomeMetrics(
      workoutsCompleted: (json['workoutsCompleted'] as num?)?.toInt() ?? 0,
      monthlyGoal: (json['monthlyGoal'] as num?)?.toInt() ?? 12,
      totalSeries: (json['totalSeries'] as num?)?.toInt() ?? 0,
      totalRoutines: (json['totalRoutines'] as num?)?.toInt() ?? 0,
    );
  }
}
