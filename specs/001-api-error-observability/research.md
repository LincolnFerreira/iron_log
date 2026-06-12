# Research: Observabilidade de Erros

**Feature**: `001-api-error-observability` | **Date**: 2026-06-11

## R1 — Onde persistir logs de erro de API

**Decision**: Nova tabela Drift `ApiErrorLogs` no SQLite local (`schemaVersion` 4 → 5), sem alteração no PostgreSQL de produção.

**Rationale**: Spec exige FR-003/FR-004 (apenas local, purge de 7 dias). Padrão existente: `WorkoutOutbox` em `lib/core/database/` com JSON em coluna texto.

**Alternatives considered**:
- Tabela no Prisma/PostgreSQL — rejeitado (proibido pelo usuário e spec).
- Arquivo JSON em `path_provider` — rejeitado (sem query eficiente para purge por data).
- SharedPreferences — rejeitado (limite de tamanho, difícil truncar/purgar).

---

## R2 — Ponto de interceptação HTTP

**Decision**: Estender `AuthInterceptor.onError` (ou wrapper dedicado `ApiErrorObservabilityInterceptor` encadeado após auth) chamando `ApiErrorLogService.record(DioException)`.

**Rationale**: FR-001 exige pipeline central; hoje `AuthInterceptor` já chama `HttpErrorHandler.handleError` e `HttpLoggingService.logError`. Um único ponto evita duplicata.

**Alternatives considered**:
- Hook em cada repository — rejeitado (fragmentação, viola core reuse).
- Override `HttpService.request` — viável mas interceptor Dio é mais idiomático.

---

## R3 — Upgrade Firebase Crashlytics ^5.2.3

**Decision**: Bump coordenado do stack Firebase conforme [FlutterFire VERSIONS.md](https://github.com/firebase/flutterfire/blob/main/VERSIONS.md):

| Pacote | Atual | Alvo |
|--------|-------|------|
| `firebase_core` | ^3.15.2 | ^4.10.0 |
| `firebase_crashlytics` | ^4.3.10 | ^5.2.3 |
| `firebase_auth` | ^5.7.0 | ^6.5.2 (peer do ecossistema 5.x) |

Validar com `flutter pub get` e smoke test Auth + Crashlytics em Android/iOS.

**Rationale**: Crashlytics 5.2.3 requer Dart ^3.6 e Flutter >=3.27; projeto usa Dart ^3.8 — compatível.

**Alternatives considered**:
- Manter 4.x — rejeitado (requisito explícito ^5.2.3).
- Upgrade só crashlytics — rejeitado (pub resolver falha ou runtime incompatível).

---

## R4 — Reporte Crashlytics para erros de API

**Decision**: `CrashReportingService.recordApiError(...)` com `FirebaseCrashlytics.instance.recordError(..., fatal: false)` + custom keys: `http_method`, `http_path`, `http_status`, `dio_type`. Rate-limit: máx. 1 reporte idêntico (path+status) a cada 5 minutos.

**Rationale**: FR-008 (non-fatal), edge case 401 loop. Custom keys visíveis no console Firebase (SC-005).

**Alternatives considered**:
- `log()` apenas — rejeitado (menos visível que non-fatal errors).
- Fatal para 500 — rejeitado (não indica crash do app).

---

## R5 — Sanitização de payload JSON

**Decision**: `ErrorLogSanitizer` remove/redige chaves: `Authorization`, `authorization`, `token`, `password`, `refreshToken`, `idToken`. Truncar body/resposta em 8 KB com campo `truncated: true` e `originalLength`.

**Rationale**: FR-010, SC-004. Headers do Dio passam por redaction antes de serializar.

**Alternatives considered**:
- Log completo — rejeitado (risco de token vazado).
- Não logar body — rejeitado (perde diagnóstico de 400/500).

---

## R6 — ErrorWidget.builder

**Decision**: Configurar em `main.dart` após `WidgetsFlutterBinding.ensureInitialized`, antes de `runApp`. Widget `AppErrorFallback` em `lib/core/widgets/app_error_fallback.dart` usando `AppTheme`/`AppColors`. Em `kDebugMode`: manter `ErrorWidget.builder` padrão ou overlay com detalhes; em release: UI amigável pt-BR + `CrashReportingService.recordWidgetError`.

**Rationale**: FR-009, constitution IV (reuse theme). Flutter docs: `ErrorWidget.builder` substitui tela vermelha.

**Alternatives considered**:
- Só Crashlytics sem UI — rejeitado (spec P2).
- `ErrorBoundary` por tela — rejeitado (escopo v1 global).

---

## R7 — Purge de retenção 7 dias

**Decision**: Constante `ApiErrorLogRetention.days = 7` em `lib/core/observability/retention_policy.dart`. Executar `DELETE WHERE createdAt < now - 7 days` no startup (`main.dart` após init DB) e após init do `HttpService`.

**Rationale**: FR-005/FR-006; simples, offline-safe, não toca outras tabelas.

**Alternatives considered**:
- Workmanager periódico — rejeitado (complexidade desnecessária v1).
- Purge no backend — rejeitado (sem tabela servidor).

---

## R8 — Escopo backend (iron_log_back_end)

**Decision**: **Sem alterações** no NestJS/Prisma para v1.

**Rationale**: Spec Out of Scope e Assumptions — erros server-side já logados via `GlobalExceptionFilter` + Render logs.

**Alternatives considered**:
- Endpoint POST `/client-errors` — rejeitado (scope creep, DB produção).

---

## R9 — Testes

**Decision**:
- Unit: `ErrorLogSanitizer`, `ApiErrorLogService` (mock Drift), retention purge.
- Widget: `AppErrorFallback` render.
- Integration: interceptor grava linha após Dio mock 500 (sem rede real).

**Rationale**: Constitution VI; E2E Patrol opcional (Crashlytics não assertável em CI facilmente).

---

## R10 — Estrutura de módulo

**Decision**: Infra cross-cutting em `lib/core/observability/` (não feature folder completa):

```
lib/core/observability/
├── api_error_log_service.dart
├── crash_reporting_service.dart
├── error_log_sanitizer.dart
├── retention_policy.dart
lib/core/database/api_error_logs_table.dart
lib/core/widgets/app_error_fallback.dart
lib/core/services/api_error_observability_interceptor.dart
```

Providers Riverpod em `lib/core/providers/observability_providers.dart`.

**Rationale**: Constitution IV — extensão do core HTTP/DB, não domínio workout.
