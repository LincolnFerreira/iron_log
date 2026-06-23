# Arquitetura Flutter — Iron Log

Fonte de verdade: [spec](../specs/006-flutter-architecture-standard/spec.md) · [plan](../specs/006-flutter-architecture-standard/plan.md) · [tasks](../specs/006-flutter-architecture-standard/tasks.md)

Contratos: [layer-boundaries](../specs/006-flutter-architecture-standard/contracts/layer-boundaries.md) · [riverpod](../specs/006-flutter-architecture-standard/contracts/riverpod-conventions.md) · [folders](../specs/006-flutter-architecture-standard/contracts/folder-structure.md) · [PR checklist](../specs/006-flutter-architecture-standard/contracts/pr-review-checklist.md)

Constituição: [.specify/memory/constitution.md](../.specify/memory/constitution.md) (v1.2.2)

## Referências de código

| Papel | Caminho |
|-------|---------|
| Feature completa (plano + CRUD) | `lib/features/routines/` |
| Execução de treino | `lib/features/workout_day/` |
| Infra compartilhada | `lib/core/` |
| **Não copiar** | `lib/features/analytics/`, `lib/features/workout_session/` |

## Como criar uma feature nova

1. Criar `lib/features/<nome>/` com camadas conforme [folder-structure](../specs/006-flutter-architecture-standard/contracts/folder-structure.md):

```text
lib/features/<nome>/
├── domain/entities/, domain/repositories/, domain/usecases/ (se necessário)
├── data/datasources/, data/repositories/, data/models/
└── presentation/pages/, presentation/providers/, presentation/widgets/
```

2. **Domain**: entidades puras — sem Flutter, Dio ou Drift.
3. **Data**: datasources + implementação de repository; HTTP só via `HttpService` / Dio injetado.
4. **Presentation**: `ConsumerWidget` + providers/controllers; sem SQL/Dio direto na UI.

Features só visuais podem omitir `domain/` e `data/`, mas MUST viver em `presentation/`.

## Injeção de repositório (`ProviderScope`)

Padrão atual (ver `lib/features/routines/routine_providers.dart`):

1. Interface em `domain/repositories/<nome>_repository.dart`
2. Provider abstrato que `throw UnimplementedError` se não sobrescrito
3. Implementação concreta + `*ProvidersOverrides` exportado
4. Registro em `lib/main.dart`:

```dart
ProviderScope(
  overrides: [
    ...routineProvidersOverrides,
    // ...outras features
  ],
  child: const MyApp(),
)
```

Migração futura: `@Riverpod(keepAlive: true)` codegen para DI.

## Riverpod — estado ≠ DI

| Papel | API na UI | API no controller |
|-------|-----------|-------------------|
| Estado (rebuild) | `ref.watch(controllerProvider)` | `state = ...` |
| DI (repository, HTTP) | **não** `watch` | `ref.read(repositoryProvider)` |
| Side-effect (snackbar, nav) | `ref.listen(...)` | — |

**Código novo**: `@riverpod` + `AsyncNotifier` / `Notifier`, `AsyncValue.guard`.

**Proibido código novo**: `StateNotifier`, `package:provider`, BLoC, GetIt, `ref.watch(repository)` na UI, snackbar no `build`.

**Legado**: `StateNotifier` existente — migrar ao tocar o arquivo, sem rewrite em massa.

Detalhes: [riverpod-conventions](../specs/006-flutter-architecture-standard/contracts/riverpod-conventions.md).

## Endpoints HTTP

Único arquivo: `lib/core/api/api_endpoints.dart`. Não criar `endpoints.dart` nem duplicatas.

## Navegação

Shell: `lib/core/routes/app_router.dart` (GoRouter).

Rotas de execução de treino: `lib/core/routes/workout_route_locations.dart` (`/workout/execution`, `/workout/manual`, `/workout/edit/:id`, `/workout/resume/:draftId`). Preferir `context.push(WorkoutRouteLocations.*)` em vez de `Navigator.push`.

`WorkoutSessionScreen` está `@Deprecated` — usar apenas `WorkoutDayScreen` via GoRouter.

## Inventário `StateNotifier` legado (migrar ao tocar)

| Arquivo | Notifier |
|---------|----------|
| ~~`lib/features/auth/auth_state.dart`~~ | Migrado → `auth_controller.dart` (`@riverpod`) |
| ~~`lib/features/home/presentation/providers/home_provider.dart`~~ | Migrado → `home_controller.dart` (`@riverpod`) |
| ~~`lib/features/routines/presentation/providers/routine_provider.dart`~~ | Migrado → `routine_controller.dart` (`@riverpod`) |
| `lib/features/home/presentation/providers/workout_provider.dart` | `WorkoutNotifier` |
| `lib/features/routines/presentation/providers/session_provider.dart` | `SessionNotifier` |
| `lib/features/routines/presentation/providers/session_selection_provider.dart` | `SessionExerciseSelectionNotifier` |
| `lib/features/workout_creation/presentation/providers/workout_creation_provider.dart` | `WorkoutCreationNotifier` |
| `lib/features/workout_day/presentation/providers/workout_day_provider.dart` | `WorkoutDayExercisesNotifier` |
| `lib/features/workout_day/presentation/providers/workout_timer_provider.dart` | `WorkoutTimerNotifier` |
| `lib/features/workout_day/presentation/providers/voice_input_provider.dart` | `VoiceInputNotifier` |
| `lib/features/workout_day/presentation/controllers/workout_controller.dart` | `WorkoutController` |
| `lib/core/providers/sync_providers.dart` | `SyncStateNotifier` |
| `lib/core/components/exercise_search/unified_exercise_search.dart` | `ExerciseSearchNotifier` |

Prioridade de migração para `@riverpod` `AsyncNotifier`: auth → home → routines (ver tasks T056–T058).

## Testes

- Unit/widget: `test/` espelhando `lib/`
- Overrides: `test/helpers/test_providers_setup.dart`
- E2E: Patrol em `integration_test/`; chaves estáveis em `integration_test/support/test_keys.dart` (prefixo `e2e_*`, ex.: `e2e_start_workout`)

## Quick reject (review)

Rejeitar código **novo** que:

1. Importa `package:provider` ou `flutter_bloc`
2. Declara `extends StateNotifier`
3. Usa `ref.watch(*RepositoryProvider)` em widget
4. Importa `endpoints.dart`
5. Cria pasta `state/` ou `bloc/` na raiz da feature
6. Chama Dio/Drift direto de widget

Script local: `./scripts/check_architecture.sh`

## Validação

[quickstart](../specs/006-flutter-architecture-standard/quickstart.md) — greps, `flutter test`, walkthrough SC-002.
