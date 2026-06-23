import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/auth_service.dart';
import 'package:iron_log/features/home/data/models/active_rest_dto.dart';
import 'package:iron_log/features/home/presentation/providers/workout_calendar_provider.dart';

export 'home_controller.dart';
export 'home_state.dart';

/// Provider para criar/atualizar um dia de descanso (rest day)
final createRestDayProvider =
    FutureProvider.family<RestDayEntity, CreateRestDayDto>((ref, dto) async {
      final authService = AuthService();
      authService.initialize();

      final response = await authService.post('/rest-day', data: dto.toJson());

      final restDay = RestDayEntity.fromJson(
        response.data as Map<String, dynamic>,
      );

      ref.invalidate(workoutCalendarProvider);

      return restDay;
    });
