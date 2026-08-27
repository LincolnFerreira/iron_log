# Research: 010-state-management-audit

**Date**: 2026-08-27  
**Spec**: [spec.md](./spec.md)

## R1 — Padrão de side-effect (`ref.listen`)

**Decision**: Side-effects reativos a mudança de provider (erro, sucesso, navegação pós-estado) MUST usar `ref.listen` no widget `Consumer*` que possui `BuildContext` válido — tipicamente a **page** ou **ConsumerStatefulWidget** pai do fluxo.

**Rationale**: Constituição III e contrato 006 já exigem; grep confirma **0** usos de `ref.listen` hoje vs ~62 call sites de snackbar — gap principal da feature.

**Padrão escolhido**:

```dart
@override
Widget build(BuildContext context) {
  ref.listen(authControllerProvider, (previous, next) {
    next.whenOrNull(
      error: (e, _) => AppSnackbar.showError(context, message: ...),
    );
  });
  // watch separado para UI
  final authState = ref.watch(authControllerProvider);
  ...
}
```

**Alternatives considered**:

- **Helper global / mixin `ListenSideEffects`**: rejeitado — esconde contexto e dificulta review; preferir listener explícito na page.
- **Side-effect dentro do Notifier** (`AppSnackbar` no controller): rejeitado — notifier não tem `BuildContext`; acopla UI ao domínio.
- **Manter `ScaffoldMessenger` em callbacks imperativos**: aceitável **só** para ações 100% síncronas locais (ex.: validação de form antes de chamar controller); MUST migrar quando feedback depende de `AsyncValue`.

---

## R2 — Fronteira `setState` vs Riverpod

**Decision**: Três categorias documentadas no inventário:

| Categoria | Exemplo | Ação |
|-----------|---------|------|
| **A — Efêmero local** | expansão de tile, foco, animação drag | `setState` OK — registrar como `accepted_exception` |
| **B — Espelho de provider** | loading duplicado (`login_screen._isLoading`) enquanto controller já tem `AsyncLoading` | Migrar para `ref.watch` do controller |
| **C — Estado de domínio local** | lista de exercícios editada só em sheet sem controller | Migrar para Notifier ou callback que chama controller existente |

**Rationale**: FR-006; 20 arquivos com `setState` — maioria em `workout_day`/`routines` (categoria B/C).

**Alternatives considered**: Proibir todo `setState` — rejeitado (Flutter idiom para UI pura). Migrar tudo para Riverpod de uma vez — rejeitado (rewrite monólito).

---

## R3 — Watch vs read em wiring de providers

**Decision**:

- `*_providers.dart` na raiz da feature e `presentation/providers/*`: wiring de repo MUST usar `ref.read` no `overrideWith` / factory — MUST NOT `ref.watch(routineRepositoryProviderImpl)`.
- Providers `@riverpod` que **derivam dados** (ex.: `browseExercises`) MAY `watch` datasource **dentro do provider** se o retorno é estado cacheado — preferir `read` + invalidação explícita quando não precisa rebuild cascata.

**Hotspots confirmados**:

- `lib/features/routines/routine_providers.dart:54` — `ref.watch(routineRepositoryProviderImpl)`
- `lib/features/routines/presentation/providers/exercise_browse_provider.dart:9` — `ref.watch(exerciseRemoteDataSourceProvider)`

**Alternatives considered**: Manter watch “porque provider rebuilda anyway” — rejeitado (cascata e confusão DI/estado).

---

## R4 — Ciclo de widget e async

**Decision**: Hierarquia de preferência para callbacks async em widgets:

1. **Melhor**: operação no Notifier; UI só `listen` + `watch` — dispose do provider cancela via `ref.onDispose` se necessário
2. **Aceitável**: `if (!context.mounted) return` antes de side-effect após `await` em callback de widget
3. **Proibido**: `setState` após `await` sem guarda; snackbar após pop sem listener desmontado

**Rationale**: FR-005; padrão ad hoc de `mounted` espalhado em `workout_session_screen`, sheets.

**Alternatives considered**: `CancelToken` global por tela — rejeitado como padrão obrigatório (complexidade); usar quando Notifier já gerencia stream longa.

---

## R5 — Rebuild mínimo (`.select`)

**Decision**: Ao remediar qualquer arquivo P1/P2, aplicar `.select` quando widget consome **subconjunto** de estado (padrão já aplicado em `home_template.dart` / `home_header_providers.dart` na 008).

**Gabaritos existentes**:

- `home_page.dart` — Consumers delegados ao template
- `elapsedTimeProvider` — timer isolado (referência SC-006)

**Alternatives considered**: Provider derivado `@riverpod` para cada campo — usar quando `.select` ficar ilegível; não obrigatório em toda tela upfront.

---

## R6 — Inventário inicial de hotspots P1 (side-effects)

**Decision**: Ordem de remediação side-effect:

| Ordem | Área | Arquivos (amostra) | Motivo |
|-------|------|-------------------|--------|
| 1 | auth | `login_screen.dart` | Entrada do app; loading duplicado + snackbars imperativos |
| 2 | workout_day | `workout_day_screen.dart`, `workout_finish_flow.dart` | Fluxo crítico treino |
| 3 | routines | `routines_page.dart`, `session_detail_content.dart` | CRUD rotina |
| 4 | home | `rest_day_creation_sheet.dart`, `activity_type_selection_sheet.dart` | Sheets com ScaffoldMessenger |
| 5 | workout_creation | `add_workout_bottom_sheet.dart`, `quick_workout_creation_page.dart` | Criação rápida |

**Alternatives considered**: Big-bang em todos os 62 sites — rejeitado (FR-007).

---

## R7 — Relação com 008 RX-*

**Decision**: Não reabrir trabalho `done` da 008 (`RX-home-watches`, `RX-di-watch` home). Ampliar `.select` e `read` em **outras** features durante P2 desta 010.

**Rationale**: Evitar churn duplicado; 008 deixou “open elsewhere” em RX-select-coverage.

---

## R8 — Checklist e enforcement

**Decision**: Estender (não substituir) `006/contracts/pr-review-checklist.md` com seção estado em `contracts/state-enforcement.md`; greps copy-paste no quickstart.

**Rationale**: SC-005; revisor audita PR em <10 min.
