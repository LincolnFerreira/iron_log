# Contract: ApiErrorLogService

**Type**: Internal Dart service (client-only)  
**Feature**: `001-api-error-observability`

## recordFromDioException

Persiste um log local a partir de falha HTTP.

**Input**: `DioException error`

**Behavior**:
1. Extrair method, path, baseUrl, status, type, bodies.
2. Passar por `ErrorLogSanitizer`.
3. Truncar bodies > 8KB.
4. Inserir row em `ApiErrorLogs`.
5. Invocar `CrashReportingService.recordApiError` (non-fatal, rate-limited).
6. MUST NOT throw — falha de logging MUST NOT quebrar fluxo do app.

**Output**: `Future<String?>` — id do log ou null se falhou silenciosamente.

---

# Contract: CrashReportingService

**Type**: Internal Dart service  
**Wraps**: `FirebaseCrashlytics`

## recordApiError

**Input**: metadata map (sanitized), optional `StackTrace?`

**Behavior**: `recordError(..., fatal: false)` + `setCustomKey` para http_* fields.

**Rate limit**: Same `(httpPath, statusCode)` max 1 per 5 minutes.

---

## recordWidgetError

**Input**: `FlutterErrorDetails details`

**Behavior**: `recordFlutterError` ou `recordError` conforme severidade; custom key `error_source=widget_build`.

---

## setUserContext

**Input**: Firebase UID (optional)

**Behavior**: `setUserIdentifier` com hash ou clear on logout — MUST NOT enviar email plain.

---

# Contract: ApiErrorObservabilityInterceptor

**Type**: Dio `Interceptor`

**Order in chain**: After `AuthInterceptor` logging, before `handler.next(err)`.

**onError**: Call `ApiErrorLogService.recordFromDioException` then delegate to existing error handler.

**Idempotency**: One log per failed request attempt (Dio retry policy: if retries added later, dedupe by request hash).

---

# Contract: ErrorWidget.builder

**Signature**: `Widget Function(FlutterErrorDetails details)`

**Release**: Returns `AppErrorFallback(details: details)` — pt-BR message, themed, no stack visible.

**Debug**: Default red screen OR `AppErrorFallback` with expandable debug section (implementation choice in tasks).

---

# Contract: RetentionPurgeJob

**Method**: `Future<int> purgeExpiredLogs()`

**Input**: implicit `retentionDays = 7`

**Output**: count of deleted rows

**SQL semantics**: `DELETE FROM api_error_logs WHERE created_at < datetime('now', '-7 days')`

**Safety**: MUST only target `api_error_logs` table.
