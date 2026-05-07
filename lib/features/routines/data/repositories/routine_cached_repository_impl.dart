import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../core/network/connectivity_utils.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/routine_update.dart';
import '../../domain/entities/session_creation.dart';
import '../../domain/repositories/routine_repository.dart';
import '../datasources/routine_local_datasource.dart';
import '../datasources/routine_remote_datasource.dart';
import '../models/routine_model.dart';

/// [RoutineRepository] with local Drift cache and [RoutineRemoteDataSource] for network.
///
/// Naming: this is not "offline-only" — when online it refreshes from the API and persists
/// snapshots; when offline (or on failure) it reads from [RoutineLocalDataSource].
class RoutineCachedRepositoryImpl implements RoutineRepository {
  RoutineCachedRepositoryImpl({
    required RoutineRemoteDataSource remote,
    required RoutineLocalDataSource localDataSource,
    required Connectivity connectivity,
    required String userId,
  }) : _remote = remote,
       _localDataSource = localDataSource,
       _connectivity = connectivity,
       _userId = userId;

  final RoutineRemoteDataSource _remote;
  final RoutineLocalDataSource _localDataSource;
  final Connectivity _connectivity;
  final String _userId;

  Future<bool> _hasInternetConnection() =>
      hasLikelyInternet(_connectivity);

  List<Routine> _toRoutineList(List<RoutineModel> models) =>
      List<Routine>.from(models);

  /// Backend persiste [Routine.userId] como **User.id** (Prisma), não Firebase UID.
  /// O cache local indexa por `authStateProvider.user.uid` — alinhar antes de gravar/ler.
  RoutineModel _withLocalOwnerUserId(RoutineModel r) {
    if (_userId.isEmpty) return r;
    if (r.userId == _userId) return r;
    return RoutineModel(
      id: r.id,
      userId: _userId,
      name: r.name,
      division: r.division,
      isTemplate: r.isTemplate,
      isActive: r.isActive,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      sessions: r.sessions,
      version: r.version,
      pendingSync: r.pendingSync,
      syncedAt: r.syncedAt,
    );
  }

  /// Corrige linhas antigas gravadas com `User.id` do backend em vez do Firebase UID.
  /// Só reescreve se existir um único `userId` distinto no banco (um “dono” local).
  Future<void> _healMismatchedOwnerUserIds() async {
    if (_userId.isEmpty) return;
    final all = await _localDataSource.getRoutines('');
    if (all.isEmpty) return;
    final distinct = all.map((e) => e.userId).where((id) => id.isNotEmpty).toSet();
    if (distinct.length != 1) return;
    final only = distinct.single;
    if (only == _userId) return;
    for (final r in all) {
      await _localDataSource.saveRoutine(_withLocalOwnerUserId(r));
    }
  }

  @override
  Future<List<Routine>> getRoutines() async {
    try {
      final isOnline = await _hasInternetConnection();

      if (isOnline) {
        final remote = await _remote.fetchRoutines();
        final forCache = remote.map(_withLocalOwnerUserId).toList();
        await _localDataSource.saveRoutines(forCache);
        return _toRoutineList(forCache);
      } else {
        await _healMismatchedOwnerUserIds();
        final cached = await _localDataSource.getRoutines(_userId);
        return _toRoutineList(cached);
      }
    } catch (e) {
      await _healMismatchedOwnerUserIds();
      final cached = await _localDataSource.getRoutines(_userId);
      if (cached.isNotEmpty) return _toRoutineList(cached);
      rethrow;
    }
  }

  @override
  Future<Routine> getRoutine(String id) async {
    try {
      final isOnline = await _hasInternetConnection();

      if (isOnline) {
        final remote = await _remote.fetchRoutine(id);
        final normalized = _withLocalOwnerUserId(remote);
        await _localDataSource.saveRoutine(normalized);
        return normalized;
      } else {
        final cached = await _localDataSource.getRoutine(id);
        if (cached != null) return cached;
        throw Exception('Rotina não encontrada localmente');
      }
    } catch (e) {
      final cached = await _localDataSource.getRoutine(id);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<Routine> createRoutine({
    required String name,
    String? division,
    bool isTemplate = false,
    List<SessionCreation>? sessions,
  }) async {
    try {
      final localRoutine = RoutineModel(
        id: _generateId(),
        userId: _userId,
        name: name,
        division: division,
        isTemplate: isTemplate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sessions: [],
        version: 1,
        pendingSync: true,
      );

      await _localDataSource.saveRoutine(localRoutine);

      final isOnline = await _hasInternetConnection();

      if (isOnline) {
        return await _pushCreateToRemote(
          localRoutine,
          division: division,
          isTemplate: isTemplate,
          sessions: sessions,
        );
      } else {
        return localRoutine;
      }
    } catch (e) {
      throw Exception('Erro ao criar rotina: $e');
    }
  }

  @override
  Future<Routine> updateRoutine(String id, RoutineUpdate updates) async {
    try {
      var routine = await _localDataSource.getRoutine(id);
      if (routine == null) {
        throw Exception('Rotina não encontrada');
      }

      final updated = RoutineModel(
        id: routine.id,
        userId: routine.userId,
        name: updates.name ?? routine.name,
        division: updates.division ?? routine.division,
        isTemplate: routine.isTemplate,
        createdAt: routine.createdAt,
        updatedAt: DateTime.now(),
        sessions: routine.sessions,
        version: (routine.version ?? 1) + 1,
        pendingSync: true,
      );

      await _localDataSource.saveRoutine(updated);

      final isOnline = await _hasInternetConnection();

      if (isOnline) {
        try {
          final synced = await _remote.updateRoutine(id, updates);
          final normalized = _withLocalOwnerUserId(synced);
          await _localDataSource.saveRoutine(normalized);
          return normalized;
        } catch (_) {
          return updated;
        }
      } else {
        return updated;
      }
    } catch (e) {
      throw Exception('Erro ao atualizar rotina: $e');
    }
  }

  @override
  Future<void> deleteRoutine(String id) async {
    try {
      await _localDataSource.markAsModified(id);

      final isOnline = await _hasInternetConnection();

      if (isOnline) {
        try {
          await _remote.deleteRoutine(id);
          await _localDataSource.deleteRoutine(id);
        } catch (_) {
          return;
        }
      }
    } catch (e) {
      throw Exception('Erro ao deletar rotina: $e');
    }
  }

  Stream<List<Routine>> watchRoutines() {
    return _localDataSource.watchRoutines(_userId).map(_toRoutineList);
  }

  Future<List<Routine>> getPendingChanges() async {
    final pending = await _localDataSource.getPendingChanges(_userId);
    return _toRoutineList(pending);
  }

  Future<Routine> _pushCreateToRemote(
    RoutineModel localRoutine, {
    String? division,
    bool isTemplate = false,
    List<SessionCreation>? sessions,
  }) async {
    try {
      final synced = await _remote.createRoutine(
        name: localRoutine.name,
        division: division,
        isTemplate: isTemplate,
        sessions: sessions,
      );

      final normalized = _withLocalOwnerUserId(synced);

      await _localDataSource.deleteRoutine(localRoutine.id);
      await _localDataSource.saveRoutine(normalized);

      return normalized;
    } catch (_) {
      return localRoutine;
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
