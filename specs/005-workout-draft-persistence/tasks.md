# Tasks: Persistência de Rascunhos de Treino

**Input**: Design documents from `/specs/005-workout-draft-persistence/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/workout-draft-services.md

**Tests**: Incluídos conforme plan.md (unit/widget no Polish; Patrol opcional). Não é TDD estrito — testes após implementação por story.

**Organization**: Tarefas agrupadas por user story (spec.md). Auto-save mínimo na fase Foundational porque US2–US4 (P1) dependem de rascunho `inProgress` persistido.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependência de tarefas incompletas)
- **[Story]**: US1–US6 conforme spec.md

## Path Conventions

- Cliente: `lib/features/workout_day/`, `lib/features/home/`, `lib/core/`
- Testes: `test/features/`, `integration_test/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Preparar branch e wiring inicial de providers

- [x] T001 Verificar branch `005-workout-draft-persistence` e executar `flutter pub get` na raiz `iron_log/`
- [x] T002 [P] Criar arquivo stub `lib/features/workout_day/presentation/providers/workout_draft_providers.dart` com exports de providers
- [x] T003 [P] Registrar override de `WorkoutDraftRepository` em `lib/main.dart` (ProviderScope.overrides)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Tabela Drift, repository, mapper e persistência `inProgress` — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

- [x] T004 Criar tabela Drift `lib/core/database/workout_drafts_table.dart` conforme `specs/005-workout-draft-persistence/data-model.md`
- [x] T005 Atualizar `lib/core/database/app_database.dart` — schema v7, registrar `WorkoutDrafts`, migration `WorkoutOutbox` → `WorkoutDrafts`
- [x] T006 Executar `dart run build_runner build --delete-conflicting-outputs` e commitar `lib/core/database/app_database.g.dart`
- [x] T007 [P] Criar entidade de domínio `lib/features/workout_day/domain/entities/workout_draft.dart` (status, pendingOperation, metadados)
- [x] T008 [P] Criar interface `lib/features/workout_day/domain/repositories/workout_draft_repository.dart` conforme `contracts/workout-draft-services.md`
- [x] T009 [P] Implementar `lib/features/workout_day/data/datasources/workout_draft_local_datasource.dart` (CRUD + query `inProgress` por userId)
- [x] T010 Implementar `lib/features/workout_day/data/repositories/workout_draft_repository_impl.dart` (upsert único `inProgress`, invariantes do contrato)
- [x] T011 [P] Implementar `lib/features/workout_day/data/mappers/workout_draft_snapshot_mapper.dart` (`DraftSnapshotV1`, entries + blocks)
- [x] T012 Completar `lib/features/workout_day/presentation/providers/workout_draft_providers.dart` (`workoutDraftRepositoryProvider`, `activeWorkoutDraftProvider`)
- [x] T013 Criar/atualizar draft `inProgress` em `startExecution` em `lib/features/workout_day/presentation/providers/workout_day_provider.dart`
- [x] T014 Adicionar auto-save debounced (~500ms) após mutações em `lib/features/workout_day/presentation/providers/workout_day_provider.dart`
- [x] T015 Adicionar `PopScope` com flush de draft em `lib/features/workout_day/presentation/pages/workout_day_screen.dart`

**Checkpoint**: Repository + draft `inProgress` gravável — base para Continuar e resume

---

## Phase 3: User Story 1 — Salvar treino quando a API falha (Priority: P1) 🎯 MVP

**Goal**: Qualquer falha POST/PATCH `/workout` persiste rascunho `pendingUpload` sem perder dados

**Independent Test**: Finalizar treino com rede off ou API 500 → snackbar + row `pendingUpload` em `WorkoutDrafts`; dados completos no `apiPayloadJson`

### Implementation for User Story 1

- [x] T016 [US1] Estender `lib/features/workout_day/data/services/workout_log_service.dart` — em qualquer `DioException`, chamar repository (`markPendingUpload` / upsert) antes de propagar erro
- [x] T017 [US1] Remover bypass sem persistência de `skipOutboxEnqueueOnUnreachable` em `saveWorkout` e `startExecution` em `lib/features/workout_day/presentation/providers/workout_day_provider.dart`
- [x] T018 [US1] Atualizar `lib/features/workout_day/presentation/controllers/workout_controller.dart` — falha no finish → `pendingUpload` + `FinishResult` com flag local-saved
- [x] T019 [US1] Exibir feedback pt-BR via `AppSnackbar` em `lib/features/workout_day/presentation/controllers/workout_finish_flow.dart` quando envio falhar mas rascunho salvo
- [x] T020 [US1] Remover draft após envio bem-sucedido em `lib/features/workout_day/presentation/controllers/workout_controller.dart`
- [x] T021 [US1] Redirecionar writes de `lib/features/workout_day/data/datasources/workout_outbox_local_datasource.dart` para draft repository (deprecar inserts novos)

**Checkpoint**: Cenário 3 do `quickstart.md` (finalizar com API falhando) passa

---

## Phase 4: User Story 2 — Continuar treino pela Home (Priority: P1)

**Goal**: Botão **CONTINUAR TREINO** no card da Home quando existe draft `inProgress`

**Independent Test**: Registrar série → voltar Home → card mostra Continuar → toque reabre execução

### Implementation for User Story 2

- [x] T022 [P] [US2] Criar `lib/features/home/components/atoms/continue_workout_button.dart` (espelhar `start_workout_button.dart`, label CONTINUAR TREINO)
- [x] T023 [US2] Estender `lib/features/home/components/molecules/active_workout_card.dart` — props `activeDraft`, `onContinueWorkout`; trocar botão quando draft existe
- [x] T024 [US2] Propagar draft summary em `lib/features/home/components/molecules/todays_workout_card.dart` e `lib/features/home/components/templates/home_template.dart`
- [x] T025 [US2] Watch `activeWorkoutDraftProvider` e bifurcar navegação em `lib/features/home/home_page.dart` (`resume` vs `create`)
- [x] T026 [US2] Adicionar construtor `WorkoutDayScreen.resume({required String draftId})` em `lib/features/workout_day/presentation/pages/workout_day_screen.dart`

**Checkpoint**: Cenário 1 do `quickstart.md` passa

---

## Phase 5: User Story 3 — Recuperar estado completo da tela (Priority: P1)

**Goal**: Retomada restaura exercícios, ordem, séries, modo manual/ao vivo e timer

**Independent Test**: Kill app após séries registradas → Continuar → UI idêntica (SC-003)

### Implementation for User Story 3

- [x] T027 [US3] Implementar `applyToProviders` no mapper em `lib/features/workout_day/data/mappers/workout_draft_snapshot_mapper.dart` (hidratar `workoutDayExercisesProvider`, `workoutScreenModeProvider`, `workoutSessionIdProvider`)
- [x] T028 [US3] Carregar draft e aplicar snapshot no `initState` de `WorkoutDayScreen.resume` em `lib/features/workout_day/presentation/pages/workout_day_screen.dart`
- [x] T029 [US3] Restaurar timer em `lib/features/workout_day/presentation/providers/workout_timer_provider.dart` (`timerStartedAt` / duração acumulada do draft)
- [x] T030 [US3] Persistir `timerStartedAt` e `manualDate` no auto-save em `lib/features/workout_day/presentation/providers/workout_day_provider.dart`
- [x] T031 [US3] Espelhar `PopScope` + resume em `lib/features/workout_day/presentation/pages/workout_session_screen.dart` se ainda exportada como alternativa

**Checkpoint**: Cenário 2 do `quickstart.md` passa

---

## Phase 6: User Story 4 — Finalizar ou manter em andamento (Priority: P1)

**Goal**: Sair sem finalizar mantém `inProgress`; finalizar move para `pendingUpload` sem apagar local

**Independent Test**: Opção A — sair e Continuar; Opção B — finalizar com API down → sem Continuar na Home, mas pendente reenviável

### Implementation for User Story 4

- [x] T032 [US4] Garantir transição `inProgress` → `pendingUpload` em `markPendingUpload` no `lib/features/workout_day/data/repositories/workout_draft_repository_impl.dart`
- [x] T033 [US4] Ao sair sem finalizar, manter status `inProgress` (validar T014/T015) em `lib/features/workout_day/presentation/pages/workout_day_screen.dart`
- [x] T034 [US4] Ocultar **Continuar** na Home quando status ≠ `inProgress` em `lib/features/workout_day/presentation/providers/workout_draft_providers.dart`
- [x] T035 [US4] Diálogo ao tentar **Iniciar treino** com draft `inProgress` existente em `lib/features/home/home_page.dart` (continuar atual — descarte explícito fora de escopo)

**Checkpoint**: Acceptance scenarios US4 na spec passam

---

## Phase 7: User Story 5 — Reenviar rascunhos (Priority: P2)

**Goal**: Flush de `pendingUpload` no startup/sync; UI mínima para reenvio manual

**Independent Test**: Criar pendente offline → restaurar API → reenvio → histórico atualizado, draft removido

### Implementation for User Story 5

- [x] T036 [P] [US5] Criar `lib/features/workout_day/data/services/workout_draft_sync_service.dart` conforme contrato (`flushPendingUploads`, sem delete em falha)
- [x] T037 [US5] Chamar flush em `lib/core/sync/sync_manager.dart` antes do batch `/sync`
- [x] T038 [US5] Chamar flush no startup em `lib/main.dart` (pós-inicialização DB/auth)
- [x] T039 [US5] Delegar `lib/core/sync/workout_outbox_sync.dart` para `WorkoutDraftSyncService` (compat migration)
- [x] T040 [P] [US5] Criar widget lista de pendentes `lib/features/workout_day/presentation/widgets/pending_workout_drafts_sheet.dart`
- [x] T041 [US5] Expor entrada para lista (badge/botão) em `lib/features/settings/` ou `lib/features/history/` — escolher tela com menor fricção

**Checkpoint**: Cenário 3 do `quickstart.md` passa

---

## Phase 8: User Story 6 — Salvamento contínuo durante execução (Priority: P2)

**Goal**: Refinar auto-save em todas as mutações relevantes (reorder, add exercise, voice)

**Independent Test**: Alterar ordem e adicionar exercício → kill app → dados preservados

### Implementation for User Story 6

- [x] T042 [US6] Hook auto-save em `reorderExercises` e `replaceExercises` em `lib/features/workout_day/presentation/providers/workout_day_provider.dart`
- [x] T043 [US6] Hook auto-save após `updateExerciseExecution` em `lib/features/workout_day/presentation/providers/workout_day_provider.dart`
- [x] T044 [US6] Persistir draft após entrada por voz se aplicável em `lib/features/workout_day/presentation/widgets/voice_input_bottom_sheet.dart` (ou provider chamado por ela)

**Checkpoint**: Cenários de mutação mid-workout do `quickstart.md` passam

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Testes, validação e limpeza

- [x] T045 [P] Unit tests `test/features/workout_day/data/workout_draft_repository_test.dart`
- [x] T046 [P] Unit tests `test/features/workout_day/data/workout_draft_snapshot_mapper_test.dart`
- [x] T047 [P] Unit tests `test/features/workout_day/data/workout_log_service_draft_test.dart`
- [x] T048 [P] Widget test `test/features/home/components/continue_workout_button_test.dart`
- [x] T049 Executar validação manual `specs/005-workout-draft-persistence/quickstart.md` (todos os cenários)
- [x] T050 [P] Atualizar seção workout em `.cursor/rules/specify-rules.mdc` com referência a drafts (pós-implement)

---

## Dependencies & Execution Order

### Phase Dependencies

```text
Phase 1 (Setup)
    ↓
Phase 2 (Foundational) — BLOCKS ALL
    ↓
Phase 3 (US1) — MVP upload failure
    ↓
Phase 4 (US2) ──┐
Phase 5 (US3) ──┼── P1 resume (US2 antes de US3 no mesmo sprint ok)
Phase 6 (US4) ──┘
    ↓
Phase 7 (US5) — P2 reenvio
Phase 8 (US6) — P2 refinamento auto-save (parcial em Phase 2)
    ↓
Phase 9 (Polish)
```

### User Story Dependencies

| Story | Depende de | Independente quando |
|-------|------------|---------------------|
| US1 | Foundational | Finish com API falhando persiste `pendingUpload` |
| US2 | Foundational + T013–T015 | Home Continuar com draft salvo |
| US3 | US2 + resume constructor | Kill app + UI restaurada |
| US4 | US1 + US2 | Transições de status corretas |
| US5 | US1 (`pendingUpload` rows) | Reenvio após API ok |
| US6 | Foundational | Refinos além do debounce base |

### Parallel Opportunities

**Phase 2** (após T006):
```text
T007 entity ∥ T008 interface ∥ T009 datasource ∥ T011 mapper
```

**Phase 4** (US2):
```text
T022 continue_workout_button.dart ∥ (aguardar T012 para T023+)
```

**Phase 7** (US5):
```text
T036 sync_service.dart ∥ T040 pending_workout_drafts_sheet.dart
```

**Phase 9**:
```text
T045 ∥ T046 ∥ T047 ∥ T048
```

---

## Parallel Example: User Story 2

```bash
# Sequência mínima:
# 1. T022 — continue_workout_button.dart (paralelo se Foundational pronto)
# 2. T023–T025 — card + home wiring
# 3. T026 — WorkoutDayScreen.resume shell (detalhe UI em US3)
```

---

## Implementation Strategy

### MVP First (US1 only)

1. Phase 1 + Phase 2 (Foundational)
2. Phase 3 (US1)
3. **VALIDAR**: finalizar com API falhando — dados em `WorkoutDrafts`, snackbar ok
4. Demo/deploy interno

### Entrega P1 completa

1. MVP (acima)
2. Phase 4–6 (US2, US3, US4) — Continuar + resume + estados
3. **VALIDAR**: `quickstart.md` cenários 1–2 + US4

### Entrega completa

1. P1 completa
2. Phase 7–8 (US5, US6)
3. Phase 9 (Polish)

### Parallel Team Strategy

| Dev | Foco após Foundational |
|-----|------------------------|
| A | US1 + US5 (serviços HTTP/sync) |
| B | US2 + US4 (Home + estados) |
| C | US3 + US6 (resume + auto-save refinado) |

---

## Notes

- Backend `iron_log_back_end`: **sem tarefas** nesta feature
- Não deletar rows de draft em falha de upload — só `deleteAfterSuccessfulUpload`
- `WorkoutOutbox`: apenas migration + delegate; sem novos inserts
- Commit sugerido após cada checkpoint de fase
