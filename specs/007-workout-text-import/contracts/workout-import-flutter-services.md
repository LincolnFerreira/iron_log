# Contract: Workout Import Services (Flutter)

**Feature**: `007-workout-text-import`  
**Scope**: `iron_log` — camadas `domain` / `data` / `presentation`  
**Feature path**: `lib/features/workout_import/`

---

## `WorkoutImportRepository` (domain interface)

```dart
abstract class WorkoutImportRepository {
  /// Salva texto localmente e chama parse remoto; retorna draft em reviewing.
  Future<WorkoutImportDraft> parseText(String rawText);

  /// Recarrega draft local por id.
  Future<WorkoutImportDraft?> getDraft(String draftId);

  /// Lista drafts em reviewing (resume após kill app).
  Future<List<WorkoutImportDraft>> listActiveDrafts(String userId);

  /// Persiste edições da UI no snapshot local.
  Future<void> saveReviewEdits(String draftId, ParsedWorkoutImport snapshot);

  /// Confirma: POST /confirm + grava WorkoutSessions locais pendingSync.
  Future<WorkoutImportConfirmResult> confirm(String draftId);

  /// Descarta draft local (+ opcional discard remoto futuro).
  Future<void> discard(String draftId);
}
```

### Invariants

- `parseText` MUST NOT criar `WorkoutSession` local com séries finais antes de `confirm`
- `confirm` MUST usar transação Drift para todas as sessões da importação
- Falha de rede no `confirm` MUST manter draft em `reviewing` ou `confirming` com `lastError`

---

## `WorkoutImportRemoteDataSource`

```dart
abstract class WorkoutImportRemoteDataSource {
  Future<ParseImportResponse> parse({required String rawText});
  Future<ConfirmImportResponse> confirm(ConfirmImportRequest request);
  Future<ImportAuditResponse> getImport(String importId);
}
```

Usa `HttpService` + `ApiEndpoints.workoutImport*`. Erros → `HttpErrorHandler.getUserFriendlyMessage()`.

---

## `WorkoutImportLocalDataSource`

```dart
abstract class WorkoutImportLocalDataSource {
  Future<void> upsertDraft(WorkoutImportDraft draft);
  Future<WorkoutImportDraft?> findById(String id);
  Future<List<WorkoutImportDraft>> findByStatus(String userId, Set<ImportDraftStatus> statuses);
  Future<void> deleteDraft(String id);
}
```

Tabela: `WorkoutImportDrafts` (ver [data-model.md](../data-model.md)).

---

## `WorkoutImportController` (`@riverpod` AsyncNotifier)

```dart
@riverpod
class WorkoutImportController extends _$WorkoutImportController {
  Future<void> submitText(String text);
  Future<void> updateExercise(String sessionKey, String exerciseKey, ...);
  Future<void> removeExercise(String sessionKey, String exerciseKey);
  Future<void> updateSet(...);
  Future<void> setSessionDate(String sessionKey, DateTime? date);
  Future<WorkoutImportConfirmResult> confirm();
  Future<void> discard();
}
```

**Estado**: `AsyncValue<WorkoutImportReviewState>` com `draftId`, `snapshot`, `rawTextVisible`.

**Side-effects** (`ref.listen` na page, não no `build`):
- Snackbar em erro de parse/confirm
- `context.go` para histórico após confirm bem-sucedido

---

## `WorkoutImportConfirmMapper`

Converte `ParsedWorkoutImport` (pós-edição) →  
1. `ConfirmImportRequest` (API)  
2. `List<WorkoutSessionsCompanion>` + `SerieLogsCompanion` (Drift)

Reutiliza mapeamento de esforço de [research.md](../research.md#r4--mapeamento-tipo-de-esforço--modelo-existente).

---

## UI contracts (pages)

| Route | Widget | Responsibility |
|-------|--------|----------------|
| `/workout/import` | `WorkoutImportPastePage` | Textarea, contador chars, botão "Interpretar" |
| `/workout/import/review/:draftId` | `WorkoutImportReviewPage` | Lista sessões, edição inline, ver texto original, confirmar/cancelar |

**Componentes** (atomic design sob `presentation/`):
- `ImportSessionCard` — título, data, badge incerteza
- `ImportExerciseTile` — nome editável, link picker catálogo (`UnifiedExerciseSearch`)
- `ImportSetRow` — peso, reps, chip tipo esforço
- `ImportUncertaintyBanner` — fragmentos não mapeados

---

## Provider registration (`main.dart`)

```dart
List<Override> get workoutImportProvidersOverrides => [
  workoutImportRepositoryProvider.overrideWithValue(
    WorkoutImportRepositoryImpl(
      local: WorkoutImportLocalDataSourceImpl(db),
      remote: WorkoutImportRemoteDataSourceImpl(http),
      confirmMapper: WorkoutImportConfirmMapper(),
    ),
  ),
];
```

---

## Test contracts

| Test | Validates |
|------|-----------|
| `workout_import_confirm_mapper_test.dart` | effortType → SerieLog fields |
| `workout_import_controller_test.dart` | parse → edit → confirm sem persist antes |
| `workout_import_review_page_test.dart` | remove exercise, confirm disabled when empty |
| Backend `workout-import.service.spec.ts` | golden texts, no invent data, multi-session |

Golden texts: `test/fixtures/workout_import/*.txt` (mín. 20 para SC-002).
