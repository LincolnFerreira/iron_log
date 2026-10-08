import 'package:iron_log/features/training_place/data/datasources/training_place_local_datasource.dart';
import 'package:iron_log/features/training_place/data/datasources/training_place_remote_datasource.dart';
import 'package:iron_log/features/training_place/domain/entities/exercise_station.dart';
import 'package:iron_log/features/training_place/domain/entities/gym.dart';
import 'package:iron_log/features/training_place/domain/nickname_key.dart';
import 'package:iron_log/features/training_place/domain/repositories/training_place_repository.dart';

class TrainingPlaceRepositoryImpl implements TrainingPlaceRepository {
  TrainingPlaceRepositoryImpl({
    required this.local,
    required this.remote,
    required this.userId,
  });

  final TrainingPlaceLocalDataSource local;
  final TrainingPlaceRemoteDataSource remote;
  final String userId;

  @override
  Future<List<Gym>> listGyms() {
    if (userId.isEmpty) return Future.value(const []);
    return local.listGyms(userId);
  }

  @override
  Future<Gym> createGym(
    String name, {
    bool attachUnscopedStations = false,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 40) {
      throw ArgumentError('Nome da academia deve ter de 1 a 40 caracteres');
    }
    final existing = await local.listGyms(userId);
    final gym = await local.insertGym(
      userId: userId,
      id: newTrainingPlaceId(),
      name: trimmed,
    );
    if (attachUnscopedStations && existing.isEmpty) {
      await local.attachUnscopedStations(userId, gym.id);
    }
    try {
      await remote.upsertGym(
        gym,
        attachUnscopedStations: attachUnscopedStations && existing.isEmpty,
      );
      await local.markGymSynced(gym.id);
    } catch (_) {}
    return gym;
  }

  @override
  Future<void> renameGym(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 40) {
      throw ArgumentError('Nome da academia deve ter de 1 a 40 caracteres');
    }
    await local.renameGym(id, trimmed);
    try {
      await remote.renameGym(id, trimmed);
      await local.markGymSynced(id);
    } catch (_) {}
  }

  @override
  Future<String?> gymIdForWorkout() async {
    final gyms = await listGyms();
    if (gyms.isEmpty) return null;
    if (gyms.length == 1) return gyms.first.id;
    return gyms.first.id;
  }

  @override
  Future<void> touchGym(String id) async {
    await local.touchGym(id);
  }

  @override
  Future<List<ExerciseStation>> listStations({
    required String exerciseId,
    String? gymId,
    bool includeUnscoped = false,
    int limit = 3,
  }) {
    if (userId.isEmpty) return Future.value(const []);
    return local.listStations(
      userId: userId,
      exerciseId: exerciseId,
      gymId: gymId,
      includeUnscoped: includeUnscoped,
      limit: limit,
    );
  }

  @override
  Future<ExerciseStation> createStation({
    required String exerciseId,
    required String nickname,
    String? gymId,
    String? brand,
  }) async {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty || trimmed.length > 40) {
      throw ArgumentError('Apelido deve ter de 1 a 40 caracteres');
    }
    final brandText = brand?.trim();
    if (brandText != null && brandText.length > 60) {
      throw ArgumentError('Marca deve ter no máximo 60 caracteres');
    }

    var resolvedGymId = gymId;
    final gyms = await listGyms();
    if ((resolvedGymId == null || resolvedGymId.isEmpty) && gyms.length == 1) {
      resolvedGymId = gyms.first.id;
    }
    if (resolvedGymId != null && resolvedGymId.isEmpty) {
      resolvedGymId = null;
    }

    final existing = await local.findActiveByNickname(
      userId: userId,
      exerciseId: exerciseId,
      nicknameKey: foldNickname(trimmed),
      gymId: resolvedGymId,
    );
    if (existing != null) return existing;

    final id = newTrainingPlaceId();
    final created = await local.insertStation(
      userId: userId,
      id: id,
      exerciseId: exerciseId,
      nickname: trimmed,
      gymId: resolvedGymId,
      brand: brandText == null || brandText.isEmpty ? null : brandText,
    );

    try {
      final remoteStation = await remote.upsertStation(
        id: id,
        exerciseId: exerciseId,
        nickname: trimmed,
        gymId: resolvedGymId,
        brand: created.brand,
      );
      if (remoteStation.id != id) {
        await local.deleteStation(id);
        return local.insertStation(
          userId: userId,
          id: remoteStation.id,
          exerciseId: remoteStation.exerciseId,
          nickname: remoteStation.nickname,
          gymId: remoteStation.gymId,
          brand: remoteStation.brand,
          note: remoteStation.note,
          pendingSync: false,
        );
      }
      await local.markStationSynced(id);
      return remoteStation;
    } catch (_) {
      return created;
    }
  }

  @override
  Future<ExerciseStation> renameStation(String id, String nickname) async {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty || trimmed.length > 40) {
      throw ArgumentError('Apelido deve ter de 1 a 40 caracteres');
    }
    final renamed = await local.renameStation(id, trimmed);
    if (renamed == null) {
      throw StateError('Estação não encontrada');
    }
    try {
      await remote.updateStation(id, nickname: trimmed);
      await local.markStationSynced(id);
    } catch (_) {}
    return renamed;
  }

  @override
  Future<void> archiveStation(String id) async {
    await local.archiveStation(id);
    try {
      await remote.updateStation(id, archived: true);
      await local.markStationSynced(id);
    } catch (_) {}
  }

  @override
  Future<void> touchStation(String id) async {
    await local.touchStation(id);
  }
}
