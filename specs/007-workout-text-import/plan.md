# Implementation Plan: Importação de Treino por Texto Livre

**Branch**: `007-workout-text-import` | **Date**: 2026-06-23 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/007-workout-text-import/spec.md`

## Summary

Permitir que o usuário cole textos informais de treino (WhatsApp, notas) e receba uma **estrutura sugerida por IA** para revisão humana obrigatória antes de salvar no histórico. Fluxo: **parse (backend/Gemini) → revisão (Flutter) → confirm (backend + Drift offline-first)**. A IA nunca persiste treinos; apenas interpreta.

**Abordagem técnica**: novo módulo NestJS `workout-import` (`POST /parse`, `POST /confirm`) + nova feature Flutter `workout_import` com rascunho local Drift. Treinos confirmados reutilizam `WorkoutSession`/`SerieLog` via rotina oculta de importação por usuário (ver [research.md](./research.md)).

## Technical Context

**Language/Version**: Dart ^3.8 / Flutter 3.8+ (cliente) · TypeScript ^5.7 / NestJS 11 (API)

**Primary Dependencies**:
- Cliente: Riverpod 3 (`@riverpod` + `AsyncNotifier`), Drift, Dio/`HttpService`, go_router, `UnifiedExerciseSearch`
- Backend: Prisma 6, `@google/genai` (Gemini 2.5 Flash), class-validator, Firebase Auth Guard

**Storage**: PostgreSQL (`WorkoutTextImport`, extensão `WorkoutSession`) + Drift (`WorkoutImportDrafts`)

**Testing**: Jest (`workout-import/*.spec.ts`, golden texts) · `flutter_test` (mapper, controller, review page)

**Target Platform**: Android + iOS mobile-first + API REST

**Project Type**: Dual-repo — `iron_log` + `iron_log_back_end`

**Performance Goals**: parse p95 < 30s (texto ≤16k chars); UI de revisão fluida com até ~8 sessões por importação

**Constraints**: offline-first no confirm (Drift antes de rede); pt-BR; IA não inventa dados; human-in-the-loop obrigatório; texto original 100% rastreável

**Scale/Scope**: 2 endpoints novos + 2 telas + 1 tabela Prisma + 1 tabela Drift; ~20 golden texts de referência

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Verify against `.specify/memory/constitution.md` (Iron Log v1.2.2) + backend constitution:

- [x] **Offline-first**: confirm grava Drift com `pendingSync`; parse exige rede mas preserva texto local em draft
- [x] **Feature layers**: `lib/features/workout_import/{domain,data,presentation}` + `src/workout-import/` NestJS
- [x] **Riverpod**: `WorkoutImportController` como `AsyncNotifier`; repos via `ref.read`
- [x] **Core reuse**: `HttpService`, `ApiEndpoints`, `AppSnackbar`, `UnifiedExerciseSearch`, `SyncManager`
- [x] **Product scope**: histórico de execução only; sem áudio/OCR/coaching na v1
- [x] **Domain model**: Rotina → Sessão → WorkoutSession → SerieLog preservado (bucket import para âncora técnica)
- [x] **Backend transactions**: `confirm` usa `prisma.$transaction` para N sessões
- [x] **Tests**: quickstart + golden texts + unit ambos repos

**Post-design re-check**: ✅ Passed — rotina oculta de importação documentada em Complexity Tracking (exceção justificada ao fluxo manual com `routineId` obrigatório hoje).

## Project Structure

### Documentation (this feature)

```text
specs/007-workout-text-import/
├── plan.md              # This file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   ├── workout-import-api.md
│   └── workout-import-flutter-services.md
└── tasks.md             # Phase 2 (/speckit-tasks — not yet)
```

### Source Code

```text
iron_log_back_end/
├── prisma/
│   └── schema.prisma                          # WorkoutTextImport, WorkoutSession.importId, Routine.source
└── src/
    └── workout-import/
        ├── workout-import.module.ts
        ├── workout-import.controller.ts
        ├── workout-import.service.ts
        ├── workout-import.prompt.ts             # system prompt versionado
        ├── dto/
        │   ├── parse-import.dto.ts
        │   ├── confirm-import.dto.ts
        │   └── parsed-workout-import.dto.ts
        ├── helpers/
        │   ├── import-routine.resolver.ts     # rotina/sessão oculta por user
        │   ├── import-session-exercise.resolver.ts
        │   └── effort-type.mapper.ts
        └── __tests__/
            ├── workout-import.service.spec.ts
            └── golden/*.txt

iron_log/
├── lib/
│   ├── core/
│   │   ├── api/api_endpoints.dart             # workout-import paths
│   │   ├── database/
│   │   │   ├── app_database.dart              # schema + migration
│   │   │   └── workout_import_drafts_table.dart
│   │   └── routes/
│   │       ├── app_router.dart
│   │       └── workout_route_locations.dart   # import routes
│   └── features/
│       └── workout_import/
│           ├── domain/
│           │   ├── entities/
│           │   ├── repositories/workout_import_repository.dart
│           │   └── mappers/
│           ├── data/
│           │   ├── datasources/
│           │   ├── repositories/
│           │   ├── mappers/
│           │   └── models/
│           └── presentation/
│               ├── providers/workout_import_controller.dart
│               └── pages/
│                   ├── workout_import_paste_page.dart
│                   └── workout_import_review_page.dart
└── test/features/workout_import/
```

**Structure Decision**: Feature full-stack em dois repos existentes; sem novo serviço deployável. Parser rule-based `VoiceToWorkoutParser` permanece isolado em `workout_day` (não reutilizado).

## Complexity Tracking

| Violation / exceção | Why Needed | Simpler Alternative Rejected Because |
|---------------------|------------|--------------------------------------|
| Rotina oculta `__import_history__` por usuário | `SerieLog` exige `sessionExerciseId`; training exige rotina no schema atual | Exigir `SessionPickerSheet` por sessão importada quebra UX de bulk histórico com datas incertas |
| Entidade server-only `WorkoutTextImport` | Rastreabilidade FR-004/SC-003 cross-device | Só notas no workout mistura auditoria com domínio e limita tamanho |
| Novo módulo vs estender `/workout` | Separa interpretação (sugestão) de persistência (confirm); evita POST /workout sem revisão | Unificar em `/workout` arriscaria salvamento acidental e acoplaria prompt IA ao CRUD existente |

## Implementation Phases (high-level)

### Phase A — Backend foundation
1. Prisma migration (`WorkoutTextImport`, `importId`, `Routine.source`)
2. `ImportRoutineResolver` + `ImportSessionExerciseResolver`
3. `POST /workout-import/parse` com Gemini + validação JSON
4. `POST /workout-import/confirm` com `$transaction`
5. Testes unit + golden texts (20 amostras)

### Phase B — Flutter data layer
1. Drift `WorkoutImportDrafts` + migration
2. Remote/local datasources + repository
3. `WorkoutImportConfirmMapper` → API + Drift companions
4. `api_endpoints.dart` + provider overrides em `main.dart`

### Phase C — Flutter UI
1. Rotas `/workout/import`, `/workout/import/review/:draftId`
2. Paste page + review page (sessões, exercícios, séries editáveis)
3. Entry point em `WorkoutHistoryPage`
4. `ref.listen` para snackbar/navegação pós-confirm

### Phase D — Integration & polish
1. SyncManager hook para treinos importados (`pendingSync`)
2. Exibir link "ver texto original" na revisão e no detalhe do histórico (futuro próximo)
3. Quickstart manual + widget tests
4. Atualizar agent context / Swagger

## Artifacts Generated (Phase 0–1)

| Artifact | Path |
|----------|------|
| Research | [research.md](./research.md) |
| Data model | [data-model.md](./data-model.md) |
| API contract | [contracts/workout-import-api.md](./contracts/workout-import-api.md) |
| Flutter contract | [contracts/workout-import-flutter-services.md](./contracts/workout-import-flutter-services.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Next Step

Executar **`/speckit-tasks`** para gerar `tasks.md` com dependências ordenadas (backend Phase A antes de Flutter parse; UI após data layer).
