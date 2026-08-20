# Contract: Layer enforcement (008)

**Purpose**: Regras verificáveis de fronteira durante a remediação.  
**Extends**: `specs/006-flutter-architecture-standard/contracts/layer-boundaries.md` e `riverpod-conventions.md`

## Allowed dependencies (within a feature)

```text
presentation → domain          ✅
data → domain                  ✅
presentation → data            ❌ (use domain repository interface)
domain → data | presentation   ❌
presentation → HttpService / ApiEndpoints / Dio / AuthService  ❌ (após remediação do item)
```

## DI vs state

| Need | API |
|------|-----|
| Rebuild UI on state | `ref.watch` state provider / AsyncNotifier |
| Obtain repository / HttpService | `ref.read` only |
| Snackbar / navigation | `ref.listen` (not in `build`) |

## Repository wiring

```text
abstract provider (throws if not overridden)
  + concrete Impl
  + registered in main via *ProvidersOverrides
```

Espelhar `routineProvidersOverrides`.

## Legacy workout screen

| Rule | Enforcement |
|------|-------------|
| Product routes | Only `WorkoutDayScreen` via `WorkoutRouteLocations` |
| Barrel export | MUST NOT export `WorkoutSessionScreen` from product barrel |
| File retention | Allowed under isolated/legacy path |

## Stub deletion

| Module | After P3 |
|--------|----------|
| `features/analytics` | MUST NOT exist |
| `features/workout_session` | MUST NOT exist |
| Deprecated exercise search field | MUST NOT exist |

## State migration target

- MUST NOT introduce new `StateNotifier`  
- Inventariados MUST become `@riverpod` + `AsyncNotifier`/`Notifier`  
- Regenerate `*.g.dart` with build_runner; do not hand-edit  

## Verification commands (illustrative)

```bash
# Presentation HTTP / AuthService leaks (ajustar paths por slice)
# Inclui httpServiceProvider — greps só com HttpService|AuthService falham em vazamentos reais.
rg "\bHttpService\b|\bApiEndpoints\b|\bAuthService\b|\bhttpServiceProvider\b" \
  lib/features/home/presentation \
  lib/features/workout_day/presentation \
  lib/features/routines/presentation \
  lib/features/auth/presentation

# GoogleAuthService: proibido em pages/widgets; permitido só no AuthController
rg "GoogleAuthService" lib/features --glob "**/presentation/pages/**"
rg "GoogleAuthService" lib/features --glob "**/presentation/widgets/**"
rg "GoogleAuthService" lib/features --glob "**/presentation/components/**"

# Legacy export
rg "workout_session_screen" lib/features/workout_day/workout_day.dart

# StateNotifier inventory
rg "StateNotifierProvider|extends StateNotifier" lib/features lib/core/providers lib/core/components/exercise_search

# FR-005 — pages/widgets MUST NOT watch repositories (DI *providers.dart OK)
rg "ref\.watch\([a-zA-Z]*[Rr]epository" lib/features --glob "**/presentation/pages/**"
rg "ref\.watch\([a-zA-Z]*[Rr]epository" lib/features --glob "**/presentation/widgets/**"
rg "ref\.watch\([a-zA-Z]*[Rr]epository" lib/features --glob "**/presentation/components/**"
```

## Reactivity (follow-up / U1)

008 NÃO exige rewrite de performance. Quando tocar UI quente, SHOULD:

- `ref.watch` só estado necessário; preferir `.select` / Consumer filho
- DI (`*Repository`, `HttpService`) com `ref.read` em Notifier/actions
- Timer / streams isolados (padrão `WorkoutTimer` + `elapsedTimeProvider`)
- Evitar N `watch` no `build` da page raiz se só um subárvore precisa do valor

Inventário de hotspots: `inventory-status.md` → seção Reactivity follow-up.
