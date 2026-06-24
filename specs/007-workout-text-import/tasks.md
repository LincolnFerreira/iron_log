---
description: "Task list for feature 007-workout-text-import"
---

# Tasks: Importação de Treino por Texto Livre

**Input**: Design documents from `/specs/007-workout-text-import/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md  
**Branch**: `007-workout-text-import`  
**Repos**: `iron_log` (Flutter) + `iron_log_back_end` (NestJS)

**Organization**: Tarefas agrupadas por user story para entrega incremental e testável.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependência de tarefas incompletas)
- **[Story]**: US1–US5 mapeados à spec.md

## Path Conventions

- Backend: `iron_log_back_end/src/...`, `iron_log_back_end/prisma/...`
- Flutter: `iron_log/lib/...`, `iron_log/test/...`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Estrutura de pastas, registro de módulos e contratos compartilhados nos dois repos.

- [x] T001 Criar estrutura do módulo backend em `iron_log_back_end/src/workout-import/` (dto/, helpers/, `__tests__/golden/`) conforme plan.md
- [x] T002 Criar estrutura da feature Flutter em `iron_log/lib/features/workout_import/{domain,data,presentation}/` e `iron_log/test/features/workout_import/`
- [x] T003 [P] Adicionar endpoints em `iron_log/lib/core/api/api_endpoints.dart` (`workoutImportParse`, `workoutImportConfirm`, `workoutImportById`)
- [x] T004 [P] Adicionar constantes de rota em `iron_log/lib/core/routes/workout_route_locations.dart` (`import`, `importReview`)
- [x] T005 [P] Criar barrel export em `iron_log/lib/features/workout_import/workout_import.dart`
- [x] T006 Registrar `WorkoutImportModule` em `iron_log_back_end/src/app.module.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema, entidades de domínio, resolvers de importação e contratos de dados — **bloqueia todas as user stories**.

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase.

- [x] T007 Adicionar modelos `WorkoutTextImport`, campo `WorkoutSession.importId` e `Routine.source` em `iron_log_back_end/prisma/schema.prisma` e gerar migration
- [x] T008 [P] Criar tabela Drift `WorkoutImportDrafts` em `iron_log/lib/core/database/workout_import_drafts_table.dart` e registrar migration em `iron_log/lib/core/database/app_database.dart`
- [x] T009 [P] Implementar entidades de domínio (`ParsedWorkoutImport`, `WorkoutImportDraft`, `EffortType`) em `iron_log/lib/features/workout_import/domain/entities/`
- [x] T010 [P] Criar DTOs de request/response em `iron_log_back_end/src/workout-import/dto/` (`parse-import.dto.ts`, `parsed-workout-import.dto.ts`, `confirm-import.dto.ts`)
- [x] T011 Implementar `import-routine.resolver.ts` em `iron_log_back_end/src/workout-import/helpers/import-routine.resolver.ts` (rotina oculta `__import_history__` por usuário)
- [x] T012 Implementar `import-session-exercise.resolver.ts` em `iron_log_back_end/src/workout-import/helpers/import-session-exercise.resolver.ts` (find-or-create + SessionExercise sob demanda)
- [x] T013 [P] Implementar `effort-type.mapper.ts` em `iron_log_back_end/src/workout-import/helpers/effort-type.mapper.ts` e espelho em `iron_log/lib/features/workout_import/data/mappers/effort_type_mapper.dart`
- [x] T014 [P] Definir prompt versionado em `iron_log_back_end/src/workout-import/workout-import.prompt.ts` (regras: não inventar, separar sessões, marcar incertezas)
- [x] T015 [P] Criar interface `WorkoutImportRepository` em `iron_log/lib/features/workout_import/domain/repositories/workout_import_repository.dart`
- [x] T016 [P] Adicionar 20 fixtures golden em `iron_log_back_end/src/workout-import/__tests__/golden/*.txt` para validação SC-002
- [x] T017 Scaffold `workout-import.module.ts` e `workout-import.controller.ts` em `iron_log_back_end/src/workout-import/` com `FirebaseAuthGuard`

**Checkpoint**: Schema migrado, resolvers testáveis, contratos de domínio prontos — user stories podem iniciar.

---

## Phase 3: User Story 1 — Colar texto e receber treino estruturado (Priority: P1) 🎯 MVP

**Goal**: Usuário cola texto → sistema interpreta → exibe pré-visualização estruturada **sem** gravar treino no histórico.

**Independent Test**: Colar texto com exercício/cargas/reps → tela de revisão com sessões e séries → histórico permanece inalterado até confirm (US2).

### Implementation for User Story 1

- [x] T018 [US1] Implementar método `parse()` com Gemini em `iron_log_back_end/src/workout-import/workout-import.service.ts` (cria `WorkoutTextImport`, valida JSON, retry 1x)
- [x] T019 [US1] Implementar `POST /workout-import/parse` em `iron_log_back_end/src/workout-import/workout-import.controller.ts` com erros 400/422/503 do contrato
- [x] T020 [P] [US1] Implementar modelos JSON em `iron_log/lib/features/workout_import/data/models/` (`parse_import_response.dart`, `parsed_workout_import.dart`)
- [x] T021 [P] [US1] Implementar `WorkoutImportRemoteDataSource` em `iron_log/lib/features/workout_import/data/datasources/workout_import_remote_datasource.dart`
- [x] T022 [P] [US1] Implementar `WorkoutImportLocalDataSource` em `iron_log/lib/features/workout_import/data/datasources/workout_import_local_datasource.dart`
- [x] T023 [US1] Implementar `parseText()` em `iron_log/lib/features/workout_import/data/repositories/workout_import_repository_impl.dart` (salva draft local `reviewing`)
- [x] T024 [US1] Implementar `WorkoutImportController` com `submitText()` em `iron_log/lib/features/workout_import/presentation/providers/workout_import_controller.dart` (`@riverpod` + `AsyncNotifier`)
- [x] T025 [US1] Criar `WorkoutImportPastePage` em `iron_log/lib/features/workout_import/presentation/pages/workout_import_paste_page.dart` (textarea, contador 16k, validação vazio)
- [x] T026 [US1] Criar `WorkoutImportReviewPage` somente leitura inicial em `iron_log/lib/features/workout_import/presentation/pages/workout_import_review_page.dart` (lista sessões/exercícios/séries)
- [x] T027 [P] [US1] Criar widgets `ImportSessionCard` e `ImportExerciseTile` em `iron_log/lib/features/workout_import/presentation/widgets/`
- [x] T028 [US1] Registrar rotas `/workout/import` e `/workout/import/review/:draftId` em `iron_log/lib/core/routes/app_router.dart`
- [x] T029 [US1] Adicionar entrada "Importar de texto" em `iron_log/lib/features/workout_history/presentation/pages/workout_history_page.dart`
- [x] T030 [US1] Registrar `workoutImportProvidersOverrides` em `iron_log/lib/main.dart`

**Checkpoint**: Fluxo colar → interpretar → revisar (read-only) funcional; zero `WorkoutSession` criada no confirm.

---

## Phase 4: User Story 2 — Revisar, corrigir e confirmar antes de salvar (Priority: P1)

**Goal**: Usuário edita sugestão, confirma ou cancela; apenas versão validada persiste no histórico.

**Independent Test**: Alterar carga, remover exercício, confirmar → histórico reflete edições; cancelar → nenhum treino salvo.

### Implementation for User Story 2

- [x] T031 [US2] Implementar método `confirm()` com `prisma.$transaction` em `iron_log_back_end/src/workout-import/workout-import.service.ts`
- [x] T032 [US2] Implementar `POST /workout-import/confirm` em `iron_log_back_end/src/workout-import/workout-import.controller.ts` (201, 409 idempotência)
- [x] T033 [P] [US2] Implementar `WorkoutImportConfirmMapper` em `iron_log/lib/features/workout_import/data/mappers/workout_import_confirm_mapper.dart` (snapshot → API + Drift companions)
- [x] T034 [US2] Estender `WorkoutImportReviewPage` com edição de carga/reps em `iron_log/lib/features/workout_import/presentation/widgets/import_set_row.dart`
- [x] T035 [US2] Adicionar remoção de exercício/série no `WorkoutImportController` em `iron_log/lib/features/workout_import/presentation/providers/workout_import_controller.dart`
- [x] T036 [US2] Implementar `saveReviewEdits()` e `confirm()` no `workout_import_repository_impl.dart` (Drift transação + POST confirm)
- [x] T037 [US2] Adicionar ações Confirmar/Cancelar na `WorkoutImportReviewPage` com `ref.listen` para snackbar em `workout_import_review_page.dart`
- [x] T038 [US2] Implementar `discard()` no repository e controller; navegação de volta ao histórico sem persistir
- [x] T039 [US2] Garantir gravação local `WorkoutSession`/`SerieLog` com `pendingSync: true` no confirm em `workout_import_confirm_mapper.dart`

**Checkpoint**: Ciclo completo IA sugere → humano valida → sistema persiste; cancelamento não grava.

---

## Phase 5: User Story 3 — Separar múltiplos treinos no mesmo texto (Priority: P2)

**Goal**: Texto com vários treinos (Upper/Lower, múltiplos dias) aparece como sessões distintas na revisão.

**Independent Test**: Colar texto com "Upper 1" e "Lower 1" → dois cards de sessão separados na UI.

### Implementation for User Story 3

- [x] T040 [US3] Refinar prompt multi-sessão e labels Upper/Lower em `iron_log_back_end/src/workout-import/workout-import.prompt.ts`
- [x] T041 [US3] Tratar `dateConfidence: undetermined` no parse service em `iron_log_back_end/src/workout-import/workout-import.service.ts`
- [x] T042 [P] [US3] Exibir badge "Data não determinada" em `iron_log/lib/features/workout_import/presentation/widgets/import_session_card.dart`
- [x] T043 [US3] Adicionar `setSessionDate()` e remoção de sessão inteira no `WorkoutImportController`
- [x] T044 [US3] Suportar `confirm` com N sessões em `workout-import.service.ts` (uma `WorkoutSession` por sessão não removida)

**Checkpoint**: Multi-sessão parse + review + confirm atômico por importação.

---

## Phase 6: User Story 4 — Preservar contexto, falhas e incertezas (Priority: P2)

**Goal**: Anotações, falhas, aquecimentos e fragmentos não mapeados permanecem visíveis e rastreáveis.

**Independent Test**: Texto com dor, warmup, falha e trecho ambíguo → anotações no exercício, chips de esforço, painel de texto original.

### Implementation for User Story 4

- [x] T045 [US4] Mapear `unmappedFragments` e `parserWarnings` no response parse em `workout-import.service.ts`
- [x] T046 [P] [US4] Criar `ImportUncertaintyBanner` em `iron_log/lib/features/workout_import/presentation/widgets/import_uncertainty_banner.dart`
- [x] T047 [P] [US4] Exibir chips de `effortType` (warmup/work/failure/uncertain) em `import_set_row.dart`
- [x] T048 [US4] Adicionar painel "Ver texto original" na `WorkoutImportReviewPage` (toggle com `rawText` do draft)
- [x] T049 [US4] Persistir `exerciseNotes` e `isFailure` no confirm via `effort-type.mapper.ts` e mapper Flutter
- [x] T050 [US4] Implementar `GET /workout-import/:importId` em `workout-import.controller.ts` para auditoria pós-confirm

**Checkpoint**: Nenhum trecho relevante perdido silenciosamente; texto original recuperável.

---

## Phase 7: User Story 5 — Corrigir exercícios não reconhecidos (Priority: P3)

**Goal**: Usuário renomeia exercícios informais ou associa ao catálogo durante a revisão.

**Independent Test**: Exercício com nome ambíguo → editar nome ou picker → versão salva reflete correção.

### Implementation for User Story 5

- [x] T051 [US5] Exibir `nameConfidence` badge e campo editável no `ImportExerciseTile` em `iron_log/lib/features/workout_import/presentation/widgets/import_exercise_tile.dart`
- [x] T052 [US5] Integrar `UnifiedExerciseSearch` para override de `exerciseId` na review page
- [x] T053 [US5] Propagar `exerciseId` corrigido no `confirm` request em `workout_import_confirm_mapper.dart`
- [x] T054 [US5] Usar `exercises/find-or-create` no `import-session-exercise.resolver.ts` quando nome não resolver por ID

**Checkpoint**: Nomes informais corrigíveis sem reescrita manual do texto inteiro.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Offline, resume, sync, testes e validação quickstart.

- [ ] T055 [P] Implementar resume de draft `reviewing` ao reabrir app em `workout_import_local_datasource.dart` + banner na `workout_history_page.dart`
- [ ] T056 Integrar treinos importados no fluxo `SyncManager` existente em `iron_log/lib/core/sync/sync_manager.dart`
- [x] T057 [P] Escrever `workout-import.service.spec.ts` em `iron_log_back_end/src/workout-import/__tests__/workout-import.service.spec.ts` com golden texts
- [x] T058 [P] Escrever `workout_import_confirm_mapper_test.dart` em `iron_log/test/features/workout_import/workout_import_confirm_mapper_test.dart`
- [x] T059 [P] Escrever `workout_import_controller_test.dart` em `iron_log/test/features/workout_import/workout_import_controller_test.dart`
- [x] T060 Tratar erros de rede no parse com mensagem `HttpErrorHandler` preservando texto em `workout_import_paste_page.dart`
- [ ] T061 Validar cenários 1–7 do `specs/007-workout-text-import/quickstart.md` manualmente e documentar resultados
- [x] T062 [P] Documentar endpoints no Swagger via decorators em `workout-import.controller.ts`

---

## Dependencies & Execution Order

### Phase Dependencies

```text
Phase 1 (Setup)
    ↓
Phase 2 (Foundational) — BLOCKS all user stories
    ↓
Phase 3 (US1) ──► Phase 4 (US2)     [P1 chain: MVP = US1 + US2]
    ↓                  ↓
Phase 5 (US3)    Phase 6 (US4)       [P2 — podem paralelizar após US2]
    └────────┬─────────┘
             ↓
Phase 7 (US5)                        [P3]
             ↓
Phase 8 (Polish)
```

### User Story Dependencies

| Story | Depende de | Independente quando |
|-------|------------|---------------------|
| US1 | Phase 2 | Parse + review read-only sem confirm |
| US2 | US1 | Edit + confirm + cancel |
| US3 | US2 | Multi-sessão end-to-end |
| US4 | US2 | Incertezas + texto original + effort types |
| US5 | US2 | Picker de exercício na review |

### Parallel Opportunities

**Phase 1**: T003, T004, T005 em paralelo após T001/T002.  
**Phase 2**: T008+T009+T010+T013+T014+T015+T016 em paralelo após T007.  
**US1**: T020+T021+T022+T027 em paralelo; T018→T019 antes do Flutter parse.  
**US2**: T033 paralelo com T031 enquanto backend confirm é desenvolvido.  
**Polish**: T057+T058+T059+T062 em paralelo.

### Parallel Example: User Story 1

```bash
# Após T019 (parse API pronto):
# Flutter data layer em paralelo:
T020  # models
T021  # remote datasource
T022  # local datasource
T027  # widgets

# Sequencial depois:
T023 → T024 → T025 → T026 → T028 → T029
```

---

## Implementation Strategy

### MVP First (US1 + US2)

1. Complete Phase 1 + Phase 2  
2. Complete Phase 3 (US1) — validar preview sem save  
3. Complete Phase 4 (US2) — validar confirm/cancel  
4. **STOP**: Demo do fluxo principal (quickstart cenários 1–2)

### Incremental Delivery

1. MVP (US1+US2) → deploy interno  
2. US3 multi-sessão → US4 contexto/incertezas (P2)  
3. US5 picker exercícios (P3)  
4. Polish + golden tests

### Suggested MVP Scope

**US1 + US2** (Phases 1–4): colar, interpretar, revisar, editar, confirmar/cancelar — atende FR-001–FR-003, FR-014–FR-020 e princípio "IA sugere → humano valida → sistema persiste".

---

## Notes

- Total: **62 tasks** (T001–T062)
- Backend e Flutter: completar Foundational backend (T007–T017) antes de T018–T019; Flutter Foundational (T008–T009) pode paralelizar com backend
- Não reutilizar `VoiceToWorkoutParser` — fluxo isolado em `workout_import`
- Commits sugeridos por fase ou por checkpoint de user story
- Próximo comando: **`/speckit-implement`** (ou implementação manual seguindo esta lista)
