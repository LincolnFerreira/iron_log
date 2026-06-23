# Implementation Plan: Persistência de Rascunhos de Treino

**Branch**: `005-workout-draft-persistence` | **Date**: 2026-06-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/005-workout-draft-persistence/spec.md`

## Summary

Garantir que treinos de musculação **nunca percam dados** quando a API falha ou o app fecha: nova tabela Drift `WorkoutDrafts` unifica rascunho **em andamento** (auto-save + botão **Continuar** na Home) e **aguardando envio** (reenvio POST/PATCH). Estende `WorkoutLogService` para persistir em **qualquer** `DioException`, substitui o papel operacional de `WorkoutOutbox`, e adiciona `WorkoutDayScreen.resume(draftId)` para restaurar exercícios, timer e contexto. **Backend inalterado.**

## Technical Context

**Language/Version**: Dart ^3.8 / Flutter 3.8+ (cliente only)

**Primary Dependencies**: Riverpod, Drift, Dio, Firebase Auth; reuso de `WorkoutLogService`, `WorkoutDayScreen`, `SyncManager`

**Storage**: Nova tabela `WorkoutDrafts` (Drift schema v6 → v7); migração de rows `WorkoutOutbox` → drafts `pendingUpload`

**Testing**: `flutter_test` — repository, mapper, `WorkoutLogService` failure paths, `ContinueWorkoutButton`; Patrol opcional para resume pós kill

**Target Platform**: Android + iOS mobile-first

**Project Type**: Flutter client (`iron_log`); `iron_log_back_end` **sem mudanças**

**Performance Goals**: auto-save debounced ≤500ms após mutação; flush de pendentes em background sem bloquear UI de treino

**Constraints**: offline-first; pt-BR; máx. 1 draft `inProgress` por usuário; nunca delete automático em falha de upload

**Scale/Scope**: 1 draft ativo + N `pendingUpload` por usuário; domínio workout execution only

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Verify against `.specify/memory/constitution.md` (Iron Log v1.2.1):

- [x] **Offline-first**: escrita Drift antes de rede; drafts + flush dedicado (extensão do padrão outbox)
- [x] **Feature layers**: `workout_day/data` (repository, datasource, mapper, sync service) + `domain` + `presentation` (Home + WorkoutDayScreen)
- [x] **Riverpod only**: novos providers `activeWorkoutDraftProvider`, injeção em `main.dart`
- [x] **Core reuse**: `HttpService`, `ApiEndpoints`, `AppSnackbar`, `HttpErrorHandler.getUserFriendlyMessage`
- [x] **Product scope**: sem backend social/web; só execução de treino
- [x] **Domain model**: respeita Rotina → Sessão → WorkoutSession; draft é camada local transitória
- [x] **Workout modes**: documentado — `WorkoutScreenMode.execution` + `WorkoutMode` create/manual/edit; ramificação start/finish/resume abaixo
- [x] **Tests**: unit + widget + quickstart Patrol opcional

**Post-design re-check**: ✅ Passed — sem violações; Complexity Tracking vazio.

## Project Structure

### Documentation (this feature)

```text
specs/005-workout-draft-persistence/
├── plan.md              # This file
├── research.md            # Phase 0
├── data-model.md          # Phase 1
├── quickstart.md          # Phase 1
├── contracts/
│   └── workout-draft-services.md
└── tasks.md               # Phase 2 (/speckit-tasks — not yet)
```

### Source Code (repository root)

```text
iron_log/
├── lib/
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart              # schema v7 + migration outbox→drafts
│   │   │   └── workout_drafts_table.dart        # NEW
│   │   └── sync/
│   │       ├── sync_manager.dart                # hook flushPendingUploads
│   │       └── workout_outbox_sync.dart         # delegate/deprecate
│   └── features/
│       ├── workout_day/
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   └── workout_draft_local_datasource.dart    # NEW
│       │   │   ├── repositories/
│       │   │   │   └── workout_draft_repository_impl.dart     # NEW
│       │   │   ├── services/
│       │   │   │   ├── workout_log_service.dart               # MODIFY — all failures → draft
│       │   │   │   └── workout_draft_sync_service.dart      # NEW
│       │   │   └── mappers/
│       │   │       └── workout_draft_snapshot_mapper.dart     # NEW
│       │   ├── domain/
│       │   │   ├── entities/workout_draft.dart                # NEW
│       │   │   └── repositories/workout_draft_repository.dart # NEW
│       │   └── presentation/
│       │       ├── pages/workout_day_screen.dart              # resume + PopScope save
│       │       ├── providers/
│       │       │   ├── workout_day_provider.dart              # auto-save hook
│       │       │   └── workout_draft_providers.dart           # NEW
│       │       └── controllers/workout_controller.dart        # finish → pendingUpload
│       └── home/
│           ├── home_page.dart                                 # continue navigation
│           └── components/
│               ├── atoms/continue_workout_button.dart         # NEW
│               └── molecules/active_workout_card.dart           # MODIFY
├── test/features/workout_day/...                              # NEW tests
└── integration_test/workout_draft_resume_test.dart            # optional

iron_log_back_end/                                             # NO CHANGES
```

**Structure Decision**: 100% implementação no cliente; unifica outbox legado em `WorkoutDrafts` para atender spec sem segunda fila paralela.

## Complexity Tracking

> Nenhuma violação de constituição.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

## Workout Modes & Lifecycle (feature impact)

| Modo | Start | Durante | Finish / falha | Resume |
|------|-------|---------|----------------|--------|
| `execution` (ao vivo) | `startExecution` → cria `inProgress` draft + POST (falha ok) | auto-save debounced | sucesso: delete draft; falha: `pendingUpload` | `WorkoutDayScreen.resume` + timer |
| `execution` + `manualDate` | idem sem timer | auto-save | idem | resume sem timer |
| `editing` | load existing | auto-save opcional | PATCH falha → `pendingUpload` | resume como editing |

**Regra**: `startExecution` MUST criar/atualizar draft mesmo offline (remove `skipOutboxEnqueueOnUnreachable` como bypass de persistência).

## Phase 0: Research

**Status**: ✅ Complete — see [research.md](./research.md)

Decisões-chave:
- Tabela única `WorkoutDrafts` (substitui outbox operacional)
- Snapshot JSON versionado para UI + mapper para API payload
- Auto-save debounced + PopScope
- Qualquer `DioException` → persistir
- Home `ContinueWorkoutButton` via `activeWorkoutDraftProvider`
- Backend fora de escopo

## Phase 1: Design

**Status**: ✅ Complete

| Artifact | Path |
|----------|------|
| Data model | [data-model.md](./data-model.md) |
| Contracts | [contracts/workout-draft-services.md](./contracts/workout-draft-services.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

### Implementation phases (for `/speckit-tasks`)

**Phase A — Data layer (P1)**
1. `workout_drafts_table.dart` + migration v7 (incl. outbox copy)
2. `WorkoutDraftRepository` + local datasource
3. `WorkoutDraftSnapshotMapper` (entries + blocks)

**Phase B — Execution persistence (P1)**
4. Auto-save em `workoutDayExercisesProvider` + `WorkoutDayScreen` PopScope
5. Alterar `startExecution` / `WorkoutLogService` failure paths
6. `WorkoutController.finishWorkout` → `pendingUpload` on failure; delete on success

**Phase C — Home Continuar (P1)**
7. `activeWorkoutDraftProvider` + `ContinueWorkoutButton`
8. `WorkoutDayScreen.resume` + `HomePage` navigation branch
9. Diálogo se tentar novo treino com `inProgress` existente

**Phase D — Reenvio (P2)**
10. `WorkoutDraftSyncService` + hook em `SyncManager` / startup
11. UI lista pendentes (Settings ou Histórico — mínimo: badge + tela simples)
12. Deprecar writes em `WorkoutOutbox`; manter read até migration estável

**Phase E — Tests**
13. Unit repository, mapper, log service
14. Widget Continue button
15. Patrol resume (opcional)

## Phase 2: Tasks

**Status**: ⏳ Pending — run `/speckit-tasks` to generate `tasks.md`
