import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/home/presentation/providers/workout_calendar_provider.dart';
import 'package:iron_log/features/workout_day/workout_day_providers.dart';

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
      try {
        if (kDebugMode) {
          debugPrint('create-activity: sending payload=${dto.toJson()}');
        }

        final data = await ref
            .read(workoutDayRepositoryProvider)
            .createWorkoutActivity(dto.toJson());

        if (kDebugMode) {
          debugPrint('create-activity: response=$data');
        }

        final result = CreateActivityResponse.fromJson(data);
        ref.invalidate(workoutCalendarProvider);
        return result;
      } catch (e) {
        throw Exception('Failed to create activity: $e');
      }
    });

/// Submit latch for [CardioCreationPage] — loading lives here, not in setState.
class CardioCreationSubmitNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> save(CreateActivityDto dto) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(createActivityProvider(dto).future);
    });
    return !state.hasError;
  }
}

final cardioCreationSubmitProvider =
    NotifierProvider<CardioCreationSubmitNotifier, AsyncValue<void>>(
  CardioCreationSubmitNotifier.new,
);
