# Data Model: 010-state-management-audit

**Date**: 2026-08-27  
**Nota**: Esta feature **não** altera schema Drift/Prisma. O modelo rastreia inventário e remediação de **padrões de estado**.

## Entities (tracking)

### StateDeviationItem

Representa um anti-padrão de gerenciamento de estado ou ciclo de widget.

| Campo | Tipo | Notas |
|-------|------|-------|
| id | string | estável, ex.: `SM-auth-login-listen` |
| area | string | feature ou `core` |
| category | enum | `side_effect` \| `watch_read` \| `setstate_boundary` \| `lifecycle` \| `select_rebuild` |
| severity | enum | `high` \| `medium` \| `low` |
| problem | string | descrição curta |
| remediation | string | ação (listener, migrate, exception) |
| status | enum | `open` \| `done` \| `accepted_exception` |
| evidence | string | path:line / grep / PR |
| sliceId | string | FK → RemediationSlice |

**Validation**:

- `status=done` exige evidência grep ou PR
- `accepted_exception` exige justificativa (ex.: setState efêmero drag)
- `severity=high` MUST estar `done` ou `accepted_exception` antes do close-out (SC-001)

### RemediationSlice

Fatia entregável (~1 PR).

| Campo | Tipo | Notas |
|-------|------|-------|
| id | string | ex.: `p1-auth-listen` |
| priority | enum | P1 \| P2 \| P3 |
| items | StateDeviationItem[] | 1..n |
| smoke | boolean | login→home→treino→histórico |

### SideEffectHotspot

Subtipo lógico de `StateDeviationItem` (`category=side_effect`).

| Campo | Tipo | Notas |
|-------|------|-------|
| trigger | enum | `async_error` \| `async_success` \| `imperative_callback` |
| currentPattern | string | ex.: `ScaffoldMessenger in callback` |
| targetPattern | string | `ref.listen + AppSnackbar` |

### SetStateBoundary

Subtipo lógico (`category=setstate_boundary`).

| Campo | Tipo | Notas |
|-------|------|-------|
| stateKind | enum | `ephemeral_ui` \| `mirrors_provider` \| `domain_local` |
| resolution | enum | `keep` \| `migrate_to_provider` |

### ReferencePattern

Gabarito a copiar (SC-006).

| Campo | Tipo | Notas |
|-------|------|-------|
| id | string | ex.: `REF-home-template` |
| path | string | arquivo(s) |
| describes | string | reatividade / listener / timer |

**Instâncias iniciais**:

| id | path | describes |
|----|------|-----------|
| REF-home-template | `home/presentation/components/templates/home_template.dart` | Consumers + `.select` |
| REF-workout-timer | `workout_day/.../workout_timer_provider.dart` | rebuild isolado |
| REF-state-patterns-doc | `contracts/state-patterns.md` | page + controller + listen |

## Relationships

```text
ReferencePattern ← guides — RemediationSlice
RemediationSlice —contains→ StateDeviationItem
StateDeviationItem —may specialize→ SideEffectHotspot | SetStateBoundary
```

## State transitions

### StateDeviationItem.status

```text
open → done
open → accepted_exception
```

`accepted_exception` é terminal (revisar só se produto mudar).

## Baseline counts (2026-08-27)

| category | open (approx) |
|----------|---------------|
| side_effect | ~62 call sites / ~25 arquivos |
| watch_read | 2 wiring + 0 em pages/widgets UI |
| setstate_boundary | 20 arquivos |
| lifecycle | subset de side_effect + setState async |
| select_rebuild | app-wide (home done) |

Detalhe vivo: [inventory-status.md](./inventory-status.md)
