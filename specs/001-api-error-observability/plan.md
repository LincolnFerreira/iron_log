# Implementation Plan: Observabilidade de Erros (API, UI e Crashlytics)

**Branch**: `001-api-error-observability` | **Date**: 2026-06-11 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-api-error-observability/spec.md`

## Summary

Completar observabilidade do app Iron Log: (1) persistir falhas de API como JSON no SQLite local com sanitização e retenção de 7 dias; (2) atualizar Firebase Crashlytics para ^5.2.3 e reportar erros de API (non-fatal) e falhas de widget; (3) configurar `ErrorWidget.builder` com fallback pt-BR alinhado ao tema. **Zero alterações** no PostgreSQL de produção — toda persistência nova é Drift local. Interceptação central via Dio interceptor; purge no startup.

## Technical Context

**Language/Version**: Dart ^3.8 / Flutter 3.27+ (cliente); backend NestJS **sem mudanças v1**

**Primary Dependencies**: `firebase_core` ^4.10.0, `firebase_crashlytics` ^5.2.3, `firebase_auth` ^6.5.2 (upgrade coordenado), Dio ^5.8, Drift ^2.14, Riverpod ^2.6, `package_info_plus` ^8.3

**Storage**: Nova tabela Drift `ApiErrorLogs` (schema v4 → v5); PostgreSQL **unchanged**

**Testing**: `flutter_test` — sanitizer, retention, interceptor com mock Dio/Drift; widget test `AppErrorFallback`

**Target Platform**: Android + iOS (mobile-first; web degradado — log local only)

**Project Type**: Flutter client (`iron_log`); backend out of scope v1

**Performance Goals**: Inserção de log < 50ms async; purge < 100ms para até 1000 rows; sem bloquear UI thread

**Constraints**: FR-004 — proibido DELETE/DROP em produção; sanitizar tokens; Crashlytics disabled em debug (`!kDebugMode`)

**Scale/Scope**: ~dezenas de logs/dia/usuário; purge mantém máx. ~7 dias de histórico local

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Verify against `.specify/memory/constitution.md` (Iron Log v1.1.0):

- [x] **Offline-first**: logs locais Drift; sem dependência de rede para persistir erro; purge local only
- [x] **Feature layers**: infra em `lib/core/observability/` + providers; não viola padrão feature pois é cross-cutting core
- [x] **Riverpod only**: providers em `observability_providers.dart`
- [x] **Core reuse**: estende `HttpService`/`AuthInterceptor`; UI fallback usa `AppTheme`/`AppColors`
- [x] **Product scope**: sem painel admin, sem web APM; mobile observability only
- [x] **Domain model**: não altera Rotina/Workout/SerieLog
- [x] **Workout modes**: N/A — feature não toca execução de treino
- [x] **Tests**: unit sanitizer/retention/interceptor; widget fallback documentados em quickstart

**Post-design re-check**: ✅ Passed — nenhuma violação; Complexity Tracking vazio.

## Project Structure

### Documentation (this feature)

```text
specs/001-api-error-observability/
├── plan.md              # This file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   └── observability-services.md
└── tasks.md             # Phase 2 (/speckit-tasks — not yet)
```

### Source Code (repository root)

```text
iron_log/
├── lib/
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart          # schema v5 + migration
│   │   │   └── api_error_logs_table.dart  # NEW
│   │   ├── observability/                 # NEW
│   │   │   ├── api_error_log_service.dart
│   │   │   ├── crash_reporting_service.dart
│   │   │   ├── error_log_sanitizer.dart
│   │   │   └── retention_policy.dart
│   │   ├── providers/
│   │   │   └── observability_providers.dart  # NEW
│   │   ├── services/
│   │   │   ├── http_service.dart             # register interceptor
│   │   │   ├── auth_interceptor.dart         # or split observability interceptor
│   │   │   └── api_error_observability_interceptor.dart  # NEW
│   │   └── widgets/
│   │       └── app_error_fallback.dart       # NEW
│   └── main.dart                             # ErrorWidget.builder, purge on startup
├── test/
│   └── core/observability/                   # NEW tests
└── pubspec.yaml                              # Firebase bump

iron_log_back_end/                            # NO CHANGES v1
```

**Structure Decision**: Implementação 100% no cliente Flutter em `lib/core/` (padrão sync/http). Backend permanece inalterado.

## Complexity Tracking

> Nenhuma violação de constituição — tabela vazia.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

## Phase 0: Research

**Status**: ✅ Complete — see [research.md](./research.md)

Decisões-chave:
- Drift local `ApiErrorLogs`, schema v5
- Interceptor Dio centralizado
- Firebase stack bump coordenado
- Sanitizer + truncamento 8KB
- Purge 7 dias no startup
- Backend fora de escopo

## Phase 1: Design

**Status**: ✅ Complete

| Artifact | Path |
|----------|------|
| Data model | [data-model.md](./data-model.md) |
| Contracts | [contracts/observability-services.md](./contracts/observability-services.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

### Implementation sequence (for `/speckit-tasks`)

1. **Setup**: pubspec Firebase bump + `build_runner`
2. **Foundation**: `api_error_logs_table`, migration v5, sanitizer, retention
3. **US1**: `ApiErrorLogService` + interceptor + wire HttpService
4. **US2**: `CrashReportingService` + rate limit + auth user context
5. **US3**: `AppErrorFallback` + `ErrorWidget.builder` in main
6. **US4**: purge job on startup
7. **Polish**: unit/widget tests per quickstart

## Phase 2

**Deferred** to `/speckit-tasks` — gera `tasks.md` com IDs ordenados.
