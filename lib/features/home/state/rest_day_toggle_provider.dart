import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/services/auth_service.dart';
import 'package:iron_log/features/home/data/models/rest_day_toggle_dto.dart';
import 'workout_calendar_provider.dart';

/// Calls POST /rest-day with a given ISO date and invalidates the calendar.
/// Returns true if the day is now active (marked), false if removed (toggled off).
final restDayToggleProvider = FutureProvider.family<bool, String>((
  ref,
  isoDate,
) async {
  final auth = AuthService();
  final response = await auth.post(
    ApiEndpoints.restDay,
    data: {'date': isoDate},
  );
  final dto = RestDayToggleDto.fromJson(response.data as Map<String, dynamic>);
  // Invalidate calendar so the strip refreshes
  ref.invalidate(workoutCalendarProvider);
  return dto.active;
});
