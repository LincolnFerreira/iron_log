# Quickstart: Validar Conformidade Arquitetural

**Feature**: `006-flutter-architecture-standard` | **Date**: 2026-06-23

Guia para validar que o padrão está documentado e que refactors não quebraram o app. Não substitui `tasks.md` — use após cada fase de migração.

## Prerequisites

- Flutter SDK compatível com `pubspec.yaml` (^3.8)
- Repo `iron_log` na branch `006-flutter-architecture-standard` ou `main` pós-merge
- Documentos: [spec.md](./spec.md), [contracts/](./contracts/)

```bash
cd iron_log
flutter pub get
```

---

## 1. Documentação (Fase 0)

| Check | Command / action | Expected |
|-------|------------------|----------|
| Spec existe | `test -f specs/006-flutter-architecture-standard/spec.md` | exit 0 |
| Plan + contracts | `ls specs/006-flutter-architecture-standard/contracts/` | 4 arquivos `.md` |
| Agent context | `grep "006-flutter-architecture" .cursor/rules/specify-rules.mdc` | match |
| Constitution v1.2.2+ | `grep "Estado ≠ DI" .specify/memory/constitution.md` | match |

---

## 2. Grep guards (Fase 1+)

Rodar da raiz `iron_log/`:

```bash
# Proibidos em lib/ (legado pode existir até Fase 5/6 — meta é zero crescimento)
rg "package:provider/|package:flutter_bloc/" lib/ && echo "FAIL: provider/bloc import" || echo "OK: no provider/bloc imports"

# Novos imports endpoints.dart (Fase 1 done = zero)
rg "api/endpoints\.dart" lib/ test/ | wc -l
# Meta pós-Fase 1: 0 (ou só re-export deprecado)

# StateNotifier novo — revisar diff do PR
git diff main --name-only -- lib/ | xargs rg -l "extends StateNotifier" 2>/dev/null || true

# watch repository na UI (heurística — revisar manualmente hits)
rg "ref\.watch\(.*[Rr]epository" lib/features/
```

**Expected após Fase 1**: zero arquivos importando `endpoints.dart` (exceto re-export deprecado se ainda existir).

**Expected após Fase 6**: primeiro comando OK; `pubspec.yaml` sem `provider:` / `bloc:`.

---

## 3. Estrutura de pastas (Fase 2)

Após migrar cada feature:

```bash
# Não deve existir em features migradas
find lib/features/home lib/features/onboarding lib/features/routines \
  -type d \( -name state -o -name bloc \) 2>/dev/null
# Expected: vazio pós-migração da feature

# home_page em presentation
test -f lib/features/home/presentation/pages/home_page.dart && echo OK
```

Repita para cada feature conforme [plan.md](./plan.md) Fase 2.

---

## 4. Testes (todo PR de migração)

```bash
flutter test
```

Widget tests críticos:

```bash
flutter test test/features/routines/
flutter test test/features/workout_day/
flutter test test/helpers/
```

**Expected**: todos passam; sem alteração de comportamento declarada no PR.

### Paths pós-migração arquitetural (006)

| Legado | Canônico |
|--------|----------|
| `lib/features/home/state/` | `lib/features/home/presentation/providers/` |
| `lib/features/home/components/` | `lib/features/home/presentation/components/` |
| `lib/features/routines/presentation/bloc/` | `lib/features/routines/presentation/providers/` |
| `lib/features/workout_creation/presentation/state/` | `lib/features/workout_creation/presentation/providers/` |
| `lib/features/workout_day/data/providers/` | `lib/features/workout_day/presentation/providers/` |

Helpers: `test/helpers/test_providers_setup.dart` — usar `routineRepositoryProvider.overrideWithValue` ou `getTestProviderOverrides()`; evitar Firebase real em widget tests (ex.: `session_edit_page_test.dart` override `routineLastWorkoutProvider`).

---

## 5. E2E Patrol (Fase 4 — navegação workout)

Após registrar `WorkoutDayScreen` no GoRouter:

```bash
# Requer device/emulador + Patrol setup
patrol test integration_test/workout_create_e2e_test.dart
patrol test integration_test/workout_manual_e2e_test.dart
patrol test integration_test/workout_edit_e2e_test.dart
```

**Expected**: fluxos start/finish/manual/edit verdes com novas rotas.

Detalhes de bootstrap: `integration_test/support/e2e_bootstrap.dart`.

---

## 6. Riverpod observer (Fase 5)

Em debug build, ao abrir o app:

- Console mostra logs `providerName -> newValue` se `AppProviderObserver` registrado.

Verificar em `lib/main.dart`:

```bash
rg "ProviderObserver" lib/main.dart
```

---

## 7. Walkthrough desenvolvedor (SC-002)

Sem código — validação humana (~5 min):

1. Abrir [contracts/folder-structure.md](./contracts/folder-structure.md)
2. Responder: onde criar repository? → `domain/repositories` + `data/repositories`
3. Onde provider de estado? → `presentation/providers/`
4. Como injetar repo? → override em `main.dart` ou `@Riverpod(keepAlive: true)`
5. UI consome como? → `ref.watch(controller)` + `ref.read(repo)` só no notifier

**Pass**: respostas sem ambiguidade.

---

## 8. PR checklist

Antes de merge, copiar [contracts/pr-review-checklist.md](./contracts/pr-review-checklist.md) na descrição do PR e marcar itens aplicáveis.

---

## Troubleshooting

| Sintoma | Causa provável | Ação |
|---------|----------------|------|
| Imports quebrados após move | paths antigos | `dart fix --apply`; buscar feature root |
| Testes falham após rename provider | override path | atualizar `test_providers_setup.dart` |
| E2E não acha rota workout | GoRouter params | conferir `route_names.dart` e factories |
| Hot reload perde router | nova instância GoRouter | manter `routerProvider` singleton |

---

## Links

- [research.md](./research.md) — decisões DP-01..04
- [data-model.md](./data-model.md) — entidades de governança
- [riverpod-conventions.md](./contracts/riverpod-conventions.md)
