# Contract: Remediation slices (010)

**Purpose**: Definir o que cada fatia de PR MUST entregar para a feature 010.  
**Related**: [spec.md](../spec.md), [research.md](../research.md), 006 `contracts/riverpod-conventions.md`, 006 `contracts/pr-review-checklist.md`

## Slice rules (all PRs)

1. Prefer **one feature** (or one P1 cluster) per PR  
2. **No UX redesign** — comportamento visível equivalente  
3. Smoke: login → home → start/open workout → history  
4. Update [inventory-status.md](../inventory-status.md) no PR description  
5. Follow [state-patterns.md](./state-patterns.md) + 006 Riverpod conventions  
6. Run greps from [state-enforcement.md](./state-enforcement.md) for touched paths  

## P1 slices — side-effects & listeners

| Slice ID | Scope | Done when |
|----------|-------|-----------|
| `p1-listen-foundation` | Publicar `state-patterns.md`; primeiro `ref.listen` canônico em fluxo real | Doc mergeada; ≥1 listen em auth ou workout_day |
| `p1-auth-listen` | `login_screen.dart` | Remove `_isLoading` duplicado se controller cobre; erros via `ref.listen`; grep login sem ScaffoldMessenger reativo a auth state |
| `p1-workout-day-listen` | `workout_day_screen.dart`, `workout_finish_flow.dart`, `exercise_card.dart` (subset) | Side-effects de AsyncValue via listen; smoke treino OK |
| `p1-routines-listen` | `routines_page.dart`, `session_detail_content.dart` | CRUD feedback via listen ou callback pós-`read` controller |
| `p1-home-sheets-listen` | `rest_day_creation_sheet`, `activity_type_selection_sheet` | Substituir ScaffoldMessenger por listen ou feedback via controller |

## P2 slices — watch/read, setState, lifecycle

| Slice ID | Scope | Done when |
|----------|-------|-----------|
| `p2-routines-watch-read` | `routine_providers.dart`, `exercise_browse_provider.dart` | `ref.read` no wiring; grep watch repo/datasource → 0 nesses arquivos |
| `p2-setstate-workout-day` | footer, sheets, cardio (inventário) | Categoria B/C migrada ou exceção documentada |
| `p2-setstate-routines` | modals, reorder lists | Idem |
| `p2-setstate-creation` | `add_workout_bottom_sheet` | Idem |
| `p2-select-on-touch` | Qualquer arquivo P1/P2 tocado | `.select` ou provider derivado quando rebuild amplo |
| `p2-lifecycle-sheets` | voice_input, rest_day async | `mounted` guard ou Notifier; no setState após await sem guarda |

## P3 slices — docs & exceptions

| Slice ID | Scope | Done when |
|----------|-------|-----------|
| `p3-checklist` | `state-enforcement.md` + agent context | Revisor consegue auditar com quickstart |
| `p3-legacy-session-doc` | `workout_session_screen` | `accepted_exception` no inventário com nota “sem rota produto” |

## Close-out checklist

- [ ] Todos StateDeviationItem `high` = `done` \| `accepted_exception`  
- [ ] SC-002 greps side-effect limpos nas features remediadas  
- [ ] SC-003 grep watch repo em UI = 0  
- [ ] Agent context aponta plano 010  
- [ ] Smoke SC-004 confirmado  
