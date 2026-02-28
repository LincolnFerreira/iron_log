import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Cores ANSI para terminal
class AnsiColors {
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';

  // Cores de texto
  static const String black = '\x1B[30m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';

  // Cores de fundo
  static const String bgRed = '\x1B[41m';
  static const String bgGreen = '\x1B[42m';
  static const String bgYellow = '\x1B[43m';
  static const String bgBlue = '\x1B[44m';
  static const String bgMagenta = '\x1B[45m';
  static const String bgCyan = '\x1B[46m';

  // Cores brilhantes
  static const String brightRed = '\x1B[91m';
  static const String brightGreen = '\x1B[92m';
  static const String brightYellow = '\x1B[93m';
  static const String brightBlue = '\x1B[94m';
  static const String brightMagenta = '\x1B[95m';
  static const String brightCyan = '\x1B[96m';
}

/// Serviço responsável pelo logging detalhado de requisições HTTP
/// Segue o Single Responsibility Principle - foca apenas em logging
class HttpLoggingService {
  /// Log detalhado da requisição com cores
  static void logRequest(RequestOptions options) {
    if (!kDebugMode) return;

    print(
      '\n${AnsiColors.brightBlue}${AnsiColors.bold}🔵 ===== REQUEST =====${AnsiColors.reset}',
    );
    print(
      '${AnsiColors.cyan}🔗 URL: ${AnsiColors.white}${options.baseUrl}${options.path}${AnsiColors.reset}',
    );
    print(
      '${AnsiColors.cyan}📝 Method: ${AnsiColors.yellow}${options.method}${AnsiColors.reset}',
    );

    // Headers simplificados (esconde token longo)
    final headersSimplified = Map<String, dynamic>.from(options.headers);
    if (headersSimplified.containsKey('Authorization')) {
      final auth = headersSimplified['Authorization'] as String;
      headersSimplified['Authorization'] = auth.length > 50
          ? '${auth.substring(0, 20)}...${auth.substring(auth.length - 10)}'
          : auth;
    }
    print(
      '${AnsiColors.cyan}🔧 Headers: ${AnsiColors.white}$headersSimplified${AnsiColors.reset}',
    );

    if (options.queryParameters.isNotEmpty) {
      print(
        '${AnsiColors.cyan}🔍 Query Parameters: ${AnsiColors.white}${options.queryParameters}${AnsiColors.reset}',
      );
    }

    if (options.data != null) {
      print(
        '${AnsiColors.cyan}📦 Request Body: ${AnsiColors.white}${options.data}${AnsiColors.reset}',
      );
    }

    print('${AnsiColors.blue}========================${AnsiColors.reset}\n');
  }

  /// Log detalhado da resposta com cores
  static void logResponse(Response response) {
    if (!kDebugMode) return;

    // Cor baseada no status code
    String statusColor = _getStatusColor(response.statusCode ?? 0);

    print(
      '\n${AnsiColors.brightGreen}${AnsiColors.bold}🟢 ===== RESPONSE =====${AnsiColors.reset}',
    );
    print(
      '${AnsiColors.cyan}🔗 URL: ${AnsiColors.white}${response.requestOptions.path}${AnsiColors.reset}',
    );
    print(
      '${AnsiColors.cyan}📊 Status: ${statusColor}${response.statusCode}${AnsiColors.reset}',
    );
    print(
      '${AnsiColors.cyan}📝 Headers: ${AnsiColors.white}${response.headers}${AnsiColors.reset}',
    );

    // Response body truncado se muito longo
    final responseBody = response.data.toString();
    final truncatedBody = responseBody.length > 500
        ? '${responseBody.substring(0, 500)}...[truncated ${responseBody.length - 500} chars]'
        : responseBody;
    print(
      '${AnsiColors.cyan}📦 Response Body: ${AnsiColors.white}$truncatedBody${AnsiColors.reset}',
    );

    // Calcula duração se timestamp estiver disponível
    final startTime = response.requestOptions.extra['start_time'] as DateTime?;
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      String durationColor = duration > 1000
          ? AnsiColors.red
          : duration > 500
          ? AnsiColors.yellow
          : AnsiColors.green;
      print(
        '${AnsiColors.cyan}⏱️  Duration: ${durationColor}${duration}ms${AnsiColors.reset}',
      );
    } else {
      print(
        '${AnsiColors.cyan}⏱️  Duration: ${AnsiColors.yellow}[timestamp missing]${AnsiColors.reset}',
      );
    }

    print('${AnsiColors.green}========================${AnsiColors.reset}\n');
  }

  /// Log detalhado do erro com cores
  static void logError(DioException error) {
    if (!kDebugMode) return;

    String statusColor = _getStatusColor(error.response?.statusCode ?? 0);

    print(
      '\n${AnsiColors.brightRed}${AnsiColors.bold}🔴 ===== ERROR =====${AnsiColors.reset}',
    );
    print(
      '${AnsiColors.cyan}🔗 URL: ${AnsiColors.white}${error.requestOptions.path}${AnsiColors.reset}',
    );
    print(
      '${AnsiColors.cyan}📊 Status: ${statusColor}${error.response?.statusCode}${AnsiColors.reset}',
    );
    print(
      '${AnsiColors.cyan}❌ Error: ${AnsiColors.brightRed}${error.message}${AnsiColors.reset}',
    );

    if (error.response?.data != null) {
      print(
        '${AnsiColors.cyan}📦 Error Body: ${AnsiColors.red}${error.response?.data}${AnsiColors.reset}',
      );
    }

    print('${AnsiColors.red}========================${AnsiColors.reset}\n');
  }

  /// Adiciona timestamp para cálculo de duração
  static void addTimestamp(RequestOptions options) {
    options.extra['start_time'] = DateTime.now();
  }

  /// Retorna cor baseada no status code
  static String _getStatusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return AnsiColors.brightGreen; // Sucesso
    } else if (statusCode >= 300 && statusCode < 400) {
      return AnsiColors.brightYellow; // Redirecionamento
    } else if (statusCode >= 400 && statusCode < 500) {
      return AnsiColors.brightRed; // Erro do cliente
    } else if (statusCode >= 500) {
      return AnsiColors.brightMagenta; // Erro do servidor
    }
    return AnsiColors.white; // Padrão
  }
}
