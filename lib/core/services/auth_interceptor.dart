import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'http_logging_service.dart';
import 'http_error_handler.dart';

/// Interceptor responsável por adicionar token de autenticação e logging
/// Segue o Single Responsibility Principle - foca apenas em interceptação
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Adiciona timestamp para cálculo de duração
    HttpLoggingService.addTimestamp(options);

    // Log da requisição
    HttpLoggingService.logRequest(options);

    // Adiciona token Firebase automaticamente se o usuário estiver logado
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final token = await currentUser.getIdToken();
        options.headers['Authorization'] = 'Bearer $token';

        if (kDebugMode) {
          print('🔑 Token Firebase adicionado automaticamente');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erro ao obter token Firebase: $e');
        }
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Log da resposta
    HttpLoggingService.logResponse(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log do erro
    HttpLoggingService.logError(err);

    // Tratamento do erro
    HttpErrorHandler.handleError(err);

    handler.next(err);
  }
}
