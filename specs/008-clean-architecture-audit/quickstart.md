# Quickstart: Validar remediação 008

**Goal**: Provar que uma fatia (ou o close-out) não quebrou produto e atende greps da spec.

## Prerequisites

- Flutter SDK do projeto (`iron_log`)
- Emulador/device + backend local **ou** API acessível (conforme launch Local)
- Checkout branch `008-clean-architecture-audit`

## Setup

```bash
cd iron_log
flutter pub get
```

Se migrou `@riverpod`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Baseline commands

Comandos de verificação de fronteira (fonte: [contracts/layer-enforcement.md](./contracts/layer-enforcement.md)):

```bash
# Presentation HTTP / AuthService leaks (paths P1 + auth)
rg "\bHttpService\b|\bApiEndpoints\b|\bAuthService\b|\bhttpServiceProvider\b" \
  lib/features/home/presentation \
  lib/features/workout_day/presentation \
  lib/features/routines/presentation \
  lib/features/auth/presentation
# Esperado: 0

# GoogleAuthService proibido em pages/widgets (AuthController OK)
rg "GoogleAuthService" lib/features --glob "**/presentation/pages/**"
rg "GoogleAuthService" lib/features --glob "**/presentation/widgets/**"
rg "GoogleAuthService" lib/features --glob "**/presentation/components/**"
# Esperado: 0

# Legacy export / rotas
rg "workout_session_screen" lib/features/workout_day/workout_day.dart lib/core/routes

# Product finish → summary MUST use GoRouter (US2 AC3)
rg "Navigator\.(of\(context\)\.)?push|WorkoutSummaryScreen" \
  lib/features/workout_day/presentation/pages/workout_day_screen.dart \
  lib/features/workout_day/presentation/controllers/workout_finish_flow.dart
# Esperado: finish flow usa context.push(WorkoutRouteLocations…); sem Navigator.push para summary

# FR-005 — pages/widgets MUST NOT watch repositories
rg "ref\.watch\([a-zA-Z]*[Rr]epository" lib/features --glob "**/presentation/pages/**"
rg "ref\.watch\([a-zA-Z]*[Rr]epository" lib/features --glob "**/presentation/widgets/**"
rg "ref\.watch\([a-zA-Z]*[Rr]epository" lib/features --glob "**/presentation/components/**"
# Esperado: 0 em UI; DI wiring em *providers.dart / feature root OK

# StateNotifier inventory
rg "StateNotifierProvider|extends StateNotifier" \
  lib/features/workout_day \
  lib/features/workout_creation \
  lib/features/home \
  lib/features/routines \
  lib/core/providers/sync_providers.dart \
  lib/core/components/exercise_search
```

## Per-slice validation

### 1) Analyze

```bash
flutter analyze lib/features/<feature_tocada>
```

Esperado: sem errors novos na feature.

### 2) Targeted greps (conforme slice)

Ver comandos em [contracts/layer-enforcement.md](./contracts/layer-enforcement.md).

Exemplos:

**Após `p1-home-data` / `p1-http-*` / auth:**

```bash
rg "\bHttpService\b|\bApiEndpoints\b|\bAuthService\b|\bhttpServiceProvider\b" \
  lib/features/home/presentation \
  lib/features/workout_day/presentation \
  lib/features/routines/presentation \
  lib/features/auth/presentation
rg "GoogleAuthService" lib/features --glob "**/presentation/pages/**"
```

Esperado: zero hits (ou só arquivos ainda não no slice — documentar).

**Após `p1-isolate-session-screen`:**

```bash
rg "workout_session_screen" lib/features/workout_day/workout_day.dart lib/core/routes
```

Esperado: sem export/rota de produto.

**Após migração StateNotifier de um arquivo:**

```bash
rg "StateNotifier" path/to/migrated_file.dart
```

Esperado: zero (exceto comentários de histórico, preferir remover).

### 3) Unit/widget (se o slice tocou providers)

```bash
flutter test test/features/<feature>/
```

Usar `ProviderScope(overrides: ...)` / `getTestProviderOverrides()` quando aplicável.

### 4) Smoke manual (obrigatório em todo PR — SC-005)

1. Login  
2. Home carrega métricas/calendário  
3. Abrir/iniciar treino (execução ou manual)  
4. Registrar ao menos uma série e voltar / finalizar conforme fluxo  
5. Abrir Histórico  

Esperado: comportamento equivalente ao pré-PR (FR-011).

## Close-out validation (fim da 008)

```bash
# Stubs removidos
test ! -d lib/features/analytics
test ! -d lib/features/workout_session

# StateNotifier inventário (ajustar se paths mudaram)
rg "StateNotifierProvider|extends StateNotifier" \
  lib/features/workout_day \
  lib/features/workout_creation \
  lib/features/home \
  lib/features/routines \
  lib/core/providers/sync_providers.dart \
  lib/core/components/exercise_search
```

Esperado: zero matches nos pontos inventariados.

## References

- Spec success criteria: [spec.md](./spec.md)  
- Slices: [contracts/remediation-slices.md](./contracts/remediation-slices.md)  
- 006 PR checklist: `../006-flutter-architecture-standard/contracts/pr-review-checklist.md`
