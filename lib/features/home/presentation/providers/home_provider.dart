import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/home/data/models/active_rest_dto.dart';
import 'package:iron_log/features/home/home_providers.dart';
import 'package:iron_log/features/home/presentation/providers/workout_calendar_provider.dart';

export 'home_controller.dart';
export 'home_state.dart';

/// Provider para criar/atualizar um dia de descanso (rest day)
final createRestDayProvider =
    FutureProvider.family<RestDayEntity, CreateRestDayDto>((ref, dto) async {
      final restDay = await ref.read(homeRepositoryProvider).createRestDay(dto);
      ref.invalidate(workoutCalendarProvider);
      return restDay;
    });
