# Contract: Workout Import API (Backend)

**Feature**: `007-workout-text-import`  
**Base path**: `/workout-import`  
**Auth**: `FirebaseAuthGuard` — todas as rotas  
**Repo**: `iron_log_back_end`

---

## POST `/workout-import/parse`

Interpreta texto livre e persiste registro de auditoria. **Não cria treinos.**

### Request

```json
{
  "rawText": "Upper 1\nSupino 20x15 40x10..."
}
```

| Field | Type | Rules |
|-------|------|-------|
| `rawText` | string | required, trim, 1–16000 chars |

### Response `200`

```json
{
  "importId": "cmxxx",
  "parsed": { /* ParsedWorkoutImport — ver data-model.md */ }
}
```

### Errors

| Status | When |
|--------|------|
| `400` | Texto vazio, muito longo, ou JSON da IA inválido após retry |
| `401` | Token inválido |
| `422` | IA não extraiu nenhuma sessão/exercício estruturável (`code: UNSTRUCTURABLE_TEXT`) |
| `503` | Gemini indisponível (`code: AI_UNAVAILABLE`) |

### Behavior

- Cria `WorkoutTextImport` com `status: parsed`, `rawText`, `parsedSnapshot`
- Prompt MUST instruir: não inventar dados, marcar incertezas, separar sessões, preservar anotações
- Retry interno: 1 re-parse se JSON inválido
- Latência alvo: p95 < 30s (texto médio)

---

## POST `/workout-import/confirm`

Persiste treinos **após revisão humana** no cliente.

### Request

```json
{
  "importId": "cmxxx",
  "sessions": [
    {
      "clientKey": "s0",
      "title": "Upper 1",
      "scheduledDate": "2025-03-12",
      "removed": false,
      "sessionNotes": null,
      "exercises": [
        {
          "clientKey": "e0",
          "name": "Supino reto",
          "exerciseId": "cmeyyy",
          "removed": false,
          "notes": "Senti ombro",
          "sets": [
            {
              "weight": 40,
              "reps": 10,
              "weightUnit": "kg",
              "effortType": "work",
              "isFailure": false
            }
          ]
        }
      ]
    }
  ]
}
```

| Field | Rules |
|-------|-------|
| `importId` | MUST existir, `status: parsed`, pertencer ao user |
| `sessions` | min 1 após filter `removed != true` |
| `scheduledDate` | ISO date; se ausente, usa `startedAt` = now UTC date (documentado na resposta) |
| `exercises[].sets` | min 1 por exercício não removido |
| `weight` / `reps` | nullable se usuário deixou em branco na revisão |

### Response `201`

```json
{
  "importId": "cmxxx",
  "status": "confirmed",
  "workoutIds": ["ws1", "ws2"],
  "createdAt": "2026-06-23T12:00:00.000Z"
}
```

### Errors

| Status | When |
|--------|------|
| `400` | Payload inválido, sessão sem exercícios |
| `404` | `importId` não encontrado |
| `409` | `importId` já `confirmed` |
| `422` | Exercício não resolvível mesmo após find-or-create |

### Behavior

- `$transaction`: para cada sessão → `WorkoutSession` + séries via import resolver
- Atualiza `WorkoutTextImport.status = confirmed`, `confirmedAt`
- `WorkoutSession.importId` preenchido
- `isManual: true` em todas as sessões criadas
- Idempotência: segundo confirm com mesmo `importId` → `409`

---

## GET `/workout-import/:importId`

Recupera texto original + snapshot para auditoria / reabrir revisão (opcional v1, recomendado).

### Response `200`

```json
{
  "importId": "cmxxx",
  "rawText": "...",
  "status": "parsed",
  "parsedSnapshot": { },
  "workoutIds": [],
  "createdAt": "...",
  "confirmedAt": null
}
```

Se `confirmed`, `workoutIds` preenchido.

---

## Swagger

Registrar em `WorkoutImportModule` com tags `workout-import`. Adicionar paths em `iron_log/lib/core/api/api_endpoints.dart`:

```dart
static const String workoutImportParse = '/workout-import/parse';
static const String workoutImportConfirm = '/workout-import/confirm';
static String workoutImportById(String id) => '/workout-import/$id';
```

---

## Sync

Treinos criados seguem campos `version`, `pendingSync`, `syncedAt` padrão. Cliente Drift grava local com `pendingSync: true` e inclui no `SyncManager` existente (pull/push de `WorkoutSession`).

`WorkoutTextImport` é **server-only** na v1 (não replica Drift).
