import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/services/auth_service.dart';
import 'package:iron_log/features/home/state/workout_calendar_provider.dart';

/// DTO para criar uma atividade (training, cardio, ou rest)
class CreateActivityDto {
  final String type; // 'training', 'cardio', 'rest'
  final String? cardioType;
  final String? intensity;
  final int? duration; // segundos
  final String? notes;
  final String date; // ISO: yyyy-MM-dd

  CreateActivityDto({
    required this.type,
    this.cardioType,
    this.intensity,
    this.duration,
    this.notes,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    if (cardioType != null) 'cardioType': cardioType,
    if (intensity != null) 'intensity': intensity,
    if (duration != null) 'duration': duration,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    'startedAt': '${date}T00:00:00Z',
  };
}

/// Response do backend
class CreateActivityResponse {
  final String id;
  final String type;
  final String date;

  CreateActivityResponse({
    required this.id,
    required this.type,
    required this.date,
  });

  factory CreateActivityResponse.fromJson(Map<String, dynamic> json) {
    return CreateActivityResponse(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'training',
      date: json['startedAt'] as String? ?? '',
    );
  }
}

/// Provider para criar uma atividade (cardio, rest, etc)
final createActivityProvider =
    FutureProvider.family<CreateActivityResponse, CreateActivityDto>((
      ref,
      dto,
    ) async {
      final auth = AuthService();
      auth.initialize();

      final response = await auth.post(
        ApiEndpoints.createWorkout,
        data: dto.toJson(),
      );

      final result = CreateActivityResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      // Invalida o provider de calendar para refrescar UI
      ref.invalidate(workoutCalendarProvider);

      return result;
    });
