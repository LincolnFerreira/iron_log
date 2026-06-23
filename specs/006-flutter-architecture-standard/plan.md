# Implementation Plan: Padrão Arquitetural Flutter — Iron Log

**Branch**: `006-flutter-architecture-standard` | **Date**: 2026-06-23 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/006-flutter-architecture-standard/spec.md`

## Summary

Formalizar e **implementar incrementalmente** o padrão arquitetural do app Flutter: Clean Architecture por feature (`domain` / `data` / `presentation`), Riverpod 3 com `AsyncNotifier` + `read`/`watch` corretos, GoRouter para shell, offline-first inalterado, e migração faseada do legado (pastas, `StateNotifier`, endpoints duplicados, navegação imperativa de treino). **Sem big bang** — uma feature ou um conjunto pequeno de arquivos por PR.

Entregáveis desta feature são **governança + refactors incrementais**, não reescrita do app. Código novo segue o padrão imediatamente; legado migra ao ser tocado ou em PRs dedicados pequenos.

## Technical Context

**Language/Version**: Dart ^3.8 / Flutter 3.8+

**Primary Dependencies**: `flutter_riverpod` ^2.6, `riverpod_annotation` + `riverpod_generator`, `go_router` ^16, `dio` ^5.8, Drift ^2.14, Firebase Auth/Crashlytics, `equatable`

**Storage**: Drift em `lib/core/database/` (schema v4+); sem mudança de schema nesta feature

**Testing**: `flutter_test` (unit/widget com `getTestProviderOverrides()`), Patrol E2E em `integration_test/`; adicionar smoke de estrutura/grep em CI opcional

**Target Platform**: Android + iOS mobile-first (Iron Log cliente)

**Project Type**: Flutter app (`iron_log`); backend `iron_log_back_end` **sem mudanças**

**Performance Goals**: refactors de pasta não devem alterar comportamento runtime; `ProviderObserver` só em `kDebugMode`

**Constraints**: offline-first NON-NEGOTIABLE; migração incremental; pt-BR; zero `StateNotifier` novo; proibido rewrite massivo de providers

**Scale/Scope**: 8 features ativas + `core/`; ~14 arquivos com `StateNotifier` legado; 6 fases de migração; 13 divergências catalogadas na spec

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Verify against `.specify/memory/constitution.md` (Iron Log v1.2.2):

- [x] **Offline-first**: plano não altera sync/outbox; refactors estruturais only
- [x] **Feature layers**: alinha código ao padrão `routines` / `workout_day`
- [x] **Riverpod**: AsyncNotifier código novo; legado StateNotifier migra gradualmente
- [x] **Core reuse**: consolida `api_endpoints.dart`; mantém `HttpService`, `AppSnackbar`
- [x] **Product scope**: sem social/web; preserva plano vs execução workout
- [x] **Tests**: quickstart valida grep + estrutura + E2E existentes verdes

**Post-design re-check**: ✅ Passed — migração respeita exceção temporária `Navigator.push` para treino até Fase 4; documentada em Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/006-flutter-architecture-standard/
├── plan.md              # This file
├── research.md          # Phase 0 — decisões DP-01..04 + Riverpod
├── data-model.md        # Phase 1 — entidades de governança arquitetural
├── quickstart.md        # Phase 1 — validação de conformidade
├── contracts/
│   ├── layer-boundaries.md
│   ├── riverpod-conventions.md
│   ├── folder-structure.md
│   └── pr-review-checklist.md
└── tasks.md             # Phase 2 (/speckit-tasks — not yet)
```

### Source Code (repository root) — touch map por fase

```text
iron_log/
├── lib/
│   ├── main.dart                              # Fase 5: ProviderObserver (debug)
│   ├── app_widget.dart
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_endpoints.dart             # Fase 1: canônico — absorver endpoints.dart
│   │   │   └── endpoints.dart                 # Fase 1: deprecate → re-export → delete
│   │   ├── routes/
│   │   │   ├── app_router.dart                # Fase 1: remove prints; Fase 4: workout routes
│   │   │   └── route_names.dart               # Fase 4: WorkoutRouteParams
│   │   └── providers/                         # Fase 5: codegen keepAlive gradual
│   └── features/
│       ├── auth/                              # Fase 3: utils → domain/presentation
│       ├── home/                              # Fase 2: maior refactor estrutural
│       ├── onboarding/                        # Fase 2
│       ├── routines/                          # Fase 2: bloc/ → providers/
│       ├── workout_day/                       # Fase 2+4+5: data/providers, GoRouter, AsyncNotifier
│       ├── workout_history/                   # Fase 3
│       ├── workout_creation/                  # Fase 2
│       └── settings/                          # Fase 3: IronTokens → AppTheme
├── test/helpers/test_providers_setup.dart     # Estender conforme novos overrides
├── integration_test/                          # Fase 4: rotas workout — must stay green
├── .cursor/rules/specify-rules.mdc            # Fase 0: agent context (done)
├── docs/architecture/                         # Fase 0: opcional — link para spec
└── pubspec.yaml                               # Fase 6: remove provider/bloc

iron_log_back_end/                             # NO CHANGES
```

**Structure Decision**: Feature-first Clean Architecture já parcialmente presente; este plano **normaliza** desvios sem criar camada global `lib/domain`. Referência canônica permanece `routines/` + `workout_day/`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| `Navigator.push` para `WorkoutDayScreen` até Fase 4 | Migração GoRouter de tela crítica (E2E, offline, timer) é alto risco em um PR | Migrar tudo agora quebraria Patrol e fluxos start/finish; Fase 4 dedicada com rota `/workout` |
| Manter `StateNotifier` legado temporariamente | ~14 arquivos em produção; rewrite único = regressão | Constituição e spec exigem migração arquivo a arquivo |
| `endpoints.dart` re-export temporário na Fase 1 | Evita quebrar imports em um único commit | Delete imediato forçaria PR gigante |

## Migration Phases (implementation roadmap)

| Fase | Escopo | PR strategy | Done when |
|------|--------|-------------|-----------|
| **0** | Governança: spec, plan, contracts, agent context, PR checklist | 1 PR docs | Time pode revisar com checklist |
| **1** | Core higiene: `api_endpoints`, router prints, `endpoints.dart` deprecate | 1 PR pequeno | Grep: zero novos imports `endpoints.dart` |
| **2** | Pastas: home, onboarding, routines, workout_creation, workout_day | **1 feature = 1 PR** | Zero `state/`, `bloc/` nas features migradas |
| **3** | Camadas: settings, workout_history, auth utils | 1–2 PRs | History sem Dio direto na presentation |
| **4** | GoRouter workout + deprecate `WorkoutSessionScreen` | 1 PR + E2E fix | Patrol verde; uma tela execução |
| **5** | Riverpod moderno: observer, AsyncNotifier ao tocar arquivo | Contínuo em PRs de produto | Zero StateNotifier **novo**; observer em debug |
| **6** | `pubspec` cleanup: provider, bloc | 1 PR após grep zero | `flutter pub get` + CI verde |

### Fase 4 — Workout GoRouter (DP-01 resolvido)

Rota proposta:

```text
/workout/execution?routineId=&sessionId=     # create ao vivo
/workout/manual?manualDate=&routineId=       # retroativo
/workout/edit/:workoutId                     # edição histórico
/workout/resume/:draftId                     # resume draft (005)
```

Factory constructors `WorkoutDayScreen.create/edit/manual/resume` delegam parsing de `GoRouterState` — minimiza mudança interna da tela.

### Fase 5 — StateNotifier inventory (migrar gradualmente)

| Arquivo | Prioridade migração |
|---------|---------------------|
| `auth/auth_state.dart` | Alta — tocar em Fase 3 auth |
| `workout_day/.../workout_day_provider.dart` | Média — só com PR workout |
| `home/state/home_provider.dart` | Alta — após Fase 2 home |
| `routines/.../routine_provider.dart` | Média — após rename bloc/ |
| Demais (`voice_input`, `session_provider`, etc.) | Baixa — ao tocar feature |

## Phase 0 / 1 Artifacts

| Artifact | Path | Status |
|----------|------|--------|
| Research | [research.md](./research.md) | ✅ |
| Data model | [data-model.md](./data-model.md) | ✅ |
| Contracts | [contracts/](./contracts/) | ✅ |
| Quickstart | [quickstart.md](./quickstart.md) | ✅ |

## Next Step

Run `/speckit-tasks` to generate dependency-ordered `tasks.md` for phased implementation.
