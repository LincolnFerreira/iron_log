/// Represents a single workout day returned by GET /workout/calendar
class CalendarDay {
  final DateTime date;
  final int durationSeconds;

  const CalendarDay({required this.date, required this.durationSeconds});

  factory CalendarDay.fromJson(Map<String, dynamic> json) => CalendarDay(
        date: DateTime.parse(json['date'] as String),
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      );
}

/// Full calendar response from GET /workout/calendar
class CalendarResponse {
  final List<CalendarDay> workoutDays;

  /// ISO date strings (yyyy-MM-dd) of rest days
  final List<String> restDays;

  const CalendarResponse({required this.workoutDays, required this.restDays});

  factory CalendarResponse.fromJson(Map<String, dynamic> json) =>
      CalendarResponse(
        workoutDays: ((json['workoutDays'] as List<dynamic>?) ?? [])
            .map((e) => CalendarDay.fromJson(e as Map<String, dynamic>))
            .toList(),
        restDays: ((json['restDays'] as List<dynamic>?) ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  static CalendarResponse empty() =>
      const CalendarResponse(workoutDays: [], restDays: []);
}
