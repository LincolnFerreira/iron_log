# Data Model: Governança Arquitetural (conceitual)

**Feature**: `006-flutter-architecture-standard` | **Date**: 2026-06-23

> Este documento **não** define tabelas Drift nem entidades de negócio do Iron Log. Modela os **artefatos de governança** que o time usa para organizar o código.

---

## FeatureModule

Unidade de organização em `lib/features/<name>/`.

| Atributo | Regra |
|----------|-------|
| `name` | `snake_case` — ex.: `workout_day`, `workout_history` |
| `layers` | Subconjunto de `{domain, data, presentation}` — presentation obrigatório; domain+data se houver lógica/I/O |
| `reference` | `true` se módulo é referência (`routines`, `workout_day`) |
| `stub` | `true` se MUST NOT copiar (`analytics`, `workout_session`) |

**Relacionamentos**:
- Depende de `CoreInfrastructure` (HTTP, DB, sync, routes).
- Pode exportar `ProviderOverrideBundle` para `main.dart`.

---

## Layer

| Layer | Contém | Importa de |
|-------|--------|------------|
| `domain` | entities, repository interfaces, use cases | Dart puro apenas |
| `data` | datasources, DTOs, repository impl, services I/O | domain, core/database, core/api (paths only) |
| `presentation` | pages, widgets, providers/controllers | domain, data via DI (read), flutter, riverpod |
| `core` | infra cross-cutting | pacotes externos; não importa features |

**Invariante**: `domain` MUST NOT import `presentation` ou `data`.

---

## RepositoryContract

| Campo | Descrição |
|-------|-----------|
| `interface` | `domain/repositories/<name>_repository.dart` |
| `implementation` | `data/repositories/<name>_repository_impl.dart` |
| `injection` | Provider abstrato + override em `main.dart` OU `@Riverpod(keepAlive: true)` |
| `uiAccess` | `ref.read` only — MUST NOT `ref.watch` na UI |

---

## ProviderKind

Classificação de providers Riverpod — determina API de consumo.

| Kind | Exemplo | UI watch? | Notifier read? |
|------|---------|-----------|----------------|
| `state_controller` | `authControllerProvider` | ✅ | N/A |
| `async_data` | `productsProvider` | ✅ | N/A |
| `derived` | `cartTotalProvider` | ✅ (derivado) | watches source |
| `dependency` | `routineRepositoryProvider` | ❌ | ✅ `ref.read` |
| `infrastructure` | `httpServiceProvider` | ❌ | ✅ `ref.read` |

---

## ProviderOverrideBundle

| Campo | Descrição |
|-------|-----------|
| `feature` | Nome da feature |
| `overrides` | `List<Override>` exportada — ex. `routineProvidersOverrides` |
| `registration` | Composição em `ProviderScope(overrides: [...])` em `main.dart` |

---

## SyncableEntity (referência — domínio existente)

Entidades que participam do sync offline (constituição I). Esta feature **não altera** o modelo; documenta dependência.

| Campo | Tipo | Regra |
|-------|------|-------|
| `version` | int | incrementa em write |
| `pendingSync` | bool | true até sync confirmado |
| `syncedAt` | DateTime? | timestamp último sync |

---

## ShellRoute vs ModalRoute

| Tipo | Mecanismo | Exemplos |
|------|-----------|----------|
| `shell` | GoRouter path em `app_router.dart` | `/home`, `/routines`, `/history` |
| `full_screen_legacy` | `Navigator.push` temporário | `WorkoutDayScreen` até Fase 4 |
| `modal` | `showModalBottomSheet`, `showDialog` | SessionPicker, AddExercise |

**Transição Fase 4**: `full_screen_legacy` → `shell` com prefixo `/workout/*`.

---

## MigrationPhase

| Phase | id | deliverable |
|-------|-----|-------------|
| Governança | 0 | docs, contracts, checklist |
| Core higiene | 1 | endpoints, router prints |
| Pastas | 2 | feature folder normalization |
| Camadas | 3 | settings, history, auth |
| Navegação | 4 | GoRouter workout |
| Riverpod | 5 | AsyncNotifier gradual, observer |
| Deps | 6 | pubspec cleanup |

**State machine**: fases ordenadas; Fase 2 permite paralelismo **entre features** (PRs separados), não dentro da mesma feature em um PR gigante.

---

## ArchitectureViolation (review)

| id | severity | detection |
|----|----------|-----------|
| `AV-01` | critical | Dio/Drift em widget |
| `AV-02` | critical | novo `StateNotifier` |
| `AV-03` | high | `ref.watch(repository)` na UI |
| `AV-04` | high | import `endpoints.dart` novo |
| `AV-05` | high | `provider` / `bloc` package |
| `AV-06` | medium | pasta `state/` ou `bloc/` nova |
| `AV-07` | medium | snackbar no `build` sem `ref.listen` |
| `AV-08` | low | abreviação opaca em código novo |
