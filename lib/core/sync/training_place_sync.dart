import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/database/app_database.dart';

/// Envia academias e estações pendentes antes do treino que as referencia.
Future<void> flushTrainingPlaces({
  required AppDatabase database,
  required Dio dio,
}) async {
  final allGyms = await database.select(database.gyms).get();
  String? oldestGymId;
  if (allGyms.isNotEmpty) {
    final ordered = [...allGyms]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    oldestGymId = ordered.first.id;
  }

  final pendingGyms = await (database.select(database.gyms)
        ..where((g) => g.pendingSync.equals(true))
        ..orderBy([(g) => OrderingTerm.asc(g.createdAt)]))
      .get();

  for (final gym in pendingGyms) {
    try {
      if (gym.syncedAt == null) {
        await dio.post(
          ApiEndpoints.gyms,
          data: {
            'id': gym.id,
            'name': gym.name,
            if (gym.id == oldestGymId) 'attachUnscopedStations': true,
          },
        );
      } else {
        await dio.patch(
          ApiEndpoints.gymById(gym.id),
          data: {'name': gym.name},
        );
      }
      await (database.update(database.gyms)..where((g) => g.id.equals(gym.id)))
          .write(
        GymsCompanion(
          pendingSync: const Value(false),
          syncedAt: Value(DateTime.now()),
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        print('TrainingPlaceSync: academia ${gym.id} não enviada: $error');
      }
    }
  }

  final pendingStations = await (database.select(database.exerciseStations)
        ..where((s) => s.pendingSync.equals(true)))
      .get();

  for (final station in pendingStations) {
    try {
      if (station.syncedAt == null) {
        await dio.post(
          ApiEndpoints.exerciseStations,
          data: {
            'id': station.id,
            'exerciseId': station.exerciseId,
            'nickname': station.nickname,
            if (station.gymId != null) 'gymId': station.gymId,
            if (station.brand != null && station.brand!.isNotEmpty)
              'brand': station.brand,
            if (station.note != null && station.note!.isNotEmpty)
              'note': station.note,
          },
        );
        if (station.archivedAt != null) {
          await dio.patch(
            ApiEndpoints.exerciseStationById(station.id),
            data: {'archived': true},
          );
        }
      } else {
        await dio.patch(
          ApiEndpoints.exerciseStationById(station.id),
          data: {
            'nickname': station.nickname,
            if (station.archivedAt != null) 'archived': true,
          },
        );
      }
      await (database.update(database.exerciseStations)
            ..where((s) => s.id.equals(station.id)))
          .write(
        ExerciseStationsCompanion(
          pendingSync: const Value(false),
          syncedAt: Value(DateTime.now()),
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        print('TrainingPlaceSync: estação ${station.id} não enviada: $error');
      }
    }
  }
}
