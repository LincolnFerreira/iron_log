// lib/features/auth/data/datasources/auth_remote_data_source_impl.dart
import 'package:dio/dio.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String name);
  Future<void> logout();
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(
          contentType: Headers.jsonContentType,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw _handleError(response);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UserModel> register(String email, String password, String name) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {'email': email, 'password': password, 'name': name},
      );

      if (response.statusCode == 201) {
        return UserModel.fromJson(response.data);
      } else {
        throw _handleError(response);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post('/auth/logout');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await dio.get('/auth/me');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw _handleError(response);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ServerException _handleError(Response response) {
    return ServerException(
      message: response.data['message'] ?? 'Erro na requisição',
      statusCode: response.statusCode,
      data: response.data,
    );
  }

  ServerException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ServerException(message: 'Tempo de conexão expirado');
    } else if (e.type == DioExceptionType.connectionError) {
      return ServerException(message: 'Erro de conexão com o servidor');
    }

    return ServerException(
      message: e.response?.data['message'] ?? 'Erro desconhecido',
      statusCode: e.response?.statusCode,
      data: e.response?.data,
    );
  }
}

// lib/core/errors/exceptions.dart
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ServerException({required this.message, this.statusCode, this.data});

  factory ServerException.fromResponse(dynamic response) {
    return ServerException(
      message: response['message'] ?? 'Server error',
      statusCode: response['statusCode'],
      data: response,
    );
  }

  @override
  String toString() => 'ServerException: $message';
}
