# Contract: State enforcement (010)

**Purpose**: Greps e regras verificáveis para remediação e review de PR.  
**Related**: 006 `contracts/pr-review-checklist.md`, [state-patterns.md](./state-patterns.md)

## PR review — estado (append to 006 checklist)

### Side-effects

- [ ] Nenhum `AppSnackbar` / `ScaffoldMessenger` no `build` reagindo a mudança de provider sem `ref.listen`
- [ ] Fluxos async com feedback usam controller `AsyncValue` + listener na page/sheet
- [ ] Navegação pós-sucesso via `ref.listen` ou callback síncrono antes de pop

### Watch / read

- [ ] UI (pages/widgets/components) não faz `ref.watch` em `*Repository*`, `*DataSource*`, `httpServiceProvider`
- [ ] Notifiers usam `ref.read` para repositórios em métodos async
- [ ] Wiring `overrideWith` usa `ref.read`, não `ref.watch`

### setState / lifecycle

- [ ] `setState` restante é efêmero local OU exceção documentada no inventário
- [ ] Após `await` em widget: `if (!context.mounted) return` antes de UI side-effect
- [ ] Sem duplicar loading flag local se controller já expõe `AsyncLoading`

### Rebuild

- [ ] Widgets que consomem subcampo usam `.select` ou provider derivado (ao tocar arquivo)

---

## Grep commands

Run from repo root `iron_log/`.

### G1 — ref.listen exists in remediated features

```bash
rg "ref\.listen\(" lib/features/auth lib/features/workout_day lib/features/routines lib/features/home
```

**After P1**: ≥1 match per remediated feature cluster (not necessarily every file).

### G2 — ScaffoldMessenger / AppSnackbar in presentation (baseline tracker)

```bash
rg "AppSnackbar\.|ScaffoldMessenger\.of" lib/features --glob "**/presentation/**"
```

**Trend**: count MUST NOT increase in PR; decreases as slices complete.  
**Close-out P1 paths**: zero **reactive** misuse (manual review + no snackbar triggered from `build` without listen).

### G3 — ref.watch repository in UI (SC-003)

```bash
rg "ref\.watch\([a-zA-Z]*[Rr]epository" lib/features --glob "**/presentation/pages/**"
rg "ref\.watch\([a-zA-Z]*[Rr]epository" lib/features --glob "**/presentation/widgets/**"
rg "ref\.watch\([a-zA-Z]*[Rr]epository" lib/features --glob "**/presentation/components/**"
rg "ref\.watch\([a-zA-Z]*[Dd]ataSource" lib/features --glob "**/presentation/**"
```

**Expected**: 0 in UI layers.

### G4 — ref.watch in DI wiring (P2)

```bash
rg "ref\.watch\([a-zA-Z]*[Rr]epository|ref\.watch\([a-zA-Z]*[Dd]ataSource" lib/features --glob "*_providers.dart"
```

**Expected after P2**: 0 (or listed exceptions in inventory).

### G5 — setState inventory

```bash
rg -l "setState\(" lib/features --glob "**/presentation/**"
```

**Expected**: each remaining file has inventory entry with `ephemeral_ui` or migration plan.

### G6 — StateNotifier (regression guard from 008)

```bash
rg "StateNotifierProvider|extends StateNotifier" lib/features lib/core
```

**Expected**: 0 (must stay 0).

---

## Per-slice minimum

| Slice | Required greps |
|-------|----------------|
| p1-auth-listen | G1 auth, G2 login path ↓ |
| p1-workout-day-listen | G1 workout_day, smoke treino |
| p1-routines-listen | G1 routines |
| p2-routines-watch-read | G4 → 0 |
| p2-setstate-* | G5 file removed or inventoried |

---

## Prohibited (new code)

Same as 006 `riverpod-conventions.md` plus:

- New `_isLoading` bool when controller already returns `AsyncValue`
- New `ScaffoldMessenger` for provider-driven errors
- New `ref.watch` on DI providers in widgets
