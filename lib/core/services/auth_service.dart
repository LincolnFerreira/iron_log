import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiConfig {
  // Para emulador Android: 10.0.2.2 é o alias para localhost do host
  // Para iOS Simulator: localhost funciona
  // Para dispositivo físico: use o IP da máquina host
  static const String baseUrl =
      'http://10.0.2.2:3000'; // Altere para sua URL de produção

  // Headers padrão
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Dio _dio = Dio();

  // Getters para estado do Firebase Auth
  User? get currentUser => FirebaseAuth.instance.currentUser;
  bool get isAuthenticated => currentUser != null;
  Stream<User?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges();

  /// Inicializa o serviço com interceptors
  void initialize() {
    _setupDioInterceptors();
  }

  /// Configura interceptors do Dio para adicionar token automaticamente
  void _setupDioInterceptors() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.headers.addAll(ApiConfig.defaultHeaders);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Adiciona token Firebase automaticamente se o usuário estiver logado
          if (isAuthenticated) {
            try {
              final token = await currentUser!.getIdToken();
              options.headers['Authorization'] = 'Bearer $token';
              print('🔑 Token adicionado automaticamente');
            } catch (e) {
              print('❌ Erro ao obter token Firebase: $e');
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            '✅ Resposta recebida: ${response.statusCode} - ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          print('❌ Erro na requisição: ${error.message}');
          _handleApiError(error);
          handler.next(error);
        },
      ),
    );
  }

  /// Trata erros da API de forma centralizada
  void _handleApiError(DioException error) {
    switch (error.response?.statusCode) {
      case 401:
        print('🚨 Token inválido ou expirado');
        // Você pode implementar logout automático aqui se necessário
        break;
      case 403:
        print('🚨 Acesso negado');
        break;
      case 500:
        print('🚨 Erro interno do servidor');
        break;
      default:
        print('🚨 Erro desconhecido: ${error.message}');
    }
  }

  /// Valida token manualmente (POST /auth/validate)
  Future<Map<String, dynamic>> validateToken(String token) async {
    try {
      final response = await _dio.post(
        '/auth/validate',
        data: {'token': token},
      );
      return response.data;
    } catch (e) {
      throw Exception('Erro ao validar token: $e');
    }
  }

  /// Obtém dados do usuário autenticado (GET /auth/me)
  Future<Map<String, dynamic>> getUserProfile() async {
    if (!isAuthenticated) {
      throw Exception('Usuário não está autenticado');
    }

    try {
      final response = await _dio.get('/auth/me');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao obter perfil do usuário: $e');
    }
  }

  /// Faz logout do Firebase
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      print('✅ Logout realizado com sucesso');
    } catch (e) {
      print('❌ Erro no logout: $e');
      throw Exception('Erro ao fazer logout: $e');
    }
  }

  /// Faz uma requisição autenticada genérica
  Future<Response> authenticatedRequest({
    required String method,
    required String path,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (!isAuthenticated) {
      throw Exception('Usuário não está autenticado');
    }

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          return await _dio.get(path, queryParameters: queryParameters);
        case 'POST':
          return await _dio.post(
            path,
            data: data,
            queryParameters: queryParameters,
          );
        case 'PUT':
          return await _dio.put(
            path,
            data: data,
            queryParameters: queryParameters,
          );
        case 'DELETE':
          return await _dio.delete(path, queryParameters: queryParameters);
        default:
          throw Exception('Método HTTP não suportado: $method');
      }
    } catch (e) {
      throw Exception('Erro na requisição autenticada: $e');
    }
  }
}
