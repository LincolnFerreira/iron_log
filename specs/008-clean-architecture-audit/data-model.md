# Data Model: 008-clean-architecture-audit

**Date**: 2026-08-20  
**Nota**: Esta feature **não** altera schema Drift/Prisma. O “modelo” abaixo rastreia remediação e inventário.

## Entities (tracking)

### DeviationItem

Representa um desvio arquitetural inventariado.

| Campo | Tipo | Notas |
|-------|------|-------|
| id | string | estável, ex.: `P1-home-http` |
| area | string | feature ou `core` |
| priority | enum | `high` \| `medium` \| `low` (P1/P2/P3) |
| problem | string | descrição curta |
| remediation | string | ação acordada |
| status | enum | `open` \| `done` \| `accepted_exception` |
| evidence | string | grep path / PR link |

**Validation**:

- `status=done` só com evidência (grep limpo ou PR mergeado)
- `accepted_exception` exige justificativa escrita no inventário/PR

### RemediationSlice

Fatia entregável (≈ 1 PR).

| Campo | Tipo | Notas |
|-------|------|-------|
| id | string | ex.: `slice-p1-home` |
| priority | enum | P1/P2/P3 |
| items | DeviationItem[] | 1..n |
| smoke | boolean | login→home→treino→histórico |

### CanonicalFeature

| Campo | Tipo | Notas |
|-------|------|-------|
| name | string | `routines` \| `workout_day` |
| role | string | gabarito estrutural |

### LegacyWorkoutScreen

| Campo | Tipo | Notas |
|-------|------|-------|
| path | string | `.../workout_session_screen.dart` |
| isolation | enum | `isolated` \| `product_exported` |
| target | | MUST ser `isolated` ao fim do P1 |

### StateNotifierMigration

| Campo | Tipo | Notas |
|-------|------|-------|
| sourcePath | string | arquivo atual |
| notifierName | string | classe |
| targetPattern | string | `AsyncNotifier` / `Notifier` + `@riverpod` |
| status | enum | `open` \| `done` |

Lista inicial: ver [research.md](./research.md) R5.

## Relationships

```text
CanonicalFeature ← guides — RemediationSlice
RemediationSlice —contains→ DeviationItem
DeviationItem —may map→ StateNotifierMigration | LegacyWorkoutScreen
```

## State transitions

### DeviationItem.status

```text
open → done
open → accepted_exception
```

### LegacyWorkoutScreen.isolation

```text
product_exported → isolated   (P1)
```

### Feature 008 close-out

```text
all DeviationItem status ∈ {done, accepted_exception}
AND SC-003, SC-004, SC-007 verdes
→ feature closable
```

## Out of scope (data)

- Novas tabelas Drift / migrations Prisma
- Novos endpoints REST
- Mudança de payloads de sync
