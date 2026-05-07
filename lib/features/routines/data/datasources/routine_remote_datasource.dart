import 'package:dio/dio.dart';

import '../../domain/entities/routine_update.dart';
import '../../domain/entities/session_creation.dart';
import '../models/routine_model.dart';

/// HTTP-only access to routine endpoints (no cache). Used by the cached repository.
abstract class RoutineRemoteDataSource {
  Future<List<RoutineModel>> fetchRoutines();

  Future<RoutineModel> fetchRoutine(String id);

  Future<RoutineModel> createRoutine({
    required String name,
    String? division,
    bool isTemplate,
    List<SessionCreation>? sessions,
  });

  Future<RoutineModel> updateRoutine(String id, RoutineUpdate updates);

  Future<void> deleteRoutine(String id);
}

class RoutineRemoteDataSourceImpl implements RoutineRemoteDataSource {
  RoutineRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<RoutineModel>> fetchRoutines() async {
    try {
      final response = await _dio.get('/routine');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => RoutineModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar rotinas remotamente: $e');
    }
  }

  @override
  Future<RoutineModel> fetchRoutine(String id) async {
    try {
      final response = await _dio.get('/routine/$id');
      return RoutineModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erro ao buscar rotina remotamente: $e');
    }
  }

  @override
  Future<RoutineModel> createRoutine({
    required String name,
    String? division,
    bool isTemplate = false,
    List<SessionCreation>? sessions,
  }) async {
    try {
      final data = {
        'name': name,
        'division': division,
        'isTemplate': isTemplate,
        if (sessions != null) 'sessions': sessions.map((s) => s.toJson()).toList(),
      };
      final response = await _dio.post('/routine', data: data);
      return RoutineModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erro ao criar rotina remotamente: $e');
    }
  }

  @override
  Future<RoutineModel> updateRoutine(String id, RoutineUpdate updates) async {
    try {
      final response = await _dio.patch('/routine/$id', data: updates.toJson());
      return RoutineModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erro ao atualizar rotina remotamente: $e');
    }
  }

  @override
  Future<void> deleteRoutine(String id) async {
    try {
      await _dio.delete('/routine/$id');
    } catch (e) {
      throw Exception('Erro ao deletar rotina remotamente: $e');
    }
  }
}
