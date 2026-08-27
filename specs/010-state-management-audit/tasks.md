# Tasks: Auditoria e Padronização de Gerenciamento de Estado

**Input**: Design documents from `/specs/010-state-management-audit/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Não solicitados na spec — greps + smoke (quickstart) são a validação principal.

**Organization**: Por user story (US1 inventário → US2 side-effects P1 → US3 watch/read P2 → US4 setState/lifecycle P2 → US5 checklist P3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Paralelo (arquivos diferentes, sem dependência incompleta)
- **[Story]**: [US1]…[US5]
- Paths relativos à raiz do repo `iron_log/`

---

## Phase 1: Setup

**Purpose**: Congelar baseline e tracking da remediação de estado

- [X] T001 Confirm `specs/010-state-management-audit/inventory-status.md` lists all high/medium/low StateDeviationItems from `spec.md` with slice IDs and status=open
- [X] T002 [P] Confirm links in `specs/010-state-management-audit/plan.md` Summary to `inventory-status.md`, `contracts/remediation-slices.md`, and `contracts/state-patterns.md`
- [X] T003 [P] Confirm `specs/010-state-management-audit/contracts/state-patterns.md` and `contracts/state-enforcement.md` exist and reference 006 `contracts/riverpod-conventions.md`

---

## Phase 2: Foundational

**Purpose**: Baseline greps e gabaritos — bloqueia remediação de código

**⚠️ CRITICAL**: Completar antes das user stories de remediação

- [X] T004 Run baseline greps G1–G6 from `specs/010-state-management-audit/contracts/state-enforcement.md`; record counts in `specs/010-state-management-audit/inventory-status.md` Baseline section
- [X] T005 Verify `lib/features/auth/presentation/providers/` exposes `AsyncValue` suitable for `ref.listen` on login errors (inspect auth controller); note gaps in inventory if controller needs adjustment before US2
- [X] T006 [P] Document reference patterns REF-home-template, REF-workout-timer, REF-state-patterns in `specs/010-state-management-audit/inventory-status.md` with absolute lib paths
- [X] T007 Confirm `specs/010-state-management-audit/quickstart.md` per-slice validation table matches `contracts/state-enforcement.md`

**Checkpoint**: Baseline medido — remediação pode começar

---

## Phase 3: User Story 1 — Time vê mapa de problemas de estado (Priority: P1) 🎯 MVP doc

**Goal**: Inventário verificável com evidência por arquivo para priorizar PRs.

**Independent Test**: Dev lista hotspots `high` + gabarito a copiar só com `spec.md` + `inventory-status.md` + `contracts/state-patterns.md`.

### Implementation for User Story 1

- [X] T008 [US1] Run `rg "AppSnackbar\.|ScaffoldMessenger\.of" lib/features --glob "**/presentation/**"` and add file:line evidence to high-priority rows in `specs/010-state-management-audit/inventory-status.md`
- [X] T009 [P] [US1] Run `rg -l "setState\(" lib/features --glob "**/presentation/**"` and map each file to category (`ephemeral_ui` / `mirrors_provider` / `domain_local`) in `specs/010-state-management-audit/inventory-status.md` medium rows
- [X] T010 [P] [US1] Run G3/G4 greps for `ref.watch` on Repository/DataSource; confirm 2 hits in `lib/features/routines/routine_providers.dart` and `lib/features/routines/presentation/providers/exercise_browse_provider.dart` in inventory
- [X] T011 [US1] Add `category` column to inventory tables aligning with `specs/010-state-management-audit/data-model.md` (`side_effect`, `watch_read`, `setstate_boundary`, `lifecycle`, `select_rebuild`)
- [X] T012 [US1] Verify "How to pick next PR" + slice mapping in `specs/010-state-management-audit/inventory-status.md` covers every open high item

**Checkpoint**: US1 done — mapa auditável sem depender de código remediado

---

## Phase 4: User Story 2 — Side-effects e feedback fora do `build` (Priority: P1)

**Goal**: `ref.listen` + `AppSnackbar` nos fluxos críticos; zero side-effect reativo proibido no `build`.

**Independent Test**: Login, treino e rotinas disparam feedback via listener; G1 ≥1 match por cluster remediado; smoke login→home→treino OK.

### Slice `p1-listen-foundation`

- [X] T013 [US2] Validate Pattern 1 in `specs/010-state-management-audit/contracts/state-patterns.md` against real `AuthController` API; update doc examples if provider names differ

### Slice `p1-auth-listen`

- [X] T014 [US2] Add `ref.listen` on auth controller in `lib/features/auth/presentation/pages/login_screen.dart` for `AsyncError` / success feedback per `contracts/state-patterns.md`
- [X] T015 [US2] Remove duplicate `_isLoading` / local loading flags from `lib/features/auth/presentation/pages/login_screen.dart`; derive UI loading from `ref.watch(authControllerProvider)` (or equivalent)
- [X] T016 [US2] Remove imperative `ScaffoldMessenger` calls tied to auth async state from `lib/features/auth/presentation/pages/login_screen.dart`
- [X] T017 [US2] Run G1 on `lib/features/auth`; mark `SM-auth-login` done in `specs/010-state-management-audit/inventory-status.md`

### Slice `p1-workout-day-listen`

- [X] T018 [US2] Add `ref.listen` for workout-related providers in `lib/features/workout_day/presentation/pages/workout_day_screen.dart`; migrate reactive snackbars off bare `build` logic
- [X] T019 [P] [US2] Refactor side-effects in `lib/features/workout_day/presentation/controllers/workout_finish_flow.dart` to listener at call site or controller-only navigation without orphan ScaffoldMessenger
- [X] T020 [P] [US2] Refactor reactive `ScaffoldMessenger`/`AppSnackbar` in `lib/features/workout_day/presentation/organisms/exercise_card.dart` to `ref.listen` where tied to provider state
- [X] T021 [US2] Run G1 on `lib/features/workout_day`; smoke treino; mark `SM-workout-day-screen`, `SM-workout-finish`, `SM-exercise-card` done in `inventory-status.md`

### Slice `p1-routines-listen`

- [X] T022 [US2] Add `ref.listen` / migrate snackbars in `lib/features/routines/presentation/pages/routines_page.dart` for CRUD feedback
- [X] T023 [P] [US2] Refactor side-effects in `lib/features/routines/presentation/widgets/session_detail_content.dart` to listener or post-controller callback pattern
- [X] T024 [US2] Run G1 on `lib/features/routines`; mark `SM-routines-page`, `SM-session-detail` done in `inventory-status.md`

### Slice `p1-home-sheets-listen`

- [X] T025 [P] [US2] Refactor `lib/features/home/presentation/components/molecules/rest_day_creation_sheet.dart` — controller feedback + `ref.listen` or parent listener; remove reactive ScaffoldMessenger
- [X] T026 [P] [US2] Refactor `lib/features/home/presentation/components/molecules/activity_type_selection_sheet.dart` similarly
- [X] T027 [US2] Mark `SM-home-sheets` done; verify G2 count decreased for `lib/features/home/presentation`

### US2 close

- [X] T028 [US2] Confirm G1 shows `ref.listen` in auth, workout_day, routines, home clusters; mark `SM-se-no-listen` done in `inventory-status.md`

**Checkpoint**: US2 / P1 side-effects — SC-002 em paths remediados

---

## Phase 5: User Story 3 — Rebuild mínimo e fronteira watch/read (Priority: P2)

**Goal**: `ref.read` em DI wiring; `.select` ao tocar telas remediadas.

**Independent Test**: G4 → 0 em `*_providers.dart` routines; G3 → 0 em UI layers; rebuilds óbvios reduzidos nos arquivos tocados.

### Slice `p2-routines-watch-read`

- [X] T029 [US3] Replace `ref.watch` with `ref.read` in `lib/features/routines/routine_providers.dart` repository override wiring (line ~54)
- [X] T030 [US3] Replace `ref.watch(exerciseRemoteDataSourceProvider)` with `ref.read` in `lib/features/routines/presentation/providers/exercise_browse_provider.dart` unless watch is required for cache invalidation — document if kept
- [X] T031 [US3] Run G4; mark `SM-watch-routine-providers`, `SM-watch-exercise-browse` done in `inventory-status.md`

### Slice `p2-select-on-touch`

- [X] T032 [P] [US3] Apply `ref.watch(...select(...))` or derived `@riverpod` provider in `lib/features/routines/presentation/pages/routines_page.dart` for fields that caused wide rebuilds
- [X] T033 [P] [US3] Apply `.select` or child Consumer pattern in `lib/features/workout_day/presentation/pages/workout_day_screen.dart` for partial UI updates
- [X] T034 [US3] Update `SM-select-coverage` status in `inventory-status.md` for files touched (home already done per 008 — note, don't rework)

**Checkpoint**: US3 — SC-003 UI + G4 wiring clean

---

## Phase 6: User Story 4 — Ciclo de widget e fronteira setState/Riverpod (Priority: P2)

**Goal**: setState restante é efêmero ou migrado; async seguro após dispose.

**Independent Test**: Cada arquivo com setState tem entrada no inventário com resolução; G5 files migrated or `accepted_exception`.

### Slice `p2-setstate-workout-day`

- [X] T035 [US4] Audit `lib/features/workout_day/presentation/organisms/footer_actions.dart` — migrate domain state to notifier or document `ephemeral_ui` exception in `inventory-status.md`
- [X] T036 [P] [US4] Audit `lib/features/workout_day/presentation/pages/cardio_creation_page.dart` setState vs provider boundary
- [X] T037 [P] [US4] Audit `lib/features/workout_day/presentation/components/organisms/session_exercises_sheet.dart` setState vs provider boundary
- [X] T038 [US4] Mark `SM-setstate-workout-day`, `SM-footer-actions` done or `accepted_exception` in `inventory-status.md`

### Slice `p2-setstate-routines`

- [ ] T039 [P] [US4] Audit `lib/features/routines/presentation/widgets/create_exercise_modal.dart` — migrate persisted state to controller or document exception
- [ ] T040 [P] [US4] Audit `lib/features/routines/presentation/widgets/reorderable_session_list.dart` — drag/reorder may stay local with justification
- [ ] T041 [US4] Mark `SM-setstate-routines` done in `inventory-status.md`

### Slice `p2-setstate-creation`

- [ ] T042 [US4] Audit `lib/features/workout_creation/presentation/widgets/organisms/add_workout_bottom_sheet.dart` — mutations via controller, not setState-only
- [ ] T043 [US4] Mark `SM-setstate-creation` done in `inventory-status.md`

### Slice `p2-lifecycle-sheets`

- [ ] T044 [P] [US4] Add `context.mounted` guards or Notifier-side completion in `lib/features/workout_day/presentation/widgets/voice_input_bottom_sheet.dart` async callbacks
- [ ] T045 [US4] Mark `SM-lifecycle-sheets`, `SM-voice-input` done in `inventory-status.md`

**Checkpoint**: US4 — setState inventory resolved or excepted

---

## Phase 7: User Story 5 — Revisor e código novo seguem o padrão (Priority: P3)

**Goal**: Checklist de PR publicado e ligado ao fluxo de review.

**Independent Test**: Revisor audita PR típico em <10 min com `state-enforcement.md` + quickstart greps.

### Implementation for User Story 5

- [X] T046 [US5] Add cross-reference from `specs/006-flutter-architecture-standard/contracts/pr-review-checklist.md` to `specs/010-state-management-audit/contracts/state-enforcement.md` (estado section)
- [X] T047 [US5] Mark `SM-checklist-doc` done in `inventory-status.md`; confirm SC-005 checklist complete
- [X] T048 [US5] Confirm `SM-legacy-session` is `accepted_exception` for `lib/features/workout_day/presentation/pages/workout_session_screen.dart` (or `_legacy/` path) with "sem rota produto" note in `inventory-status.md`

**Checkpoint**: US5 — review process documented

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Close-out SC-001–SC-006

- [ ] T049 Run full validation from `specs/010-state-management-audit/quickstart.md` (G1–G6 + close-out checklist); tick items in `inventory-status.md`
- [ ] T050 [P] Run `flutter analyze lib/features/auth lib/features/home lib/features/workout_day lib/features/routines lib/features/workout_creation` — zero new errors
- [ ] T051 Execute smoke SC-004 (login → home → treino → histórico); record pass/fail in `specs/010-state-management-audit/inventory-status.md`
- [X] T052 Update `.cursor/rules/specify-rules.mdc` active plan to reference `specs/010-state-management-audit/tasks.md` when implementation starts
- [ ] T053 Verify 100% high-severity items `done` or `accepted_exception`; mark feature close-out in `inventory-status.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies
- **Foundational (Phase 2)**: Depends on Setup — **blocks** US2–US5 code changes
- **US1 (Phase 3)**: Depends on Foundational; can overlap with early US2 doc task T013
- **US2 (Phase 4)**: Depends on Foundational + US1 evidence (T008–T012 recommended before code)
- **US3 (Phase 5)**: Depends on Foundational; **best after US2** for same files (listen first, then select)
- **US4 (Phase 6)**: Depends on Foundational; may parallel US3 on different files
- **US5 (Phase 7)**: Depends on US2 patterns existing (T014+ as reference)
- **Polish (Phase 8)**: Depends on US2–US5 completion

### User Story Dependencies

| Story | Depends on | Independent test |
|-------|------------|------------------|
| US1 | Phase 2 | Inventory + greps documented |
| US2 | US1 (recommended), Phase 2 | G1 + smoke login/treino/rotinas |
| US3 | Phase 2; after US2 on same files | G3, G4 |
| US4 | Phase 2 | G5 + inventory exceptions |
| US5 | US2 gabarito | Checklist cross-link |

### Parallel Opportunities

**After Phase 2 completes:**

```text
US1: T009 ∥ T010
US2: T019 ∥ T020 ∥ T023 ∥ T025 ∥ T026 (different files)
US3: T032 ∥ T033
US4: T036 ∥ T037 ∥ T039 ∥ T040 ∥ T044
Polish: T050 ∥ (other non-analyze tasks)
```

**Per slice PR strategy** (one feature/cluster per PR):

1. `p1-auth-listen` → T014–T017  
2. `p1-workout-day-listen` → T018–T021  
3. `p1-routines-listen` → T022–T024  
4. `p1-home-sheets-listen` → T025–T027  
5. `p2-routines-watch-read` → T029–T031  
6. `p2-setstate-*` / `p2-lifecycle-*` → T035–T045  

---

## Parallel Example: User Story 2

```bash
# After T018 (workout_day_screen listen), in parallel:
# T019 workout_finish_flow.dart
# T020 exercise_card.dart
# T023 session_detail_content.dart
# T025 rest_day_creation_sheet.dart
# T026 activity_type_selection_sheet.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Phase 1 + Phase 2  
2. Phase 3 (US1) — inventário com evidência  
3. **STOP** — time pode priorizar PRs com mapa claro  

### Recommended delivery

1. Setup + Foundational + US1 → baseline locked  
2. US2 slice `p1-auth-listen` → primeiro `ref.listen` real (T014–T017)  
3. US2 remaining P1 slices → smoke  
4. US3 + US4 in parallel on different features  
5. US5 checklist + Polish close-out  

### Suggested first code PR

**Slice `p1-auth-listen` (T014–T017)** — menor superfície, prova o padrão `state-patterns.md` antes de `workout_day`.

---

## Notes

- Não reabrir remediação 008 (HTTP layers, StateNotifier) — G6 MUST stay 0  
- `WorkoutSessionScreen` — não bloquear close-out (T048 exception)  
- Widget tests opcionais nos hotspots P1 — não listados como tasks bloqueantes  
- Marcar `done` no inventário só com evidência grep ou PR mergeado  
- Commit após cada slice; smoke após cada fatia P1+
