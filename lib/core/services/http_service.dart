import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/env.dart';
import 'package:iron_log/core/services/auth_interceptor.dart';
import 'package:iron_log/core/services/diag_http_interceptor.dart';



/// Configuração da API

class ApiConfig {

  // Local: 127.0.0.1:3000 + adb reverse. Cloud: FLAVOR=prod.

  static final String baseUrl = Env.apiBaseUrl;



  // Headers padrão

  static const Map<String, String> defaultHeaders = {

    'Content-Type': 'application/json',

    'Accept': 'application/json',

  };

}



/// Serviço HTTP responsável pela configuração e execução de requisições

/// Segue o Single Responsibility Principle - foca apenas em requisições HTTP

class HttpService {

  static final HttpService _instance = HttpService._internal();

  factory HttpService() => _instance;

  HttpService._internal();



  late final Dio _dio;

  bool _initialized = false;



  /// Inicializa o serviço HTTP com configurações e interceptors.

  void initialize() {

    if (_initialized) return;



    _dio = Dio();

    _setupConfiguration();

    _setupInterceptors();

    _initialized = true;

  }



  /// Configura opções básicas do Dio

  void _setupConfiguration() {

    _dio.options.baseUrl = ApiConfig.baseUrl;

    _dio.options.headers.addAll(ApiConfig.defaultHeaders);

    _dio.options.connectTimeout = const Duration(seconds: 60);

    _dio.options.receiveTimeout = const Duration(seconds: 60);

    _dio.options.sendTimeout = const Duration(seconds: 60);

  }



  /// Adiciona interceptors

  void _setupInterceptors() {
    if (kDebugMode) {
      _dio.interceptors.add(DiagHttpInterceptor());
    }
    _dio.interceptors.add(AuthInterceptor());
  }



  /// Executa uma requisição HTTP genérica

  Future<Response> request({

    required String method,

    required String path,

    Map<String, dynamic>? data,

    Map<String, dynamic>? queryParameters,

    Options? options,

  }) async {

    if (!_initialized) {

      throw StateError('HttpService must be initialized before use');

    }



    return await _dio.request(

      path,

      data: data,

      queryParameters: queryParameters,

      options: (options ?? Options()).copyWith(method: method),

    );

  }



  /// Métodos de conveniência para diferentes tipos de requisição

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {

    return request(method: 'GET', path: path, queryParameters: queryParameters);

  }



  Future<Response> post(String path, {data}) {

    return request(method: 'POST', path: path, data: data);

  }



  Future<Response> put(String path, {data}) {

    return request(method: 'PUT', path: path, data: data);

  }



  Future<Response> patch(String path, {data}) {

    return request(method: 'PATCH', path: path, data: data);

  }



  Future<Response> delete(String path) {

    return request(method: 'DELETE', path: path);

  }



  /// Getter para acesso direto ao Dio (se necessário para casos específicos)
  Dio get dio {
    if (!_initialized) {
      throw StateError('HttpService must be initialized before use');
    }
    return _dio;
  }
}



/// Provider para HttpService

final httpServiceProvider = Provider<HttpService>((ref) {

  final httpService = HttpService();

  httpService.initialize();

  return httpService;

});


