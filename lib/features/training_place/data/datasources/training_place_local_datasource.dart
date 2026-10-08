import 'package:drift/drift.dart';
import 'package:iron_log/core/database/app_database.dart' as db;
import 'package:iron_log/features/training_place/domain/entities/exercise_station.dart';
import 'package:iron_log/features/training_place/domain/entities/gym.dart';
import 'package:iron_log/features/training_place/domain/nickname_key.dart';

class TrainingPlaceLocalDataSource {
  TrainingPlaceLocalDataSource(this._database);

  final db.AppDatabase _database;

  Future<List<Gym>> listGyms(String userId) async {
    final rows = await (_database.select(_database.gyms)
          ..where((g) => g.userId.equals(userId))
          ..orderBy([(g) => OrderingTerm.desc(g.updatedAt)]))
        .get();
    return rows.map(_gymFromRow).toList();
  }

  Future<Gym> insertGym({
    required String userId,
    required String id,
    required String name,
  }) async {
    final now = DateTime.now();
    await _database.into(_database.gyms).insert(
          db.GymsCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            createdAt: Value(now),
            updatedAt: Value(now),
            version: const Value(1),
            pendingSync: const Value(true),
          ),
        );
    return Gym(id: id, name: name, updatedAt: now);
  }

  Future<void> renameGym(String id, String name) async {
    final row = await (_database.select(_database.gyms)
          ..where((g) => g.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    await (_database.update(_database.gyms)..where((g) => g.id.equals(id)))
        .write(
      db.GymsCompanion(
        name: Value(name),
        updatedAt: Value(DateTime.now()),
        version: Value(row.version + 1),
        pendingSync: const Value(true),
      ),
    );
  }

  Future<void> touchGym(String id) async {
    final row = await (_database.select(_database.gyms)
          ..where((g) => g.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    await (_database.update(_database.gyms)..where((g) => g.id.equals(id)))
        .write(
      db.GymsCompanion(
        updatedAt: Value(DateTime.now()),
        version: Value(row.version + 1),
        pendingSync: const Value(true),
      ),
    );
  }

  Future<void> markGymSynced(String id) async {
    await (_database.update(_database.gyms)..where((g) => g.id.equals(id)))
        .write(
      db.GymsCompanion(
        pendingSync: const Value(false),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> attachUnscopedStations(String userId, String gymId) async {
    await (_database.update(_database.exerciseStations)
          ..where((s) => s.userId.equals(userId) & s.gymId.isNull()))
        .write(
      db.ExerciseStationsCompanion(
        gymId: Value(gymId),
        updatedAt: Value(DateTime.now()),
        pendingSync: const Value(true),
      ),
    );
  }

  Future<List<ExerciseStation>> listStations({
    required String userId,
    required String exerciseId,
    String? gymId,
    bool includeUnscoped = false,
    int limit = 3,
  }) async {
    final rows = await (_database.select(_database.exerciseStations)..where(
          (s) =>
              s.userId.equals(userId) &
              s.exerciseId.equals(exerciseId) &
              s.archivedAt.isNull(),
        ))
        .get();

    final filtered = rows.where((row) {
      if (includeUnscoped) {
        return row.gymId == null || row.gymId == gymId;
      }
      if (gymId == null) return row.gymId == null;
      return row.gymId == gymId;
    }).toList();

    final ids = filtered.map((row) => row.id).toList();
    final latestUse = <String, DateTime>{};
    if (ids.isNotEmpty) {
      final series = await (_database.select(_database.serieLogs)
            ..where((s) => s.stationId.isIn(ids))
            ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
          .get();
      for (final serie in series) {
        final stationId = serie.stationId;
        if (stationId == null) continue;
        latestUse.putIfAbsent(stationId, () => serie.createdAt);
      }
    }

    filtered.sort((a, b) {
      final aAt = latestUse[a.id] ?? a.updatedAt;
      final bAt = latestUse[b.id] ?? b.updatedAt;
      return bAt.compareTo(aAt);
    });

    return filtered.take(limit).map(_stationFromRow).toList();
  }

  Future<ExerciseStation?> findActiveByNickname({
    required String userId,
    required String exerciseId,
    required String nicknameKey,
    String? gymId,
  }) async {
    final rows = await (_database.select(_database.exerciseStations)..where(
          (s) =>
              s.userId.equals(userId) &
              s.exerciseId.equals(exerciseId) &
              s.nicknameKey.equals(nicknameKey) &
              s.archivedAt.isNull(),
        ))
        .get();
    for (final row in rows) {
      if (row.gymId == gymId) return _stationFromRow(row);
    }
    return null;
  }

  Future<ExerciseStation> insertStation({
    required String userId,
    required String id,
    required String exerciseId,
    required String nickname,
    String? gymId,
    String? brand,
    String? note,
    bool pendingSync = true,
  }) async {
    final now = DateTime.now();
    await _database.into(_database.exerciseStations).insert(
          db.ExerciseStationsCompanion.insert(
            id: id,
            userId: userId,
            exerciseId: exerciseId,
            gymId: Value(gymId),
            nickname: nickname,
            nicknameKey: foldNickname(nickname),
            brand: Value(brand),
            note: Value(note),
            createdAt: Value(now),
            updatedAt: Value(now),
            version: const Value(1),
            pendingSync: Value(pendingSync),
            syncedAt: pendingSync ? const Value.absent() : Value(now),
          ),
        );
    return ExerciseStation(
      id: id,
      exerciseId: exerciseId,
      nickname: nickname,
      gymId: gymId,
      brand: brand,
      note: note,
    );
  }

  Future<void> deleteStation(String id) async {
    await (_database.delete(_database.exerciseStations)
          ..where((s) => s.id.equals(id)))
        .go();
  }

  Future<ExerciseStation?> renameStation(String id, String nickname) async {
    final row = await (_database.select(_database.exerciseStations)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    final now = DateTime.now();
    await (_database.update(_database.exerciseStations)
          ..where((s) => s.id.equals(id)))
        .write(
      db.ExerciseStationsCompanion(
        nickname: Value(nickname),
        nicknameKey: Value(foldNickname(nickname)),
        updatedAt: Value(now),
        version: Value(row.version + 1),
        pendingSync: const Value(true),
      ),
    );
    return _stationFromRow(row).copyWith(nickname: nickname);
  }

  Future<void> archiveStation(String id) async {
    final row = await (_database.select(_database.exerciseStations)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    final now = DateTime.now();
    await (_database.update(_database.exerciseStations)
          ..where((s) => s.id.equals(id)))
        .write(
      db.ExerciseStationsCompanion(
        archivedAt: Value(now),
        updatedAt: Value(now),
        version: Value(row.version + 1),
        pendingSync: const Value(true),
      ),
    );
  }

  Future<void> touchStation(String id) async {
    await (_database.update(_database.exerciseStations)
          ..where((s) => s.id.equals(id)))
        .write(
      db.ExerciseStationsCompanion(
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markStationSynced(String id) async {
    await (_database.update(_database.exerciseStations)
          ..where((s) => s.id.equals(id)))
        .write(
      db.ExerciseStationsCompanion(
        pendingSync: const Value(false),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  Gym _gymFromRow(db.Gym row) {
    return Gym(id: row.id, name: row.name, updatedAt: row.updatedAt);
  }

  ExerciseStation _stationFromRow(db.ExerciseStation row) {
    return ExerciseStation(
      id: row.id,
      exerciseId: row.exerciseId,
      gymId: row.gymId,
      nickname: row.nickname,
      brand: row.brand,
      note: row.note,
      archivedAt: row.archivedAt,
    );
  }
}

extension on ExerciseStation {
  ExerciseStation copyWith({String? nickname}) {
    return ExerciseStation(
      id: id,
      exerciseId: exerciseId,
      gymId: gymId,
      nickname: nickname ?? this.nickname,
      brand: brand,
      note: note,
      archivedAt: archivedAt,
    );
  }
}
