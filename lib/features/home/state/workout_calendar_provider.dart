import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/services/auth_service.dart';
import 'package:iron_log/features/home/data/models/calendar_day_model.dart';

/// Fetches lightweight calendar data from GET /workout/calendar?days=14.
/// Much cheaper than loading full workout history with series[].
final workoutCalendarProvider = FutureProvider<CalendarResponse>((ref) async {
  final auth = AuthService();
  final response = await auth.get(ApiEndpoints.workoutCalendar(days: 14));
  return CalendarResponse.fromJson(response.data as Map<String, dynamic>);
});

/// ISO date strings (yyyy-MM-dd) with a workout logged.
final workoutCalendarDatesProvider = Provider<Set<String>>((ref) {
  final calAsync = ref.watch(workoutCalendarProvider);
  return calAsync.maybeWhen(
    data: (cal) => cal.workoutDays.map((d) => _isoDate(d.date)).toSet(),
    orElse: () => {},
  );
});

/// ISO date strings (yyyy-MM-dd) that the user has explicitly marked as rest.
final restDaysProvider = Provider<Set<String>>((ref) {
  final calAsync = ref.watch(workoutCalendarProvider);
  return calAsync.maybeWhen(
    data: (cal) => cal.restDays.toSet(),
    orElse: () => {},
  );
});

/// Current training streak in consecutive days (ending today or yesterday).
final workoutStreakProvider = Provider<int>((ref) {
  final dates = ref.watch(workoutCalendarDatesProvider);
  if (dates.isEmpty) return 0;

  int streak = 0;
  final today = DateTime.now();
  for (int i = 0; i <= 365; i++) {
    final d = today.subtract(Duration(days: i));
    if (dates.contains(_isoDate(d))) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
});

String _isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
