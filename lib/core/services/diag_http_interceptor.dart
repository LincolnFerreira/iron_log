import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:iron_log/core/debug/diag_log.dart';

/// Debug-only HTTP tracing. Registered from [HttpService._setupInterceptors].
class DiagHttpInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      DiagLog.http(
        '[HTTP START]',
        detail: '${options.method} ${options.uri}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      DiagLog.http(
        '[HTTP END]',
        detail:
            '${response.requestOptions.method} ${response.requestOptions.uri} '
            '→ ${response.statusCode}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      DiagLog.http(
        '[HTTP ERROR]',
        detail:
            '${err.requestOptions.method} ${err.requestOptions.uri} '
            '→ ${err.type} ${err.message}',
      );
    }
    handler.next(err);
  }
}
