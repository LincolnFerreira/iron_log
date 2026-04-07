import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/routine.dart';
import '../../domain/entities/routine_update.dart';
import '../../domain/entities/session_creation.dart';
import '../../domain/repositories/routine_repository.dart';
import '../datasources/routine_local_datasource.dart';
import '../models/routine_model.dart';

/// Extended RoutineRepositoryImpl with offline-first support
/// Uses hybrid sync: local Drift database + remote API
class RoutineRepositoryOfflineImpl implements RoutineRepository {
  final Dio _dio;
  final RoutineLocalDataSource _localDataSource;
  final Connectivity _connectivity;
  final String _userId;

  RoutineRepositoryOfflineImpl({
    required Dio dio,
    required RoutineLocalDataSource localDataSource,
    required Connectivity connectivity,
    required String userId,
  }) : _dio = dio,
       _localDataSource = localDataSource,
       _connectivity = connectivity,
       _userId = userId;

  /// Check if device has internet connection
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();

      // Handle both list and single result types
      if (result is List) {
        // Newer connectivity_plus returns List<ConnectivityResult>
        return (result as List).contains(ConnectivityResult.wifi) ||
            (result as List).contains(ConnectivityResult.mobile) ||
            (result as List).contains(ConnectivityResult.ethernet);
      } else {
        // Older versions return single ConnectivityResult
        return result == ConnectivityResult.wifi ||
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.ethernet;
      }
    } catch (e) {
      // If there's an error checking connectivity, assume offline
      return false;
    }
  }

  @override
  Future<List<Routine>> getRoutines() async {
    try {
      final isOnline = await _hasInternetConnection();

      if (isOnline) {
        // Fetch from remote and cache locally
        final remote = await _fetchRemoteRoutines();
        await _localDataSource.saveRoutines(remote);
        return remote;
      } else {
        // Return cached data
        return _localDataSource.getRoutines(_userId);
      }
    } catch (e) {
      // On error, fallback to local cache
      final cached = await _localDataSource.getRoutines(_userId);
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  @override
  Future<Routine> getRoutine(String id) async {
    try {
      final isOnline = await _hasInternetConnection();

      if (isOnline) {
        // Fetch from remote and cache locally
        final remote = await _fetchRemoteRoutine(id);
        await _localDataSource.saveRoutine(remote);
        return remote;
      } else {
        // Return cached data
        final cached = await _localDataSource.getRoutine(id);
        if (cached != null) return cached;
        throw Exception('Rotina não encontrada localmente');
      }
    } catch (e) {
      // Fallback to local cache
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
      // Create locally first
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
        // Try to sync immediately
        return await _syncCreateRoutine(
          localRoutine,
          division: division,
          isTemplate: isTemplate,
          sessions: sessions,
        );
      } else {
        // Return local version, will sync later
        return localRoutine;
      }
    } catch (e) {
      throw Exception('Erro ao criar rotina: $e');
    }
  }

  @override
  Future<Routine> updateRoutine(String id, RoutineUpdate updates) async {
    try {
      // Get current routine
      var routine = await _localDataSource.getRoutine(id);
      if (routine == null) {
        throw Exception('Rotina não encontrada');
      }

      // Update locally
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
        // Try to sync immediately
        try {
          final response = await _dio.patch(
            '/routine/$id',
            data: updates.toJson(),
          );
          final synced = RoutineModel.fromJson(response.data);
          await _localDataSource.markAsSynced(id);
          return synced;
        } catch (e) {
          // Keep pending if sync fails
          return updated;
        }
      } else {
        // Return local version, will sync later
        return updated;
      }
    } catch (e) {
      throw Exception('Erro ao atualizar rotina: $e');
    }
  }

  @override
  Future<void> deleteRoutine(String id) async {
    try {
      // Mark as deleted locally
      await _localDataSource.markAsModified(id);

      final isOnline = await _hasInternetConnection();

      if (isOnline) {
        // Try to sync deletion
        try {
          await _dio.delete('/routine/$id');
          await _localDataSource.deleteRoutine(id);
        } catch (e) {
          // Keep marked as pending if sync fails
          return;
        }
      }
      // If offline, stay marked as pending
    } catch (e) {
      throw Exception('Erro ao deletar rotina: $e');
    }
  }

  /// Watch routines for real-time updates (streams from local DB)
  Stream<List<Routine>> watchRoutines() {
    return _localDataSource.watchRoutines(_userId);
  }

  /// Get pending changes ready for sync
  Future<List<Routine>> getPendingChanges() {
    return _localDataSource.getPendingChanges(_userId);
  }

  // Private helper methods

  Future<List<RoutineModel>> _fetchRemoteRoutines() async {
    try {
      final response = await _dio.get('/routine');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => RoutineModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar rotinas remotamente: $e');
    }
  }

  Future<RoutineModel> _fetchRemoteRoutine(String id) async {
    try {
      final response = await _dio.get('/routine/$id');
      return RoutineModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao buscar rotina remotamente: $e');
    }
  }

  Future<Routine> _syncCreateRoutine(
    RoutineModel localRoutine, {
    String? division,
    bool isTemplate = false,
    List<SessionCreation>? sessions,
  }) async {
    try {
      final data = {
        'name': localRoutine.name,
        'division': division,
        'isTemplate': isTemplate,
        if (sessions != null)
          'sessions': sessions.map((s) => s.toJson()).toList(),
      };

      final response = await _dio.post('/routine', data: data);
      final synced = RoutineModel.fromJson(response.data);

      // Update local copy with server ID and mark as synced
      await _localDataSource.deleteRoutine(localRoutine.id);
      await _localDataSource.saveRoutine(synced);

      return synced;
    } catch (e) {
      // Keep local version if sync fails
      return localRoutine;
    }
  }

  String _generateId() {
    // Simple ID generation - in production, use proper UUID
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
