# Tasks: Auditoria e Organização Clean Architecture

**Input**: Design documents from `/specs/008-clean-architecture-audit/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Não solicitados na spec — greps + smoke (quickstart) são a validação.

**Organization**: Por user story (US1 inventário → US2 P1 remediação → US3 P2 → US4 P3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Paralelo (arquivos diferentes, sem dependência incompleta)
- **[Story]**: [US1]…[US4]
- Paths relativos à raiz do repo `iron_log/`

---

## Phase 1: Setup

**Purpose**: Congelar baseline e tracking da remediação

- [X] T001 Create inventário rastreável `specs/008-clean-architecture-audit/inventory-status.md` com DeviationItems (id, area, priority, status=open) alinhados a `spec.md` + `research.md` R5
- [X] T002 [P] Document in `specs/008-clean-architecture-audit/inventory-status.md` the StateNotifier migration checklist (10 rows from research R5) with status=open
- [X] T003 [P] Add link from `specs/008-clean-architecture-audit/plan.md` Summary to `inventory-status.md` and `contracts/remediation-slices.md`

---

## Phase 2: Foundational

**Purpose**: Regras de verificação compartilhadas (bloqueiam stories)

**⚠️ CRITICAL**: Completar antes das stories de remediação de código

- [X] T004 Copy verification greps from `specs/008-clean-architecture-audit/contracts/layer-enforcement.md` into `specs/008-clean-architecture-audit/quickstart.md` as a “Baseline commands” subsection (paths already correct)
- [X] T005 Confirm canonical routes use only `WorkoutDayScreen` in `lib/core/routes/app_router.dart` and `lib/core/routes/workout_route_locations.dart` (note findings in inventory-status.md)
- [X] T006 [P] List current product exports of `WorkoutSessionScreen` via `rg workout_session_screen lib/` and record hits in `specs/008-clean-architecture-audit/inventory-status.md`

**Checkpoint**: Inventário + greps baseline prontos — remediação pode começar

---

## Phase 3: User Story 1 — Time vê o mapa do que está errado (Priority: P1) 🎯 MVP doc

**Goal**: Inventário claro e usável para priorizar PRs (sem mudança obrigatória de runtime além do tracking).

**Independent Test**: Qualquer dev lista violações high/medium/low e gabarito `routines`/`workout_day` só com `spec.md` + `inventory-status.md`.

### Implementation for User Story 1

- [X] T007 [US1] Fill high-priority rows in `specs/008-clean-architecture-audit/inventory-status.md` with concrete file paths from audit (`lib/features/home/presentation/providers/*.dart`, `workout_session_screen.dart`, HTTP providers em workout_day/routines)
- [X] T008 [P] [US1] Fill medium-priority rows in `specs/008-clean-architecture-audit/inventory-status.md` (`lib/features/auth/` controllers — later moved to `presentation/providers/`, `workout_history`, `workout_creation`, `exercise_tag.dart`, core leaks)
- [X] T009 [P] [US1] Fill low-priority rows in `specs/008-clean-architecture-audit/inventory-status.md` (`lib/features/analytics/`, `lib/features/workout_session/`, `lib/features/routines/presentation/widgets/exercise_search_field.dart`)
- [X] T010 [US1] Add “How to pick next PR” section to `specs/008-clean-architecture-audit/inventory-status.md` mapping items → slice IDs in `contracts/remediation-slices.md`

**Checkpoint**: US1 done — mapa verificável sem depender de código novo

---

## Phase 4: User Story 2 — Remediação alta prioridade (Priority: P1)

**Goal**: `home` com fronteira data; tela legada isolada; HTTP fora da presentation em `home` + `workout_day` + `routines`.

**Independent Test**: Greps SC-003/SC-004 verdes nos paths remediados; smoke login→home→treino→histórico.

### Slice `p1-home-data`

- [X] T011 [US2] Create `lib/features/home/domain/repositories/home_repository.dart` (abstract API for metrics/calendar/rest-day as used by home controllers)
- [X] T012 [P] [US2] Create `lib/features/home/data/datasources/home_remote_datasource.dart` using `HttpService` + `ApiEndpoints` (move calls from presentation)
- [X] T013 [US2] Create `lib/features/home/data/repositories/home_repository_impl.dart` implementing `HomeRepository`
- [X] T014 [US2] Create `lib/features/home/home_providers.dart` with abstract repo provider + `homeProvidersOverrides` pattern (mirror `lib/features/routines/routine_providers.dart`)
- [X] T015 [US2] Register `homeProvidersOverrides` in `lib/main.dart` `ProviderScope.overrides`
- [X] T016 [US2] Refactor `lib/features/home/presentation/providers/home_controller.dart` to use `ref.read(homeRepositoryProvider)` — remove direct `HttpService`/`ApiEndpoints`
- [X] T017 [P] [US2] Refactor `lib/features/home/presentation/providers/home_provider.dart` off `AuthService` onto `HomeRepository`
- [X] T018 [P] [US2] Refactor `lib/features/home/presentation/providers/workout_calendar_provider.dart` onto `HomeRepository`
- [X] T019 [P] [US2] Refactor `lib/features/home/presentation/providers/rest_day_toggle_provider.dart` onto `HomeRepository`
- [X] T020 [US2] Verify `rg "HttpService|ApiEndpoints|AuthService" lib/features/home/presentation` is clean; mark `P1-home-http` done in `inventory-status.md`

### Slice `p1-isolate-session-screen`

- [X] T021 [US2] Remove product export of `WorkoutSessionScreen` from `lib/features/workout_day/workout_day.dart`
- [X] T022 [US2] Move `lib/features/workout_day/presentation/pages/workout_session_screen.dart` to `lib/features/workout_day/presentation/pages/_legacy/workout_session_screen.dart` (or keep path + `@Deprecated` + banner comment per research R3)
- [X] T023 [US2] Ensure `lib/core/routes/app_router.dart` has zero routes to `WorkoutSessionScreen`; only `WorkoutDayScreen` + `WorkoutRouteLocations`
- [X] T024 [US2] Replace any remaining product imports of `WorkoutSessionScreen` under `lib/` (except `_legacy`) with `WorkoutDayScreen` / route helpers
- [X] T025 [US2] Verify SC-004 greps from quickstart; mark isolation item done in `inventory-status.md`

### Slice `p1-http-workout-day`

- [X] T026 [US2] Add remote datasource methods under `lib/features/workout_day/data/datasources/` (new or extend existing) for session load/remove/patch/workout fetch currently in `workout_day_provider.dart`
- [X] T027 [US2] Route `lib/features/workout_day/presentation/providers/workout_day_provider.dart` HTTP through repository/datasource — no raw `HttpService`/`ApiEndpoints` in presentation
- [X] T028 [P] [US2] Extract HTTP from `lib/features/workout_day/presentation/providers/exercise_last_sets_provider.dart` into data layer
- [X] T029 [P] [US2] Extract HTTP from `lib/features/workout_day/presentation/providers/exercise_suggestion_provider.dart` into data layer
- [X] T030 [P] [US2] Extract HTTP from `lib/features/workout_day/presentation/providers/create_activity_provider.dart` into data layer
- [X] T031 [P] [US2] Extract Auth/HTTP usage from `lib/features/workout_day/presentation/providers/workout_draft_providers.dart` into data/DI boundary
- [X] T032 [US2] Reduce direct `AuthService` coupling in `lib/features/workout_day/presentation/providers/voice_input_provider.dart` (user id via auth/domain boundary)
- [X] T033 [US2] Verify presentation HTTP greps for `lib/features/workout_day/presentation`; update inventory

### Slice `p1-http-routines`

- [X] T034 [US2] Move browse/create exercise remote calls out of `lib/features/routines/presentation/providers/exercise_browse_provider.dart` into `lib/features/routines/data/`
- [X] T035 [US2] Refactor `lib/features/routines/presentation/widgets/create_exercise_modal.dart` to use repository/controller — no `AuthService`/`ApiEndpoints` in widget
- [X] T036 [US2] Refactor active-routine PATCH out of `lib/features/routines/presentation/pages/routines_page.dart` into repository/controller
- [X] T037 [US2] Verify `rg "HttpService|ApiEndpoints|AuthService" lib/features/routines/presentation` (allow only files deferred to US4 delete of `exercise_search_field.dart` if still present); update inventory

**Checkpoint**: US2 / P1 runtime remediação completa — SC-003 + SC-004

---

## Phase 5: User Story 3 — Features parciais + StateNotifier (Priority: P2)

**Goal**: Alinhar auth/history/creation/onboarding/domain/core; migrar todos StateNotifiers inventariados.

**Independent Test**: Estrutura mínima por feature; `rg StateNotifier` zero nos paths da lista R5.

### Auth / history / structure

- [X] T038 [US3] Move `lib/features/auth/auth_controller.dart` + `auth_controller.g.dart` + `auth_state.dart` to `lib/features/auth/presentation/providers/` and fix imports/`auth.dart` barrel
- [X] T039 [US3] Remove direct HTTP from `lib/features/auth/presentation/pages/login_screen.dart` (controller/repository only)
- [X] T040 [US3] Deduplicate `lib/features/auth/utils/logout_utils.dart` vs `lib/features/auth/presentation/utils/logout_utils.dart` (single path under presentation)
- [X] T041 [US3] Create `lib/features/workout_history/workout_history_providers.dart` (overrides pattern) and stop wiring datasources inside `lib/features/workout_history/presentation/providers/workout_history_provider.dart`
- [X] T042 [US3] Register workout history overrides in `lib/main.dart` if not already
- [X] T043 [P] [US3] Document or complete data boundary for `lib/features/workout_creation/` in `inventory-status.md` (UI-only over routines vs thin adapters) and align folders `components/` vs `widgets/` only as needed
- [X] T044 [P] [US3] Document or complete data boundary for `lib/features/onboarding/`; delete orphan page file if present under `lib/features/onboarding/presentation/pages/`
- [X] T045 [US3] Remove Flutter `Color` from `lib/features/workout_day/domain/entities/exercise_tag.dart`; map colors in presentation styles/mapper
- [X] T046 [US3] Resolve core→feature leaks noted in inventory (`lib/core/services/auth_service.dart`, `lib/core/providers/sync_providers.dart`, `lib/core/components/exercise_search/`) per research R9 — document decision in inventory-status.md

### StateNotifier migrations (one cluster per task; [P] only when files don’t conflict)

- [X] T047 [US3] Migrate `WorkoutTimerNotifier` in `lib/features/workout_day/presentation/providers/workout_timer_provider.dart` to `@riverpod` Notifier; run build_runner
- [X] T048 [US3] Migrate `WorkoutController` in `lib/features/workout_day/presentation/controllers/workout_controller.dart` to `@riverpod` Notifier/`AsyncNotifier` (AsyncValue state OK); run build_runner; fix call sites
- [X] T049 [US3] Migrate `VoiceInputNotifier` in `lib/features/workout_day/presentation/providers/voice_input_provider.dart` to AsyncNotifier/Notifier; run build_runner
- [X] T050 [US3] Migrate `WorkoutDayExercisesNotifier` in `lib/features/workout_day/presentation/providers/workout_day_provider.dart` to AsyncNotifier; run build_runner; fix overrides/tests
- [X] T051 [P] [US3] Migrate `WorkoutCreationNotifier` in `lib/features/workout_creation/presentation/providers/workout_creation_provider.dart`
- [X] T052 [P] [US3] Migrate `WorkoutNotifier` in `lib/features/home/presentation/providers/workout_provider.dart`
- [X] T053 [P] [US3] Migrate `SessionNotifier` in `lib/features/routines/presentation/providers/session_provider.dart`
- [X] T054 [P] [US3] Migrate `SessionExerciseSelectionNotifier` in `lib/features/routines/presentation/providers/session_selection_provider.dart`
- [X] T055 [P] [US3] Migrate `ExerciseSearchNotifier` in `lib/core/components/exercise_search/unified_exercise_search.dart`
- [X] T056 [P] [US3] Migrate `SyncStateNotifier` in `lib/core/providers/sync_providers.dart`
- [X] T057 [US3] Verify `rg "StateNotifierProvider|extends StateNotifier"` on inventário paths is clean (SC-007); mark all R5 rows done in `inventory-status.md`

**Checkpoint**: US3 complete

---

## Phase 6: User Story 4 — Limpeza stubs/órfãos (Priority: P3)

**Goal**: Remover stubs e código morto para ninguém copiar exemplo errado.

**Independent Test**: Pastas/arquivos ausentes; imports zero; UnifiedExerciseSearch permanece.

- [X] T058 [US4] Confirm zero product imports of `lib/features/analytics/` then delete the directory
- [X] T059 [P] [US4] Confirm zero product imports of `lib/features/workout_session/` then delete the directory
- [X] T060 [US4] Remove deprecated `lib/features/routines/presentation/widgets/exercise_search_field.dart` and any `exercise_search_section` that only wraps it; ensure `UnifiedExerciseSearch` remains the path
- [X] T061 [P] [US4] Remove stale references to deleted stubs from docs / `.cursor/rules/specify-rules.mdc` / architecture README if paths still cited as existing
- [X] T062 [US4] Optionally unify dual organism roots / loose styles under `lib/features/workout_day/presentation/` only if touching those files in this PR; mark cosmetic item done or accepted_exception in inventory

**Checkpoint**: US4 / P3 complete

---

## Phase 7: Polish & Close-out

**Purpose**: Fechar inventário e validar quickstart

- [X] T063 Run full close-out greps from `specs/008-clean-architecture-audit/quickstart.md` and paste results into `inventory-status.md`
- [ ] T064 [P] Smoke manual SC-005 (login → home → workout → history) and note in `inventory-status.md`
- [X] T065 Ensure every DeviationItem status is `done` or `accepted_exception` in `inventory-status.md` (SC-001)
- [X] T066 [P] Update `specs/008-clean-architecture-audit/spec.md` Status to reflect implementation readiness / done when inventory closed
- [X] T067 Run `flutter analyze` on touched features and fix regressions introduced by remediação

---

## Phase 8: Analyze remediação + Reactivity follow-up (pós `/speckit-analyze`)

**Purpose**: Fechar buracos C1–C3/A1 encontrados na analyze; documentar U1 (reatividade) sem bloquear SC-001.

### Leak fixes (bloqueiam greps SC-003 ampliados)

- [X] T068 [P] Delete dead HTTP presentation `lib/features/routines/presentation/providers/routine_history_provider.dart` (+ DTO só usado por ele) — C1
- [X] T069 [P] Move Google Sign-In out of `lib/features/auth/presentation/pages/login_screen.dart` into `AuthController.signInWithGoogle` — C2
- [X] T070 Route `userProfileProvider` through `AuthRepository.getUserProfile` / `AuthRemoteDataSource` (no `AuthService()` in presentation) — C3
- [X] T071 Widen verification greps in `quickstart.md` + `contracts/layer-enforcement.md` to include `\bhttpServiceProvider\b` + separate `GoogleAuthService` page/widget checks — A1

### Reactivity (U1 — open; não bloqueia close-out 008)

- [X] T072 [P] Inventory reactivity hotspots in `inventory-status.md` (Home multi-watch, DI `ref.watch` repos) — seeded as RX-*
- [X] T073 Narrow `HomePage` watches with `.select` / child `Consumer` without changing product logic
- [X] T074 Prefer `ref.read` for repository/`HttpService` DI in feature `*_providers.dart` / Notifier `build` where safe (mirror `home_providers.dart`)

**Note**: T073–T074 MAY ship in a follow-up PR or feature; 008 Assumption keeps inputs/performance orthogonal to layer remediação.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** → sem deps
- **Foundational (Phase 2)** → Setup
- **US1 (Phase 3)** → Foundational (só docs/inventário)
- **US2 (Phase 4)** → Foundational; pode seguir US1 em paralelo se inventário mínimo já existir
- **US3 (Phase 5)** → Preferir após US2 data-layer nas mesmas features (evita migrar StateNotifier ainda cheio de HTTP)
- **US4 (Phase 6)** → Pode começar cedo se imports=0, mas `exercise_search_field` delete após HTTP routines (T037)
- **Polish (Phase 7)** → após US2–US4 desejados

### User Story Dependencies

- **US1**: Independente (MVP documental)
- **US2**: Independente de US3/US4; bloqueia qualidade de migrações StateNotifier em workout_day/home/routines
- **US3**: Depende parcialmente de US2 para providers HTTP pesados
- **US4**: Independente exceto busca deprecada após T037

### Parallel Opportunities

- T002/T003; T008/T009
- T017–T019 (home providers) após T016
- T028–T031 (workout_day HTTP) após datasource base T026–T027
- T051–T056 (StateNotifiers em features diferentes) em paralelo por dev
- T058/T059 deletes de stubs

---

## Parallel Example: User Story 2 (home providers)

```bash
# Após T016 (home_controller):
Task: "Refactor home_provider.dart onto HomeRepository"
Task: "Refactor workout_calendar_provider.dart onto HomeRepository"
Task: "Refactor rest_day_toggle_provider.dart onto HomeRepository"
```

## Parallel Example: User Story 3 (StateNotifier)

```bash
# Features distintas, após data-layer P1:
Task: "Migrate WorkoutCreationNotifier"
Task: "Migrate WorkoutNotifier (home)"
Task: "Migrate SessionNotifier"
Task: "Migrate SyncStateNotifier"
```

---

## Implementation Strategy

### MVP First (US1)

1. Phase 1–2  
2. Phase 3 US1 inventário  
3. **STOP** — time já sabe o que corrigir  

### Incremental delivery (recommended)

1. US1 mapa  
2. US2 P1 (`home` → isolate screen → HTTP workout_day → HTTP routines) — PRs por slice  
3. US3 structure + StateNotifier (1 notifier / PR)  
4. US4 deletes  
5. Polish close-out greps + smoke  

### Suggested PR sequence

1. `p1-home-data` (T011–T020)  
2. `p1-isolate-session-screen` (T021–T025)  
3. `p1-http-workout-day` (T026–T033)  
4. `p1-http-routines` (T034–T037)  
5. `p2-auth` / `p2-history` / domain / core (T038–T046)  
6. StateNotifier PRs (T047–T056)  
7. P3 deletes (T058–T061)  
8. Close-out (T063–T067)  

---

## Notes

- Sem tasks de teste automatizado (spec não pediu TDD); validação = greps + smoke quickstart  
- `[P]` só quando arquivos não colidem  
- Commit por task ou por slice de `remediation-slices.md`  
- FR-011: sem redesign de UX nestas tasks  
- Exceção constituição StateNotifier: escopo completo, PRs pequenos (Complexity Tracking no plan)
