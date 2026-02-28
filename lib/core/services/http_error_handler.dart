import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Cores ANSI para terminal (reutilização)
class ErrorColors {
  static const String reset = '\x1B[0m';
  static const String red = '\x1B[31m';
  static const String yellow = '\x1B[33m';
  static const String brightRed = '\x1B[91m';
  static const String brightYellow = '\x1B[93m';
}

/// Serviço responsável pelo tratamento centralizado de erros HTTP
/// Segue o Single Responsibility Principle - foca apenas em error handling
class HttpErrorHandler {
  /// Trata erros da API de forma centralizada
  static void handleError(DioException error) {
    switch (error.response?.statusCode) {
      case 400:
        _handleBadRequest(error);
        break;
      case 401:
        _handleUnauthorized(error);
        break;
      case 403:
        _handleForbidden(error);
        break;
      case 404:
        _handleNotFound(error);
        break;
      case 500:
        _handleServerError(error);
        break;
      default:
        _handleGenericError(error);
    }
  }

  static void _handleBadRequest(DioException error) {
    if (kDebugMode) {
      print(
        '${ErrorColors.brightYellow}🚨 Bad Request (400): Dados inválidos enviados${ErrorColors.reset}',
      );
    }
  }

  static void _handleUnauthorized(DioException error) {
    if (kDebugMode) {
      print(
        '${ErrorColors.brightRed}🚨 Unauthorized (401): Token inválido ou expirado${ErrorColors.reset}',
      );
    }
    // TODO: Implementar logout automático se necessário
    // FirebaseAuth.instance.signOut();
  }

  static void _handleForbidden(DioException error) {
    if (kDebugMode) {
      print(
        '${ErrorColors.brightRed}🚨 Forbidden (403): Acesso negado${ErrorColors.reset}',
      );
    }
  }

  static void _handleNotFound(DioException error) {
    if (kDebugMode) {
      print(
        '${ErrorColors.brightYellow}🚨 Not Found (404): Recurso não encontrado${ErrorColors.reset}',
      );
      print(
        '${ErrorColors.yellow}💡 Verificar se a rota existe no backend: ${error.requestOptions.path}${ErrorColors.reset}',
      );
      if (error.response?.data != null) {
        print(
          '${ErrorColors.yellow}📋 Detalhes: ${error.response?.data}${ErrorColors.reset}',
        );
      }
    }
  }

  static void _handleServerError(DioException error) {
    if (kDebugMode) {
      print(
        '${ErrorColors.brightRed}🚨 Server Error (500): Erro interno do servidor${ErrorColors.reset}',
      );
    }
  }

  static void _handleGenericError(DioException error) {
    if (kDebugMode) {
      print(
        '${ErrorColors.red}🚨 Erro desconhecido (${error.response?.statusCode}): ${error.message}${ErrorColors.reset}',
      );
    }
  }

  /// Verifica se o erro é relacionado à conectividade
  static bool isConnectivityError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  /// Retorna uma mensagem amigável para o usuário baseada no erro
  static String getUserFriendlyMessage(DioException error) {
    if (isConnectivityError(error)) {
      return 'Erro de conexão. Verifique sua internet.';
    }

    switch (error.response?.statusCode) {
      case 400:
        return 'Dados inválidos. Verifique as informações.';
      case 401:
        return 'Sessão expirada. Faça login novamente.';
      case 403:
        return 'Acesso negado.';
      case 404:
        return 'Recurso não encontrado.';
      case 500:
        return 'Erro no servidor. Tente novamente.';
      default:
        return 'Erro inesperado. Tente novamente.';
    }
  }
}
