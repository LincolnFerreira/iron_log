# Implementation Plan: Auditoria e Padronização de Gerenciamento de Estado

**Branch**: `010-state-management-audit` | **Date**: 2026-08-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/010-state-management-audit/spec.md`

**Note**: Remediação de **uso prático** de Riverpod, side-effects e ciclo de widget — complementa 006 (padrão) e 008 (camadas + StateNotifier + RX parcial em `home`). Sem mudança de API backend ou schema Drift.

## Summary

Auditar anti-padrões de estado no app Flutter, inventariar por feature/severidade e corrigir incrementalmente: introduzir `ref.listen` como padrão único de side-effect; eliminar snackbars reativos soltos; corrigir `ref.watch` em DI; documentar fronteira `setState`/Riverpod; ampliar `.select` ao tocar telas.

**Baseline medido (2026-08-27)**:

| Métrica | Valor atual | Meta close-out |
|---------|-------------|----------------|
| `ref.listen` em `lib/` | 0 | ≥1 por fluxo P1 remediado; 0 side-effects proibidos no `build` |
| `AppSnackbar` / `ScaffoldMessenger` em `lib/features` | ~62 call sites | P1: fluxos críticos via listener; demais migrados ou exceção |
| Arquivos com `setState` em features | 20 | Negócio migrado ou exceção documentada |
| `ref.watch` em repo/datasource wiring | 2 (`routines`) | 0 (exceto exceções inventário) |

**Tracking**: [inventory-status.md](./inventory-status.md) · **Slices**: [contracts/remediation-slices.md](./contracts/remediation-slices.md) · **Gabarito**: [contracts/state-patterns.md](./contracts/state-patterns.md)

## Technical Context

**Language/Version**: Dart ^3.8 / Flutter 3.8+

**Primary Dependencies**: flutter_riverpod 3 + riverpod_annotation, go_router, Drift, Dio (`HttpService`), Firebase Auth

**Storage**: Drift (SQLite) — sem schema novo; remediação não altera persistência

**Testing**: flutter_test + `getTestProviderOverrides()`; widget tests nos hotspots P1 quando tocados; smoke manual login → home → treino → histórico; Patrol E2E se regressão em fluxo crítico

**Target Platform**: Android / iOS (mobile-first)

**Project Type**: Mobile app — remediação multi-feature de estado/UI lifecycle

**Performance Goals**: Eliminar rebuilds óbvios (watch amplo, DI observado); sem regressão perceptível nos fluxos smoke

**Constraints**: Seguir constituição III (Riverpod); PRs pequenos por feature/cluster; `WorkoutSessionScreen` legada — exceção baixa, não bloqueia close-out; sem nova lib de estado

**Scale/Scope**: 6 features prioritárias (`auth`, `home`, `workout_day`, `routines`, `workout_creation`, `workout_history`) + `settings`/`onboarding` se violações aparecerem na auditoria

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Offline-first | PASS | Remediação não move writes; controllers continuam via repositório |
| II. Feature layers | PASS | Não reabre HTTP-na-UI da 008; foco estado/lifecycle |
| III. Riverpod | PASS | **Objetivo central**: aplicar `ref.listen`, watch/read, AsyncNotifier já exigidos |
| IV. Core compartilhado | PASS | `AppSnackbar` canônico; substituir `ScaffoldMessenger` solto |
| V. Escopo produto | PASS | Sem feature de produto nova |
| VI. Testes | PASS | Overrides preservados; smoke por fatia |

**Post-design re-check**: PASS — contratos reforçam gates III sem violações novas.

## Project Structure

### Documentation (this feature)

```text
specs/010-state-management-audit/
├── plan.md
├── research.md
├── data-model.md
├── inventory-status.md
├── quickstart.md
├── contracts/
│   ├── remediation-slices.md
│   ├── state-enforcement.md
│   └── state-patterns.md
└── tasks.md                 # gerado (/speckit-tasks)
```

### Source Code (áreas tocadas)

```text
lib/
├── core/
│   └── components/app_snackbar.dart          # referência de feedback
└── features/
    ├── auth/presentation/
    │   ├── pages/login_screen.dart           # P1: listener + loading state
    │   └── providers/                        # AuthController
    ├── home/presentation/                    # gabarito parcial (008 RX); P1 sheets
    ├── workout_day/presentation/
    │   ├── pages/workout_day_screen.dart     # P1: side-effects
    │   ├── controllers/workout_finish_flow.dart
    │   ├── organisms/                        # exercise_card, footer_actions
    │   └── pages/workout_session_screen.dart # P3: exceção legada
    ├── routines/
    │   ├── routine_providers.dart            # P2: watch→read wiring
    │   └── presentation/                     # pages, sheets, modals
    ├── workout_creation/presentation/
    └── workout_history/presentation/
```

**Structure Decision**: Remediação in-place no monólito `iron_log`. Gabaritos = `home` pós-008 (reatividade) + `WorkoutTimer`/`elapsedTimeProvider` (isolamento) + template em `contracts/state-patterns.md`.

## Complexity Tracking

> Nenhuma violação de constituição requer exceção. Escopo limitado a padrões já definidos na 006/constituição.

| Item | Notas |
|------|-------|
| `WorkoutSessionScreen` legada | `accepted_exception` baixa — documentar, não rewrite |
| `setState` local legítimo | Drag/reorder UI efêmera MAY permanecer com justificativa no inventário |

## Implementation Phases (design → tasks)

Ordem alinhada à spec (detalhe em `contracts/remediation-slices.md`):

1. **Baseline (US1)**: congelar inventário em `inventory-status.md`; greps documentados em `state-enforcement.md`
2. **P1 (US2)**: `ref.listen` + side-effects — `auth/login`, `workout_day` (day screen + finish flow), `routines` page crítica, sheets home prioritários
3. **P2 (US3–US4)**: watch/read DI (`routines` wiring); `.select` ao tocar; fronteira setState em `workout_day`/`routines`/`creation`
4. **P3 (US5)**: checklist PR em `state-enforcement.md`; agent context apontando plano 010
5. **Close-out**: SC-001–SC-006; smoke SC-004; inventário alta = done/exception
