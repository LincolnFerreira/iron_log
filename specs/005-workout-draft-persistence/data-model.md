# Data Model: Persistência de Rascunhos de Treino

**Feature**: `005-workout-draft-persistence` | **Storage**: Drift (SQLite local) | **Schema**: v6 → v7

## Entity: WorkoutDraft

Representação local unificada de treino **em andamento** ou **aguardando envio**. Substitui o papel operacional de `WorkoutOutbox` para novos registros.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | TEXT | yes | PK; `draft_{micros}` ou reutiliza `ob_*` migrado |
| `userId` | TEXT | yes | Firebase UID |
| `status` | TEXT | yes | `inProgress` \| `pendingUpload` \| `failedValidation` (diagnóstico; nunca auto-delete) |
| `routineId` | TEXT | no | Rotina associada |
| `sessionId` | TEXT | no | Sessão do plano |
| `serverWorkoutId` | TEXT | no | ID remoto se start/create já obteve resposta parcial |
| `pendingOperation` | TEXT | yes | `create` \| `patch` |
| `snapshotJson` | TEXT | yes | `draftSnapshotV1` — estado UI + exercícios |
| `apiPayloadJson` | TEXT | no | Corpo POST/PATCH pronto; preenchido no finalize |
| `startedAt` | DateTime | yes | Início do treino |
| `endedAt` | DateTime | no | Preenchido ao finalizar localmente |
| `manualDate` | DateTime | no | Data retroativa quando aplicável |
| `timerStartedAt` | DateTime | no | Para restaurar timer ao vivo |
| `accumulatedDurationSeconds` | INT | no | Fallback de duração |
| `lastErrorType` | TEXT | no | Ex. `badResponse`, `connectionError` |
| `lastErrorStatusCode` | INT | no | HTTP status quando houver |
| `lastAttemptAt` | DateTime | no | Última tentativa de upload |
| `createdAt` | DateTime | yes | default now |
| `updatedAt` | DateTime | yes | Atualizado a cada auto-save |

### Indexes

- `{ userId, status }` — query Home “Continuar” (`inProgress`)
- `{ userId, status, updatedAt }` — lista `pendingUpload`
- **Unique partial** (app-level): no máximo um `inProgress` por `userId` (enforced no repository)

### Validation rules

- `snapshotJson` MUST parsear como JSON com `schemaVersion: 1`.
- `status = pendingUpload` MUST ter `apiPayloadJson` não vazio antes de flush.
- `pendingOperation = patch` MUST ter `serverWorkoutId` ou id local mapeável.
- Rows MUST NOT ser deleted por falha de rede/API; delete apenas após upload confirmado.

---

## Value object: DraftSnapshotV1 (`snapshotJson`)

```json
{
  "schemaVersion": 1,
  "screenMode": "execution",
  "workoutStarted": true,
  "exercises": [ "/* WorkoutExercise + entries + blocks */" ],
  "subtitle": "Peito A - Minha Rotina",
  "workoutSessionId": "uuid-or-local"
}
```

| Field | Type | Notes |
|-------|------|-------|
| `schemaVersion` | int | sempre `1` na v1 |
| `screenMode` | string | `execution` \| `editing` — alinhado `WorkoutScreenMode` |
| `workoutStarted` | bool | Botão já foi “Iniciar” |
| `exercises` | array | Lista serializada completa |
| `subtitle` | string | UI |
| `workoutSessionId` | string? | Provider atual persistido |

---

## State transitions

```text
                    startExecution / first auto-save
         ┌──────────────────────────────────────────┐
         │                                          ▼
    (none) ──────────────────────────────► inProgress
         │                                    │    │
         │                                    │    │ sair sem finalizar
         │                                    │    └──────────► inProgress (persistido)
         │                                    │
         │                                    │ finishWorkout (ok ou falha API)
         │                                    ▼
         │                              pendingUpload
         │                                    │
         │              flush success         │ flush fail
         │                    ▼               └──────────► pendingUpload (intacto)
         │                 [DELETE]
         │
         └─ migrate from WorkoutOutbox ─────► pendingUpload
```

`failedValidation`: opcional quando payload irrecuperável para API mas snapshot preservado para suporte.

---

## Entity: WorkoutOutbox (legacy)

| Ação | Detalhe |
|------|---------|
| Migration v7 | Copiar rows válidas → `WorkoutDrafts` (`status=pendingUpload`, `pendingOperation` do envelope) |
| Runtime pós-migration | `flushWorkoutOutbox` delega para `WorkoutDraftSyncService` ou lê drafts |
| Novos writes | **Não** inserir em `WorkoutOutbox` |

---

## Provider / read models (não persistidos)

| Model | Uso |
|-------|-----|
| `WorkoutDraftSummary` | Home card: sessionName, exerciseCount, startedAt, draftId |
| `PendingUploadItem` | Lista de reenvio: draftId, date, error hint |

---

## Relationships

```text
User (Firebase) 1 ── * WorkoutDraft
WorkoutDraft * ── 0..1 serverWorkoutId (WorkoutSession remota)
WorkoutDraft * ── 0..1 sessionId (Session plano)
WorkoutDraft * ── 0..1 routineId (Routine)
```

Nenhuma FK Drift para tabelas remotas — apenas TEXT ids.
