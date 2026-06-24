# Data Model: Importação de Treino por Texto Livre

**Feature**: `007-workout-text-import`  
**Storage**: PostgreSQL (backend) + Drift SQLite (cliente)  
**Repos**: `iron_log_back_end` + `iron_log`

---

## Backend entities (PostgreSQL / Prisma)

### WorkoutTextImport

Registro de auditoria de uma importação; **não** é treino executável até `confirm`.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String (cuid) | yes | PK |
| `userId` | String | yes | FK → User |
| `rawText` | String (text) | yes | Texto original colado (imutável após create) |
| `status` | enum | yes | `parsed` \| `confirmed` \| `discarded` |
| `parsedSnapshot` | Json | no | Última sugestão estruturada da IA (auditoria) |
| `modelVersion` | String | no | Ex. `gemini-2.5-flash@v1` |
| `createdAt` | DateTime | yes | |
| `updatedAt` | DateTime | yes | |
| `confirmedAt` | DateTime | no | Preenchido no confirm |

**Indexes**: `{ userId, createdAt }`, `{ userId, status }`

**Validation**:
- `rawText` length ≤ 16_000 chars
- `rawText` MUST NOT ser alterado após insert
- `status = confirmed` MUST ter ≥1 `WorkoutSession` vinculada

---

### WorkoutSession (extensão)

Campo novo opcional:

| Field | Type | Description |
|-------|------|-------------|
| `importId` | String? | FK → `WorkoutTextImport.id` quando originado de importação |

Treinos confirmados: `isManual: true`, `type: training`, `routineId` → rotina oculta de importação, `sessionId` → sessão "Importado".

---

### Routine / Session (import bucket — sistema)

Criados lazy por usuário; **não** expostos na UI de rotinas.

| Entity | Identificação | Notes |
|--------|---------------|-------|
| `Routine` | `source = 'import'` + `userId` | Nome interno: `__import_history__` |
| `Session` | única por rotina import | Nome: `Importado`, `order: 0` |

`SessionExercise` criado on-demand no confirm para cada exercício distinto.

---

## API value objects (JSON — não persistidos como entidade separada até confirm)

### ParsedWorkoutImport (resposta de `/parse`)

```json
{
  "importId": "cuid",
  "sessions": [
    {
      "clientKey": "s0",
      "title": "Upper 1",
      "titleConfidence": "high",
      "scheduledDate": null,
      "dateConfidence": "undetermined",
      "sessionNotes": "string?",
      "exercises": [
        {
          "clientKey": "e0",
          "name": "Supino reto",
          "nameConfidence": "medium",
          "suggestedExerciseId": null,
          "notes": "Senti ombro no último set",
          "sets": [
            {
              "clientKey": "set0",
              "weight": 20,
              "reps": 15,
              "weightUnit": "kg",
              "effortType": "warmup",
              "effortConfidence": "high",
              "isFailure": false,
              "label": "Warm-up"
            }
          ],
          "uncertainties": ["weight_unit_ambiguous"]
        }
      ]
    }
  ],
  "unmappedFragments": ["trecho não estruturado preservado"],
  "parserWarnings": ["multiple_upper_lower_detected"]
}
```

### ConfirmedWorkoutImport (body de `/confirm`)

Mesma árvore, editada pelo usuário, mais:

| Field | Type | Notes |
|-------|------|-------|
| `importId` | string | obrigatório |
| `sessions[].scheduledDate` | ISO date? | usuário pode definir na revisão |
| `sessions[].exercises[].exerciseId` | string? | override após picker |
| `sessions[].exercises[].removed` | bool | default false |
| `sessions[].removed` | bool | default false |

---

## Effort type enum (domínio compartilhado)

| Value | Meaning |
|-------|---------|
| `warmup` | Aquecimento / leve |
| `feeder` | Preparatória |
| `work` | Série válida (progressão) |
| `failure` | Tentativa falha |
| `uncertain` | Classificação incerta |

Mapeamento para `SerieLog`: ver [research.md](./research.md#r4--mapeamento-tipo-de-esforço--modelo-existente).

---

## Client entity (Drift): WorkoutImportDraft

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | TEXT | yes | PK local `import_{micros}` |
| `userId` | TEXT | yes | Firebase UID |
| `importId` | TEXT | no | ID remoto após parse bem-sucedido |
| `status` | TEXT | yes | `draft` \| `parsing` \| `reviewing` \| `confirming` \| `confirmed` \| `discarded` |
| `rawText` | TEXT | yes | Cópia local do texto |
| `reviewSnapshotJson` | TEXT | yes | `ParsedWorkoutImport` + edições UI |
| `lastError` | TEXT | no | Mensagem amigável |
| `createdAt` | DateTime | yes | |
| `updatedAt` | DateTime | yes | |

**Indexes**: `{ userId, status }`

---

## State transitions

### Server: WorkoutTextImport

```text
(parse) ──► parsed ──► confirmed   (POST /confirm)
              │
              └──► discarded       (opcional: DELETE ou PATCH status)
```

### Client: WorkoutImportDraft

```text
draft ──► parsing ──► reviewing ──► confirming ──► confirmed
  │          │            │              │
  └──────────┴────────────┴──────────────┴──► discarded
```

**Invariants**:
- Nenhum `WorkoutSession` com `importId` criado antes de `POST /confirm`
- `reviewing` MUST ter `reviewSnapshotJson` válido
- Texto original em draft e em `WorkoutTextImport` MUST permanecer idêntico ao colado

---

## Relationships

```text
User 1──* WorkoutTextImport
WorkoutTextImport 1──* WorkoutSession (após confirm)
WorkoutSession 1──* SerieLog
SerieLog *──1 SessionExercise (bucket import)
SessionExercise *──1 Exercise
Routine (import) 1──1 Session (Importado) per user
```
