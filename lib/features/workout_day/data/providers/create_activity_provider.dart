import 'package:flutter/foundation.dart';
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
    'date': date,
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
    final idVal = (json['id'] ?? json['workoutId']) as String? ?? '';
    final typeVal =
        json['type'] as String? ?? json['status'] as String? ?? 'training';
    final dateVal =
        json['date'] as String? ?? json['startedAt'] as String? ?? '';

    return CreateActivityResponse(id: idVal, type: typeVal, date: dateVal);
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

      try {
        if (kDebugMode) {
          debugPrint('create-activity: sending payload=${dto.toJson()}');
        }

        final response = await auth.post(
          ApiEndpoints.createWorkout,
          data: dto.toJson(),
        );

        if (kDebugMode) {
          debugPrint('create-activity: response=${response.data}');
        }

        final data = response.data;
        if (data == null || data is! Map<String, dynamic>) {
          throw Exception(
            'Unexpected response from server when creating activity',
          );
        }

        final result = CreateActivityResponse.fromJson(
          data as Map<String, dynamic>,
        );

        // Invalida o provider de calendar para refrescar UI
        ref.invalidate(workoutCalendarProvider);

        return result;
      } catch (e) {
        throw Exception('Failed to create activity: $e');
      }
    });
