# Implementation Plan: Auditoria e Organização Clean Architecture

**Branch**: `008-clean-architecture-audit` | **Date**: 2026-08-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/008-clean-architecture-audit/spec.md`

**Note**: Remediação estrutural do app Flutter contra o padrão já definido em `006-flutter-architecture-standard`. Sem mudança de API backend.

## Summary

Aplicar o padrão clean architecture (feature-first + `domain` / `data` / `presentation`) no código existente: inventário verificável, remediação P1→P2→P3 até zerar o inventário, PRs pequenos, comportamento de produto inalterado.

Abordagem técnica: espelhar `routines/` e `workout_day/` como gabarito; extrair HTTP da presentation para datasources/repositórios; isolar `WorkoutSessionScreen` (sem export/rota); remover stubs mortos; migrar todos os `StateNotifier` inventariados para `@riverpod` + `AsyncNotifier`/`Notifier` em PRs por arquivo/módulo (exceção de escopo documentada à regra “só ao tocar”).

**Tracking**: [inventory-status.md](./inventory-status.md) · **Slices**: [contracts/remediation-slices.md](./contracts/remediation-slices.md)

## Technical Context

**Language/Version**: Dart ^3.8 / Flutter 3.8+

**Primary Dependencies**: flutter_riverpod + riverpod_annotation, go_router, Dio (`HttpService`), Drift, Firebase Auth

**Storage**: Drift (SQLite) local — sem schema novo nesta feature; PostgreSQL só via API existente (fora de escopo de mudança)

**Testing**: flutter_test (+ overrides `getTestProviderOverrides()`); smoke manual login → home → treino → histórico; Patrol E2E só se fluxo crítico de rota de treino regressar

**Target Platform**: Android / iOS (mobile-first Iron Log)

**Project Type**: Mobile app (Flutter) — remediação estrutural multi-feature

**Performance Goals**: Sem regressão perceptível de digitação/treino; rebuilds não pioram vs baseline atual nos fluxos remediados

**Constraints**: FR-011 — sem redesign de UX; PRs preferencialmente uma feature (ou um cluster P1); constituição I–VI; exceção justificada só para escopo de migração StateNotifier (Complexity Tracking)

**Scale/Scope**: ~10 features sob `lib/features/`; ~10 clusters StateNotifier; inventário P1+P2+P3 completo para done da 008

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Offline-first | PASS | Sem alterar contratos de sync/version; remediação não move writes para rede-first |
| II. Feature layers | PASS | Objetivo central: `domain`/`data`/`presentation` + overrides como `routines` |
| III. Riverpod | PASS com exceção justificada | Código novo = AsyncNotifier; legado StateNotifier **será migrado nesta feature** em PRs pequenos (clarification) — ver Complexity Tracking |
| IV. Core compartilhado | PASS | Continuar `HttpService` / `ApiEndpoints`; sem Dio direto na UI |
| V. Escopo produto | PASS | Sem features de produto novas |
| VI. Testes | PASS | Overrides + smoke; E2E se rotas de treino mudarem |

**Post-design re-check**: PASS — contratos de fronteira e checklist de PR reforçam gates; nenhuma violação nova introduzida pelo desenho.

## Project Structure

### Documentation (this feature)

```text
specs/008-clean-architecture-audit/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── remediation-slices.md
│   └── layer-enforcement.md
└── tasks.md                 # gerado (/speckit-tasks) — 67 tasks
```

### Source Code (áreas tocadas)

```text
lib/
├── core/
│   ├── api/api_endpoints.dart          # sem duplicar endpoints
│   ├── components/exercise_search/     # StateNotifier → migrar
│   ├── providers/sync_providers.dart   # StateNotifier → migrar
│   └── routes/                         # garantir só WorkoutDayScreen nas rotas
└── features/
    ├── home/                           # P1: data/ + repos; tirar HTTP da presentation
    ├── workout_day/
    │   ├── presentation/pages/
    │   │   ├── workout_day_screen.dart      # canônico
    │   │   └── workout_session_screen.dart  # isolar (sem export)
    │   ├── data/datasources/                # extrair HTTP dos providers
    │   └── presentation/providers/          # StateNotifier → AsyncNotifier
    ├── routines/                       # P1 HTTP presentation + P2 StateNotifier
    ├── auth/                           # P2: controllers → presentation/providers
    ├── workout_history/                # P2: DI overrides na raiz da feature
    ├── workout_creation/               # P2/P3 estrutura + StateNotifier
    ├── onboarding/                     # P2/P3 órfãos + estrutura
    ├── analytics/                      # P3: DELETE
    └── workout_session/                # P3: DELETE (stub)
```

**Structure Decision**: Remediação in-place no monólito Flutter `iron_log`. Gabarito = `routines` + `workout_day`. Contratos de API HTTP **não** mudam; contratos desta feature são de **fronteira de camadas** e fatiamento de PRs.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Escopo 008 migra **todos** os StateNotifier inventariados (vs constituição “só ao tocar”) | Clarification explícita do produto: done da 008 exige zerar legado de estado listado | Deixar “só ao tocar” deixaria SC-007 / FR-014 incompletos e inventário P2 aberto |
| Entrega ainda em PRs pequenos por arquivo/módulo | Evita rewrite monólito proibido pela constituição | Um único PR de StateNotifier seria rewrite em massa e alto risco de regressão |

## Implementation Phases (design → tasks)

Ordem alinhada à spec (não substitui `tasks.md`):

1. **Baseline**: congelar inventário em `data-model.md` + checklist de verificação (grep/smoke)
2. **P1**: `home` data layer; isolar `WorkoutSessionScreen`; extrair HTTP presentation em `workout_day` + `routines`
3. **P2**: `auth`, `workout_history`, `workout_creation`/`onboarding`; domínio sem cor; core↔features; **migração StateNotifier** (lista em research)
4. **P3**: delete `analytics` / `workout_session`; delete órfãos e `ExerciseSearchField` deprecado; unificar pastas cosméticas ao tocar
5. **Close-out**: greps SC-003/SC-004/SC-007 verdes; inventário 100% feito ou exceção documentada
