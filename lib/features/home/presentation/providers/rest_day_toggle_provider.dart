import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/home/home_providers.dart';
import 'package:iron_log/features/home/presentation/providers/workout_calendar_provider.dart';

/// Calls POST /rest-day with a given ISO date and invalidates the calendar.
/// Returns true if the day is now active (marked), false if removed (toggled off).
final restDayToggleProvider = FutureProvider.family<bool, String>((
  ref,
  isoDate,
) async {
  final active = await ref.read(homeRepositoryProvider).toggleRestDay(isoDate);
  ref.invalidate(workoutCalendarProvider);
  return active;
});
