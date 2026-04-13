import 'package:dio/dio.dart';
import '../../domain/entities/routine.dart';
import '../../domain/repositories/session_repository.dart';
import '../../data/models/session_exercise_update_dto.dart';
import '../models/routine_model.dart';

class SessionRepositoryImpl implements SessionRepository {
  final Dio _dio;

  SessionRepositoryImpl(this._dio);

  @override
  Future<Session> createSession({
    required String routineId,
    required String name,
    required int order,
    List<String> muscles = const [],
  }) async {
    try {
      final data = {
        'routineId': routineId,
        'name': name,
        'order': order,
        'muscles': muscles,
      };

      final response = await _dio.post('/session', data: data);
      return SessionModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao criar sessão: $e');
    }
  }

  @override
  Future<Session> updateSession(
    String id, {
    String? name,
    int? order,
    List<String>? muscles,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (order != null) data['order'] = order;
      if (muscles != null) data['muscles'] = muscles;

      final response = await _dio.patch('/session/$id', data: data);
      return SessionModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao atualizar sessão: $e');
    }
  }

  @override
  Future<void> deleteSession(String id) async {
    try {
      await _dio.delete('/session/$id');
    } catch (e) {
      throw Exception('Erro ao deletar sessão: $e');
    }
  }

  @override
  Future<Session> updateSessionExercises(
    String sessionId,
    List<SessionExerciseUpdateDto> exercises,
  ) async {
    try {
      final data = {'exercises': exercises.map((e) => e.toJson()).toList()};

      final response = await _dio.patch(
        '/session/$sessionId/exercises',
        data: data,
      );
      return SessionModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao atualizar exercícios da sessão: $e');
    }
  }

  @override
  Future<void> removeExerciseFromSession(
    String sessionId,
    String exerciseId,
  ) async {
    try {
      await _dio.delete('/session/$sessionId/exercises/$exerciseId');
    } catch (e) {
      throw Exception('Erro ao remover exercício da sessão: $e');
    }
  }
}
