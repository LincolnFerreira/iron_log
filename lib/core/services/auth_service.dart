import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iron_log/features/routines/domain/entities/search_exercise.dart';
import 'package:iron_log/features/auth/domain/entities/user_profile.dart';
import 'http_service.dart';

/// Serviço responsável pela autenticação e requisições autenticadas
/// Segue o Single Responsibility Principle - foca em autenticação
/// Serviço responsável pela autenticação e requisições autenticadas
/// Segue o Single Responsibility Principle - foca em autenticação
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final HttpService _httpService = HttpService();

  // Getters para estado do Firebase Auth
  User? get currentUser => FirebaseAuth.instance.currentUser;
  bool get isAuthenticated => currentUser != null;
  Stream<User?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges();

  /// Inicializa o serviço de autenticação
  void initialize() {
    _httpService.initialize();
  }

  /// Executa uma requisição autenticada
  /// Wrapper que garante que o token será adicionado automaticamente pelo interceptor
  Future<Response> authenticatedRequest({
    required String method,
    required String path,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _httpService.request(
      method: method,
      path: path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Métodos de conveniência para requisições autenticadas
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return authenticatedRequest(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
    );
  }

  Future<Response> post(String path, {dynamic data}) {
    return authenticatedRequest(method: 'POST', path: path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return authenticatedRequest(method: 'PUT', path: path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return authenticatedRequest(method: 'PATCH', path: path, data: data);
  }

  Future<Response> delete(String path) {
    return authenticatedRequest(method: 'DELETE', path: path);
  }

  /// Login com email e senha
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Registro com email e senha
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Faz logout do Firebase e limpa dados locais
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      print('✅ Logout realizado com sucesso');
    } catch (e) {
      print('❌ Erro no logout: $e');
      throw Exception('Erro ao fazer logout: $e');
    }
  }

  /// Busca exercícios (método específico mantido por compatibilidade)
  /// TODO: Mover para um ExerciseService dedicado no futuro
  static Future<List<SearchExercise>> searchExercises(String query) async {
    final authService = AuthService();
    authService.initialize();

    final response = await authService.get(
      '/exercises/search',
      queryParameters: {'q': query, 'limit': 30},
    );

    final results = (response.data as List).cast<Map<String, dynamic>>();
    return results.map((json) => SearchExercise.fromJson(json)).toList();
  }

  /// Busca dados do perfil do usuário autenticado via /auth/me
  Future<UserProfile?> getUserProfile() async {
    try {
      if (!isAuthenticated) {
        return null;
      }

      final response = await get('/auth/me');
      final userData = response.data as Map<String, dynamic>?;

      if (userData == null) {
        return null;
      }

      // O backend retorna { message: ..., user: { ... } }
      // Precisamos acessar o objeto 'user' dentro da resposta
      final userObject = userData['user'] as Map<String, dynamic>?;

      if (userObject == null) {
        return null;
      }

      return UserProfile.fromJson(userObject);
    } catch (e) {
      print('❌ Erro ao buscar perfil do usuário: $e');
      return null;
    }
  }
}
