---
description: "Task list for Observabilidade de Erros (API, UI e Crashlytics)"
---

# Tasks: Observabilidade de Erros (API, UI e Crashlytics)

**Input**: Design documents from `/specs/001-api-error-observability/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/observability-services.md, quickstart.md

**Tests**: Incluídos na fase Polish conforme plan.md e quickstart.md (não TDD estrito).

**Organization**: Tasks grouped by user story — US1 e US2 são P1; US3 e US4 são P2.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Atualizar stack Firebase e validar resolução de dependências.

- [X] T001 Atualizar `pubspec.yaml` com `firebase_core: ^4.10.0`, `firebase_crashlytics: ^5.2.3`, `firebase_auth: ^6.5.2` (ajustar peers se `flutter pub get` exigir)
- [X] T002 Executar `flutter pub get` na raiz `iron_log/` e corrigir breaking changes de import em arquivos que quebrem compilação

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema Drift, sanitização, Crashlytics wrapper e providers — **bloqueia todas as user stories**.

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase.

- [X] T003 [P] Criar `lib/core/database/api_error_logs_table.dart` conforme `data-model.md` (campos, PK, índices em `createdAt` e `httpPath+createdAt`)
- [X] T004 Registrar `ApiErrorLogs` em `lib/core/database/app_database.dart`, bump `schemaVersion` 4→5 e migration `onUpgrade` que apenas `createTable(apiErrorLogs)`
- [X] T005 Executar `dart run build_runner build --delete-conflicting-outputs` e commitar `app_database.g.dart` gerado
- [X] T006 [P] Criar `lib/core/observability/retention_policy.dart` com `retentionDays = 7` e `maxBodyBytes = 8192`
- [X] T007 [P] Criar `lib/core/observability/error_log_sanitizer.dart` (redação Authorization/token/password, truncamento 8KB, flags `truncated`/`originalLength`)
- [X] T008 [P] Criar `lib/core/observability/crash_reporting_service.dart` com `recordApiError`, `recordWidgetError`, `setUserContext`, rate-limit 5min por `(path, status)` e no-op seguro em debug/web
- [X] T009 Criar `lib/core/providers/observability_providers.dart` expondo `CrashReportingService`, `ApiErrorLogService` (stub ok até T010) via Riverpod

**Checkpoint**: Drift v5 compila; serviços base instanciáveis via providers.

---

## Phase 3: User Story 1 — Registro persistente de falhas de API (Priority: P1) 🎯 MVP

**Goal**: Toda falha HTTP no pipeline Dio gera registro JSON local sanitizado.

**Independent Test**: Simular 401, 500 e timeout → linhas em `api_error_logs` com method, path, status/tipo, timestamp, body truncado quando aplicável.

### Implementation for User Story 1

- [X] T010 [US1] Implementar `lib/core/observability/api_error_log_service.dart` com `recordFromDioException` (extrair Dio metadata, sanitizar, insert Drift, MUST NOT throw)
- [X] T011 [US1] Criar `lib/core/services/api_error_observability_interceptor.dart` chamando `ApiErrorLogService` em `onError` antes de `handler.next(err)`
- [X] T012 [US1] Registrar `ApiErrorObservabilityInterceptor` em `lib/core/services/http_service.dart` após `AuthInterceptor` em `_setupInterceptors`
- [X] T013 [US1] Garantir idempotência (uma linha por tentativa falha) via chave de request ou flag no `RequestOptions.extra` em `api_error_observability_interceptor.dart`
- [X] T014 [US1] Completar provider `ApiErrorLogService` em `lib/core/providers/observability_providers.dart` injetando `AppDatabase` e metadados (`package_info_plus`, `Env.flavor`)

**Checkpoint**: Falhas API visíveis no SQLite local; snackbars existentes (`HttpErrorHandler`) inalterados.

---

## Phase 4: User Story 2 — Crashlytics completo (Priority: P1)

**Goal**: SDK ^5.2.3 funcional; erros de API como non-fatal com custom keys; fatais preservados.

**Independent Test**: Build release → forçar erro API 500 → non-fatal no console Firebase com `http_path`/`http_status`; zone error continua fatal.

### Implementation for User Story 2

- [X] T015 [US2] Integrar `CrashReportingService.recordApiError` dentro de `api_error_log_service.dart` após insert local (custom keys conforme contrato)
- [X] T016 [US2] Atualizar `lib/main.dart` handlers (`FlutterError.onError`, `PlatformDispatcher`, `runZonedGuarded`) para compatibilidade API Crashlytics 5.x mantendo `setCrashlyticsCollectionEnabled(!kDebugMode)`
- [X] T017 [US2] Chamar `CrashReportingService.setUserContext` no fluxo de auth (login/logout) — ex.: `lib/features/auth/presentation/providers/` ou listener em `AuthService` sem expor email plain
- [X] T018 [P] [US2] Validar `android/app/build.gradle.kts` e plugins Firebase pós-bump (Crashlytics NDK, google-services) — ajustar versões se build Android falhar
- [X] T019 [P] [US2] Validar config iOS (`ios/Runner/GoogleService-Info.plist`, Podfile) compila após bump Firebase

**Checkpoint**: US1 + US2 juntos — erro API grava local **e** reporta Crashlytics em release.

---

## Phase 5: User Story 3 — Tela amigável quando widget quebra (Priority: P2)

**Goal**: `ErrorWidget.builder` com fallback temático pt-BR; reporte Crashlytics.

**Independent Test**: Widget de teste que lança no build → fallback visível em release; evento widget no Crashlytics.

### Implementation for User Story 3

- [X] T020 [P] [US3] Criar `lib/core/widgets/app_error_fallback.dart` usando `AppTheme`/`AppColors`, mensagem pt-BR, sem stack em release
- [X] T021 [US3] Configurar `ErrorWidget.builder` em `lib/main.dart` — release usa `AppErrorFallback`; debug mantém diagnóstico (tela vermelha ou seção expandível)
- [X] T022 [US3] Chamar `CrashReportingService.recordWidgetError` de `app_error_fallback.dart` com custom key `error_source=widget_build`

**Checkpoint**: Falhas de build não expõem stack ao usuário final em release.

---

## Phase 6: User Story 4 — Retenção e purge 7 dias (Priority: P2)

**Goal**: Logs locais >7 dias removidos automaticamente; zero impacto em outras tabelas.

**Independent Test**: Inserir log com `createdAt` −8 dias → startup → row removida; logs recentes permanecem.

### Implementation for User Story 4

- [X] T023 [US4] Implementar `purgeExpiredLogs()` em `lib/core/observability/api_error_log_service.dart` (DELETE only `api_error_logs` WHERE `createdAt < now - retentionDays`)
- [X] T024 [US4] Invocar purge no startup em `lib/main.dart` após `AppDatabase`/providers init (fire-and-forget, MUST NOT bloquear first frame)
- [X] T025 [US4] Documentar constante `retentionDays` em comentário em `retention_policy.dart` como ponto único de ajuste futuro

**Checkpoint**: Retenção 7 dias ativa; nenhuma operação em PostgreSQL.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Testes, validação quickstart, garantias de segurança.

- [X] T026 [P] Criar `test/core/observability/error_log_sanitizer_test.dart` — 50 fixtures sem substring `Bearer `
- [X] T027 [P] Criar `test/core/observability/api_error_log_retention_test.dart` — purge remove só expirados
- [X] T028 [P] Criar `test/core/observability/api_error_observability_interceptor_test.dart` — mock Dio 500 gera insert
- [X] T029 [P] Criar `test/core/widgets/app_error_fallback_test.dart` — widget render pt-BR
- [X] T030 Adicionar overrides de `observability_providers` em helper de testes existente (ex. `test/` ou `getTestProviderOverrides`) se necessário
- [X] T031 Executar checklist manual de `specs/001-api-error-observability/quickstart.md` e anotar desvios
- [X] T032 Confirmar **zero** alterações em `iron_log_back_end/prisma/` e nenhum script DELETE em produção

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** → **Foundational (Phase 2)** → **US1 (Phase 3)** → **US2 (Phase 4)** pode overlap após T010
- **US3 (Phase 5)** depende de T008 (`CrashReportingService`)
- **US4 (Phase 6)** depende de T010 (`ApiErrorLogService`)
- **Polish (Phase 7)** depende das fases desejadas completas

### User Story Dependencies

| Story | Depends on | Independent test after |
|-------|------------|----------------------|
| US1 | Phase 2 | Phase 3 checkpoint |
| US2 | US1 T010 + Phase 2 T008 | Phase 4 checkpoint |
| US3 | Phase 2 T008 | Phase 5 checkpoint |
| US4 | US1 T010 | Phase 6 checkpoint |

### Within Each User Story

- Services antes de wiring em `main.dart` / `http_service.dart`
- Interceptor antes de testes E2E manuais

### Parallel Opportunities

```bash
# Foundational (após T003 path acordado):
T006 retention_policy.dart ∥ T007 error_log_sanitizer.dart ∥ T008 crash_reporting_service.dart

# US2 validação nativa:
T018 Android gradle ∥ T019 iOS pods

# Polish tests:
T026 ∥ T027 ∥ T028 ∥ T029
```

---

## Parallel Example: User Story 1

```bash
# Sequencial obrigatório:
T010 api_error_log_service.dart → T011 interceptor → T012 http_service.dart → T013 idempotência

# Paralelo apenas na foundational prévia (T006–T008).
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Phase 1: Setup (T001–T002)
2. Phase 2: Foundational (T003–T009)
3. Phase 3: User Story 1 (T010–T014)
4. **STOP and VALIDATE**: quickstart §3–§4 (logs locais 401/timeout)
5. Demo diagnóstico offline

### Incremental Delivery

1. Setup + Foundational → base pronta
2. US1 → logs JSON locais (**MVP**)
3. US2 → Crashlytics non-fatal API
4. US3 → ErrorWidget fallback
5. US4 → purge 7 dias
6. Polish → testes automatizados

### Suggested MVP Scope

**Phases 1–3 (T001–T014)** entregam valor imediato: histórico local de erros API sem depender de Firebase Console.

---

## Notes

- **Backend out of scope**: nenhuma task em `iron_log_back_end/`
- **Produção DB**: purge e DELETE aplicam-se **somente** à tabela Drift `api_error_logs`
- Commit sugerido após cada phase checkpoint
- Total: **32 tasks** — US1: 5 | US2: 5 | US3: 3 | US4: 3 | Setup: 2 | Foundational: 7 | Polish: 7
