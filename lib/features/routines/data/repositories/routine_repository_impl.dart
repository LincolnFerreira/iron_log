import 'package:dio/dio.dart';
import '../../domain/entities/routine.dart';
import '../../domain/repositories/routine_repository.dart';
import '../models/routine_model.dart';

class RoutineRepositoryImpl implements RoutineRepository {
  final Dio _dio;

  RoutineRepositoryImpl(this._dio);

  @override
  Future<List<Routine>> getRoutines() async {
    try {
      final response = await _dio.get('/routine');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => RoutineModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar rotinas: $e');
    }
  }

  @override
  Future<Routine> getRoutine(String id) async {
    try {
      final response = await _dio.get('/routine/$id');
      return RoutineModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao buscar rotina: $e');
    }
  }

  @override
  Future<Routine> createRoutine({
    required String name,
    String? division,
    bool isTemplate = false,
    List<Map<String, dynamic>>? sessions,
  }) async {
    try {
      final data = {
        'name': name,
        'division': division,
        'isTemplate': isTemplate,
        if (sessions != null) 'sessions': sessions,
      };

      final response = await _dio.post('/routine', data: data);
      return RoutineModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao criar rotina: $e');
    }
  }

  @override
  Future<Routine> updateRoutine(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.patch('/routine/$id', data: updates);
      return RoutineModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao atualizar rotina: $e');
    }
  }

  @override
  Future<void> deleteRoutine(String id) async {
    try {
      await _dio.delete('/routine/$id');
    } catch (e) {
      throw Exception('Erro ao deletar rotina: $e');
    }
  }
}
