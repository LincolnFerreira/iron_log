# Quickstart: Validar remediação 010

**Goal**: Provar que uma fatia (ou close-out) de estado não quebrou produto e atende greps da spec.

## Prerequisites

- Flutter SDK (`iron_log`)
- Emulador/device + backend/API conforme launch Local
- Branch `010-state-management-audit`

## Setup

```bash
cd iron_log
flutter pub get
```

Se alterou `@riverpod`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Baseline commands

Fonte: [contracts/state-enforcement.md](./contracts/state-enforcement.md)

```bash
# G1 — listeners (baseline 0; deve subir após P1)
rg "ref\.listen\(" lib --glob "*.dart"

# G2 — snackbar/scaffold tracker (~62 baseline)
rg -c "AppSnackbar\.|ScaffoldMessenger\.of" lib/features --glob "**/presentation/**"

# G3 — watch repo in UI (must stay 0)
rg "ref\.watch\([a-zA-Z]*[Rr]epository" lib/features \
  --glob "**/presentation/pages/**" \
  --glob "**/presentation/widgets/**" \
  --glob "**/presentation/components/**"

# G4 — watch in DI wiring (2 hits baseline in routines)
rg "ref\.watch\([a-zA-Z]*[Rr]epository|ref\.watch\([a-zA-Z]*[Dd]ataSource" \
  lib/features --glob "*_providers.dart"

# G5 — setState files (20 baseline)
rg -l "setState\(" lib/features --glob "**/presentation/**"

# G6 — StateNotifier regression (must stay 0)
rg "StateNotifierProvider|extends StateNotifier" lib/features lib/core
```

## Per-slice validation

### 1) Analyze

```bash
flutter analyze lib/features/<feature_tocada>
```

Esperado: sem errors novos.

### 2) Targeted greps

Ver tabela “Per-slice minimum” em [state-enforcement.md](./contracts/state-enforcement.md).

### 3) Widget test (when touching P1 hotspot)

```bash
flutter test test/features/<feature>/
```

### 4) Smoke manual (SC-004)

Executar após cada fatia P1+:

1. **Login** (Google) — erro de rede mostra **uma** mensagem; sem crash ao sair rápido
2. **Home** — refresh, banner treino, sheets rest/cardio
3. **Treino** — iniciar/continuar, registrar série, finalizar → summary
4. **Histórico** — abrir treino salvo

**Pass**: sem snackbar duplicado; sem erro de contexto após navegação rápida.

## Close-out

- [ ] [inventory-status.md](./inventory-status.md) — all `high` = done/exception
- [ ] G3 = 0
- [ ] G6 = 0
- [ ] Smoke SC-004 OK
- [ ] [state-patterns.md](./contracts/state-patterns.md) linked from agent context

## Reference files (gabarito)

| Pattern | File |
|---------|------|
| Consumers + select | `lib/features/home/presentation/components/templates/home_template.dart` |
| Timer isolado | `lib/features/workout_day/presentation/providers/workout_timer_provider.dart` |
| Page + listen (target) | `specs/010-state-management-audit/contracts/state-patterns.md` |
