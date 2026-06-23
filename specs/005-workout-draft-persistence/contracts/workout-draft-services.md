# Contracts: Workout Draft Services (Cliente Flutter)

**Feature**: `005-workout-draft-persistence` | **Scope**: `iron_log` only

Contratos internos entre camadas `data` ↔ `domain` ↔ `presentation`. API REST do backend **inalterada**.

---

## `WorkoutDraftRepository` (interface — domain)

```dart
abstract class WorkoutDraftRepository {
  Future<WorkoutDraft?> getActiveInProgress(String userId);
  Future<List<WorkoutDraft>> listPendingUpload(String userId);
  Future<WorkoutDraft?> getById(String draftId);
  Future<void> saveInProgress(WorkoutDraft draft);
  Future<void> markPendingUpload({
    required String draftId,
    required Map<String, dynamic> apiPayload,
    String? serverWorkoutId,
    required PendingOperation operation,
    DateTime? endedAt,
  });
  Future<void> deleteAfterSuccessfulUpload(String draftId);
  Future<void> recordUploadFailure(String draftId, DraftUploadError error);
}
```

### Invariants

- `saveInProgress` MUST upsert; se outro `inProgress` existir para o mesmo `userId`, MUST atualizar o mesmo row (único ativo).
- `deleteAfterSuccessfulUpload` é o **único** delete automático permitido.

---

## `WorkoutDraftSnapshotMapper`

```dart
abstract class WorkoutDraftSnapshotMapper {
  String encode(DraftSnapshotV1 snapshot);
  DraftSnapshotV1 decode(String json);
  DraftSnapshotV1 fromExecutionState({
    required List<WorkoutExercise> exercises,
    required WorkoutScreenMode screenMode,
    required bool workoutStarted,
    String? subtitle,
    String? workoutSessionId,
    DateTime? timerStartedAt,
    int? accumulatedDurationSeconds,
  });
  void applyToProviders(DraftSnapshotV1 snapshot, Ref ref); // resume
}
```

---

## `WorkoutDraftSyncService`

```dart
abstract class WorkoutDraftSyncService {
  /// Envia todos `pendingUpload` do usuário atual; retorna contagem synced/failed.
  Future<DraftFlushResult> flushPendingUploads({bool stopOnFirstError = false});
}
```

### Behavior contract

| Cenário | Resultado |
|---------|-----------|
| POST sucesso | `deleteAfterSuccessfulUpload`; retorna `workoutId` para atualizar histórico local se necessário |
| PATCH sucesso | idem |
| Qualquer DioException | `recordUploadFailure`; row **permanece** |
| Payload inválido local | `status = failedValidation`; **não** delete |

Reutiliza `WorkoutLogService` / `AuthService` para HTTP — não duplicar montagem de DTO.

---

## `WorkoutLogService` (alteração de contrato comportamental)

| Método | Comportamento novo |
|--------|-------------------|
| `saveWorkout` | Em falha: MUST chamar `WorkoutDraftRepository.markPendingUpload` (ou `saveInProgress`→pending no finish flow) antes de propagar erro à UI |
| `saveWorkout` + `skipOutboxEnqueueOnUnreachable` | **Deprecar** skip para draft: start offline MUST criar `inProgress` draft + `local_` id |
| `updateWorkout` | Mesma regra de persistência em qualquer falha |

---

## UI contracts

### `ContinueWorkoutButton`

| Prop | Tipo | Descrição |
|------|------|-----------|
| `sessionName` | String | Do draft summary |
| `exerciseCount` | int | |
| `onTap` | VoidCallback | Navega para resume |
| `isLoading` | bool | |

Label fixo: **CONTINUAR TREINO** (pt-BR, espelha `INICIAR TREINO`).

### `WorkoutDayScreen.resume`

```dart
WorkoutDayScreen.resume({
  required String draftId,
});
```

MUST:
1. Carregar draft do repository
2. `applyToProviders` no `initState`
3. Restaurar timer se `timerStartedAt != null`
4. Não chamar `startExecution` novamente se `workoutStarted == true`

### `ActiveWorkoutCard`

| Prop nova | Tipo |
|-----------|------|
| `activeDraft` | `WorkoutDraftSummary?` |
| `onContinueWorkout` | `VoidCallback?` |

Se `activeDraft != null`: exibir `ContinueWorkoutButton` **em vez de** `StartWorkoutButton`.

---

## API externa (backend — referência, sem mudança)

| Operação | Endpoint | Usado por |
|----------|----------|-----------|
| Create | `POST /workout` | `pendingOperation=create` |
| Update | `PATCH /workout/:id` | `pendingOperation=patch` |

Payload: idêntico ao `WorkoutLogService` atual (`exercises`, `date`, `endedAt`, `sessionId`, `techniqueBlocks`, etc.).
